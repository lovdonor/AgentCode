#!/usr/bin/env bash
# send-msg.sh — 특정 역할 수신함에 메시지를 기록하고 해당 역할 터미널(tmux pane / Orca 터미널)에 알림을 보낸다
# 사용법: bash .ai/core/skills/team-agent/scripts/send-msg.sh <수신자> <발신자> "<메시지>" [프로젝트_루트]
#
# 예시:
#   bash .ai/core/skills/team-agent/scripts/send-msg.sh developer leader "auth 모듈 구현 시작"
#   bash .ai/core/skills/team-agent/scripts/send-msg.sh leader developer "구현 완료. 검증 요청"

set -euo pipefail

TO="${1:-}"
FROM="${2:-}"
MESSAGE="${3:-}"
PROJECT_ROOT="${4:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=backend/common.sh
source "$SCRIPT_DIR/backend/common.sh"

TEAM_DIR="$(team_dir "$PROJECT_ROOT")"

# ── 인자 검증 ────────────────────────────────────────────────────────────────
if [ -z "$TO" ] || [ -z "$FROM" ] || [ -z "$MESSAGE" ]; then
  echo "사용법: send-msg.sh <수신자> <발신자> \"<메시지>\" [프로젝트_루트]"
  echo "역할 목록: ${TEAM_ROLES[*]}"
  exit 1
fi
if ! team_is_valid_role "$TO"; then
  echo "[오류] 알 수 없는 수신자: '$TO'. 유효한 역할: ${TEAM_ROLES[*]}"
  exit 1
fi
if ! team_is_valid_role "$FROM"; then
  echo "[오류] 알 수 없는 발신자: '$FROM'. 유효한 역할: ${TEAM_ROLES[*]}"
  exit 1
fi

# ── 수신함 파일에 메시지 추가 (백엔드 무관) ─────────────────────────────────
INBOX="$TEAM_DIR/inbox/$TO.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

if [ ! -f "$INBOX" ]; then
  echo "[오류] 수신함 파일 없음: $INBOX (setup.sh를 먼저 실행하세요)"
  exit 1
fi

cat >> "$INBOX" << EOT

---
from: $FROM
to: $TO
time: $TIMESTAMP
status: pending
---

$MESSAGE

EOT

echo "[send-msg] $FROM → $TO: 메시지 기록 완료 ($TIMESTAMP)"

# ── 역할 터미널에 알림 전송 (백엔드 위임) ───────────────────────────────────
NOTIFY="[inbox] $FROM 으로부터 새 메시지가 도착했습니다. .team/inbox/$TO.md 를 확인하고 지시에 따라 행동하세요."
NOTIFY_OK=true
if team_init_backend "$PROJECT_ROOT" 2>/dev/null && be_available; then
  if ! be_notify "$PROJECT_ROOT" "$TO" "$NOTIFY"; then
    NOTIFY_OK=false
    echo "[send-msg] 오류: '$TO' 터미널 알림 실패 ($TEAM_BACKEND). 메시지는 파일에 기록되었으나 수신자는 알지 못합니다."
  fi
else
  NOTIFY_OK=false
  echo "[send-msg] 오류: 터미널 백엔드 없음. 메시지는 파일에 기록되었으나 수신자는 알지 못합니다."
fi

# ── status/progress.md 업데이트 ──────────────────────────────────────────────
PROGRESS="$TEAM_DIR/status/progress.md"
if [ -f "$PROGRESS" ]; then
  sed -i "s/^| $TO |.*$/| $TO | pending | $FROM 으로부터 메시지 대기 중 |/" "$PROGRESS" 2>/dev/null || true
fi

if [ "$NOTIFY_OK" = true ]; then
  echo "[send-msg] 완료"
else
  echo "[send-msg] 미완료: 알림 전송 실패 — setup.sh 로 역할 터미널을 복구한 뒤 send-msg.sh 를 다시 실행하세요 (완료 알람 필수 규칙)."
  exit 2
fi
