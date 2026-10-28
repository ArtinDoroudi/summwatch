# Riot policy and Summwatch

This page explains which features Summwatch includes or excludes, and why. Research date: **October 2026.** Riot's rules change, so open a [policy question](../.github/ISSUE_TEMPLATE/policy_question.yml) if anything here looks stale.

## Summary

| Feature | Status | Why |
|---|---|---|
| Enemy **ultimate** timers | ❌ Never | Banned since 2025-03-13, whether tracked manually or automatically |
| Any enemy **ability** cooldown tracking | ❌ Never | Same reasoning as ultimates |
| Enemy **summoner spell** timers (manual marking) | ⚠️ Shipped, at-risk | Riot's own text doesn't ban them, but Overwolf's Riot compliance guide does, and Riot calls its policy "inconsistent" |
| Gold estimates from visible items | ✅ Planned | Items are visible on the in-game scoreboard |
| Jungle camp timers | ⏸ Deferred | Riot says this is under internal discussion |
| Dragon / Baron timers | ⏸ Low value | Already built into the game |
| Reading memory, injecting, modifying files | ❌ Never | Cheating territory; risks accounts |
| Typing into chat or simulating input | ❌ Never | Automation; we copy to the clipboard instead |
| League Client (LCU) API | ❌ Not in v0.x | Not officially supported for third parties; we use only port 2999 |
| Ads in the overlay | ❌ Never | Banned since 2025-05-29 |

## Sources

### Enemy ultimate timers are banned
- Riot's League docs give "tracking enemy ultimate cooldowns" as the example of "information not present in the game client that would give players a competitive edge." ([developer.riotgames.com/docs/lol](https://developer.riotgames.com/docs/lol))
- In March 2025, Riot's Developer Relations team required all third-party apps to remove enemy ult timers by 2025-03-13. The ban covers manual tracking too. ([mein-mmo](https://mein-mmo.de/lol-riot-verbietet-ultimate-time-tracker/))
- Riot's head of product, Drew Levin, said in May 2025: "enemy ult tracking isn't allowed anymore." ([esports-news](https://esports-news.co.uk/2025/05/30/captainflowers-riot-games-lol-third-party-apps/))

### Enemy summoner spell timers are ambiguous
- **For:** summoner casts are visible in game, and League's own scoreboard lets you click an enemy's summoner icon to share its timing in chat. Riot's primary policy text doesn't name summoner timers.
- **Against:** Overwolf's Riot compliance guide lists as prohibited: "Tracking of enemy summoner spells cooldowns, or facilitating players tracking these with timers." That guide is undated and isn't Riot's own text. ([Overwolf](https://dev.overwolf.com/ow-native/guides/game-compliance/riot-games/))
- **Unsettled:** in May 2025, Riot acknowledged its third-party policy is inconsistent and said internal discussions were ongoing. ([esports-news](https://esports-news.co.uk/2025/05/30/captainflowers-riot-games-lol-third-party-apps/), [lolnow](https://lolnow.gg/riot-cracks-down-on-overlays-in-league-of-legends-a-long-overdue-clean-up/))

**Our position:** we ship manual summoner timers with a clear disclaimer, and we'll remove or disable them if Riot clarifies they're not allowed. Keep the feature isolated so it can be switched off cleanly.

### General rules ([policies/general](https://developer.riotgames.com/policies/general), updated 2025-05-29)
- All products must be registered with and audited by Riot through the Developer Portal.
- No ads in Riot properties, including in-game overlays.
- Monetized products need a free tier; no gambling.
- The legal notice below must be visible to players.

### API facts that shape features
- Enemy players expose only their **keystone and rune trees**, not minor runes. That's why Cosmic Insight is a manual toggle. ([Overwolf](https://dev.overwolf.com/ow-native/guides/game-compliance/riot-games/), [Riot sample payload](https://static.developer.riotgames.com/docs/lol/liveclientdata_sample.json))
- The Live Client Data API doesn't report spell casts, so marking is always manual.

## Required legal notice

> Summwatch isn't endorsed by Riot Games and doesn't reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc.

This appears in the README, the app's About window, and on first launch. To avoid implying endorsement, the app's name and icon don't use Riot marks ("League", "LoL", "Rift") or Riot art. Champion and spell icons are downloaded from Data Dragon at runtime and aren't committed to the repository.
