# termux-ai-setup

Install **OpenCode** sa Termux — optimized for Xiaomi Pad 7 (aarch64).

> **NOTE:** Ang **MiMoCode** (Xiaomi fork ng OpenCode) ay nasa **hiwalay na repo** na:
> 👉 [heje1221/mimo-install](https://github.com/heje1221/mimo-install)
>
> Hindi na kasama ang MiMoCode dito. Kung kailangan mo pareho, i-install ang dalawang repos nang hiwalay.

## Quick Start (After Format / Fresh Termux)

**One command — copies, installs deps, OpenCode:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/heje1221/termux-ai-setup/master/install-ai-cli.sh) --bootstrap
```

That's it. Restart shell: `source ~/.bashrc`

---

## Usage

```bash
# Interactive menu
bash install-ai-cli.sh

# Or with flags:
bash install-ai-cli.sh --bootstrap   # Fresh Termux: git + deps + opencode
bash install-ai-cli.sh --all         # deps + opencode (default)
bash install-ai-cli.sh --opencode    # opencode only
bash install-ai-cli.sh --deps        # dependencies only
bash install-ai-cli.sh --env         # API key reminder
```

### Options

| Flag | Description |
|------|-------------|
| `--bootstrap` | **Fresh install** — clones repo, installs git/deps OpenCode |
| `--all` | Install deps + OpenCode |
| `--opencode` | Install OpenCode only |
| `--deps` | Install dependencies only (proot, glibc, glibc-runner) |
| `--env` | Show API key setup reminder |

---

## How It Works

- **proot + grun (glibc-runner)** — bypasses Android seccomp `statx` block on aarch64
- **Wrapper** in `~/.local/bin/` — `opencode` command works globally (via `proot -k 0x20000000 grun`)
- **API keys** — add to `~/.bashrc`:
  ```bash
  export OPENAI_API_KEY="your-key"
  # or ZEN_API_KEY / OPENROUTER_API_KEY
  ```

> **IMPORTANT:** Huwag i-export ang `~/.opencode/bin` nang direkta sa PATH. Ang raw binary doon ay glibc-based at HINDI kayang i-execute ng Termux nang walang grun. Ang wrapper lang sa `~/.local/bin/` ang gumagana.

---

## Requirements

- Termux (from **F-Droid**, not Play Store)
- Xiaomi Pad 7 / aarch64 device
- Internet connection

---

## Manual Clone (Alternative)

```bash
pkg install git -y
git clone https://github.com/heje1221/termux-ai-setup.git
cd termux-ai-setup
bash install-ai-cli.sh --bootstrap
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `grun not found` | `pkg install glibc-runner` |
| `proot: command not found` | `pkg install proot` |
| `required file not found` kapag nag-run | Raw glibc binary na na-execute — gamitin ang wrapper (`~/.local/bin/opencode`), hindi ang `~/.opencode/bin` |
| Permission denied | `chmod +x install-ai-cli.sh` |
| API key not working | Add to `~/.bashrc` then `source ~/.bashrc` |