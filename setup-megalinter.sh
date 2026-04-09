#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/setup-megalinter.ps1"

PROJECT_ROOT="${PROJECT_ROOT:-$PWD/Test-and-Fix-MegaLinter-Tool}"
REPO_URL="${REPO_URL:-https://github.com/valorisa/Test-and-Fix-MegaLinter-Tool.git}"
PS_ARGS=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --project-root <path>   Chemin racine du projet (défaut: ./Test-and-Fix-MegaLinter-Tool)
  --repo-url <url>        URL du repo GitHub (défaut: https://github.com/valorisa/...)
  --dry-run               Mode simulation (aucune écriture)
  --skip-push             Ignore le git push
  --force                 Force la ré-exécution (bypass idempotence)
  -h, --help              Affiche cette aide
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    --repo-url)     REPO_URL="$2";    shift 2 ;;
    --dry-run)      PS_ARGS+=("-DryRun");   shift ;;
    --skip-push)    PS_ARGS+=("-SkipPush"); shift ;;
    --force)        PS_ARGS+=("-Force");    shift ;;
    -h|--help)      usage ;;
    *)              echo "❌ Option inconnue : $1" >&2; exit 1 ;;
  esac
done

if ! command -v pwsh &>/dev/null; then
  echo "❌ PowerShell 7+ (pwsh) requis. Installation : https://aka.ms/pwsh" >&2
  exit 1
fi

if [[ ! -f "$PS_SCRIPT" ]]; then
  echo "❌ Script introuvable : $PS_SCRIPT" >&2
  exit 1
fi

echo "🚀 Lancement du setup MegaLinter via PowerShell..."
pwsh -NoProfile -File "$PS_SCRIPT" \
  -ProjectRoot "$PROJECT_ROOT" \
  -RepoUrl "$REPO_URL" \
  "${PS_ARGS[@]}"

EXIT_CODE=$?
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "✅ Terminé avec succès."
else
  echo "❌ Échec avec le code $EXIT_CODE" >&2
fi
exit $EXIT_CODE