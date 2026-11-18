SCHEME := Nichiji
SIM_ID ?= $(shell xcrun simctl list devices available | { grep -m1 'iPhone Duo' || grep -m1 'iPhone'; } | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}')
DESTINATION ?= platform=iOS Simulator,id=$(SIM_ID)
BUILD_NUMBER ?= 1
ASC_AUTH = -allowProvisioningUpdates -authenticationKeyPath "$(ASC_KEY_PATH)" \
	-authenticationKeyID "$(ASC_KEY_ID)" -authenticationKeyIssuerID "$(ASC_ISSUER_ID)"

.PHONY: generate build test lint testflight dataset dataset-fetch dataset-test

generate:
	xcodegen generate

build: generate
	xcodebuild build -project Nichiji.xcodeproj -scheme $(SCHEME) -destination '$(DESTINATION)'

test: generate
	xcodebuild test -project Nichiji.xcodeproj -scheme $(SCHEME) -destination '$(DESTINATION)'

lint:
	swiftlint --strict

testflight: generate
	rm -rf build
	xcodebuild archive -project Nichiji.xcodeproj -scheme $(SCHEME) -configuration Internal \
		-destination 'generic/platform=iOS' -archivePath build/Nichiji.xcarchive $(ASC_AUTH) \
		CODE_SIGN_IDENTITY='Apple Distribution' CURRENT_PROJECT_VERSION=$(BUILD_NUMBER)
	xcodebuild -exportArchive -archivePath build/Nichiji.xcarchive \
		-exportOptionsPlist Config/ExportOptions-TestFlight.plist -exportPath build/export $(ASC_AUTH)

dataset-fetch:
	python3 -B tools/dataset/fetch.py

dataset:
	python3 -B tools/dataset/build.py

dataset-test:
	python3 -I -B -m unittest discover -s tools/dataset/tests -t tools/dataset
