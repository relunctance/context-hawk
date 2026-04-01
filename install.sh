#!/bin/bash
# context-hawk one-command install script
# Supports: Ubuntu/Debian, Fedora/RHEL/CentOS/Rocky/AlmaLinux, Arch, Alpine, openSUSE, macOS
# Usage:
#   curl -fsSL https://.../install.sh | bash
#   ./install.sh --help
#
set -euo pipefail

# ───────────────────────────────────────────────
# Constants
# ───────────────────────────────────────────────
VERSION="1.0.0"
HAWK_REPO="${HAWK_REPO:-https://github.com/relunctance/context-hawk}"
INSTALL_DIR="${HOME}/.openclaw/workspace/context-hawk"
HAWK_DIR="${HOME}/.hawk"
HAWK_SYMLINK="${HOME}/.openclaw/hawk"
SCRIPT_NAME="$(basename "$0")"

# ───────────────────────────────────────────────
# Colors
# ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ───────────────────────────────────────────────
# Logging helpers
# ───────────────────────────────────────────────
log() { printf "${GREEN}[INFO]${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${RESET} %s\n" "$*"; }
err()  { printf "${RED}[ERROR]${RESET} %s\n" "$*"; }
step() { printf "${CYAN}[STEP]${RESET} %s\n" "$*"; }
bold() { printf "${BOLD}%s${RESET}\n" "$*"; }

# ───────────────────────────────────────────────
# Usage
# ───────────────────────────────────────────────
usage() {
    bold "context-hawk v${VERSION} — One-Command Installer"
    echo ""
    echo "Usage: $SCRIPT_NAME [options]"
    echo ""
    echo "Options:"
    echo "  --force        Overwrite existing installation"
    echo "  --skip-seed    Skip initial memory seeding"
    echo "  --help         Show this help message"
    echo ""
    echo "Supported OS:"
    echo "  Ubuntu / Debian"
    echo "  Fedora / RHEL / CentOS / Rocky / AlmaLinux"
    echo "  Arch Linux"
    echo "  Alpine Linux"
    echo "  openSUSE"
    echo "  macOS"
    echo ""
    echo "Environment variables:"
    echo "  HAWK_REPO      Git repo URL (default: ${HAWK_REPO})"
    echo "  INSTALL_DIR    Install path (default: ${INSTALL_DIR})"
}

# ───────────────────────────────────────────────
# Parse arguments
# ───────────────────────────────────────────────
FORCE=false
SKIP_SEED=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)     FORCE=true; shift ;;
        --skip-seed)  SKIP_SEED=true; shift ;;
        --help|-h)   usage; exit 0 ;;
        *)           err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ───────────────────────────────────────────────
