#!/usr/bin/env bash
set -euo pipefail

# Installer for the `agy` Claude Code skill.
#
#   ./install.sh              Install into ~/.claude/skills/agy (user-level, all projects)
#   ./install.sh --project    Install into ./.claude/skills/agy (current project only)
#   ./install.sh --uninstall  Remove the installed skill
#
# Override the destination entirely with SKILLS_DIR=/some/path ./install.sh

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="agy"

MODE="install"
SCOPE="user"

for arg in "$@"; do
    case "$arg" in
        --uninstall) MODE="uninstall" ;;
        --project)   SCOPE="project" ;;
        -h|--help)
            sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (try --help)" >&2
            exit 1
            ;;
    esac
done

if [[ -n "${SKILLS_DIR:-}" ]]; then
    BASE="$SKILLS_DIR"
elif [[ "$SCOPE" == "project" ]]; then
    BASE="$PWD/.claude/skills"
else
    BASE="$HOME/.claude/skills"
fi

DEST="$BASE/$SKILL_NAME"

if [[ "$MODE" == "uninstall" ]]; then
    if [[ -e "$DEST" ]]; then
        rm -rf "$DEST"
        echo "Removed $DEST"
    else
        echo "Nothing to remove at $DEST"
    fi
    exit 0
fi

# --- Preflight -------------------------------------------------------------
if ! command -v agy &> /dev/null; then
    echo "Warning: 'agy' CLI was not found on PATH." >&2
    echo "         The skill will install, but will not run until Antigravity is installed." >&2
    echo "         See: https://antigravity.google/docs/cli" >&2
    echo >&2
else
    echo "Found agy: $(command -v agy) ($(agy --version 2>/dev/null || echo 'version unknown'))"
fi

if [[ "$SRC" == "$DEST" ]]; then
    echo "Error: source and destination are the same directory ($DEST)." >&2
    exit 1
fi

for required in SKILL.md scripts/agy_search.sh scripts/agy_runner.sh references/cheatsheet.md; do
    if [[ ! -f "$SRC/$required" ]]; then
        echo "Error: missing required file '$required' in $SRC" >&2
        exit 1
    fi
done

# --- Install ---------------------------------------------------------------
mkdir -p "$DEST/scripts" "$DEST/references"

cp "$SRC/SKILL.md"                    "$DEST/SKILL.md"
cp "$SRC/scripts/agy_search.sh"       "$DEST/scripts/agy_search.sh"
cp "$SRC/scripts/agy_runner.sh"       "$DEST/scripts/agy_runner.sh"
cp "$SRC/references/cheatsheet.md"    "$DEST/references/cheatsheet.md"

chmod +x "$DEST/scripts/agy_search.sh" "$DEST/scripts/agy_runner.sh"

echo "Installed skill '$SKILL_NAME' to $DEST"
echo
echo "Files:"
find "$DEST" -type f | sort | sed 's/^/  /'
echo
echo "Next steps:"
echo "  1. Restart Claude Code (or run /doctor) so the skill is picked up."
echo "  2. Verify with:  $DEST/scripts/agy_search.sh \"latest Node.js LTS version\""
echo "  3. In Claude Code, invoke it with:  /agy"
