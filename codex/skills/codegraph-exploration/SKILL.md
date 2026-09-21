---
name: codegraph-exploration
description: Explore a repository's indexed code with CodeGraph before using text search. Use for finding symbols, tracing call paths, understanding architecture, assessing change impact, or locating the implementation of unfamiliar behavior.
---

# CodeGraph Exploration

Use CodeGraph as the first exploration tool when the repository contains a `.codegraph/` directory. It provides symbol-aware source and call paths, including relationships that plain text search may miss.

## Workflow

1. Decide whether the request is exploratory: locating behavior, tracing calls or dependencies, understanding architecture, or assessing change impact.
2. Check for `.codegraph/` at the repository root. If it is absent, explain that CodeGraph is unavailable for this repository and use normal repository search tools.
3. When indexed, use the CodeGraph MCP tool if available. Otherwise run:

   ```sh
   codegraph explore "<precise question, symbol, or file>"
   ```

   Include concrete symbol names, file names, or the behavior being traced. Ask for relevant source and call paths rather than a broad repository summary.
4. Use the returned source and paths to narrow the investigation. Only then read additional files or use `rg` for exact strings, configuration, tests, or generated content that CodeGraph does not model.
5. Report findings with file paths and line numbers where available. Distinguish direct CodeGraph evidence from inferences, and call out unresolved dynamic or external boundaries.

## Guardrails

- Do not invoke CodeGraph for a simple edit when the target file and change are already known.
- Do not treat an absent, stale, or failing index as a reason to stop; fall back gracefully.
- Prefer the smallest query that answers the current question, then make follow-up queries for specific symbols.
- Never claim a complete call graph when the result has dynamic dispatch, reflection, generated code, or external services that CodeGraph cannot resolve.
