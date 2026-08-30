#!/usr/bin/env bash
# check-inbox.sh — 지정 역할의 수신함을 출력하고 처리 완료 시 비운다
# 사용법: bash .ai/core/skills/team-agent/scripts/check-inbox.sh <역할> [--clear] [프로젝트_루트]
#
# 예시:
#   bash .ai/core/skills/team-agent/scripts/check-inbox.sh developer
#   bash .ai/core/skills/team-agent/scripts/check-inbox.sh developer --clear

set -euo pipefail

ROLE="${1:-}"
CLEAR=false
PROJECT_ROOT="$(pwd)"

# 인자 파싱
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear) CLEAR=true ;;
    *) PROJECT_ROOT="$1" ;;
  esac
  shift
done

TEAM_DIR="$PROJECT_ROOT/.team"
VALID_ROLES=("leader" "developer" "reviewer" "tester")

# ── 인자 검증 ────────────────────────────────────────────────────────────────
if [ -z "$ROLE" ]; then
  echo "사용법: check-inbox.sh <역할> [--clear] [프로젝트_루트]"
  echo "역할 목록: ${VALID_ROLES[*]}"
  exit 1
fi

is_valid_role() {
  local r="$1"
  for v in "${VALID_ROLES[@]}"; do
    [ "$v" = "$r" ] && return 0
  done
  return 1
}

if ! is_valid_role "$ROLE"; then
  echo "[오류] 알 수 없는 역할: '$ROLE'. 유효한 역할: ${VALID_ROLES[*]}"
  exit 1
fi

INBOX="$TEAM_DIR/inbox/$ROLE.md"

if [ ! -f "$INBOX" ]; then
  echo "[오류] 수신함 파일 없음: $INBOX (setup.sh를 먼저 실행하세요)"
  exit 1
fi

# ── 수신함 내용 출력 ─────────────────────────────────────────────────────────
echo "========================================"
echo " [$ROLE] 수신함"
echo "========================================"

# 헤더(# ... 수신함) 이후 실제 메시지 유무 확인
# grep -c 는 0건이면 "0"을 출력하고 exit 1 → "|| echo 0" 을 붙이면 "0\n0" 이 되므로 || true 로 받는다
MSG_COUNT=$(grep -c "^from:" "$INBOX" 2>/dev/null || true)
MSG_COUNT=${MSG_COUNT:-0}

if [ "$MSG_COUNT" -eq 0 ]; then
  echo " (새 메시지 없음)"
else
  echo " 메시지 수: $MSG_COUNT"
  echo "----------------------------------------"
  cat "$INBOX"
fi

echo "========================================"

# ── --clear 옵션: 처리 후 수신함 초기화 ─────────────────────────────────────
if [ "$CLEAR" = true ]; then
  cat > "$INBOX" << EOF
# $ROLE 수신함

EOF
  echo "[check-inbox] 수신함 초기화 완료 ($ROLE)"

  # progress.md 상태 업데이트
  PROGRESS="$TEAM_DIR/status/progress.md"
  if [ -f "$PROGRESS" ]; then
    sed -i "s/^| $ROLE |.*$/| $ROLE | in-progress | 메시지 처리 중 |/" "$PROGRESS" 2>/dev/null || true
  fi
fi
