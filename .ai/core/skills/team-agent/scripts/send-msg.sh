#!/usr/bin/env bash
# send-msg.sh — 특정 에이전트 수신함에 메시지를 기록하고 tmux 창에 알림을 보낸다
# 사용법: bash .ai/core/skills/team-agent/scripts/send-msg.sh <수신자> <발신자> "<메시지>" [프로젝트_루트]
#
# 예시:
#   bash .ai/core/skills/team-agent/scripts/send-msg.sh developer leader "auth 모듈 구현 시작"
#   bash .ai/core/skills/team-agent/scripts/send-msg.sh reviewer developer "구현 완료. 리뷰 요청"

set -euo pipefail

TO="${1:-}"
FROM="${2:-}"
MESSAGE="${3:-}"
PROJECT_ROOT="${4:-$(pwd)}"

SESSION="team-agent"
TEAM_DIR="$PROJECT_ROOT/.team"
VALID_ROLES=("leader" "developer" "reviewer" "tester" "docs")

# ── 인자 검증 ────────────────────────────────────────────────────────────────
if [ -z "$TO" ] || [ -z "$FROM" ] || [ -z "$MESSAGE" ]; then
  echo "사용법: send-msg.sh <수신자> <발신자> \"<메시지>\" [프로젝트_루트]"
  echo "역할 목록: ${VALID_ROLES[*]}"
  exit 1
fi

is_valid_role() {
  local role="$1"
  for r in "${VALID_ROLES[@]}"; do
    [ "$r" = "$role" ] && return 0
  done
  return 1
}

if ! is_valid_role "$TO"; then
  echo "[오류] 알 수 없는 수신자: '$TO'. 유효한 역할: ${VALID_ROLES[*]}"
  exit 1
fi

if ! is_valid_role "$FROM"; then
  echo "[오류] 알 수 없는 발신자: '$FROM'. 유효한 역할: ${VALID_ROLES[*]}"
  exit 1
fi

# ── 수신함 파일에 메시지 추가 ────────────────────────────────────────────────
INBOX="$TEAM_DIR/inbox/$TO.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

if [ ! -f "$INBOX" ]; then
  echo "[오류] 수신함 파일 없음: $INBOX (setup.sh를 먼저 실행하세요)"
  exit 1
fi

cat >> "$INBOX" << EOF

---
from: $FROM
to: $TO
time: $TIMESTAMP
status: pending
---

$MESSAGE

EOF

echo "[send-msg] $FROM → $TO: 메시지 기록 완료 ($TIMESTAMP)"

# ── tmux 창에 알림 전송 ──────────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  # 해당 창에 알림 메시지를 출력 (에이전트가 직접 확인하도록 유도)
  ALERT="[inbox] $FROM 으로부터 새 메시지가 도착했습니다. check-inbox.sh $TO 를 실행하세요."
  tmux send-keys -t "$SESSION:$TO" "" ""   # 현재 입력 없이 빈 줄
  tmux display-message -t "$SESSION:$TO" "$ALERT"
  echo "[send-msg] tmux 창 '$TO'에 알림 전송 완료"
else
  echo "[send-msg] 경고: tmux 세션 '$SESSION' 없음. 파일에만 기록되었습니다."
fi

# ── status/progress.md 업데이트 ──────────────────────────────────────────────
PROGRESS="$TEAM_DIR/status/progress.md"
if [ -f "$PROGRESS" ]; then
  # $TO 역할의 상태를 pending으로 업데이트 (sed로 해당 행 수정)
  sed -i "s/^| $TO |.*$/| $TO | pending | $FROM 으로부터 메시지 대기 중 |/" "$PROGRESS" 2>/dev/null || true
fi

echo "[send-msg] 완료"
