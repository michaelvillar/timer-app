.PHONY: default clean build open

default: clean build open

clean:
	xcodebuild -quiet clean 

build: clean
	xcodebuild -quiet build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

open: build
	open ./build/Release/

