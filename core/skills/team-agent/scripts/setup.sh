#!/usr/bin/env bash
# setup.sh — team-agent 역할 터미널(tmux pane 또는 Orca 터미널) 및 메시지 디렉토리 초기화
# 사용법: bash .ai/core/skills/team-agent/scripts/setup.sh [프로젝트_루트]
#
# 백엔드 선택: TEAM_AGENT_BACKEND=tmux|orca > .team/status/backend > 자동 감지(Orca 안이면 orca, 아니면 tmux)
# 검증용     : TEAM_AGENT_NO_LAUNCH=1  (터미널만 열고 에이전트 CLI 는 기동하지 않음)

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=backend/common.sh
source "$SCRIPT_DIR/backend/common.sh"

TEAM_DIR="$(team_dir "$PROJECT_ROOT")"

# ── 1. 백엔드 결정 ───────────────────────────────────────────────────────────
team_init_backend "$PROJECT_ROOT" || exit 1
if ! be_available; then
  echo "[setup] 백엔드 '$TEAM_BACKEND' 를 사용할 수 없습니다 (tmux 미설치 또는 Orca 런타임 비도달)."
  echo "[setup] TEAM_AGENT_BACKEND=tmux|orca 로 다른 백엔드를 지정하거나 환경을 확인하세요."
  exit 1
fi
echo "[setup] 터미널 백엔드: $TEAM_BACKEND"

# ── 2. .team/ 메시지 디렉토리 초기화 (백엔드 무관) ──────────────────────────
echo "[setup] .team/ 디렉토리 초기화 중..."
mkdir -p "$TEAM_DIR/inbox" "$TEAM_DIR/status" "$TEAM_DIR/shared"

for ROLE in "${TEAM_ROLES[@]}"; do
  INBOX="$TEAM_DIR/inbox/$ROLE.md"
  if [ ! -f "$INBOX" ]; then
    cat > "$INBOX" << EOT
# $ROLE 수신함

EOT
    echo "[setup] 수신함 생성: $INBOX"
  fi
done

if [ ! -f "$TEAM_DIR/status/task.md" ]; then
  cat > "$TEAM_DIR/status/task.md" << 'EOT'
# 현재 태스크 상태

status: idle
task: (없음)
phase: -
started: -
updated: -
EOT
fi

if [ ! -f "$TEAM_DIR/status/progress.md" ]; then
  cat > "$TEAM_DIR/status/progress.md" << 'EOT'
# 역할별 진행 상황

| 역할 | 상태 | 메모 |
|------|------|------|
| leader | idle | |
| developer | idle | |
| reviewer | idle | |
| tester | idle | |
EOT
fi

for SHARED in requirements.md design.md review-result.md; do
  if [ ! -f "$TEAM_DIR/shared/$SHARED" ]; then
    touch "$TEAM_DIR/shared/$SHARED"
    echo "[setup] 공유 파일 생성: .team/shared/$SHARED"
  fi
done

# ── 3. 역할 터미널 열기 + 에이전트 기동 (백엔드 위임) ───────────────────────
echo "[setup] 역할 터미널 구성 중 (${TEAM_ROLES[*]})..."
be_open_roles "$PROJECT_ROOT" "${TEAM_ROLES[@]}"

# ── 4. 완료 메시지 ───────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo " team-agent 환경 준비 완료"
echo "========================================"
echo " 백엔드: $TEAM_BACKEND"
echo " 프로젝트: $PROJECT_ROOT"
echo " 역할  : ${TEAM_ROLES[*]}"
echo " 메시지: $TEAM_DIR"
echo ""
be_attach_hint "$PROJECT_ROOT"
echo " 역할 확인: bash .ai/core/skills/team-agent/scripts/whoami.sh"
echo "========================================"
