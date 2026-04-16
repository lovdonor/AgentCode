#!/usr/bin/env bash
# status.sh — 전체 팀 진행 상황 및 수신함 대기 메시지 수를 출력한다
# 사용법: bash .ai/core/skills/team-agent/scripts/status.sh [프로젝트_루트]

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SESSION="team-agent"
TEAM_DIR="$PROJECT_ROOT/.team"
ROLES=("leader" "developer" "reviewer" "tester" "docs")

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
for ROLE in "${ROLES[@]}"; do
  INBOX="$TEAM_DIR/inbox/$ROLE.md"
  if [ -f "$INBOX" ]; then
    COUNT=$(grep -c "^from:" "$INBOX" 2>/dev/null || echo 0)
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

# ── tmux 세션/pane 상태 ──────────────────────────────────────────────────────
echo ""
echo "[tmux 세션 상태]"
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "  세션 '$SESSION' 활성"
  if tmux list-windows -t "$SESSION" -F "#{window_name}" 2>/dev/null | grep -qx "team"; then
    echo "  창: team (단일 창 multi-pane)"
    tmux list-panes -t "$SESSION:team" \
      -F "    pane #{pane_index}: #{pane_title} (#{pane_width}x#{pane_height})" 2>/dev/null
  else
    echo "  창 목록 (구버전):"
    tmux list-windows -t "$SESSION" -F "    #I: #{window_name}" 2>/dev/null
  fi
else
  echo "  세션 '$SESSION' 비활성 (setup.sh를 실행하세요)"
fi

echo ""
echo "========================================"
echo " 상세 수신함: check-inbox.sh <역할>"
echo " 메시지 전송: send-msg.sh <수신자> <발신자> \"<메시지>\""
echo "========================================"
