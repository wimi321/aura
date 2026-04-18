## Aura iOS Runtime

The prebuilt `AuraLiteRTNative.xcframework` is intentionally not stored in Git.

Why:

- GitHub rejects individual files larger than 100MB
- the generated native framework slices exceed that limit
- keeping the repository source-first avoids a broken first push

To regenerate the framework locally:

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

The iOS helper build scripts in `scripts/` will also try to build it automatically when:

- Xcode is available through `DEVELOPER_DIR`
- Bazel is installed
- the local framework is missing
