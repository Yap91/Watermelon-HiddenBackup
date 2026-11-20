# Watermelon Hidden Backup local build

- Upstream: `https://github.com/zizicici/Watermelon`
- Upstream commit: `9ad0d061d3facf6526c743603655dae3d5bbba71`
- Local branch: `local-build`
- License: MIT; the upstream `LICENSE` file and copyright notice are retained.

## Hidden-only safety policy

The `hidden` data source resolves only `PHAssetCollectionSubtype.smartAlbumAllHidden`, sets `PHFetchOptions.includeHiddenAssets = true`, applies a PhotoKit `isHidden` predicate, and checks `PHAsset.isHidden` again while indexing and immediately before resource export. An unavailable or empty protected Hidden album is an error and never falls back to the full library.

PhotoKit can return an empty Hidden smart album while the system Face ID protection is enabled. The app explains that the protection cannot be bypassed, asks the user to grant Full Photos access, and reminds the user to re-enable Face ID protection after testing.

## Resource integrity

The existing lossless resource pipeline is retained. It enumerates every `PHAssetResource`, excludes only the iOS low-resolution `photoProxy`, exports with `PHAssetResourceManager.writeData`, calculates SHA-256, and records every resource by role and slot in the backup manifest. Live Photo still/video pairs and edited-resource/adjustment-data relationships are therefore retained without image or video transcoding.

## Self-signing

The iOS bundle identifier is `com.yap.watermelon.hiddenbackup` and the display name is `Watermelon Hidden`. The original associated-domain and shared Microsoft Keychain access-group entitlements are removed. PhotoKit, Bonjour/SMB, background processing, and the app's ordinary per-app Keychain storage do not require those removed entitlements.

Cloud-provider OAuth redirects that were registered to the upstream bundle identifier are not part of this local self-signing target. SMB backup remains the primary supported Windows destination for this build.

## Validation boundary

GitHub Actions validates compilation, unit tests, IPA structure, bundle metadata, executable presence, and the absence of an embedded provisioning profile or code-signature directory. A physical iPhone is still required to validate Hidden album visibility, Live Photo original export, SMB transfer, and destination SHA-256 values.
