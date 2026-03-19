#!/usr/bin/env bash
# install.sh - commit CLI installer
# Usage: curl -fsSL https://example.com/install.sh | bash

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
REPO_URL="https://raw.githubusercontent.com/yourusername/commit/main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="commit"
VERSION="1.0.0"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC}  $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}commit${NC} — AI Commit Message Generator"
echo -e "${DIM}Version ${VERSION} installer${NC}"
echo -e "${DIM}──────────────────────────────────────────${NC}"
echo ""

# ── OS check ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  *) die "지원하지 않는 운영체제: $OS (Linux, macOS만 지원)" ;;
esac

# ── Dependency checks ─────────────────────────────────────────────────────────
info "의존성 확인 중..."

if ! command -v curl &>/dev/null; then
  die "curl이 필요합니다. 설치 후 다시 시도하세요."
fi

if ! command -v git &>/dev/null; then
  die "git이 필요합니다. https://git-scm.com 에서 설치하세요."
fi

if command -v jq &>/dev/null; then
  success "jq 확인됨"
elif command -v python3 &>/dev/null; then
  success "python3 확인됨 (jq 대체 사용)"
else
  warn "jq 또는 python3이 없으면 JSON 처리가 제한됩니다."
  warn "권장: brew install jq (macOS) 또는 apt install jq (Linux)"
fi

# ── Install directory ─────────────────────────────────────────────────────────
# Try /usr/local/bin first, fallback to ~/.local/bin
if [[ -w "$INSTALL_DIR" ]] || sudo -n true 2>/dev/null; then
  USE_SUDO=true
else
  INSTALL_DIR="$HOME/.local/bin"
  USE_SUDO=false
  mkdir -p "$INSTALL_DIR"

  # Check if ~/.local/bin is in PATH
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "~/.local/bin 이 PATH에 없습니다."

    # Detect shell config file
    if [[ -f "$HOME/.zshrc" ]]; then
      SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
      SHELL_RC="$HOME/.bashrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
      SHELL_RC="$HOME/.bash_profile"
    else
      SHELL_RC="$HOME/.profile"
    fi

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    info "PATH를 $SHELL_RC 에 추가했습니다."
    warn "설치 후 'source $SHELL_RC' 또는 터미널을 재시작하세요."
  fi
fi

info "설치 위치: $INSTALL_DIR"

# ── Download script ───────────────────────────────────────────────────────────
info "commit 스크립트 다운로드 중..."

TMP_FILE=$(mktemp /tmp/commit.XXXXXX)
trap 'rm -f "$TMP_FILE"' EXIT

# Try to download from repo, fallback to embedding
if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}" -o "$TMP_FILE" 2>/dev/null; then
  warn "원격 다운로드 실패. 내장 스크립트를 사용합니다."
  # The embedded script will be injected here during release build
  die "다운로드 실패. https://github.com/yourusername/commit 에서 수동 설치하세요."
fi

chmod +x "$TMP_FILE"

# ── Install ───────────────────────────────────────────────────────────────────
DEST="${INSTALL_DIR}/${SCRIPT_NAME}"

if $USE_SUDO && [[ ! -w "$INSTALL_DIR" ]]; then
  info "관리자 권한으로 설치합니다..."
  sudo mv "$TMP_FILE" "$DEST"
  sudo chmod +x "$DEST"
else
  mv "$TMP_FILE" "$DEST"
  chmod +x "$DEST"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
if ! command -v commit &>/dev/null; then
  # Try sourcing the path update
  export PATH="${INSTALL_DIR}:$PATH"
fi

if command -v commit &>/dev/null; then
  success "설치 완료: $(command -v commit)"
else
  warn "설치는 완료됐지만 PATH 갱신이 필요합니다."
  warn "터미널을 재시작하거나 'export PATH=\"${INSTALL_DIR}:\$PATH\"' 를 실행하세요."
fi

# ── First-time setup ──────────────────────────────────────────────────────────
echo ""
echo -e "${DIM}──────────────────────────────────────────${NC}"
echo ""
echo -e "이제 ${BOLD}commit setup${NC} 을 실행하여 API 키를 설정하세요."
echo ""
echo "  사용법:"
echo -e "    ${BOLD}commit setup${NC}   # API 키 초기 설정"
echo -e "    ${BOLD}commit${NC}         # AI 커밋 메시지 생성 및 push"
echo ""
echo -e "${DIM}지원: OpenAI (GPT-4o), Anthropic (Claude)${NC}"
echo ""
