---
name: odoo-ls
description: Use when navigating or checking Odoo addon code (Python models, XML views/data, CSV access rules) - finding where an Odoo model, field or method is defined, what a model inherits, or validating a module against the Odoo version in use. Also use when the Odoo LSP server fails to start or returns nothing.
---

# Odoo Language Server (odoo-ls)

The `odoo-lsp` plugin registers the Odoo language server for `.py`, `.xml` and
`.csv` files. Use the **LSP tool** instead of grepping the Odoo source tree.

## When to use which operation

| Question | LSP operation |
|---|---|
| Where is this method/field/model defined (incl. Odoo core)? | `goToDefinition` |
| What is this model, who inherits it, method signature + docstring? | `hover` (on `_inherit = "..."` string, method name, field) |
| Symbols of a file | `documentSymbol` |
| Find methods/XML ids by name across all addons | `workspaceSymbol` (fuzzy, noisy — filter results) |

- Diagnostics (codes `OLS0xxxx`) arrive automatically after edits. Treat them
  as real signals: e.g. missing `depends`, wrong arg counts, fields missing in
  the target Odoo version. Fix them or explain why they do not apply.
- `findReferences` currently returns nothing — use Grep for usages.
- `goToDefinition` on `fields.X` points to module top, not the class line.

## Startup

Indexing a full Odoo tree (~660 modules) takes ~10–20 s. If a call says
"server is starting" or returns nothing right after session start, retry after
a few seconds.

## Configuration

- `odools.toml` (project root): `odoo_path`, `addons_paths`, `python_path`
  (a Python with Odoo's requirements), diagnostic filters. Template:
  `${CLAUDE_PLUGIN_ROOT}/templates/odools.toml`. The profile name must be
  `default`.
- The plugin starts `${CLAUDE_PLUGIN_ROOT}/bin/odoo-ls`, which runs
  `$ODOO_LS_HOME/server/target/release/odoo_ls_server` (default
  `ODOO_LS_HOME=~/.local/share/odoo-ls`) or `$ODOO_LS_SERVER` if set.
- Server logs: `$ODOO_LS_HOME/server/target/release/logs/`.

## Troubleshooting

- **Server missing**: build it with
  `${CLAUDE_PLUGIN_ROOT}/scripts/install-odoo-ls.sh` (needs git and Rust).
- **Server crashes with exit code 101**: check the newest log for `panic`.
  Upstream odoo-ls panics when the client rejects `client/registerCapability`
  (Claude Code does not support dynamic registration). The binary must be built
  from branch `claude-code-compat` of `villelaitila/odoo-ls` (upstream PR
  odoo/odoo-ls#745) until the fix is released upstream.
- **Rebuild**: re-run the install script, or
  `cd $ODOO_LS_HOME/server && cargo build --release`. The binary needs
  `typeshed/` and `additional_stubs/` next to it (symlinks in
  `target/release/`); recreate them after `cargo clean`:
  `ln -sfn ../../typeshed typeshed && ln -sfn ../../additional_stubs additional_stubs`.
- **Verify config without Claude Code**, from the project root:
  `$ODOO_LS_HOME/server/target/release/odoo_ls_server --parse -t $PWD -o /tmp/out.json`
  and check the log for "N modules loaded".
- **Unresolved third-party imports**: install them into the Python given as
  `python_path` (e.g. `uv pip install --python .venv/bin/python ...`).
