#!/data/data/com.termux/files/usr/bin/env bash
# ============================================================
#  install-ai-cli.sh — OpenCode + MiMoCode installer (Termux)
#  Para sa Xiaomi Pad 7 (aarch64), LineageOS/Termux
#  Pareho silang kailangan ng proot + grun (glibc-runner)
#  para ma-bypass ang Android seccomp "statx" block.
# ============================================================
set -euo pipefail

OPENCODE_BIN="$HOME/.opencode/bin/opencode"
MIMO_BIN="$HOME/.mimocode/bin/mimo"
WRAPPER_DIR="$HOME/.local/bin"
GRUN="/data/data/com.termux/files/usr/glibc/bin/grun"
PROOT="/data/data/com.termux/files/usr/bin/proot"
ARCH="aarch64"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

say()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# ------------------------------------------------------------
# 1. Dependencies
# ------------------------------------------------------------
install_deps() {
    say "Installing dependencies: proot, glibc-repo, glibc, glibc-runner, curl, tar..."
    pkg update -y
    pkg install -y proot curl tar glibc-repo || warn "glibc-repo install failed (baka naka-install na)"
    pkg install -y glibc glibc-runner || fail "Hindi ma-install ang glibc/glibc-runner"

    # verify tools
    for t in proot curl tar; do
        command -v "$t" >/dev/null 2>&1 || fail "Missing tool: $t"
    done
    [ -x "$PROOT" ]   || fail "proot not found: $PROOT"
    [ -x "$GRUN" ]    || fail "grun not found: $GRUN (i-install ang glibc-runner)"
    say "Dependencies OK (proot + grun ready)"
}

# ------------------------------------------------------------
# 2. Wrapper creator (shared: unset LD_PRELOAD + proot + grun)
# ------------------------------------------------------------
make_wrapper() {
    local name="$1" real_bin="$2"
    local wrapper="$WRAPPER_DIR/$name"
    mkdir -p "$WRAPPER_DIR"
    cat > "$wrapper" <<EOF
#!/data/data/com.termux/files/usr/bin/env bash
unset LD_PRELOAD
exec "$PROOT" -k 0x20000000 "$GRUN" "$real_bin" "\$@"
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
    make_wrapper "opencode" "$OPENCODE_BIN"

    # add to .bashrc
    grep -q 'opencode' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<EOF

# opencode
export PATH=$HOME/.opencode/bin:\$PATH
alias opencode="proot -k 0x20000000 grun ~/.opencode/bin/opencode"
EOF
    say "OpenCode OK. Run: source ~/.bashrc && opencode"
}

# ------------------------------------------------------------
# 4. Install MiMoCode (Xiaomi fork ng OpenCode)
#    Official installer: curl -fsSL https://mimo.xiaomi.com/install | bash
# ------------------------------------------------------------
install_mimo() {
    say "Installing MiMoCode (Xiaomi installer)..."
    if [ -x "$MIMO_BIN" ]; then
        warn "mimo binary exists na: $MIMO_BIN"
    else
        curl -fsSL https://mimo.xiaomi.com/install | bash \
            || fail "MiMoCode install failed"
    fi
    [ -x "$MIMO_BIN" ] || fail "MiMo binary not found after install"
    make_wrapper "mimo" "$MIMO_BIN"

    grep -q 'mimocode' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<EOF

# mimocode (Xiaomi fork) - wrapper sa ~/.local/bin/mimo
export PATH=$HOME/.local/bin:\$PATH
EOF
    say "MiMoCode OK. Run: source ~/.bashrc && mimo"
}

# ------------------------------------------------------------
# 5. API key setup (optional)
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
  --all        i-install dependencies + opencode + mimo (default)
  --opencode   opencode lang
  --mimo       mimo lang
  --deps       dependencies lang
  --env        setup API key reminder
  -h, --help   help

Halimbawa:
  $0 --all            # buong install (reco)
  $0 --opencode       # opencode lang
  $0 --mimo           # mimo lang
EOF
}

# ------------------------------------------------------------
# Interactive menu
# ------------------------------------------------------------
banner() {
    cat <<"EOF"

 ====================================================
      AI CLI INSTALLER — OpenCode + MiMoCode
      Termux | Xiaomi Pad 7 (aarch64)
 ====================================================
EOF
}

show_menu() {
    banner
    echo
    echo "  Pumili ka ng gagawin:"
    echo
    echo "    [1] Buong install  (deps + opencode + mimo)  <-- RECO"
    echo "    [2] OpenCode lang"
    echo "    [3] MiMoCode lang"
    echo "    [4] Dependencies lang"
    echo "    [5] Setup API key reminder"
    echo "    [0] Exit"
    echo
}

menu_loop() {
    local choice
    while true; do
        show_menu
        read -rp "  Pumili [0-5]: " choice
        case "$choice" in
            1) install_deps; install_opencode; install_mimo; setup_env; return ;;
            2) install_deps; install_opencode; return ;;
            3) install_deps; install_mimo; return ;;
            4) install_deps; return ;;
            5) setup_env; return ;;
            0) echo "  Bye!"; exit 0 ;;
            *) warn "Invalid choice: $choice"; sleep 1 ;;
        esac
    done
}

# --- entry point ---
if [ "$#" -eq 0 ]; then
    # walang argumento -> interactive menu
    menu_loop
else
    case "${1#--}" in
        all|both)
            install_deps; install_opencode; install_mimo; setup_env
            ;;
        opencode)
            install_deps; install_opencode
            ;;
        mimo)
            install_deps; install_mimo
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
