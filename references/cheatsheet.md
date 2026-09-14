# `agy` CLI Reference Cheatsheet

## Key CLI Options
- `--dangerously-skip-permissions`: Automatically approves tool actions without interactive prompts. **Mandatory** for non-interactive / scripted calls.
- `-p, --print`: Runs a single prompt non-interactively and prints the response.
- `--effort <low|medium|high>`: Sets reasoning effort.
- `--model <model-id>`: Specific model to use (e.g., `gemini-3.8-flash-high`, `gemini-3.7-flash-high`, `claude-sonnet-4-6`).
- `--output-format <text|json|stream-json>`: Changes output format (default is `text`).
- `--print-timeout <duration>`: Maximum wait time before timing out (default is `5m`).
- `--sandbox`: Runs in sandbox mode with restricted terminal privileges if executing untrusted code.

## Critical Flag Order Caution
Always ensure `--dangerously-skip-permissions` precedes `--print "..."`:
```bash
# CORRECT:
agy --dangerously-skip-permissions --print "prompt"

# INCORRECT (will parse following flag as prompt):
agy -p --dangerously-skip-permissions "prompt"
```

## Available Models (Quick Selection)
- `gemini-3.8-flash-high`: Fast with deep reasoning, ideal for deep research and synthesis.
- `gemini-3.8-flash-low`: Ultra-low latency, ideal for quick lookups and small tasks.
- `claude-sonnet-4-6`: High reasoning quality for complex coding tasks and reviews.
