# agent-skills

Personal [Claude Code](https://claude.com/claude-code) plugin marketplace. This repo *is* the marketplace — add it once, then install any plugin listed below on any machine.

## Install

```
/plugin marketplace add erslee/agent-skills
/plugin install dev-pipeline@erslee-agent-skills
/plugin install english-hint@erslee-agent-skills
```

Then `/plugin` to verify it's enabled, or restart Claude Code.

To pick up changes later:

```
/plugin marketplace update erslee-agent-skills
```

## Plugins

| Plugin | What it gives you |
| --- | --- |
| [`dev-pipeline`](plugins/dev-pipeline) | `/dev-pipeline` and `/commit` skills + the 5 subagents the pipeline delegates to |
| [`english-hint`](plugins/english-hint) | Hook showing a spelling/phrasing hint for each message you send (visible to you only) |

## Layout

```
.claude-plugin/marketplace.json   # marketplace manifest (repo root)
plugins/<name>/
  .claude-plugin/plugin.json      # plugin manifest
  skills/<name>/SKILL.md          # auto-discovered
  agents/<name>.md                # auto-discovered
  hooks/hooks.json                # auto-discovered
```

`skills/`, `agents/` and `hooks/hooks.json` are discovered by convention — no need to list their
paths in `plugin.json`. Inside `hooks.json`, reference scripts as
`${CLAUDE_PLUGIN_ROOT}/hooks/<script>` — never an absolute path, or the plugin only works on the
machine it was written on.

## Adding a plugin

1. Create `plugins/<name>/` with a `.claude-plugin/plugin.json`.
2. Drop skills under `skills/<skill-name>/SKILL.md`, agents under `agents/<agent>.md`, hooks under `hooks/hooks.json`.
3. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
4. Commit and push. Existing installs pick it up on `/plugin marketplace update`.