# Detect OS
# ───────────────────────────────────────────────
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
        return
    fi

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "${ID}" in
            ubuntu|debian|linuxmint|pop)
                echo "debian" ;;
            fedora|rhel|centos|rocky|almalinux)
                echo "fedora" ;;
            arch|manjaro|endeavouros)
                echo "arch" ;;
            alpine)
                echo "alpine" ;;
            opensuse|opensuse-leap|opensuse-tumbleweed|suse|sles)
                echo "suse" ;;
            *)
                # Try ID_LIKE
                if [[ -n "${ID_LIKE:-}" ]]; then
                    case "$ID_LIKE" in
                        *debian*|*ubuntu*) echo "debian" ;;
                        *rhel*|*fedora*|*centos*) echo "fedora" ;;
                        *suse*) echo "suse" ;;
                        *) echo "unknown" ;;
                    esac
                else
                    echo "unknown"
                fi
                ;;
        esac
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# ───────────────────────────────────────────────
# Install system dependencies
# ───────────────────────────────────────────────
install_system_deps() {
    step "Installing system dependencies (${OS_TYPE})..."

    case "${OS_TYPE}" in
        debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq \
                python3 python3-pip python3-venv \
                git curl wget \
                build-essential libssl-dev zlib1g-dev \
                > /dev/null 2>&1
            ;;

        fedora)
            dnf install -y -q \
                python3 python3-pip \
                git curl wget \
                gcc gcc-c++ make \
                openssl-devel zlib-devel \
                > /dev/null 2>&1
            ;;

        arch)
            pacman -Sy --noconfirm \
                python python-pip \
                git curl wget \
                base-devel \
                > /dev/null 2>&1
            ;;

        alpine)
            apk add --no-cache \
                python3 py3-pip \
                git curl wget \
                build-base openssl-dev zlib-dev \
                > /dev/null 2>&1
            ;;

        suse)
            zypper install -y -q \
                python3 python3-pip \
                git curl wget \
                gcc gcc-c++ make \
                libopenssl-devel zlib-devel \
                > /dev/null 2>&1
            ;;

        macos)
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                bold "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
                    > /dev/null 2>&1 || true
                eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
            fi
            # brew handles Python/git/curl/wget via dependencies
            if command -v brew &> /dev/null; then
                brew install python@3.12 git curl wget 2>/dev/null || true
            fi
            ;;

        unknown)
            warn "Could not detect OS. Attempting generic install..."
            if command -v apt-get &> /dev/null; then
                apt-get update -qq && apt-get install -y -qq \
                    python3 python3-pip git curl wget build-essential > /dev/null 2>&1 || true
            elif command -v dnf &> /dev/null; then
                dnf install -y -q python3 python3-pip git curl wget gcc make > /dev/null 2>&1 || true
            elif command -v pacman &> /dev/null; then
                pacman -Sy --noconfirm python python-pip git curl wget base-devel > /dev/null 2>&1 || true
            fi
            ;;
    esac

    log "System dependencies installed"
}

# ───────────────────────────────────────────────
# Find Python and ensure pip works
# ───────────────────────────────────────────────
find_python() {
    step "Finding Python..."

    PYTHON_CMD=""

    # Try python3.12, 3.11, 3.10, python3, python in order
    for py in python3.12 python3.11 python3.10 python3 python; do
        if command -v "$py" &> /dev/null; then
            version=$("$py" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")
            major=$(echo "$version" | cut -d. -f1)
            minor=$(echo "$version" | cut -d. -f2)
            if [[ "$major" -eq 3 && "$minor" -ge 10 ]]; then
                PYTHON_CMD="$py"
                break
            fi
        fi
    done

    if [[ -z "$PYTHON_CMD" ]]; then
        err "Python 3.10+ not found. Please install Python 3.10 or higher."
        exit 1
    fi

    PYTHON_VERSION=$("$PYTHON_CMD" -c 'import sys; print(sys.version_info[:3])' 2>/dev/null)
    log "Using ${PYTHON_CMD} ${PYTHON_VERSION}"
    echo "$PYTHON_CMD"
}

# ───────────────────────────────────────────────
# Ensure pip is available
# ───────────────────────────────────────────────
ensure_pip() {
    PYTHON_CMD="$1"
    step "Ensuring pip is available..."

    if ! "$PYTHON_CMD" -m pip --version &> /dev/null; then
        warn "pip not available, installing..."
        case "${OS_TYPE}" in
            debian)
                apt-get install -y -qq python3-pip > /dev/null 2>&1 || true
                ;;
            fedora)
                dnf install -y -q python3-pip > /dev/null 2>&1 || true
                ;;
            arch)
                pacman -Sy --noconfirm python-pip > /dev/null 2>&1 || true
                ;;
            alpine)
                apk add --no-cache py3-pip > /dev/null 2>&1 || true
                ;;
            suse)
                zypper install -y -q python3-pip > /dev/null 2>&1 || true
                ;;
            macos)
                "$PYTHON_CMD" -m ensurepip --upgrade &> /dev/null || true
                ;;
        esac
    fi

    # Upgrade pip
    "$PYTHON_CMD" -m pip install --upgrade pip -q 2>/dev/null || true
    log "pip ready"
}

