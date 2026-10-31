---
id: "054"
title: Prepare the v1.0 release build
type: task
mode: HITL
status: open
blocked_by: ["051", "052", "053", "055"]
claimed: false
---

## Question

Is there a signed, TestFlight-uploadable v1.0.0 build with its privacy manifest in place?

## Notes

Skills: `unslop`, `wizard`.
"Fix the v1.0 scope" put release work in v1.0. The privacy manifest (`PrivacyInfo.xcprivacy`) and the XcodeGen release/signing configuration are agent work, driven by the privacy answers "Write the App Store metadata" settles. The Apple account steps — App Store Connect record, signing, upload — are manual: write a `wizard.sh` for them and stop. "Build the Sources screen" must ship first, since it is a license requirement.
Bump to v1.0.0.

From [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the release checklist includes re-running `make dataset-fetch` and `make dataset` for every App Store release. A data-only patch release is due if the bundled EDRDG snapshot is more than 6 months old.

## Resolution
