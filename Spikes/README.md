# M1 spikes (throwaway)

Two small tools that answer questions only a real Mac running League can settle. Their findings go into `docs/adr/`, and then this folder is deleted. Output is written to `Spikes/out/`, which git ignores because recordings contain real Riot IDs.

## Before you start

Use two Terminal windows in the repo root:

```sh
# Terminal A — start BEFORE launching a game so the loading screen is captured too
swift run --package-path Spikes api-probe record

# Terminal B
swift run --package-path Spikes overlay-spike
```

A translucent panel with 5 rows of green circles appears on the left of your main screen. To quit, press **⌃⌥Q** or use Ctrl-C in Terminal B.

## Test checklist (Practice Tool is fine)

**1. Once you're in the game**, run this in a third terminal: `swift run --package-path Spikes api-probe probe`. It records the TLS details and the API schema.

**2. In each window mode** (Settings → Video → Window Mode: **Fullscreen**, **Borderless**, **Windowed**), check:

| # | Do this | Note down |
|---|---|---|
| a | Look at the left edge | Is the panel visible over the game? |
| b | Without holding anything, right-click the ground *through* the panel | Does your champion walk there? (It should: click-through.) |
| c | **Hold ⌃⌥** | Does the panel turn blue? |
| d | While holding ⌃⌥, click a green circle | Does it turn red? Do QWER and right-click still work immediately afterwards? |
| e | While holding ⌃⌥, click empty panel space | Nothing visible should happen. The log records it. |
| f | Press **⌃⌥1** … **⌃⌥5** | Does the first circle in that row toggle? Did League react at all? |
| g | Press **⌃⌥C**, then Enter, **⌘V**, Enter | Does `mid flash 14:32 \| top tp 15:10` paste into chat? |
| h | (Fullscreen only) Swipe to another Space and back | Is the panel still there? |

**3. Once only:** in Borderless, quit the spike with ⌃⌥Q and restart it with `--level statusBar`. Is the panel still visible over the game? Then do the same in Fullscreen.

**4. Once only:** restart the spike with `--consume-f1` and press **F1** in game (or **fn+F1**, depending on your keyboard settings). Does the camera still jump to your champion? If it doesn't, the hotkey swallowed the key, which is expected.

**5. Optional, any real game:** a game with enemies tells us more than Practice Tool. Let `api-probe record` run for the whole game, including the end screen. If you're up for it, also try spectating a friend's game and an ARAM.

## Afterwards

Stop Terminal A with Ctrl-C and tell me your notes from the table. You can be brief, for example "Borderless: a–g yes; Fullscreen: panel not visible". I'll read the logs and recordings in `Spikes/out/` myself.
