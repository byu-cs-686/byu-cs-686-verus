#!/bin/bash
set -euxo pipefail

find_code_cli() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return
  fi

  local server_root candidate
  for server_root in "$HOME/.vscode-server/bin" /vscode/vscode-server/bin; do
    [[ -d "$server_root" ]] || continue
    candidate=$(
      find "$server_root" -type f -path "*/bin/code-server" -perm -u+x \
        -printf "%T@ %p\n" 2>/dev/null |
        sort -nr |
        head -n 1 |
        cut -d' ' -f2-
    )
    if [[ -n "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  echo "❌ Neither the VS Code CLI nor the VS Code Server CLI was found" >&2
  return 1
}

# Find the .vsix file in the dist directory
VSIX_PATH=$(find /home/vscode/verus-analyzer/dist -maxdepth 1 -name "verus-analyzer-*.vsix" | head -n 1)

if [[ -f "$VSIX_PATH" ]]; then
  echo "📦 Installing Verus Analyzer from: $VSIX_PATH"
  CODE_CLI=$(find_code_cli)
  "$CODE_CLI" --install-extension "$VSIX_PATH"
else
  echo "❌ VSIX file not found at expected path: $VSIX_PATH"
  exit 1
fi

# Install pre-commit Git hook if config is present
PROJECT_DIR="/workspaces/byu-cs-686-verus"
cd "$PROJECT_DIR"

if [[ -f ".pre-commit-config.yaml" ]]; then
  echo "🔧 Installing pre-commit Git hook..."
  pre-commit install
else
  echo "⚠️  Skipping pre-commit install: .pre-commit-config.yaml not found in $PROJECT_DIR"
fi
