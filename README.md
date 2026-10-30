# TimerOff

A small shutdown timer for macOS and Windows. Pick a preset, a duration or a time of day, and the computer shuts down when the countdown ends. You can cancel at any moment, and the last thirty seconds come with a warning you cannot miss.

## Features

- **Presets**: 15 minutes, 30 minutes, 1 hour, 2 hours. Or any duration, or a time of day (a time that has already passed means tomorrow).
- **Always cancellable**: the remaining time is in view the whole time, with a Cancel next to it. Nothing is sent to the system until the countdown reaches zero.
- **Thirty-second warning**: a panel comes to the front with the countdown in red, a sound, and a Cancel button.
- **Graceful shutdown**: the same request as the Shut Down menu, so apps get to save and quit.
- **Native and light**: a menu bar app on macOS (about 1 MB, around 12 MB of memory), a tray app on Windows. No third-party dependencies, no network access.
- Localized in English and Italian.

## macOS

Requires macOS 15 or later, on Apple Silicon or Intel.

TimerOff lives in the menu bar, with no Dock icon. Click the power symbol and choose **Shut Down in 15 Minutes** (or 30 minutes, 1 hour, 2 hours), or **Custom…** for a duration or a time of day. The remaining time appears next to the symbol; open the menu again for **Cancel Timer**.

The first time you set a timer, macOS asks whether TimerOff may control **System Events**: that is how the app shuts the Mac down, so answer Allow. If you denied it, turn it on in System Settings › Privacy & Security › Automation.

### Build from source

Requires Xcode 16 or later.

```sh
git clone https://github.com/slioce/TimerOff.git
cd TimerOff/macOS
make install   # builds, copies to /Applications and launches
make run       # launches the build without installing it
make run-dry   # same, but logs the shutdown instead of running it
make test      # runs the timer logic tests
```

Or open `macOS/TimerOff.xcodeproj` in Xcode and press Run. The project is signed to run locally out of the box; no developer account is needed. With `TIMEROFF_DRYRUN=1` in the environment the app does everything except the shutdown itself, which it logs instead.

## Windows

Requires Windows 10 version 1809 or later, or Windows 11.

TimerOff opens as a small window: click a preset, or enter a duration or a time (HH:MM) and press **Start**. The countdown takes the place of the choices, with Cancel underneath. Closing the window keeps the timer running in the notification area, where the icon's tooltip shows the remaining time and its menu offers **Show TimerOff**, **Cancel timer** and **Exit**.

### Build from source

Requires the .NET 10 SDK; Visual Studio 2022 with the Windows application development workload for the MSIX package.

```sh
git clone https://github.com/slioce/TimerOff.git
cd TimerOff/Windows
dotnet test TimerOff.Core.Tests   # runs the timer logic tests, on any OS
dotnet run --project TimerOff      # builds and launches the app, on Windows
```

Set `TIMEROFF_DRYRUN=1` to try the whole flow without shutting down: at zero the tray icon shows a notification instead.

## Project layout

```
macOS/TimerOff/            The app: menu bar item, custom timer window, warning panel, shutdown.
macOS/TimerOff/Resources/  Info.plist, entitlements, privacy manifest, icon, localizations.
macOS/TimerOffCore/        Swift package with the timer logic and its tests. No AppKit, no UI.
macOS/Config/              Build settings shared by every configuration (xcconfig).
macOS/scripts/             make-icon.swift draws the icon for both platforms.
Windows/TimerOff/          The app: WPF window with the Fluent theme, tray icon, shutdown.
Windows/TimerOff.Core/     Class library with the timer logic; TimerOff.Core.Tests has its tests.
Windows/TimerOff.Package/  MSIX packaging project and manifest for the Microsoft Store.
```

The logic is the same on both sides and has no UI in it: a `Trigger` turns into a target date, and a `Countdown` reports the seconds left, one warning and the moment it fires. The apps only draw that state and, at zero, ask the system to shut down: macOS through an Apple event to System Events, Windows through `shutdown /s /t 0`.

## Publishing

### Mac App Store

1. Create `macOS/Config/Local.xcconfig` (ignored by git) with your team:

   ```
   DEVELOPMENT_TEAM = ABCDE12345
   CODE_SIGN_IDENTITY = Apple Development
   ```

2. In Xcode, choose Product › Archive (or run `make archive` in `macOS/`), then Distribute App › App Store Connect.

The app runs in the App Sandbox. Shutting down is an Apple event to System Events, which the sandbox blocks unless the app declares the `com.apple.security.temporary-exception.apple-events` entitlement for `com.apple.systemevents`. Apple's guidelines call this exception a likely cause of rejection, although shutdown timers with it are on the store; explain it in the App Review notes, for example:

> The app's only purpose is to shut the Mac down when a timer the user set ends. It does so with the standard AppleScript `tell application "System Events" to shut down`, which is why it declares the temporary Apple events exception for `com.apple.systemevents`. The user grants the Automation permission when arming the timer. The app has no network access and keeps no data.

If App Review declines, the same build can be distributed outside the store: archive, Distribute App › Direct Distribution (which notarizes it), and attach the app to a GitHub release.

### Microsoft Store

1. In Partner Center, reserve the app name and read its **Package identity**: the Package/Identity/Name and the Package/Identity/Publisher.
2. Put those two values in `Windows/TimerOff.Package/Package.appxmanifest`, and your name in PublisherDisplayName.
3. In Visual Studio, right-click TimerOff.Package › Publish › Create App Packages › Microsoft Store, or from a Developer Command Prompt:

   ```
   msbuild Windows\TimerOff.sln /restore /p:Configuration=Release /p:Platform=x64 /p:UapAppxPackageBuildMode=StoreUpload
   ```

4. Upload the `.msixupload` from `Windows\TimerOff.Package\AppPackages` to the submission.

The package is a full-trust desktop app (the `runFullTrust` capability), which it needs to run `shutdown.exe`. It is self-contained, so it does not depend on a .NET runtime being installed.

## Privacy

Everything happens on your computer. TimerOff has no network access, collects no data, and keeps no settings. On macOS the privacy manifest (`PrivacyInfo.xcprivacy`) declares no tracking and no collected data.

## Acknowledgements

TimerOff was written with the help of AI coding agents; design, review and testing are the author's.

## License

Copyright © 2026 Alessandro Lioce. TimerOff is free software, released under the [GNU General Public License v3.0](LICENSE) or any later version.
