// M1 overlay spike: does an NSPanel stay above League in each window mode, pass clicks through,
// accept clicks only while ⌃⌥ is held, and never steal focus? Everything is logged to Spikes/out/overlay.log.
//
//   swift run --package-path Spikes overlay-spike [--level screenSaver|statusBar|floating] [--consume-f1]
//
// Hotkeys: hold ⌃⌥ = interaction mode · ⌃⌥I = toggle interaction latch · ⌃⌥1…5 = mark row
//          ⌃⌥C = copy test chat line · ⌃⌥Q = quit · F1 (only with --consume-f1) = consumption test
import AppKit
import Carbon.HIToolbox

// MARK: - Args & logging

let args = CommandLine.arguments
func value(for flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let outDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("out")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let logURL = outDir.appendingPathComponent("overlay.log")
FileManager.default.createFile(atPath: logURL.path, contents: nil)
let logHandle = try! FileHandle(forWritingTo: logURL)

func log(_ message: String) {
    let line = String(format: "[%8.2f] ", ProcessInfo.processInfo.systemUptime) + message + "\n"
    print(line, terminator: "")
    logHandle.write(line.data(using: .utf8)!)
}

func frontmostApp() -> String {
    let app = NSWorkspace.shared.frontmostApplication
    return "\(app?.localizedName ?? "?") (\(app?.bundleIdentifier ?? "?"))"
}

// MARK: - Panel

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class RowsView: NSView {
    static let rows = 5
    var marked = Array(repeating: [false, false], count: rows)
    var interaction = false { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func circleRect(row: Int, slot: Int) -> NSRect {
        NSRect(x: 20 + CGFloat(slot) * 50, y: 40 + CGFloat(row) * 50, width: 40, height: 40)
    }

    override func draw(_ dirtyRect: NSRect) {
        let bg = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 10, yRadius: 10)
        (interaction ? NSColor.systemBlue.withAlphaComponent(0.55) : NSColor.black.withAlphaComponent(0.35)).setFill()
        bg.fill()
        let status = interaction ? "INTERACTION (clicks land here)" : "click-through"
        (status as NSString).draw(
            at: NSPoint(x: 12, y: 10),
            withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.boldSystemFont(ofSize: 12)])
        for row in 0..<Self.rows {
            for slot in 0..<2 {
                (marked[row][slot] ? NSColor.systemRed : NSColor.systemGreen).setFill()
                NSBezierPath(ovalIn: circleRect(row: row, slot: slot)).fill()
            }
            ("enemy \(row + 1)" as NSString).draw(
                at: NSPoint(x: 125, y: 52 + CGFloat(row) * 50),
                withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12)])
        }
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        for row in 0..<Self.rows {
            for slot in 0..<2 where circleRect(row: row, slot: slot).contains(p) {
                marked[row][slot].toggle()
                needsDisplay = true
                log("CLICK circle row=\(row + 1) slot=\(slot + 1); frontmost=\(frontmostApp())")
                return
            }
        }
        log("CLICK on panel background (this click did NOT reach the game); frontmost=\(frontmostApp())")
    }
}

let levels: [String: NSWindow.Level] = [
    "floating": .floating, "statusBar": .statusBar, "popUpMenu": .popUpMenu, "screenSaver": .screenSaver,
]
let levelName = value(for: "--level") ?? "screenSaver"
guard let level = levels[levelName] else { fatalError("unknown --level \(levelName); use \(levels.keys.sorted())") }

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let rowsView = RowsView(frame: NSRect(x: 0, y: 0, width: 220, height: 300))
let panel = OverlayPanel(
    contentRect: rowsView.frame, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false)
panel.contentView = rowsView
panel.isFloatingPanel = true
panel.hidesOnDeactivate = false
panel.level = level
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
panel.backgroundColor = .clear
panel.isOpaque = false
panel.hasShadow = false
panel.ignoresMouseEvents = true
if let screen = NSScreen.main {
    panel.setFrameOrigin(NSPoint(x: screen.frame.minX + 20, y: screen.frame.midY - 150))
}
panel.orderFrontRegardless()

