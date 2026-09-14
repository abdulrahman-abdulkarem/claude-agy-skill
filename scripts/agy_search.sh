#!/usr/bin/env bash
set -euo pipefail

# Dedicated Online Web Search tool using Antigravity CLI (agy)
# Performs real-time grounded web retrieval and returns concise summaries with sources.

if ! command -v agy &> /dev/null; then
    echo "Error: 'agy' CLI is not found in PATH. Ensure Antigravity CLI is installed." >&2
    exit 1
fi

QUERY="${*:-}"

if [[ -z "$QUERY" ]]; then
    echo "Usage: $0 \"<search query>\""
    echo ""
    echo "Examples:"
    echo "  $0 \"latest Python 3.13 changelog and new features\""
    echo "  $0 \"React 19 breaking changes site:react.dev\""
    echo "  $0 \"gRPC Go keepalive settings best practices\""
    exit 1
fi

exec agy --dangerously-skip-permissions \
         --effort low \
         --print-timeout 3m \
         --print "Search the live web for: ${QUERY}. Retrieve current information, synthesize a clear and concise summary, and include source links."
