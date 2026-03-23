# Linux Build Notes

## Pending Upstream Fixes (izackp/icu-swift)

Two fixes were applied to `.build/checkouts/icu-swift` to get the Linux build working. These changes live only in the local checkout and **will be lost on `swift package update`**. They need to be pushed to the `izackp/icu-swift` repo.

### Fix 1 — Add `.linux` to ICU4C platform condition

**File:** `Package.swift`

Add `.linux` to the `ICU4C` dependency condition:

```swift
Target.Dependency.product(name: "ICU4C", package: "icu4c-swift", condition: .when(platforms: [.android, .driverKit, .linux, .wasi, .windows]))
```

Without this, the `ICU4C` module is excluded from the build plan on Linux and every file that does `import ICU4C` fails with "no such module".

### Fix 2 — Import Glibc for `memcmp` on Linux

**File:** `Sources/ICU/UnicodeVersion.swift`

Add after `import ICU4C`:

```swift
#if canImport(Glibc)
import Glibc
#endif
```

Without this, `memcmp` is not in scope on Linux, causing a compile error in `UnicodeVersion.swift`.

---

## Other Linux-Specific Changes (already committed)

- `Package.swift`: Uses URL-based `icu-swift` dependency on Linux via `#if os(Linux)` variable, local path on macOS.
- `Sources/GameEngine/ImageHandling/ImageManager.swift`: `import SystemFonts` is guarded with `#if os(macOS)`.
