---
name: prepare-satk-attach
description: Configure, migrate, validate, or repair a deterministic repo-private MATLAB/Simulink Agentic Toolkit prepared-attach workflow for Claude Code CLI on Windows. Use when a repository needs Claude Code to attach to one specific persistent MATLAB desktop, preserve model state across agent sessions, expose SATK model_* MCP tools, migrate an existing Codex prepared_attach setup, or diagnose missing schemas, stale prepared slots, undefined SATK functions, and wrong-session attachment.
---

# Prepare SATK Attach

Set up one repository-owned MATLAB desktop that is initialized for SATK before
Claude Code starts. Register its MCP endpoint at Claude's **project scope**.
Never modify user-global Claude configuration unless the user separately asks.

## Core contract

Maintain both readiness layers:

1. **Claude/MCP layer:** start the MATLAB MCP server with SATK's
   `tools/tools.json` extension so Claude receives the `model_*` schemas.
2. **MATLAB layer:** run `addpath(<satk-root>); satk_initialize` in that exact
   MATLAB process so the model functions are on path and the session is shared.

One layer does not substitute for the other. Missing schemas require a fresh
Claude session. Missing MATLAB initialization produces connection or
`Undefined function` failures.

Use this startup order:

```text
prepare repo-private MATLAB -> verify readiness -> start fresh Claude Code
-> project-scoped MCP shim attaches -> use model_* tools
```

Claude may eagerly load MCP schemas, so do not rely on preparing MATLAB after
Claude has already tried to start the endpoint.

## Scope and approval rules

- Resolve the target repository before changing anything.
- Distinguish the repository containing this skill from the repository being
  configured. Do not assume they are the same.
- Read its `CLAUDE.md`, `.claude/`, `.mcp.json`, and any existing
  `.codex/matlab-session-policy.toml`.
- Show the exact files and Claude MCP server name that will change.
- Ask before replacing an existing MCP entry, stopping a live slot process, or
  launching the MATLAB desktop.
- Preserve unrelated Claude settings and MCP servers.
- Do not edit `~/.claude/settings.json`, `~/.claude.json`, or another global
  location for a project-scoped setup.
- Do not install `satk_initialize` in global `startup.m`.
- Do not kill a MATLAB process unless its PID came from this repo's validated
  readiness record.
- Do not run a nested `claude` process from inside Claude Code. Create the
  launcher and tell the user to run it from a normal terminal.

## Required inputs

Discover these values; ask only for values that cannot be established safely:

| Value | Validation |
|---|---|
| Repository root | Resolve to an absolute path |
| MATLAB root | `<root>\bin\matlab.exe` exists |
| MATLAB MCP server | Executable exists and supports existing-session mode |
| SATK root | `satk_initialize.m` or `satk_initialize.p` exists |
| SATK extension | `<satk-root>\tools\tools.json` exists |
| Claude CLI | `claude --version` and `claude mcp add --help` succeed |

## Claude Code integration facts

- Treat Claude Code CLI as the MCP client and the MathWorks MATLAB MCP server
  as the implementation host.
- Use `stdio` transport. This local child-process endpoint requires no network
  URL or authentication.
- SATK's `tools/tools.json` is consumed by the MathWorks MCP server, not by
  Codex. The same extension file supplies `model_*` schemas to Claude when
  passed through `--extension-file`.
- Manage registration with `claude mcp add`, `claude mcp get`, and
  `claude mcp list`. For project scope, Claude commonly owns a repo-local
  `.mcp.json`; accept the actual location reported by the installed CLI.
- Use
  `C:\Work\AI_Tools\matlab-agentic-toolkit\skills-catalog\toolkit\matlab-agentic-toolkit-setup\reference\claude-code-setup-guidance.md`
  as the local vendor guidance for the installed Claude version.
- If `claude` is absent, generate and statically validate local scripts only.
  Stop before MCP registration and report that runtime compatibility remains
  unverified.
- Require MATLAB R2023a or newer with Simulink. Require the MATLAB MCP Server
  Toolbox to be installed for the exact selected MATLAB release.

