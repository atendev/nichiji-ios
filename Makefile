SCHEME := Nichiji
SIM_ID ?= $(shell xcrun simctl list devices available | { grep -m1 'iPhone Duo' || grep -m1 'iPhone'; } | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}')
DESTINATION ?= platform=iOS Simulator,id=$(SIM_ID)

.PHONY: generate build test lint ipa dataset dataset-fetch dataset-test

generate:
	xcodegen generate

build: generate
	xcodebuild build -project Nichiji.xcodeproj -scheme $(SCHEME) -destination '$(DESTINATION)'

test: generate
	xcodebuild test -project Nichiji.xcodeproj -scheme $(SCHEME) -destination '$(DESTINATION)'

lint:
	swiftlint --strict

ipa: generate
	rm -rf build Payload Nichiji.ipa
	xcodebuild archive -project Nichiji.xcodeproj -scheme $(SCHEME) -configuration Release \
		-destination 'generic/platform=iOS' -archivePath build/Nichiji.xcarchive \
		CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
	mkdir Payload
	cp -R build/Nichiji.xcarchive/Products/Applications/Nichiji.app Payload/
	zip -qr Nichiji.ipa Payload

dataset-fetch:
	python3 -B tools/dataset/fetch.py

dataset:
	python3 -B tools/dataset/build.py

dataset-test:
	python3 -I -B -m unittest discover -s tools/dataset/tests -t tools/dataset
