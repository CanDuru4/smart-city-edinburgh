@AGENTS.md

Compatible heavy committed-source checks prefer the gaming PC through `remote-run.py`, which handles bounded wake/connect automatically. Follow AGENTS.md for runtime/data exceptions, native checks and matching-result reuse. Do not ask for PC availability each time or silently fall back to the Mini.

## Claude Code

- After editing `Asis/Domain/`, run `swift test`; after other app code, run the simulator `build` command from AGENTS.md.
- Use plan mode for anything touching `project.pbxproj`, the `Podfile`, or the transit API contract.
- Do not Read or Write `Asis/GoogleService-Info.plist`; it is a local secret.
