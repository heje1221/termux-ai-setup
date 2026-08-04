# termux-ai-setup

Install AI CLI tools (OpenCode + MiMoCode) sa Termux — optimized for Xiaomi Pad 7 (aarch64).

## Quick Start (After Format / Fresh Termux)

**One command — copies, installs deps, OpenCode, MiMoCode:**

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
bash install-ai-cli.sh --bootstrap   # Fresh Termux: git + deps + opencode + mimo
bash install-ai-cli.sh --all         # deps + opencode + mimo (default)
bash install-ai-cli.sh --opencode    # opencode only
bash install-ai-cli.sh --mimo        # mimo only
bash install-ai-cli.sh --deps        # dependencies only
bash install-ai-cli.sh --env         # API key reminder
```

### Options

| Flag | Description |
|------|-------------|
| `--bootstrap` | **Fresh install** — clones repo, installs git/deps, then OpenCode + MiMoCode |
| `--all` | Install deps + OpenCode + MiMoCode |
| `--opencode` | Install OpenCode only |
| `--mimo` | Install MiMoCode only |
| `--deps` | Install dependencies only (proot, glibc, glibc-runner) |
| `--env` | Show API key setup reminder |

---

## How It Works

- **proot + grun (glibc-runner)** — bypasses Android seccomp `statx` block on aarch64
- **Wrappers** in `~/.local/bin/` — `opencode` and `mimo` commands work globally
- **API keys** — add to `~/.bashrc`:
  ```bash
  export OPENAI_API_KEY="your-key"
  # or ZEN_API_KEY / OPENROUTER_API_KEY
  ```

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
| Permission denied | `chmod +x install-ai-cli.sh` |
| API key not working | Add to `~/.bashrc` then `source ~/.bashrc` |