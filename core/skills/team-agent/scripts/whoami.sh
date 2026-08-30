#!/usr/bin/env bash
# whoami.sh — 현재 셸이 어느 역할 터미널에서 실행 중인지 출력한다
# 사용법: bash .ai/core/skills/team-agent/scripts/whoami.sh [프로젝트_루트]
#
# tmux: 현재 pane ID(TMUX_PANE, 비어 있으면 활성 pane) 를 role-map 과 대조
# orca: ORCA_TERMINAL_HANDLE 을 role-map 과 대조
# 판별 불가 시 exit 1 — 이때는 터미널 타이틀(역할명)을 눈으로 확인한다.

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=backend/common.sh
source "$SCRIPT_DIR/backend/common.sh"

if ! team_init_backend "$PROJECT_ROOT" 2>/dev/null; then
  echo "[whoami] 터미널 백엔드 없음" >&2
  exit 1
fi

if ROLE="$(be_self_role "$PROJECT_ROOT")"; then
  echo "$ROLE"
else
  echo "[whoami] 역할을 판별할 수 없습니다 (백엔드: $TEAM_BACKEND). setup.sh 로 생성된 역할 터미널 안에서 실행하세요." >&2
  exit 1
fi
