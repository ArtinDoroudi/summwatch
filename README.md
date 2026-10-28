# Summwatch

A native, open-source macOS overlay for League of Legends that times enemy summoner spells.

> **Status: pre-alpha.** Nothing to install yet. See the [roadmap](#roadmap).

## What it does (v0.1 goal)

- Lives in the menu bar and detects when a game starts.
- Shows a small overlay with each enemy's summoner spells.
- You mark a spell when you see it used, either with a hotkey or by clicking. Summwatch then counts down the cooldown, including summoner haste from boots, the Cosmic Insight rune (toggled manually), and the ARAM aura.
- One hotkey copies a chat-ready line such as `mid flash 14:32 | top tp 15:10` that you can paste into team chat.

## What it does not do

Summwatch is deliberately limited to what Riot's [developer policies](https://developer.riotgames.com/policies/general) allow:

- It reads only Riot's official, read-only [Live Client Data API](https://developer.riotgames.com/docs/lol#game-client-api) at `127.0.0.1:2999`.
- It doesn't read game memory, inject code, modify game files, or use the League Client (LCU) API.
- It doesn't send keystrokes or type into chat. You paste the chat line yourself.
- It **never tracks enemy ultimates.** Riot banned that in March 2025.
- It only knows a spell was used when you mark it. Nothing is detected automatically.

## ⚠️ Use at your own risk

Riot's rules on third-party enemy summoner-spell timers are **not clearly settled**. Riot's own docs don't ban them, but Overwolf's Riot compliance guide lists them as prohibited, and in 2025 Riot staff described the policy as inconsistent and under review. Summwatch uses only the official read-only local API and no automation, and nothing documented links that to account penalties, but we can't guarantee Riot's position won't change. See [docs/POLICY.md](docs/POLICY.md) for sources.

## Roadmap

- **v0.1:** menu bar app, overlay, haste-aware enemy summoner timers, hotkey marking, chat-line copy.
- **Later:** gold estimates from visible items, and team gold difference.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

## Legal

Summwatch isn't endorsed by Riot Games and doesn't reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc.