An existing Codex prepared-attach setup is optional. When one exists, map
these values from
`.codex/matlab-session-policy.toml`:

- `matlab_root` -> `matlabRoot`
- `simulink_toolkit_path` -> `simulinkToolkitPath`
- `satk_extension_file` -> `extensionFile`

Read the MCP executable from the managed Codex endpoint or the installed
toolkit configuration. Do not migrate Codex server names or TOML enablement.

## Canonical implementation

Use the tested implementation in:

`C:\Work\AI_Tools\matlab-agent-orchestration\scripts`

Read these files before implementing:

- `prepared-satk-session-common.ps1`
- `prepare-codex-matlab-satk.ps1`
- `start-prepared-satk-mcp.ps1`
- `..\tests\PreparedSatkSession.Tests.ps1`

Create this target-repo surface:

```text
.claude/
  matlab-prepared-attach/
    policy.json
    prepared-satk-session-common.ps1
    prepare-claude-matlab-satk.ps1
    start-prepared-satk-mcp.ps1
    start-claude-prepared-satk.ps1
    tests/
      PreparedSatkAttach.Tests.ps1
```

Claude's project-scoped `mcp add` command may also create or update a
repo-local `.mcp.json`. Treat that as an expected CLI-managed artifact, not as
permission to edit it by hand.

Copy the common slot implementation and MCP shim without changing their slot
or security behavior. Adapt the prepare script to read the repo-local JSON
policy instead of Codex TOML.

Use this policy shape:

```json
{
  "schemaVersion": 1,
  "matlabRoot": "C:/MATLAB/R2026a",
  "simulinkToolkitPath": "C:/Users/USER/.matlab/agentic-toolkits/simulink",
  "vendorServerPath": "C:/Users/USER/.matlab/agentic-toolkits/bin/matlab-mcp-server.exe",
  "extensionFile": "C:/Users/USER/.matlab/agentic-toolkits/simulink/tools/tools.json",
  "readyTimeoutSeconds": 90
}
```

Use JSON serialization rather than interpolating JSON strings. Forward slashes
avoid Windows JSON escaping errors.

### Preserve these slot invariants

- Derive the slot key from the lowercase resolved repo path using SHA-256,
  truncated to 20 hexadecimal characters.
- Store slot state under `%LOCALAPPDATA%\AEG\m\<repo-hash>`.
- Use short subpaths `a` for private `APPDATA` and `l` for logs.
- Use the same private `APPDATA` for both MATLAB and the MCP server child.
- Restore the parent PowerShell process's `APPDATA` immediately after MATLAB
  starts.
- Reuse only a readiness record with `Status == "ready"`, the exact resolved
  repo path, and a live PID.
- Before stopping a recorded PID, verify the readiness repo path, configured
  MATLAB root, process name, and executable path. On Windows, inspect
  `Win32_Process.ExecutablePath` and require it to equal
  `<matlabRoot>\bin\matlab.exe`. Ask for approval before stopping a live
  process. If executable identity cannot be established, leave it running and
  stop the setup.
- Keep readiness metadata non-secret. Reject fields matching
  `secret|token|credential|sessiondetails|password`.

### MATLAB bootstrap requirements

Launch the exact `<matlabRoot>\bin\matlab.exe` with `-desktop`, set its working
directory to the repo, and run a generated bootstrap that:

1. Changes to the resolved repo root.
2. Adds the MATLAB MCP Server Toolbox path when present.
3. Adds the SATK root.
4. Calls `satk_initialize`.
5. Resolves both `which('satk_initialize')` and `which('model_overview')` and
   fails if either result is empty.
6. Writes `readiness.json` containing only status, PID, repo path, MATLAB root,
   timestamp, the two resolved function paths, and failure details when
   applicable.
7. Writes a short bootstrap log.

Wait up to the policy timeout for readiness. Return whether the process was
created or reused.

### MCP shim requirements

The shim must:

- Validate the MCP executable and extension file.
- Resolve the same repo-private slot.
- Set `APPDATA` only for its vendor-server child.
- invoke:

