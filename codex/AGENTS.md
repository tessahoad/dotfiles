<!-- CODEGRAPH_START -->
## CodeGraph

Reach for CodeGraph BEFORE grep/find or reading files when you need to understand or locate code:

- **Init:** if the repo has no `.codegraph/` directory at its root, run `codegraph init` first to create and build the index.
- **Sync:** if `.codegraph/` already exists, run `codegraph sync` before your first exploration of a task so the index reflects the current files.
- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.
<!-- CODEGRAPH_END -->