# ───────────────────────────────────────────────
# Install Python packages
# ───────────────────────────────────────────────
install_python_packages() {
    PYTHON_CMD="$1"
    step "Installing Python packages..."

    PACKAGES=(
        "lancedb>=0.8"
        "rank-bm25"
        "openai>=1.0"
        "tiktoken"
        "httpx"
        "sentence-transformers"
    )

    # Try to install; failures on optional ones are OK
    for pkg in "${PACKAGES[@]}"; do
        if "$PYTHON_CMD" -m pip install "$pkg" -q 2>/dev/null; then
            log "Installed: $pkg"
        else
            warn "Could not install: $pkg (optional, will still work)"
        fi
    done

    # Verify critical packages
    for pkg in lancedb openai tiktoken; do
        if "$PYTHON_CMD" -c "import ${pkg//-/_}" 2>/dev/null; then
            log "Verified: $pkg"
        else
            warn "Could not verify: $pkg"
        fi
    done
}

# ───────────────────────────────────────────────
# Clone or update context-hawk
# ───────────────────────────────────────────────
install_hawk_repo() {
    step "Installing context-hawk to ${INSTALL_DIR}..."

    # Check if already installed
    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        if [[ "$FORCE" == true ]]; then
            warn "Overwriting existing installation (--force)..."
            rm -rf "${INSTALL_DIR}"
        else
            log "context-hawk already installed at ${INSTALL_DIR}"
            log "Use --force to overwrite"
            cd "${INSTALL_DIR}"
            git pull origin main 2>/dev/null || true
            return
        fi
    fi

    # Create parent directory
    mkdir -p "$(dirname "${INSTALL_DIR}")"

    # Clone repo
    if command -v git &> /dev/null; then
        git clone --depth 1 "${HAWK_REPO}" "${INSTALL_DIR}" 2>/dev/null || {
            err "git clone failed. Please check HAWK_REPO or network."
            exit 1
        }
        log "Cloned context-hawk to ${INSTALL_DIR}"
    else
        err "git not found. Please install git first."
        exit 1
    fi
}

# ───────────────────────────────────────────────
# Create ~/.hawk/ directory and config
# ───────────────────────────────────────────────
setup_hawk_dir() {
    step "Setting up ~/.hawk/..."

    mkdir -p "${HAWK_DIR}"
    mkdir -p "${HAWK_DIR}/lancedb"

    log "Created ~/.hawk/ and ~/.hawk/lancedb/"
}

# ───────────────────────────────────────────────
# Create config.json
# ───────────────────────────────────────────────
create_config() {
    step "Creating ~/.hawk/config.json..."

    CONFIG_PATH="${HAWK_DIR}/config.json"

    # Backup existing if --force
    if [[ -f "${CONFIG_PATH}" && "$FORCE" == true ]]; then
        cp "${CONFIG_PATH}" "${CONFIG_PATH}.bak.$(date +%s)"
        warn "Backed up existing config.json"
    fi

    # Check if already exists and not --force
    if [[ -f "${CONFIG_PATH}" && "$FORCE" != true ]]; then
        log "config.json already exists, skipping (use --force to overwrite)"
        return
    fi

    cat > "${CONFIG_PATH}" << 'EOF'
{
  "db_path": "~/.hawk/lancedb",
  "memories_path": "~/.hawk/memories.json",
  "governance_path": "~/.hawk/governance.log",
  "openai_api_key": "",
  "embedding_model": "text-embedding-3-small",
  "embedding_dimensions": 1536,
  "recall_top_k": 5,
  "recall_min_score": 0.6,
  "capture_max_chunks": 3,
  "capture_importance_threshold": 0.5,
  "decay_rate": 0.95,
  "working_ttl_days": 1,
  "short_ttl_days": 7,
  "long_ttl_days": 90,
  "archive_ttl_days": 180
}
EOF

    log "Created ~/.hawk/config.json"
    echo ""
    bold "IMPORTANT: Add your OPENAI_API_KEY to ~/.hawk/config.json"
    bold "   Or set environment variable: export OPENAI_API_KEY=sk-..."
    echo ""
}