```text
<vendor-server> --matlab-session-mode existing --extension-file <tools.json>
```

Do not pass `--matlab-root` or `--matlab-display-mode` in existing mode. Use
`powershell.exe` as Claude's MCP command; never configure a `.ps1` path as the
command directly.

### Claude launcher requirements

Create `start-claude-prepared-satk.ps1` to:

1. Resolve its repository root.
2. Run `prepare-claude-matlab-satk.ps1`.
3. Stop if readiness fails.
4. Start `claude` with the repository as the working directory, forwarding
   caller arguments.

Do not execute this launcher from an existing Claude session.

## Register the project-scoped MCP endpoint

First inspect:

```powershell
claude mcp add --help
claude mcp list
```

Confirm that the installed CLI supports project scope. Register from the target
repo using the CLI, not by hand-editing Claude's JSON. This creates a local
stdio endpoint with no authentication:

```powershell
claude mcp add matlab_satk_prepared -s project -- powershell.exe `
  -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File "<repo>\.claude\matlab-prepared-attach\start-prepared-satk-mcp.ps1" `
  -RepoPath "<repo>" `
  -VendorServerPath "<vendor-server>" `
  -ExtensionFile "<satk-root>\tools\tools.json"
```

If that server name already exists, inspect it first. Ask before replacing it.
Do not remove or alter a user-scoped MATLAB server as part of this workflow.
If another scope exposes the same SATK tools, report the collision and verify
which endpoint Claude selects; do not silently remove the other endpoint.

Claude Code versions may defer MCP schemas. Do not guess at an undocumented
`alwaysLoad` field or hand-edit its placement. Use only options reported by the
installed CLI or the official toolkit configurator. Regardless of mechanism,
verify in a fresh Claude session that the `model_*` schemas are visible before
claiming success.

## Validation gates

Complete all applicable gates:

1. **Static files**
   - Policy, four PowerShell scripts, and the adapted Pester test exist under
     the target repo.
   - No unresolved placeholders remain.
   - No secret-like fields exist in policy or readiness data.
   - Pester tests cover stable repo hashing, secret-field rejection, process
     identity checks, private `APPDATA`, required `which` checks, and omission
     of launch-only flags from existing mode.
2. **Claude registration**
   - `claude mcp list` shows `matlab_satk_prepared` at project scope.
   - `claude mcp get matlab_satk_prepared` reports a local stdio command.
   - The command is `powershell.exe` and arguments use `-File`.
   - Existing-mode arguments contain no MATLAB root or display-mode flags.
3. **Prepared MATLAB**
   - Run the prepare script only after approval.
   - Readiness reports `ready`, the exact repo path, and a live PID.
   - The readiness record contains nonempty resolved paths for
     `satk_initialize` and `model_overview`, proving the checks ran in that
     MATLAB process.
4. **Fresh Claude session**
   - Tell the user to exit the current session.
   - Start with `start-claude-prepared-satk.ps1` from a normal terminal.
   - Confirm the SATK `model_*` tools are present.
   - Use a read-only model tool only when a model is available; do not create or
     modify a model merely to prove attachment.

Report the configured scope, files created, MCP server name, MATLAB release,
slot key, PID, whether the process was reused, and any restart still required.

## Failure handling

- **Claude has no `model_*` tools:** verify the extension argument and startup
  loading, then start a new Claude session. Schemas cannot be added reliably to
  the already-running session.
- **Undefined SATK function:** rerun the prepare script and inspect the slot log.
- **MCP cannot attach:** verify both processes use the same private `APPDATA`;
  generic shared-session discovery is not deterministic.
- **Wrong MATLAB release:** repair `policy.json`, replace only that repo's slot,
  and restart Claude.
- **Stale PID:** remove the stale readiness record. Stop a live process only
  after its executable and MATLAB root match the policy and the user approves.
- **Claude CLI lacks project scope:** stop and explain the limitation. Do not
  silently fall back to user scope.
- **Canonical scripts are unavailable:** stop and ask whether to generate local
  equivalents from the invariants above; do not invent a weaker generic attach
  workflow.
 