@AGENTS.md

Validation scope, shared capacity and remote execution follow AGENTS.md. Command examples below do not require a full-suite rerun for every edit.

## Claude Code

- After editing `Asis/Domain/`, run `swift test`; after other app code, run the simulator `build` command from AGENTS.md.
- Use plan mode for anything touching `project.pbxproj`, the `Podfile`, or the transit API contract.
- Do not Read or Write `Asis/GoogleService-Info.plist`; it is a local secret.
