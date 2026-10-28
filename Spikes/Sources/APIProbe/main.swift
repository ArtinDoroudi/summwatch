// M1 API spike: validate TLS against Riot's root cert, discover the leaf hostname, capture the Swagger
// schema, and record raw allgamedata timelines across game phases. Output goes to Spikes/out/ (gitignored:
// recordings contain real Riot IDs).
//
//   swift run --package-path Spikes api-probe probe              # one-shot: TLS report + every endpoint
//   swift run --package-path Spikes api-probe record [seconds]   # poll allgamedata until Ctrl-C (default 1 s)
import Foundation
import Security

let outDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("out")
let base = URL(string: "https://127.0.0.1:2999")!
let pemURL = URL(string: "https://static.developer.riotgames.com/docs/lol/riotgames.pem")!

func log(_ s: String) { print(s) }

// MARK: - Riot root certificate

func loadRiotRoot() async throws -> SecCertificate {
    let cached = outDir.appendingPathComponent("riotgames.pem")
    let pem: String
    if let text = try? String(contentsOf: cached, encoding: .utf8) {
        pem = text
    } else {
        let (data, _) = try await URLSession.shared.data(from: pemURL)
        pem = String(decoding: data, as: UTF8.self)
        try? data.write(to: cached)
    }
    let b64 = pem.split(whereSeparator: \.isNewline).filter { !$0.hasPrefix("-----") }.joined()  // file uses CRLF
    guard let der = Data(base64Encoded: b64), let cert = SecCertificateCreateWithData(nil, der as CFData) else {
        throw NSError(domain: "probe", code: 1, userInfo: [NSLocalizedDescriptionKey: "could not parse riotgames.pem"])
    }
    log("Riot root: \(SecCertificateCopySubjectSummary(cert) as String? ?? "?")")
    return cert
}

// host == "basic" uses plain X.509 chain validation. Apple's SSL policy rejects Riot's leaf ("not standards
// compliant") because it is valid for 100 years, beyond Apple's 825-day TLS limit; the chain itself is fine.
func evaluate(_ trust: SecTrust, anchor: SecCertificate, host: String?) -> String {
    SecTrustSetPolicies(trust, host == "basic" ? SecPolicyCreateBasicX509() : SecPolicyCreateSSL(true, host as CFString?))
    SecTrustSetAnchorCertificates(trust, [anchor] as CFArray)
    SecTrustSetAnchorCertificatesOnly(trust, true)
    var error: CFError?
    let ok = SecTrustEvaluateWithError(trust, &error)
    return ok ? "PASS" : "FAIL (\(error.map { CFErrorCopyDescription($0) as String } ?? "?"))"
}

final class RiotTrust: NSObject, URLSessionDelegate {
    let anchor: SecCertificate
    var reported = false
    init(anchor: SecCertificate) { self.anchor = anchor }

    func urlSession(
        _ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else { return completionHandler(.performDefaultHandling, nil) }

        if !reported {
            reported = true
            let chain = (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
            for (i, cert) in chain.enumerated() {
                log("chain[\(i)]: \(SecCertificateCopySubjectSummary(cert) as String? ?? "?")")
            }
            if let leaf = chain.first,
                let values = SecCertificateCopyValues(leaf, [kSecOIDSubjectAltName] as CFArray, nil) as? [String: Any]
            {
                log("leaf subjectAltName: \(values[kSecOIDSubjectAltName as String] ?? "none")")
            }
            for host in ["127.0.0.1", "localhost", "rclient", nil, "basic"] as [String?] {
                log("trust eval host=\(host ?? "<no hostname check>"): \(evaluate(trust, anchor: anchor, host: host))")
            }
        }
        // Accept only if the chain anchors to Riot's root (basic X.509) and the leaf names 127.0.0.1.
        let leafNames127 = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first.flatMap {
            SecCertificateCopyValues($0, [kSecOIDSubjectAltName] as CFArray, nil) as? [String: Any]
        }.map { "\($0)".contains("127.0.0.1") } ?? false
        let ok = leafNames127 && evaluate(trust, anchor: anchor, host: "basic").hasPrefix("PASS")
        completionHandler(ok ? .useCredential : .cancelAuthenticationChallenge, ok ? URLCredential(trust: trust) : nil)
    }
}

// MARK: - Requests

func get(_ session: URLSession, _ path: String) async -> (status: Int?, body: Data?, error: String?) {
    var request = URLRequest(url: base.appendingPathComponent(path))
    request.timeoutInterval = 2
    do {
        let (data, response) = try await session.data(for: request)
        return ((response as? HTTPURLResponse)?.statusCode, data, nil)
    } catch {
        return (nil, nil, (error as NSError).localizedDescription + " [\((error as NSError).code)]")
    }
}

func gameTime(_ body: Data?) -> Double? {
    guard let body, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
    return (json["gameData"] as? [String: Any])?["gameTime"] as? Double
}

// MARK: - Main

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let anchor = try await loadRiotRoot()
let delegate = RiotTrust(anchor: anchor)
let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
let mode = CommandLine.arguments.dropFirst().first ?? "probe"

switch mode {
case "probe":
    let probeDir = outDir.appendingPathComponent("probe")
    try FileManager.default.createDirectory(at: probeDir, withIntermediateDirectories: true)
    let endpoints = [
        "swagger/v3/openapi.json", "liveclientdata/allgamedata", "liveclientdata/activeplayer",
        "liveclientdata/playerlist", "liveclientdata/eventdata", "liveclientdata/gamestats",
    ]
    for path in endpoints {
        let r = await get(session, path)
        log("GET /\(path) -> \(r.status.map(String.init) ?? "no response") \(r.error ?? "") \(r.body?.count ?? 0) bytes")
        if let body = r.body {
            try body.write(to: probeDir.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_")))
        }
    }
    log("saved to \(probeDir.path)")

case "record":
    let interval = Double(CommandLine.arguments.dropFirst(2).first ?? "1") ?? 1
    let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    let dir = outDir.appendingPathComponent("raw/\(stamp)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: dir.appendingPathComponent("index.jsonl").path, contents: nil)
    let index = try FileHandle(forWritingTo: dir.appendingPathComponent("index.jsonl"))
    log("recording allgamedata every \(interval)s to \(dir.path). Ctrl-C to stop.")
    var seq = 0
    var lastSummary = ""
    while true {
        let started = Date()
        let r = await get(session, "liveclientdata/allgamedata")
        let name = String(format: "%05d", seq)
        if let body = r.body { try body.write(to: dir.appendingPathComponent("\(name).json")) }
        let entry: [String: Any] = [
            "seq": seq, "wall": started.timeIntervalSince1970, "status": r.status ?? NSNull(),
            "error": r.error ?? NSNull(), "gameTime": gameTime(r.body) ?? NSNull(),
        ]
        index.write(try JSONSerialization.data(withJSONObject: entry) + Data("\n".utf8))
        let summary = "status=\(r.status.map(String.init) ?? "none") \(r.error ?? "")"
        if summary != lastSummary {
            log("[\(name)] phase change: \(summary) gameTime=\(gameTime(r.body).map { String($0) } ?? "-")")
            lastSummary = summary
        }
        seq += 1
        try await Task.sleep(for: .seconds(max(0, interval - Date().timeIntervalSince(started))))
    }

default:
    log("usage: api-probe probe | api-probe record [seconds]")
}
