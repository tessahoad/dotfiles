#!/bin/bash
# Claude Code notification hook — sends a macOS notification when Claude needs attention.
# Place this file at: ~/.claude/claude-notify.sh
# Then run: chmod +x ~/.claude/claude-notify.sh

INPUT=$(cat)

# Extract message and title from the JSON payload Claude sends via stdin
MSG=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('message', 'Claude needs your attention'))
except Exception:
    print('Claude needs your attention')
" 2>/dev/null || echo "Claude needs your attention")

TITLE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('title', 'Claude Code'))
except Exception:
    print('Claude Code')
" 2>/dev/null || echo "Claude Code")

# Send a native macOS notification
osascript -e "display notification \"${MSG}\" with title \"${TITLE}\" sound name \"Frog\""