# ───────────────────────────────────────────────
# Create symlink ~/.openclaw/hawk → context-hawk/hawk/
# ───────────────────────────────────────────────
create_symlink() {
    step "Creating symlink ~/.openclaw/hawk → ${INSTALL_DIR}/hawk/..."

    mkdir -p "$(dirname "${HAWK_SYMLINK}")"

    # Remove existing symlink/file if --force
    if [[ -L "${HAWK_SYMLINK}" || -d "${HAWK_SYMLINK}" || -f "${HAWK_SYMLINK}" ]]; then
        if [[ "$FORCE" == true ]]; then
            rm -rf "${HAWK_SYMLINK}"
        else
            log "Symlink already exists, skipping (use --force to overwrite)"
            return
        fi
    fi

    ln -s "${INSTALL_DIR}/hawk" "${HAWK_SYMLINK}"
    log "Created symlink: ~/.openclaw/hawk → ${INSTALL_DIR}/hawk/"
}

# ───────────────────────────────────────────────
# Seed initial generic memories
# ───────────────────────────────────────────────
seed_memories() {
    if [[ "$SKIP_SEED" == true ]]; then
        warn "Skipping memory seeding (--skip-seed)"
        return
    fi

    step "Seeding initial generic memories..."

    MEMORIES_PATH="${HOME}/.hawk/memories.json"

    # Check if already has memories
    if [[ -f "${MEMORIES_PATH}" && "$FORCE" != true ]]; then
        size=$(wc -c < "${MEMORIES_PATH}" 2>/dev/null || echo 0)
        if [[ "$size" -gt 100 ]]; then
            log "memories.json already exists, skipping seed (use --force to overwrite)"
            return
        fi
    fi

    # Backup existing
    if [[ -f "${MEMORIES_PATH}" && "$FORCE" == true ]]; then
        cp "${MEMORIES_PATH}" "${MEMORIES_PATH}.bak.$(date +%s)"
    fi

    cat > "${MEMORIES_PATH}" << 'EOF'
{
  "seed:001": {
    "id": "seed:001",
    "text": "context-hawk installed — AI memory system with four-layer memory management",
    "category": "fact",
    "importance": 0.9,
    "access_count": 1,
    "last_accessed": 1735689600,
    "created_at": 1735689600,
    "layer": "long",
    "metadata": {"source": "install_seed"}
  },
  "seed:002": {
    "id": "seed:002",
    "text": "四层记忆系统: working (当前会话) / short (近期) / long (长期) / archive (归档)",
    "category": "fact",
    "importance": 0.8,
    "access_count": 1,
    "last_accessed": 1735689600,
    "created_at": 1735689600,
    "layer": "long",
    "metadata": {"source": "install_seed"}
  },
  "seed:003": {
    "id": "seed:003",
    "text": "记忆衰减: Weibull衰减模型, importance随时间指数衰减",
    "category": "fact",
    "importance": 0.7,
    "access_count": 1,
    "last_accessed": 1735689600,
    "created_at": 1735689600,
    "layer": "short",
    "metadata": {"source": "install_seed"}
  },
  "seed:004": {
    "id": "seed:004",
    "text": "压缩策略: summarize(摘要) / extract(提取) / delete(删除低价值) / promote(升级) / archive(归档)",
    "category": "fact",
    "importance": 0.7,
    "access_count": 1,
    "last_accessed": 1735689600,
    "created_at": 1735689600,
    "layer": "short",
    "metadata": {"source": "install_seed"}
  },
  "seed:005": {
    "id": "seed:005",
    "text": "关键词提取模式( keyword provider ): 无需API密钥, 完全离线工作",
    "category": "fact",
    "importance": 0.8,
    "access_count": 1,
    "last_accessed": 1735689600,
    "created_at": 1735689600,
    "layer": "long",
    "metadata": {"source": "install_seed"}
  }
}
EOF

    log "Seeded 5 initial generic memories"
}

