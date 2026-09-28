# odoo-lsp for Claude Code

A Claude Code plugin that connects the [Odoo Language Server](https://github.com/odoo/odoo-ls)
(odoo-ls) to Claude Code's LSP tool, plus a skill that tells Claude how to use it.

With it, Claude can jump to definitions across your addons and Odoo core, hover
models, fields and methods, list symbols, and get `OLS0xxxx` diagnostics after
edits. It covers `.py`, `.xml` and `.csv` files, so Claude no longer has to grep
the Odoo source tree.

## Why a fork of odoo-ls

Upstream odoo-ls registers some capabilities dynamically with
`client/registerCapability`. Claude Code doesn't support dynamic registration
and rejects that request, and the server then panics and exits with code 101
right after startup.

The fork [`villelaitila/odoo-ls`](https://github.com/villelaitila/odoo-ls/tree/claude-code-compat),
branch `claude-code-compat`, logs a warning and keeps running instead. Static
capabilities already cover what Claude Code uses. The change is a few lines on
top of odoo-ls 1.6.0 and is proposed upstream as
[odoo/odoo-ls#745](https://github.com/odoo/odoo-ls/pull/745). After an upstream
release includes it, any stock `odoo_ls_server` will work.

## Contents

| Path | What it is |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (`odoo-lsp`) |
| `.lsp.json` | Registers the `odoo` language server for `.py`, `.xml` and `.csv` |
| `bin/odoo-ls` | Wrapper that finds and starts `odoo_ls_server` |
| `scripts/install-odoo-ls.sh` | Clones and builds the fork |
| `skills/odoo-ls/SKILL.md` | Tells Claude when and how to use the LSP tool, and how to troubleshoot |
| `templates/odools.toml` | Example project configuration for odoo-ls |

## Setup

### 1. Build the server

This step needs git and a Rust toolchain ([rustup](https://rustup.rs)).

```sh
git clone https://github.com/softagram/odoo-lsp-claude-code.git
odoo-lsp-claude-code/scripts/install-odoo-ls.sh
```

The script builds into `~/.local/share/odoo-ls`. To use another directory, set
`ODOO_LS_HOME` both when you run the script and in the environment that starts
Claude Code. `bin/odoo-ls` looks for
`$ODOO_LS_HOME/server/target/release/odoo_ls_server`. To point it at a binary
directly, set `ODOO_LS_SERVER`.

### 2. Install the plugin

Pick one of these:

- **From the [Softagram marketplace](https://github.com/softagram/claude-plugins-marketplace)**
  (all projects):
  ```
  /plugin marketplace add softagram/claude-plugins-marketplace
  /plugin install odoo-lsp@softagram-plugins
  ```
- **Project-scoped**: copy the repo into the project as
  `.claude/skills/odoo-lsp/` (the directory holding `.claude-plugin/`,
  `.lsp.json`, `bin/` and `skills/`). Claude Code loads it as
  `odoo-lsp@skills-dir`.
- **For one session**: `claude --plugin-dir /path/to/odoo-lsp-claude-code`.

### 3. Configure the project

odoo-ls needs to know where Odoo is and which Python to use:

1. Create a Python environment with Odoo's requirements, for example:
   ```sh
   uv venv --python 3.12
   uv pip install --python .venv/bin/python -r ~/src/odoo/requirements.txt
   ```
2. Copy `templates/odools.toml` to the project root as `odools.toml`. Set
   `odoo_path` and `addons_paths` to your paths. Keep the profile name
   `default`, which `.lsp.json` selects.

Start Claude Code in the project. The first index of a full Odoo tree takes
about 10–20 s.

## Usage

Ask Claude about Odoo code as usual. The `odoo-ls` skill tells Claude to use
these LSP operations:

| Question | LSP operation |
|---|---|
| Where is this model, field or method defined? This includes Odoo core. | `goToDefinition` |
| What is this model, what inherits it, and what is the method's signature and docstring? | `hover` |
| Which symbols does this file define? | `documentSymbol` |
| Where are methods or XML ids with this name, across all addons? | `workspaceSymbol` |

Known limitations: `findReferences` returns nothing, so Claude falls back to
grep for usages. `goToDefinition` on `fields.X` points to the top of the
module instead of the class line.

## Troubleshooting

Server logs are in `$ODOO_LS_HOME/server/target/release/logs/`. The skill's
[troubleshooting section](skills/odoo-ls/SKILL.md#troubleshooting) covers
startup crashes, rebuilds, the `typeshed` symlinks and how to check the
configuration without Claude Code.

## License

The files in this repository are MIT licensed (see [LICENSE](LICENSE)).
odoo-ls itself is LGPL-3.0, from Odoo S.A.
