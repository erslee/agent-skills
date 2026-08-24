# english-hint

A `UserPromptSubmit` hook for non-native English speakers. After you send a message, it shows a
short correction and a more natural phrasing underneath it:

```
✏️  Fix: Can I make original files as a symlink to repo's files?
    Native: Can I symlink the original files to the ones in the repo?
```

**The hint goes to you only.** The hook returns `systemMessage` with `suppressOutput: true`, so
the correction never enters Claude's context and never changes the answer you get. Your message
is processed exactly as you typed it.

## Install

```
/plugin marketplace add erslee/agent-skills
/plugin install english-hint@erslee-agent-skills
```

The hook is active as soon as the plugin is enabled — no `settings.json` edit needed.
Turn it off any time with `/plugin` (disable) rather than deleting files.

## Requirements

- `jq` on `PATH` (`brew install jq`) — used to parse the hook payload and emit the response.
- `claude` on `PATH` — the hook shells out to `claude -p --model haiku` for the check.

If `jq` is missing the hook exits quietly and nothing breaks; you just get no hints.

## Cost and latency

Every qualifying prompt spends one extra Haiku call (a few hundred input tokens, capped at
`--max-turns 1`, prompt truncated to 1500 chars). The hook has a 20s timeout.

It deliberately stays quiet and skips the call entirely for:

- slash commands (`/…`), bash passthrough (`!…`) and memory notes (`#…`)
- anything containing a fenced code block
- messages under 4 words
- messages that come back clean — the model replies `OK` and nothing is shown

## How the recursion guard works

The hook invokes `claude`, which would fire the same hook again. Two independent guards prevent
that: it exports `CLAUDE_ENGLISH_HINT=1` (the nested copy sees it and exits immediately), and the
nested call passes `--settings '{"disableAllHooks":true}'`. Keep both if you edit the script.

## Local development (authoring machine)

Same rule as the other plugins in this repo: don't install it on the machine where you edit it —
installing copies the script into `~/.claude/plugins/cache/…` pinned to a git SHA, so your edits
wouldn't take effect. Symlink instead and register the hook in `~/.claude/settings.json` by
absolute path:

```bash
rm -f ~/.claude/hooks/english-hint.sh
ln -s ~/dev/agent-skills/plugins/english-hint/hooks/english-hint.sh ~/.claude/hooks/english-hint.sh
```

```jsonc
// ~/.claude/settings.json
"hooks": {
  "UserPromptSubmit": [
    { "hooks": [ {
        "type": "command",
        "command": "/Users/<you>/.claude/hooks/english-hint.sh",
        "timeout": 20,
        "statusMessage": "Checking English…"
    } ] }
  ]
}
```

Don't do both on one machine — the hook would fire twice per prompt and you'd pay for two Haiku
calls. Keep the `settings.json` entry **or** the installed plugin, never both.

Note the script must stay executable (`chmod +x`); git preserves the bit, but a copy-paste won't.
