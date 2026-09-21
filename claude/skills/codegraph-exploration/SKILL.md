---
name: codegraph-exploration
description: Explore a repository's indexed code with CodeGraph before using text search. Use for finding symbols, tracing call paths, understanding architecture, assessing change impact, or locating the implementation of unfamiliar behavior.
---

# CodeGraph Exploration

Use CodeGraph as the first exploration tool when the repository contains a `.codegraph/` directory. It provides symbol-aware source and call paths, including relationships that plain text search may miss.

## Workflow

1. For an exploratory request, check for `.codegraph/` at the repository root. If it is absent, explain that CodeGraph is unavailable and use normal repository search tools.
2. When indexed, use the CodeGraph MCP tool if available. Otherwise run `codegraph explore "<precise question, symbol, or file>"`.
3. Start with a focused query about the behavior, symbol, or file. Use follow-up queries to narrow the result, then read additional files or use `rg` only for exact strings, configuration, tests, or generated content CodeGraph does not model.
4. Report relevant source and call paths with file paths and line numbers. Separate direct evidence from inference and identify dynamic dispatch, reflection, generated code, or external-service boundaries.

## Guardrails

- Do not invoke CodeGraph for a simple edit when the target is already known.
- If the index is absent, stale, or failing, fall back gracefully rather than stopping.
- Do not claim a complete call graph when CodeGraph cannot resolve dynamic behavior.
