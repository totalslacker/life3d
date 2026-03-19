# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

## visionOS Simulator Limitations

- The visionOS Simulator boots a full xrOS runtime and is extremely resource-heavy
- On some machines it crashes the host when launched (especially with volumetric windows)
- `xcodebuild test` launches the app as test host, triggering the simulator crash
- **Workaround**: Use `xcodebuild build` for CI verification, run tests manually on device or with logic-only test targets that don't require the simulator runtime
- Volumetric window style (`WindowGroup(...) { }.windowStyle(.volumetric)`) causes `UIWindowSceneSessionRoleApplication` mismatch on visionOS 2.1 sim — use plain `WindowGroup` with `RealityView` inside instead
