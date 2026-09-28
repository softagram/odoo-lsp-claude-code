#!/usr/bin/env bash
# Builds odoo_ls_server from the Claude Code compatible odoo-ls fork into
# $ODOO_LS_HOME (default ~/.local/share/odoo-ls). Re-run to update.
#
# Requires git and a Rust toolchain (https://rustup.rs).
#
# Overrides: ODOO_LS_HOME, ODOO_LS_REPO, ODOO_LS_BRANCH.
set -euo pipefail

repo="${ODOO_LS_REPO:-https://github.com/villelaitila/odoo-ls.git}"
branch="${ODOO_LS_BRANCH:-claude-code-compat}"
home="${ODOO_LS_HOME:-$HOME/.local/share/odoo-ls}"

command -v git >/dev/null || { echo "git not found" >&2; exit 1; }
command -v cargo >/dev/null || { echo "cargo not found: install Rust from https://rustup.rs" >&2; exit 1; }

if [ -d "$home/.git" ]; then
  # Existing checkout: only fast-forward, never switch branches or discard work.
  current="$(git -C "$home" rev-parse --abbrev-ref HEAD)"
  if [ "$current" != "$branch" ]; then
    echo "$home is on branch '$current', expected '$branch'." >&2
    echo "Switch it yourself or point ODOO_LS_HOME to another directory." >&2
    exit 1
  fi
  echo "Updating $home ($branch)"
  git -C "$home" pull --ff-only
else
  echo "Cloning $repo ($branch) into $home"
  mkdir -p "$(dirname "$home")"
  git clone --branch "$branch" "$repo" "$home"
fi
git -C "$home" submodule update --init --recursive

echo "Building odoo_ls_server (release)"
(cd "$home/server" && cargo build --release)

# The server loads typeshed/ and additional_stubs/ from next to its binary.
cd "$home/server/target/release"
ln -sfn ../../typeshed typeshed
ln -sfn ../../additional_stubs additional_stubs

echo
echo "Built $home/server/target/release/odoo_ls_server"
if [ "$home" != "$HOME/.local/share/odoo-ls" ]; then
  echo "Non-default location: export ODOO_LS_HOME=$home before starting Claude Code."
fi
