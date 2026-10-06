## Dotfiles

Configuring my environment one dotfile at a time

### What do we need to do that's not covered here

1. Create new ssh key for cloning from GitHub

2. Install powerline fonts for iTerm 2
 - once installed, restart iTerm to see changes

### Cerebus CLI launchers

`.zshrc` loads `claude-cerebus` and `codex-cerebus`. Both start the interactive
CLI using `CEREBUS_MODEL`, or accept an explicit model:

```sh
claude-cerebus
codex-cerebus --model '@sandbox-shared-google/gemini-3.8-flash'
codex-cerebus --model '@sandbox-shared-google/gemini-3.8-flash' exec 'Review this change'
```

Assign and export these variables in `~/.zshenv.secret`:

| Variable | Purpose |
| --- | --- |
| `CEREBUS_BASE_URL` | Gateway root URL, without `/v1`; Codex appends `/v1`. |
| `CEREBUS_PROVIDER` | Portkey provider routing slug used by both clients. |
| `CEREBUS_MODEL` | Default model when `--model` is omitted. |
| `CEREBUS_CLAUDE_CONTEXT_WINDOW` | Claude context window in tokens; defaults to `200000`. |
| `CEREBUS_CODEX_CONTEXT_WINDOW` | Codex context window in tokens; defaults to `131072`. |
| `CEREBUS_CODEX_COMPACT_LIMIT` | Token threshold for Codex automatic compaction; defaults to `98304`. |
| `CEREBUS_API_KEY` | Gateway API key sent in the `x-portkey-api-key` header. |
