#!/usr/bin/env bash
# status.sh — 전체 팀 진행 상황, 수신함 대기 메시지 수, 역할 터미널 상태를 출력한다
# 사용법: bash .ai/core/skills/team-agent/scripts/status.sh [프로젝트_루트]

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=backend/common.sh
source "$SCRIPT_DIR/backend/common.sh"

TEAM_DIR="$(team_dir "$PROJECT_ROOT")"

echo "========================================"
echo " team-agent 팀 상태 대시보드"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# ── 현재 태스크 ──────────────────────────────────────────────────────────────
echo ""
echo "[현재 태스크]"
if [ -f "$TEAM_DIR/status/task.md" ]; then
  cat "$TEAM_DIR/status/task.md"
else
  echo " (task.md 없음)"
fi

# ── 역할별 진행 상황 ─────────────────────────────────────────────────────────
echo ""
echo "[역할별 진행 상황]"
if [ -f "$TEAM_DIR/status/progress.md" ]; then
  cat "$TEAM_DIR/status/progress.md"
else
  echo " (progress.md 없음)"
fi

# ── 수신함 대기 메시지 수 ────────────────────────────────────────────────────
echo ""
echo "[수신함 현황]"
echo "----------------------------------------"
printf "  %-12s %s\n" "역할" "대기 메시지"
echo "----------------------------------------"
for ROLE in "${TEAM_ROLES[@]}"; do
  INBOX="$TEAM_DIR/inbox/$ROLE.md"
  if [ -f "$INBOX" ]; then
    # grep -c 는 0건이면 "0"을 출력하고 exit 1 → "|| echo 0" 을 붙이면 "0\n0" 이 되므로 || true 로 받는다
    COUNT=$(grep -c "^from:" "$INBOX" 2>/dev/null || true)
    COUNT=${COUNT:-0}
    if [ "$COUNT" -gt 0 ]; then
      printf "  %-12s %d 건 ★\n" "$ROLE" "$COUNT"
    else
      printf "  %-12s %d 건\n" "$ROLE" "$COUNT"
    fi
  else
    printf "  %-12s (파일 없음)\n" "$ROLE"
  fi
done
echo "----------------------------------------"

# ── 역할 터미널 상태 (백엔드 위임) ───────────────────────────────────────────
echo ""
if team_init_backend "$PROJECT_ROOT" 2>/dev/null; then
  echo "[역할 터미널 상태 — 백엔드: $TEAM_BACKEND]"
  be_status "$PROJECT_ROOT"
else
  echo "[역할 터미널 상태]"
  echo "  터미널 백엔드 없음 (tmux 미설치, Orca 비도달)"
fi

echo ""
echo "========================================"
echo " 상세 수신함: check-inbox.sh <역할>"
echo " 메시지 전송: send-msg.sh <수신자> <발신자> \"<메시지>\""
echo " 내 역할    : whoami.sh"
echo "========================================"