log("overlay-spike started: level=\(levelName) (\(level.rawValue)) consumeF1=\(args.contains("--consume-f1"))")
log("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
for (i, s) in NSScreen.screens.enumerated() {
    log("screen \(i): \(s.localizedName) frame=\(s.frame) scale=\(s.backingScaleFactor)")
}

// MARK: - Interaction mode (hold ⌃⌥, or latch with ⌃⌥I)

var latched = false
var interaction = false
@MainActor func setInteraction(_ on: Bool, reason: String) {
    guard on != interaction else { return }
    interaction = on
    panel.ignoresMouseEvents = !on
    rowsView.interaction = on
    log("interaction=\(on) via \(reason); frontmost=\(frontmostApp())")
}

let modifierTimer = Timer(timeInterval: 1.0 / 30, repeats: true) { _ in
    // No Accessibility/Input Monitoring permission should be needed for this read; the spike verifies that.
    let flags = CGEventSource.flagsState(.combinedSessionState)
    let held = flags.contains(.maskControl) && flags.contains(.maskAlternate)
    MainActor.assumeIsolated {
        setInteraction(held || latched, reason: held ? "hold ⌃⌥" : (latched ? "latch" : "release"))
    }
}
RunLoop.main.add(modifierTimer, forMode: .common)

// MARK: - Carbon hotkeys (no permissions required)

enum HotKey: UInt32 {
    case toggleLatch = 1, mark1, mark2, mark3, mark4, mark5, copy, quit, f1Test
}

var hotKeyRefs: [EventHotKeyRef?] = []
func register(_ key: HotKey, keyCode: Int, modifiers: Int) {
    var ref: EventHotKeyRef?
    let id = EventHotKeyID(signature: OSType(0x5357_5350), id: key.rawValue)  // 'SWSP'
    let status = RegisterEventHotKey(
        UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
    log("register hotkey \(key) status=\(status == noErr ? "ok" : "ERROR \(status)")")
    hotKeyRefs.append(ref)
}

func handle(_ key: HotKey) {
    log("HOTKEY \(key) fired; frontmost=\(frontmostApp())")
    switch key {
    case .toggleLatch:
        latched.toggle()
    case .mark1, .mark2, .mark3, .mark4, .mark5:
        let row = Int(key.rawValue - HotKey.mark1.rawValue)
        rowsView.marked[row][0].toggle()
        rowsView.needsDisplay = true
    case .copy:
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("mid flash 14:32 | top tp 15:10", forType: .string)
        log("copied test chat line; paste it in League chat with ⌘V")
    case .quit:
        app.terminate(nil)
    case .f1Test:
        log("F1 captured by spike — did League's camera ALSO jump to your champion? (if not, Carbon consumes keys)")
    }
}

var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(
    GetApplicationEventTarget(),
    { _, event, _ in
        var id = EventHotKeyID()
        GetEventParameter(
            event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
            MemoryLayout<EventHotKeyID>.size, nil, &id)
        if let key = HotKey(rawValue: id.id) { handle(key) }
        return noErr
    }, 1, &eventSpec, nil, nil)

let ctrlOpt = controlKey | optionKey
register(.toggleLatch, keyCode: kVK_ANSI_I, modifiers: ctrlOpt)
for (i, code) in [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5].enumerated() {
    register(HotKey(rawValue: HotKey.mark1.rawValue + UInt32(i))!, keyCode: code, modifiers: ctrlOpt)
}
register(.copy, keyCode: kVK_ANSI_C, modifiers: ctrlOpt)
register(.quit, keyCode: kVK_ANSI_Q, modifiers: ctrlOpt)
if args.contains("--consume-f1") { register(.f1Test, keyCode: kVK_F1, modifiers: 0) }

// MARK: - Environment monitoring (window mode, Spaces, visibility)

// Keep the panel on the left edge of the game window, whichever display it is on.
// CGWindow bounds use a top-left origin on the primary display; AppKit uses bottom-left.
var lastGameBounds = CGRect.zero
@MainActor func followGameWindow(_ infos: [[String: Any]]) {
    let gamePIDs = Set(
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == "com.riotgames.LeagueofLegends.GameClient" }
            .map(\.processIdentifier))
    guard
        let window = infos.first(where: { gamePIDs.contains(($0[kCGWindowOwnerPID as String] as? pid_t) ?? -1) }),
        let dict = window[kCGWindowBounds as String] as? NSDictionary,
        let bounds = CGRect(dictionaryRepresentation: dict),
        bounds != lastGameBounds
    else { return }
    lastGameBounds = bounds
    let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    let origin = NSPoint(x: bounds.minX + 20, y: primaryHeight - bounds.midY - panel.frame.height / 2)
    panel.setFrameOrigin(origin)
    log("game window at \(bounds) -> moved panel to \(origin) on \(panel.screen?.localizedName ?? "?")")
}

var lastFrontmost = ""
var lastLeagueWindows = ""
var lastVisibility = ""
let monitorTimer = Timer(timeInterval: 1, repeats: true) { _ in
    let front = frontmostApp()
    if front != lastFrontmost {
        lastFrontmost = front
        log("frontmost app -> \(front)")
    }
    let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    let league = infos.filter { (($0[kCGWindowOwnerName as String] as? String) ?? "").lowercased().contains("league") }
        .map { w -> String in
            let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
            return "\(w[kCGWindowOwnerName as String] ?? "?") layer=\(w[kCGWindowLayer as String] ?? "?") "
                + "bounds=\(b["X"] ?? "?"),\(b["Y"] ?? "?") \(b["Width"] ?? "?")x\(b["Height"] ?? "?")"
        }
        .joined(separator: " ; ")
    if league != lastLeagueWindows {
        lastLeagueWindows = league
        log("league windows on screen -> \(league.isEmpty ? "none" : league)")
    }
    MainActor.assumeIsolated { followGameWindow(infos) }
    let visibility = "onActiveSpace=\(panel.isOnActiveSpace) visible=\(panel.occlusionState.contains(.visible))"
    if visibility != lastVisibility {
        lastVisibility = visibility
        log("panel \(visibility)")
    }
}
RunLoop.main.add(monitorTimer, forMode: .common)

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
) { _ in
    log("active Space changed; panel onActiveSpace=\(panel.isOnActiveSpace)")
}

app.run()
