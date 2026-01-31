.PHONY: default clean build open test

default: clean build open

clean:
	xcodebuild -quiet clean

build: clean
	xcodebuild -quiet build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

open: build
	open ./build/Release/

test:
	xcodebuild -quiet test -scheme Timer -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

