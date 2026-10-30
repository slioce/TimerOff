APP := build/Build/Products/Release/TimerOff.app
XCODEBUILD := xcodebuild -project TimerOff.xcodeproj -scheme TimerOff -destination generic/platform=macOS -derivedDataPath build

.PHONY: build run run-dry install test icon archive clean

# Release build, signed to run locally unless Config/Local.xcconfig sets a team.
build:
	@$(XCODEBUILD) -configuration Release build -quiet
	@echo "Built $(APP) ($$(du -sh $(APP) | cut -f1))"

run: build
	@pkill -x TimerOff || true
	@open $(APP)

# Same, but the app only logs the shutdown command instead of running it.
run-dry: build
	@pkill -x TimerOff || true
	@open --env TIMEROFF_DRYRUN=1 $(APP)

install: build
	@pkill -x TimerOff || true
	@rm -rf /Applications/TimerOff.app
	@cp -R $(APP) /Applications/
	@open /Applications/TimerOff.app
	@echo "Installed /Applications/TimerOff.app"

test:
	@swift test --package-path TimerOffCore

icon:
	@swift scripts/make-icon.swift TimerOff/Resources/Assets.xcassets/AppIcon.appiconset ../Windows/TimerOff/Assets

# App Store archive; needs DEVELOPMENT_TEAM in Config/Local.xcconfig. Upload from Xcode's Organizer.
archive:
	@$(XCODEBUILD) -configuration Release archive -archivePath build/TimerOff.xcarchive
	@open build/TimerOff.xcarchive

clean:
	@rm -rf build
