import Testing

@testable import SummwatchCore

@Test func disclaimerNamesRiotGames() {
    #expect(Summwatch.riotDisclaimer.contains("isn't endorsed by Riot Games"))
    #expect(Summwatch.riotDisclaimer.contains("trademarks or registered trademarks of Riot Games, Inc."))
}
