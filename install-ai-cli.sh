#!/data/data/com.termux/files/usr/bin/env bash
# ============================================================
#  install-ai-cli.sh — OpenCode installer (Termux)
#  ============================================================
#  Para sa Xiaomi Pad 7 (aarch64), LineageOS/Termux.
#  Kailangan ng proot + grun (glibc-runner) para ma-bypass ang
#  Android seccomp "statx" block.
#
#  NOTE: HiwALAY na installer ang MiMoCode (Xiaomi fork ng
#  OpenCode) — nasa repo na: https://github.com/heje1221/mimo-install
# ============================================================
set -euo pipefail

OPENCODE_BIN="$HOME/.opencode/bin/opencode"
WRAPPER_DIR="$HOME/.local/bin"
GRUN="/data/data/com.termux/files/usr/glibc/bin/grun"
PROOT="/data/data/com.termux/files/usr/bin/proot"
REPO_URL="https://github.com/heje1221/termux-ai-setup.git"
REPO_DIR="$HOME/termux-ai-setup"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

say()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# ------------------------------------------------------------
# 0. Bootstrap — fresh Termux install (OpenCode lang)
# ------------------------------------------------------------
bootstrap() {
    say "Bootstrapping fresh Termux..."
    pkg update -y
    pkg install -y git curl tar which proot glibc-repo || warn "glibc-repo install failed"
    pkg install -y glibc glibc-runner || fail "Hindi ma-install ang glibc/glibc-runner"
    termux-setup-storage

    if [ ! -d "$REPO_DIR" ]; then
        say "Cloning repo..."
        git clone "$REPO_URL" "$REPO_DIR" || fail "Git clone failed"
    fi
    cd "$REPO_DIR"
    say "Bootstrap done. Running OpenCode install..."
    install_deps
    install_opencode
    setup_env
}

# ------------------------------------------------------------
# 1. Dependencies
# ------------------------------------------------------------
install_deps() {
    say "Installing dependencies: proot, glibc-repo, glibc, glibc-runner, curl, tar, which..."
    pkg update -y
    pkg install -y proot curl tar which glibc-repo || warn "glibc-repo install failed (baka naka-install na)"
    pkg install -y glibc glibc-runner || fail "Hindi ma-install ang glibc/glibc-runner"

    for t in proot curl tar which; do
        command -v "$t" >/dev/null 2>&1 || fail "Missing tool: $t"
    done
    [ -x "$PROOT" ]   || fail "proot not found: $PROOT"
    [ -x "$GRUN" ]    || fail "grun not found: $GRUN (i-install ang glibc-runner)"
    say "Dependencies OK (proot + grun ready)"
}

# ------------------------------------------------------------
# 2. Wrapper creator
# ------------------------------------------------------------
make_wrapper() {
    local wrapper="$WRAPPER_DIR/opencode"
    mkdir -p "$WRAPPER_DIR"
    cat > "$wrapper" <<EOF
#!/data/data/com.termux/files/usr/bin/env bash
unset LD_PRELOAD
exec "$PROOT" -k 0x20000000 "$GRUN" "$OPENCODE_BIN" "\$@"
EOF
    chmod +x "$wrapper"
    say "Wrapper created: $wrapper"
}

# ------------------------------------------------------------
# 3. Install OpenCode
#    Official installer -> binary sa ~/.opencode/bin/opencode
# ------------------------------------------------------------
install_opencode() {
    say "Installing OpenCode (official installer)..."
    mkdir -p "$HOME/.opencode/bin"
    if [ -x "$OPENCODE_BIN" ]; then
        warn "opencode binary exists na: $OPENCODE_BIN"
    else
        curl -fsSL https://opencode.ai/install | bash \
            || fail "OpenCode install failed"
    fi
    [ -x "$OPENCODE_BIN" ] || fail "OpenCode binary not found after install"
    make_wrapper

    grep -q 'local/bin' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<EOF

# opencode - wrapper sa ~/.local/bin/opencode (proot + grun)
export PATH=\$HOME/.local/bin:\$PATH
EOF
    say "OpenCode OK. Run: source ~/.bashrc && opencode"
}

# ------------------------------------------------------------
# 4. API key setup (optional)
# ------------------------------------------------------------
setup_env() {
    if grep -qE 'OPENAI_API_KEY|ZEN_API_KEY' "$HOME/.bashrc" 2>/dev/null; then
        say "API keys nasa .bashrc na — skip"
    else
        warn "Walang API key sa .bashrc."
        warn "I-add mo ito (kopyahin mo sa API Keys.txt / memory.txt):"
        echo '  export OPENAI_API_KEY="..."   # or ZEN_API_KEY / OPENROUTER_API_KEY'
        echo "Pagkatapos: source ~/.bashrc"
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 [options]
  --bootstrap  fresh Termux: git + deps + opencode (RECO after format)
  --all        i-install dependencies + opencode (default)
  --opencode   opencode lang (same as --all)
  --deps       dependencies lang
  --env        setup API key reminder
  -h, --help   help

NOTE: MiMoCode ay nasa hiwalay na repo na:
      https://github.com/heje1221/mimo-install

Halimbawa:
  $0 --bootstrap      # fresh Termux (reco after format)
  $0 --all            # buong install
  $0 --opencode       # opencode lang
EOF
}

# ------------------------------------------------------------
# Interactive menu
# ------------------------------------------------------------
banner() {
    cat <<"EOF"

 ====================================================
      AI CLI INSTALLER — OpenCode
      Termux | Xiaomi Pad 7 (aarch64)
 ====================================================
EOF
}

show_menu() {
    banner
    echo
    echo "  Pumili ka ng gagawin:"
    echo
    echo "    [1] Bootstrap (fresh Termux — git + opencode)  <-- RECO after format"
    echo "    [2] OpenCode install (deps + opencode)"
    echo "    [3] Dependencies lang"
    echo "    [4] Setup API key reminder"
    echo "    [0] Exit"
    echo
    echo "  [i] MiMoCode? Nasa hiwalay na repo:"
    echo "      https://github.com/heje1221/mimo-install"
    echo
}

menu_loop() {
    local choice
    while true; do
        show_menu
        read -rp "  Pumili [0-4]: " choice
        case "$choice" in
            1) bootstrap; return ;;
            2) install_deps; install_opencode; setup_env; return ;;
            3) install_deps; return ;;
            4) setup_env; return ;;
            0) echo "  Bye!"; exit 0 ;;
            *) warn "Invalid choice: $choice"; sleep 1 ;;
        esac
    done
}

# --- entry point ---
if [ "$#" -eq 0 ]; then
    menu_loop
else
    case "${1#--}" in
        bootstrap)
            bootstrap
            ;;
        all)
            install_deps; install_opencode; setup_env
            ;;
        opencode)
            install_deps; install_opencode
            ;;
        deps)
            install_deps
            ;;
        env)
            setup_env
            ;;
        h|help|-h|--help)
            usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
fi

say "Done! Restart shell: source ~/.bashrc"