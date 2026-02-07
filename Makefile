SWIFTLINT := $(shell command -v swiftlint 2>/dev/null || echo mise exec -- swiftlint)

.PHONY: default clean build open test uitest lint analyze format install-cli

default: clean build open

clean:
	xcodebuild -quiet clean

build:
	xcodebuild -quiet build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

open: build
	open ./build/Release/Timer.app

test:
	xcodebuild -quiet test -scheme Timer -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

uitest:
	xcodebuild -quiet test -scheme TimerUITests -destination 'platform=macOS' -allowProvisioningUpdates

lint:
	$(SWIFTLINT)

analyze:
	xcodebuild build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO > /tmp/xcodebuild-timer.log 2>&1 || true
	$(SWIFTLINT) analyze --compiler-log-path /tmp/xcodebuild-timer.log

format:
	$(SWIFTLINT) --fix

install-cli:
	install -m 755 timer-cli /usr/local/bin/timer
