#!/usr/bin/env bash
set -euo pipefail

# Check that agy CLI is installed and available
if ! command -v agy &> /dev/null; then
    echo "Error: 'agy' CLI is not found in PATH. Ensure Antigravity CLI is installed." >&2
    exit 1
fi

MODE="${1:-}"
shift || true
PROMPT="${*:-}"

if [[ -z "$MODE" || -z "$PROMPT" ]]; then
    echo "Usage: $0 {search|deep|task} \"<your prompt>\""
    echo "Examples:"
    echo "  $0 search \"latest PyTorch 2.x CUDA compatibility matrix\""
    echo "  $0 deep \"tradeoffs between Rust and Go for high-throughput stream processing\""
    echo "  $0 task \"write a python function to validate RFC 5322 email addresses with unit tests\""
    exit 1
fi

# Every mode always runs on gemini-3.8-flash-high at --effort high. Modes differ only in
# prompt framing and timeout, never in model or effort.
case "$MODE" in
    search)
        exec agy --dangerously-skip-permissions \
                 --effort high \
                 --model gemini-3.8-flash-high \
                 --print-timeout 3m \
                 --print "Search the web for: ${PROMPT}. Provide a concise, factual summary with sources."
        ;;
    deep)
        exec agy --dangerously-skip-permissions \
                 --effort high \
                 --model gemini-3.8-flash-high \
                 --print-timeout 6m \
                 --print "Perform an in-depth research analysis on: ${PROMPT}. Include key considerations, comparisons, and concrete examples."
        ;;
    task)
        exec agy --dangerously-skip-permissions \
                 --effort high \
                 --model gemini-3.8-flash-high \
                 --print-timeout 4m \
                 --print "${PROMPT}"
        ;;
    *)
        echo "Unknown mode: $MODE. Choose from: search, deep, task" >&2
        exit 1
        ;;
esac