# ───────────────────────────────────────────────
# Verify installation with health_check.py
# ───────────────────────────────────────────────
verify_installation() {
    step "Verifying installation with health_check.py..."

    PYTHON_CMD="$1"
    HEALTH_CHECK="${INSTALL_DIR}/tests/health_check.py"

    if [[ ! -f "${HEALTH_CHECK}" ]]; then
        warn "health_check.py not found at ${HEALTH_CHECK}, skipping verification"
        return
    fi

    # Run health check, capture output
    if output=$("$PYTHON_CMD" "${HEALTH_CHECK}" 2>&1); then
        echo "$output"
        if echo "$output" | grep -q "All tests passed\|✓ PASS\|PASS"; then
            log "Verification PASSED"
        else
            warn "Verification had some failures — check output above"
        fi
    else
        echo "$output"
        warn "Verification exited with errors — check output above"
    fi
}

# ───────────────────────────────────────────────
# Print success message
# ───────────────────────────────────────────────
print_success() {
    bold ""
    bold "╔══════════════════════════════════════════════════════════╗"
    bold "║         context-hawk v${VERSION} — Installation Complete!        ║"
    bold "╚══════════════════════════════════════════════════════════╝"
    echo ""
    log "Installed to:     ${INSTALL_DIR}"
    log "Symlink:         ${HAWK_SYMLINK} → ${INSTALL_DIR}/hawk/"
    log "Config:          ${HOME}/.hawk/config.json"
    log "Memories:        ${HOME}/.hawk/memories.json"
    log "LanceDB:         ${HOME}/.hawk/lancedb/"
    echo ""

    bold "Next steps:"
    echo ""
    echo "  1. Add your API key (optional, keyword mode works offline):"
    echo "     nano ${HOME}/.hawk/config.json"
    echo "     # or set: export OPENAI_API_KEY=sk-..."
    echo ""
    echo "  2. Test the installation:"
    echo "     python3 ${INSTALL_DIR}/tests/health_check.py"
    echo ""
    echo "  3. Import existing memories from markdown files:"
    echo "     python3 -m hawk.markdown_importer --memory-dir ~/.openclaw/memory"
    echo ""
    echo "  4. Start using in Python:"
    echo "     from hawk.memory import MemoryManager"
    echo "     from hawk.wrapper import HawkContext"
    echo ""
    echo "  5. For CLI usage:"
    echo "     python3 ${INSTALL_DIR}/scripts/hawk --help"
    echo ""
    echo "  Available providers (no API key needed for keyword):"
    echo "    keyword  — offline, rule-based (zero config)"
    echo "    groq     — free Llama-3 (set GROQ_API_KEY)"
    echo "    ollama   — local LLM (set OLLAMA_BASE_URL)"
    echo "    openai   — GPT models (set OPENAI_API_KEY)"
    echo ""
}

# ───────────────────────────────────────────────
# MAIN
# ───────────────────────────────────────────────
main() {
    bold "context-hawk v${VERSION} installer"
    bold "OS: ${OS_TYPE} | Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    if [[ "$EUID" -eq 0 ]]; then
        warn "Running as root. This may cause issues with pip user installs."
        warn "Consider running as a non-root user."
    fi

    install_system_deps
    PYTHON_CMD=$(find_python)
    ensure_pip "$PYTHON_CMD"
    install_python_packages "$PYTHON_CMD"
    install_hawk_repo
    setup_hawk_dir
    create_config
    create_symlink
    seed_memories
    verify_installation "$PYTHON_CMD"
    print_success

    log "Installation finished successfully!"
}

main "$@"
