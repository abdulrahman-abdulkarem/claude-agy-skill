---
name: agy
description: Use the Antigravity CLI (agy) to execute live online web searches, deep technical research, and quick delegated subtasks. Activate whenever you need real-time internet search, up-to-date web documentation, package/release info, error diagnostics from GitHub issues, external technical research, or fast secondary task execution.
---

# Antigravity CLI (`agy`) Skill

Leverage the `agy` CLI to perform **live online web searches**, conduct **deep technical
research**, and delegate **small, focused tasks**.

Scripts live alongside this file in `scripts/` and work from any project directory.

---

## Critical Execution Rules

1. **Non-Interactive Flag Order**
   - Always supply `--dangerously-skip-permissions` **BEFORE** `--print` (`-p`).
   - If `--print` is placed first without an attached argument, it treats subsequent flags as
     prompt text and fails.
   - Correct format: `agy --dangerously-skip-permissions --print "Your prompt here"`
2. **Prefer the Wrapper Scripts**
   - Web search: `~/.claude/skills/agy/scripts/agy_search.sh "<query>"`
   - General: `~/.claude/skills/agy/scripts/agy_runner.sh [search|deep|task] "<prompt>"`
   - They handle argument escaping, timeouts, and flag sequencing automatically.
3. **Citations & Sources**
   - Live web searches return grounded source URLs. Always preserve and surface these links in
     the final answer to the user.
4. **Quoting**
   - Always wrap the query in double quotes. The scripts join all trailing args, so an unquoted
     query still works, but quoting avoids shell globbing on `*`, `?`, and `()`.

---

## 1. Online Web Search (Primary Capability)

Use online search whenever information is needed beyond the training cutoff or in real time.

### When to Trigger Online Search
- **API Documentation** — latest syntax, parameters, or functions for recently updated SDKs.
- **Breaking Changes & Release Notes** — new framework versions (Next.js, React, PyTorch, Go, Node.js).
- **Error Diagnostics & GitHub Issues** — exact stack traces or error strings to find active discussions.
- **Package Versions** — newest stable release on npm, PyPI, or crates.io.

### Execution
```bash
# Dedicated search script (preferred)
~/.claude/skills/agy/scripts/agy_search.sh "<query>"

# Multi-mode runner
~/.claude/skills/agy/scripts/agy_runner.sh search "<query>"

# Direct CLI
agy --dangerously-skip-permissions --effort low --print \
    "Search the live web for: <query>. Provide a concise summary with official source links."
```

### Query Optimization Tips
- Include current year or version: `"Next.js 15 Server Actions best practices"`
- Restrict to documentation domains: `"Python 3.13 changelog site:docs.python.org"`
- Search error strings verbatim: `"TypeError: Cannot read properties of undefined (reading 'digest')"`

Typical latency: ~20–30s.

---

## 2. Deep Searching & Technical Research (`deep`)

For architectural trade-off analysis, complex debugging, or in-depth technical comparisons
requiring high-effort reasoning:

```bash
~/.claude/skills/agy/scripts/agy_runner.sh deep "<topic>"

# Direct CLI
agy --dangerously-skip-permissions --effort high --model gemini-3.8-flash-high --print \
    "Conduct a thorough research investigation on: <topic>. Detail pros, cons, architectural implications, and sample implementations."
```

Typical latency: 35s–5m (6m timeout).

---

## 3. Simple and Small Tasks (`task`)

For quick standalone subtasks, boilerplate generation, or secondary verification:

```bash
~/.claude/skills/agy/scripts/agy_runner.sh task "<task description>"

# Direct CLI
agy --dangerously-skip-permissions --effort medium --print "Perform this focused task: <task description>."
```

Typical latency: ~5–20s.

---

## Output Handling
- Parse the text printed by `agy` on stdout.
- Surface source URLs to the user for reference.
- On error (timeout or non-zero exit), inspect stderr and retry or fall back gracefully.
- The scripts exit `1` with a usage message when the query/mode is missing, and exit `1` with
  an explanatory message if `agy` is not on `PATH`.

See `references/cheatsheet.md` for the full flag and model reference.
