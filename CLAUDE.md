@AGENTS.md

## Claude Code

- After editing `Asis/Domain/`, run `swift test`; after other app code, run the simulator `build` command from AGENTS.md.
- Use plan mode for anything touching `project.pbxproj`, the `Podfile`, or the transit API contract.
- Do not Read or Write `Asis/GoogleService-Info.plist`; it is a local secret.
