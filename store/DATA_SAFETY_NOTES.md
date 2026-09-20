# Google Play Data Safety preparation

This is a preparation aid, not a legal or Play Console certification.

Core build without AdMob:

- No account or user-entered personal data.
- No publisher backend or external analytics.
- Progress, settings and debug-only QA events stay in app-private local storage.
- No data is intentionally shared by the game code.

If AdMob/UMP is enabled, re-evaluate the form against the exact SDK version and settings. Google Mobile Ads may collect or share device/advertising identifiers, approximate location, diagnostics, app interactions and ad performance data. Declare purposes and optionality according to current Google documentation and the publisher's actual consent configuration. Confirm whether platform backup copies local app data.

Actions before submission:

1. Replace policy contact/effective date.
2. Verify the exact plugin and Google Mobile Ads SDK dependency versions in the built AAB.
3. Complete UMP consent testing in applicable regions.
4. Reconcile Play SDK Console disclosures with this form.
5. Review debug logging and ensure no personal data is added later.

