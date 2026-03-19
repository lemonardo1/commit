#!/usr/bin/env bash
# build.sh - Builds a self-contained install.sh that embeds the commit script
# Run: bash build.sh → produces dist/install.sh

set -euo pipefail

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

COMMIT_SCRIPT="commit"
OUTPUT="$DIST_DIR/install.sh"

if [[ ! -f "$COMMIT_SCRIPT" ]]; then
  echo "Error: '$COMMIT_SCRIPT' script not found. Run from repo root." >&2
  exit 1
fi

# Read the commit script and base64-encode it for embedding
ENCODED=$(base64 < "$COMMIT_SCRIPT")

cat > "$OUTPUT" << 'INSTALLER_HEADER'
#!/usr/bin/env bash
# commit - AI Commit Message Generator installer (self-contained)
# Usage: curl -fsSL https://your-host/install.sh | bash

set -euo pipefail

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="commit"

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

echo ""
echo -e "${BOLD}commit${NC} — AI Commit Message Generator"
echo -e "${DIM}Version ${VERSION} installer${NC}"
echo -e "${DIM}──────────────────────────────────────────${NC}"
echo ""

OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  *) die "지원하지 않는 운영체제: $OS" ;;
esac

info "의존성 확인 중..."
command -v curl &>/dev/null || die "curl이 필요합니다."
command -v git  &>/dev/null || die "git이 필요합니다."

if command -v jq &>/dev/null; then
  success "jq 확인됨"
elif command -v python3 &>/dev/null; then
  success "python3 확인됨"
else
  warn "jq 또는 python3 중 하나를 설치하는 것을 권장합니다."
fi

# Determine install location
USE_SUDO=false
if [[ ! -w "$INSTALL_DIR" ]]; then
  if sudo -n true 2>/dev/null; then
    USE_SUDO=true
  else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [[ -f "$rc" ]]; then
          echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
          warn "PATH를 $rc 에 추가했습니다. 터미널을 재시작하세요."
          break
        fi
      done
    fi
  fi
fi

info "설치 중... ($INSTALL_DIR/$SCRIPT_NAME)"

INSTALLER_HEADER

# Append the embedded script decoder
echo "ENCODED_SCRIPT=\"$ENCODED\"" >> "$OUTPUT"

cat >> "$OUTPUT" << 'INSTALLER_FOOTER'

TMP_FILE=$(mktemp /tmp/commit.XXXXXX)
trap 'rm -f "$TMP_FILE"' EXIT

echo "$ENCODED_SCRIPT" | base64 --decode > "$TMP_FILE"
chmod +x "$TMP_FILE"

DEST="${INSTALL_DIR}/${SCRIPT_NAME}"

if $USE_SUDO; then
  sudo mv "$TMP_FILE" "$DEST"
  sudo chmod +x "$DEST"
else
  mv "$TMP_FILE" "$DEST"
fi

export PATH="${INSTALL_DIR}:$PATH"

echo ""
success "설치 완료: $DEST"
echo ""
echo -e "${DIM}──────────────────────────────────────────${NC}"
echo ""
echo -e "  ${BOLD}commit setup${NC}   # API 키 설정 (최초 1회)"
echo -e "  ${BOLD}commit${NC}         # AI 커밋 메시지 생성 및 push"
echo ""
echo -e "${DIM}지원: OpenAI (GPT-4o), Anthropic (Claude)${NC}"
echo ""
INSTALLER_FOOTER

chmod +x "$OUTPUT"
bash -n "$OUTPUT" && echo "✓ Syntax OK"
echo "✓ Built: $OUTPUT"
echo ""
echo "배포 방법:"
echo "  1) dist/install.sh 를 웹서버에 업로드"
echo "  2) 사용자에게 다음 명령어 전달:"
echo "     curl -fsSL https://your-host/install.sh | bash"
