# DrawNuke

A drawing game for iPhone with three modes, built with SwiftUI + SpriteKit.

## Modes

| Mode | What you do |
|---|---|
| **Draw** | Free-draw neon art: 10 colors, glow effect, adjustable brush size, undo, clear all. |
| **Sandbox** | Physics playground. Draw ramps, walls and towers that crates and balls collide with, drop more debris, then press **NUKE** to blast everything across the screen with a fireball, shockwave and screen shake. |
| **Nuke** | Paint your own warhead onto the missile (8 paint colors), press **TEST FIRE** - the missile launches with a flame trail, detonates mid-air with a fireball, mushroom cloud and "BOOM", and topples the city skyline. Press **Rebuild** to start over. |

## Project layout

- `project.yml` - Xcode project definition for [xcodegen](https://github.com/yonaskolb/XcodeGen)
- `DrawNuke/` - all Swift sources + asset catalog (includes a generated app icon)
  - `DrawNukeApp.swift` - app entry point
  - `MainMenuView.swift` - mode selection screen
  - `DrawModeView.swift` - Draw mode (SwiftUI Canvas)
  - `SandboxView.swift` + `SandboxScene.swift` - Sandbox mode (SpriteKit scene)
  - `NukeModeView.swift` + `NukeScene.swift` - Nuke mode (SpriteKit scene)
  - `Helpers.swift` - texture factory + explosion effects shared by both scenes

## Building the IPA without a Mac (GitHub Actions - easiest)

1. Go to **github.com/new**, create a repo called `DrawNuke` (Public).
2. Open your local `DrawNukeGame` folder, select **everything inside it** (Ctrl+A - including the `.github` folder), then drag & drop it onto the empty repo page in your browser and click **Commit changes**.
3. Open the **Actions** tab on the repo - a "Build IPA" workflow starts automatically and takes ~3-5 minutes.
4. When it finishes, click the run, scroll to **Artifacts**, download `DrawNuke-ipa`, unzip it - that's your `DrawNuke.ipa`.
5. The IPA is **unsigned** (GitHub can't sign for you). Install it with **Sideloadly** (sideloadly.io) or **AltStore**: plug in your iPhone, drag the IPA in, enter your Apple ID - it signs and installs in one step. This is also the tool most people use to mod IPAs (it can swap/inject dylibs too).
6. Free Apple ID: app valid for 7 days, re-sign to refresh. Paid developer account: 1 year.

## Building the IPA on a Mac

An `.ipa` must be code-signed with Apple's toolchain, so the final build/sign step needs a Mac with Xcode (Windows cannot produce a signed IPA). Everything else is ready to go.

### Option A - xcodegen (fastest)

On your Mac:

```bash
brew install xcodegen
cd DrawNukeGame
xcodegen generate
open DrawNuke.xcodeproj
```

Then in Xcode:

1. Select the **DrawNuke** target -> **Signing & Capabilities** -> check *Automatically manage signing* and pick your team (a free Apple ID works).
2. Connect your iPhone, select it as the run destination. If bundle ID `com.drawnuke.game` is taken, change it to something unique.
3. Press **Run** - the game installs on your phone.
4. To export an actual `.ipa`: **Product -> Archive**, then **Distribute App -> Development** (or Ad Hoc with a paid account). The IPA appears in the archive folder.

### Option B - manual Xcode project

1. Xcode -> **File -> New -> Project -> iOS -> App**, Interface: SwiftUI, name it `DrawNuke`.
2. Delete the template `ContentView.swift`.
3. Drag every `.swift` file from the `DrawNuke/` folder into the project navigator (check "Copy items if needed"), plus the `Assets.xcassets` folder if you want the icon.
4. Continue from step 2 of Option A.

## Signing notes

- **Free Apple ID**: installs the game directly onto your device via Xcode. Valid for 7 days, then re-run to refresh. No shareable IPA.
- **Paid Apple Developer Program ($99/yr)**: Archive -> Distribute gives you a real IPA you can install via Ad Hoc or ship through TestFlight.
- Requires iOS 16.0+. Configured for iPhone in portrait (`TARGETED_DEVICE_FAMILY` = 1); set it to `"1,2"` if you also want iPad.

## Controls

- **Draw mode**: pick a color circle, drag to paint, use the slider for brush size, toggle Glow for the neon look.
- **Sandbox mode**: drag anywhere to draw solid physics lines; buttons at the bottom drop crates, detonate the nuke, or clear the board.
- **Nuke mode**: drag to paint on the missile, tap a color to switch paint, TEST FIRE launches, Rebuild resets.
