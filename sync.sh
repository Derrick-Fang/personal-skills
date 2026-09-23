#!/usr/bin/env bash
#
# sync.sh - Distribute skills from this repo to the skill directories of
#           agent harnesses installed on this machine.
#
# Usage:
#   ./sync.sh            Dry-run mode (default): detect and print planned
#                        actions only; nothing is written.
#   ./sync.sh --apply    Actually perform the sync.
#
# Sync behavior (with --apply):
#   - Uses rsync -a to copy/update each skill directory into the target.
#   - Add/update only: nothing is ever deleted from the target directories.
#     Skills removed from this repo are left untouched on the machine.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=1
case "${1:-}" in
  ""|--dry-run) DRY_RUN=1 ;;
  --apply)      DRY_RUN=0 ;;
  *)
    echo "Unknown argument: $1"
    echo "Usage: $0 [--dry-run|--apply]"
    exit 1
    ;;
esac

# -- 1. Discover skills in this repo (directories containing SKILL.md) ------
SKILLS=()
for dir in "$REPO_DIR"/*/; do
  if [[ -f "$dir/SKILL.md" ]]; then
    SKILLS+=("$(basename "$dir")")
  fi
done

echo "== Skills in this repo (${#SKILLS[@]}) =="
if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "  (none found: no directory contains SKILL.md)"
else
  for s in "${SKILLS[@]}"; do echo "  - $s"; done
fi
echo

# -- 2. Detect agent harnesses on this machine -------------------------------
# Entry format: "name|skill directory"
# Note: harnesses whose directory does not exist are skipped, so it is
# safe (and cheap) to list every common agent here.
CANDIDATES=(
  "Claude Code|$HOME/.claude/skills"
  "Codex|$HOME/.codex/skills"
  "Gemini CLI|$HOME/.gemini/skills"
  "Cursor|$HOME/.cursor/skills"
  "GitHub Copilot CLI|$HOME/.copilot/skills"
  "OpenCode|$HOME/.config/opencode/skills"
  "Amp|$HOME/.config/amp/skills"
  "Pi|$HOME/.pi/agent/skills"
  "Windsurf|$HOME/.codeium/windsurf/skills"
  "Cline|$HOME/.cline/skills"
  "Roo Code|$HOME/.roo/skills"
)

DETECTED=()
echo "== Detecting agent harnesses =="
for entry in "${CANDIDATES[@]}"; do
  name="${entry%%|*}"
  path="${entry##*|}"
  if [[ -d "$path" ]]; then
    echo "  [found]     $name -> $path"
    DETECTED+=("$entry")
  else
    echo "  [not found] $name ($path does not exist)"
  fi
done
echo

if [[ ${#DETECTED[@]} -eq 0 ]]; then
  echo "No agent harness detected. Nothing to do."
  exit 0
fi

# -- 3. Distribute skills to each detected harness ---------------------------
if [[ $DRY_RUN -eq 1 ]]; then
  echo "== DRY-RUN: planned actions only (nothing will be written) =="
fi

for entry in "${DETECTED[@]}"; do
  name="${entry%%|*}"
  path="${entry##*|}"
  echo
  echo "-> Target: $name ($path)"

  for s in "${SKILLS[@]:-}"; do
    [[ -z "$s" ]] && continue
    src="$REPO_DIR/$s/"
    dst="$path/$s/"
    if [[ $DRY_RUN -eq 1 ]]; then
      status="create"
      [[ -d "$dst" ]] && status="update"
      echo "    [would $status] $s  ($src -> $dst)"
    else
      mkdir -p "$dst"
      rsync -a "$src" "$dst"
      echo "    [synced] $s"
    fi
  done
done

echo
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run complete. No files were changed. Run './sync.sh --apply' to sync."
else
  echo "Sync complete."
fi
