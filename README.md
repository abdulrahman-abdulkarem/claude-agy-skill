# agy — Online Search & Deep Research Skill for Claude Code

A [Claude Code](https://claude.com/claude-code) skill that gives Claude **live internet access**
by delegating to the [Antigravity CLI](https://antigravity.google) (`agy`).

Claude's built-in knowledge has a training cutoff. This skill lets it reach past that — pulling
current documentation, release notes, package versions, and GitHub issue threads at the moment
you ask, with grounded source links it can cite back to you.

---

## What It Does

Three modes, distinguished only by prompt framing and timeout:

| Mode | What it's for | Typical latency |
|------|---------------|-----------------|
| **`search`** | Live web lookups — latest docs, package versions, release notes, error strings | ~30–60s |
| **`deep`** | Architectural trade-offs, technical comparisons, complex debugging research | ~35s–5m |
| **`task`** | Quick delegated subtasks, boilerplate, second-opinion verification | ~10–20s (scales with the work asked for) |

**Every mode always runs on `gemini-3.8-flash-high` at `--effort high`** — there is no
lower-effort or different-model path. That trades a bit of latency on simple lookups for
consistently strong reasoning on everything the skill does, including quick ones.

Claude triggers the skill automatically when a question needs current information, or you can
invoke it explicitly with `/agy`.

### Example

```
You:    What's the current Node.js LTS?

Claude: [runs agy_search.sh "latest stable Node.js LTS version release date"]

        Node.js v24 "Krypton" — Active LTS since October 28, 2025,
        supported until April 2028. Node.js 22 "Jod" remains supported
        until April 2027.

        Sources:
        - https://nodejs.org/en/about/previous-releases
        - https://github.com/nodejs/Release#release-schedule
```

---

## Requirements

- **[Claude Code](https://claude.com/claude-code)** — any recent version
- **[Antigravity CLI](https://antigravity.google) (`agy`)** — **installed and signed in.** This
  skill is a wrapper around it and does nothing without it. Developed against `agy` 1.2.2.
- **Bash 4+**, on Linux or macOS

> ⚠️ **Install and authenticate the Antigravity CLI *before* installing this skill.** The skill
> shells out to `agy` for every operation. If `agy` is missing or not signed in, the skill will
> install fine but every call will fail. Step 1 below covers it.

---

## Installation

### Step 1 — Install the Antigravity CLI (do this first)

**macOS / Linux:**
```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

Then **authenticate** — run `agy` once with no arguments. On first launch it opens your browser
to sign in (or prints a copyable link if you're on a remote SSH session) and walks you through
first-time setup. You must complete this, or every call from the skill will fail.

Confirm it worked before continuing:

```bash
agy --version     # should print a version, e.g. 1.2.2
agy models        # should list models — this is what proves you're authenticated
```

If `agy models` prints a model list, you're ready. If it errors or hangs, fix the sign-in first —
installing the skill won't help.

> If `agy: command not found` after installing, the installer's bin directory isn't on your
> `PATH`. It's commonly `~/.local/bin` — add it with
> `export PATH="$HOME/.local/bin:$PATH"` in your `~/.bashrc` or `~/.zshrc`.

### Step 2 — Install this skill

```bash
git clone https://github.com/abdulrahman-abdulkarem/claude-agy-skill.git
cd claude-agy-skill
./install.sh
```

This copies the skill into `~/.claude/skills/agy/`, which makes it available in **every project**.
Restart Claude Code afterwards so it picks up the new skill.

The installer checks for `agy` and prints a warning if it's missing, but it will still install —
so don't treat a successful install as proof that Step 1 worked. Use the verification below.

### Other install targets

```bash
./install.sh --project            # install into ./.claude/skills/agy (this project only)
SKILLS_DIR=/custom/path ./install.sh   # install anywhere
./install.sh --uninstall          # remove it again
```

### Manual install

If you'd rather not run the script:

```bash
mkdir -p ~/.claude/skills/agy/{scripts,references}
cp SKILL.md                  ~/.claude/skills/agy/
cp scripts/*.sh              ~/.claude/skills/agy/scripts/
cp references/cheatsheet.md  ~/.claude/skills/agy/references/
chmod +x ~/.claude/skills/agy/scripts/*.sh
```

### Step 3 — Verify

```bash
~/.claude/skills/agy/scripts/agy_search.sh "latest Node.js LTS version"
```

You should get a short summary with source URLs within ~30 seconds. Inside Claude Code, `/agy`
should now appear in the skill list.

If this errors with `'agy' CLI is not found in PATH`, go back to Step 1 — the skill is installed
correctly, but its dependency isn't.

> **Note:** Claude generally cannot install this skill for you. Claude Code's permission
> classifier blocks agents from writing executables into `~/.claude/` or onto `PATH` — a
> deliberate guard, since these scripts launch another agent CLI with auto-approval. Run
> `install.sh` yourself; that's what it's for.

---

## Usage

### From Claude Code

Usually you don't invoke it at all — just ask a question that needs current information, and
Claude reaches for the skill:

- *"What changed in the latest Next.js release?"*
- *"Find GitHub issues for `ECONNRESET` in undici"*
- *"What's the newest stable version of ruff?"*
- *"Research the trade-offs between NATS and Kafka for our event bus"*

To force it, type `/agy`.

### From the shell

The scripts are plain Bash and work standalone:

```bash
# Dedicated search
~/.claude/skills/agy/scripts/agy_search.sh "React 19 breaking changes site:react.dev"

# Multi-mode runner
~/.claude/skills/agy/scripts/agy_runner.sh search "PyTorch 2.x CUDA compatibility matrix"
~/.claude/skills/agy/scripts/agy_runner.sh deep  "Rust vs Go for high-throughput stream processing"
~/.claude/skills/agy/scripts/agy_runner.sh task  "write a Python RFC 5322 email validator with tests"
```

Want them on your `PATH` as regular commands?

```bash
ln -s ~/.claude/skills/agy/scripts/agy_search.sh ~/.local/bin/agy-search
ln -s ~/.claude/skills/agy/scripts/agy_runner.sh ~/.local/bin/agy-run
```

### Writing better queries

- **Pin the version or year:** `"Next.js 15 Server Actions best practices"`
- **Restrict to official docs:** `"Python 3.13 changelog site:docs.python.org"`
- **Paste error strings verbatim:** `"TypeError: Cannot read properties of undefined (reading 'digest')"`

---

## How It Works

Each script is a thin, correct wrapper around one `agy --print` invocation. The value is in
getting the details right:

```bash
agy --dangerously-skip-permissions \
    --effort high \
    --model gemini-3.8-flash-high \
    --print-timeout 3m \
    --print "Search the live web for: ${QUERY}. Retrieve current information, synthesize a clear and concise summary, and include source links."
```

**The flag-order gotcha.** `--dangerously-skip-permissions` must come *before* `--print`. If
`--print` comes first without its argument attached, `agy` swallows the following flags as prompt
text and the call fails in a confusing way:

```bash
agy --dangerously-skip-permissions --print "prompt"   # ✅ correct
agy -p --dangerously-skip-permissions "prompt"        # ❌ flags parsed as prompt text
```

The scripts also handle argument joining (so unquoted multi-word queries still work), set
per-mode timeouts, and fail with a clear message when `agy` isn't on `PATH`.

### Model selection

Every mode, in both scripts, pins `--model gemini-3.8-flash-high --effort high`. This is
deliberate and uniform — none of the three modes fall back to a lighter model or lower effort,
even `task` for trivial one-liners. Available models (from `agy models`):

```
gemini-3.8-flash-high / -medium / -low
gemini-3.7-flash-high / -medium / -low
gemini-3.6-flash-high / -medium / -low
gemini-3.1-pro-high / -low
claude-sonnet-4-6
claude-opus-4-6-thinking
gpt-oss-120b-medium
```

To change the pinned model or effort, edit the `--model`/`--effort` flags in both
`scripts/agy_search.sh` and `scripts/agy_runner.sh` — update all four invocations (one in
`agy_search.sh`, three in `agy_runner.sh`) to keep them consistent. See
[`references/cheatsheet.md`](references/cheatsheet.md) for the full flag reference.

---

## Security Note

These scripts pass `--dangerously-skip-permissions` to `agy`, which auto-approves all of that
CLI's tool permission prompts. This is required for non-interactive use — without it the call
hangs waiting on a prompt nobody can answer.

What that means in practice:

- The `agy` agent can act without asking you first, within whatever sandbox Antigravity gives it.
- `search` and `deep` mode prompts are read-only research instructions, which is low risk.
- **`task` mode passes your prompt through verbatim**, so it can do whatever you ask it to do —
  including touching files. Treat it like running a command, not like asking a question.
- If you want a hard boundary, add `--sandbox` to the `agy` invocations in the scripts to run
  with restricted terminal privileges.

Review the scripts before installing. They're ~40 lines each and deliberately easy to audit.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Error: 'agy' CLI is not found in PATH` | Install Antigravity, or add its bin dir to `PATH` (commonly `~/.local/bin`) |
| Call hangs, then times out | Check `agy models` works — usually an expired auth session |
| Flags appear in the model's answer | Flag order is wrong; `--dangerously-skip-permissions` must precede `--print` |
| `/agy` doesn't appear in Claude Code | Restart Claude Code; confirm `~/.claude/skills/agy/SKILL.md` exists with valid frontmatter |
| `Permission denied` running a script | `chmod +x ~/.claude/skills/agy/scripts/*.sh` |
| Deep mode times out | Raise `--print-timeout` in `scripts/agy_runner.sh` (default `6m`) |

---

## Repository Layout

```
claude-agy-skill/
├── README.md                  You are here
├── SKILL.md                   Skill definition — triggers and rules Claude reads
├── install.sh                 Installer (user-level, project-level, or custom)
├── LICENSE                    MIT
├── scripts/
│   ├── agy_search.sh          Dedicated live web search
│   └── agy_runner.sh          Multi-mode runner (search | deep | task)
└── references/
    └── cheatsheet.md          agy CLI flags and model reference
```

`SKILL.md` is the part Claude actually reads. Its YAML frontmatter `description` is what Claude
matches against to decide when the skill is relevant — if you want different trigger behavior,
that's the line to edit.

---

## Contributing

Issues and PRs welcome. Useful directions:

- Support for other agent CLIs behind the same three-mode interface
- `--output-format json` parsing for structured results
- A `--sandbox`-by-default variant of `task` mode

---

## License

MIT — see [LICENSE](LICENSE).

This project is not affiliated with Anthropic or Google.
