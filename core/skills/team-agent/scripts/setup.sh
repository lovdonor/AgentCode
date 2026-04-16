#!/usr/bin/env bash
# setup.sh — team-agent tmux 세션 및 메시지 디렉토리 초기화
# 사용법: bash .ai/core/skills/team-agent/scripts/setup.sh [프로젝트_루트]

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
SESSION="team-agent-${PROJECT_NAME}"
TEAM_DIR="$PROJECT_ROOT/.team"

ROLES=("leader" "developer" "reviewer" "tester" "docs")
TEAM_WIN="team"

# ── 1. tmux 세션 생성 ────────────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[setup] 세션 '$SESSION' 이미 존재합니다."

  # 구버전 멀티-윈도우 구조(leader/developer/… 각자 별도 창) 감지 → 제거
  OLD_WINS=$(tmux list-windows -t "$SESSION" -F "#{window_name}" \
    | grep -E "^(leader|developer|reviewer|tester|docs)$" || true)
  if [ -n "$OLD_WINS" ]; then
    echo "[setup] 구버전 멀티-윈도우 구조 감지 → 단일 창 pane 레이아웃으로 전환합니다."
    for WIN in $OLD_WINS; do
      tmux kill-window -t "$SESSION:$WIN" 2>/dev/null || true
    done
  fi
else
  echo "[setup] tmux 세션 '$SESSION' 생성 중..."
  tmux new-session -d -s "$SESSION" -n "$TEAM_WIN" -x 220 -y 50
fi

# ── 2. 단일 창 'team' 에 5개 pane 구성 ───────────────────────────────────────
echo "[setup] 단일 창 '$TEAM_WIN' 에 ${#ROLES[@]}개 pane 구성 중..."

# 'team' 창이 없으면 생성 (세션 첫 창 이름 변경 또는 신규 생성)
if ! tmux list-windows -t "$SESSION" -F "#{window_name}" | grep -qx "$TEAM_WIN"; then
  FIRST_WIN=$(tmux list-windows -t "$SESSION" -F "#{window_name}" | head -1)
  tmux rename-window -t "$SESSION:${FIRST_WIN}" "$TEAM_WIN" 2>/dev/null \
    || tmux new-window -t "$SESSION" -n "$TEAM_WIN"
fi

# 필요한 수만큼 pane 추가 (매 split 후 tiled 적용으로 공간 부족 방지)
CURRENT_PANES=$(tmux list-panes -t "$SESSION:$TEAM_WIN" | wc -l)
NEEDED=$(( ${#ROLES[@]} - CURRENT_PANES ))
i=0
while [ "$i" -lt "$NEEDED" ]; do
  tmux split-window -t "$SESSION:$TEAM_WIN" -d
  tmux select-layout -t "$SESSION:$TEAM_WIN" tiled
  i=$(( i + 1 ))
done

# 최종 tiled 레이아웃 정렬
tmux select-layout -t "$SESSION:$TEAM_WIN" tiled

# pane 타이틀 설정 (역할명 표시) 및 pane ID 매핑 저장
PANE_MAP_FILE="$TEAM_DIR/status/pane-map.sh"
echo "# pane-map.sh — role → pane ID 매핑 (setup.sh 자동 생성)" > "$PANE_MAP_FILE"

for idx in "${!ROLES[@]}"; do
  ROLE="${ROLES[$idx]}"
  PANE_NUM=$(( idx + 1 ))
  tmux select-pane -t "$SESSION:$TEAM_WIN.$PANE_NUM" -T "$ROLE" 2>/dev/null || true
  PANE_ID=$(tmux list-panes -t "$SESSION:$TEAM_WIN" -F "#{pane_index} #{pane_id}" \
    | awk -v n="$PANE_NUM" '$1==n {print $2}' | head -1)
  echo "PANE_${ROLE}=\"${PANE_ID}\"" >> "$PANE_MAP_FILE"
done

echo "[setup] pane 레이아웃 완료: ${ROLES[*]}"
echo "[setup] pane ID 매핑 저장: $PANE_MAP_FILE"

# ── 3. .team/ 메시지 디렉토리 초기화 ────────────────────────────────────────
echo "[setup] .team/ 디렉토리 초기화 중..."

mkdir -p "$TEAM_DIR/inbox"
mkdir -p "$TEAM_DIR/status"
mkdir -p "$TEAM_DIR/shared"

# 수신함 파일 초기화 (없는 경우만)
for ROLE in leader developer reviewer tester docs; do
  INBOX="$TEAM_DIR/inbox/$ROLE.md"
  if [ ! -f "$INBOX" ]; then
    cat > "$INBOX" << EOF
# $ROLE 수신함

EOF
    echo "[setup] 수신함 생성: $INBOX"
  fi
done

# 상태 파일 초기화
if [ ! -f "$TEAM_DIR/status/task.md" ]; then
  cat > "$TEAM_DIR/status/task.md" << 'EOF'
# 현재 태스크 상태

status: idle
task: (없음)
phase: -
started: -
updated: -
EOF
fi

if [ ! -f "$TEAM_DIR/status/progress.md" ]; then
  cat > "$TEAM_DIR/status/progress.md" << 'EOF'
# 역할별 진행 상황

| 역할 | 상태 | 메모 |
|------|------|------|
| leader | idle | |
| developer | idle | |
| reviewer | idle | |
| tester | idle | |
| docs | idle | |
EOF
fi

# 공유 파일 초기화
for SHARED in requirements.md design.md review-result.md; do
  if [ ! -f "$TEAM_DIR/shared/$SHARED" ]; then
    touch "$TEAM_DIR/shared/$SHARED"
    echo "[setup] 공유 파일 생성: .team/shared/$SHARED"
  fi
done

# ── 4. 각 pane에서 프로젝트 루트로 이동 후 에이전트 실행 ────────────────────
echo "[setup] 각 pane을 프로젝트 루트로 이동 후 에이전트 실행 중..."

# 역할별 에이전트 CLI 매핑
declare -A ROLE_AGENT=(
  [leader]="claude"
  [developer]="claude"
  [reviewer]="codex"
  [tester]="gemini"
  [docs]="gemini"
)

for idx in "${!ROLES[@]}"; do
  ROLE="${ROLES[$idx]}"
  PANE_NUM=$(( idx + 1 ))
  AGENT="${ROLE_AGENT[$ROLE]}"
  tmux send-keys -t "$SESSION:$TEAM_WIN.$PANE_NUM" "cd \"$PROJECT_ROOT\" && $AGENT" Enter
  echo "[setup] pane $PANE_NUM ($ROLE): $AGENT 실행"
done

# ── 5. 완료 메시지 ───────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo " team-agent 환경 준비 완료"
echo "========================================"
echo " 세션  : $SESSION"
echo " 창    : $TEAM_WIN (단일 창, ${#ROLES[@]} pane)"
echo " 역할  : ${ROLES[*]}"
echo " 메시지: $TEAM_DIR"
echo ""
echo " 세션 접속: tmux attach -t $SESSION"
echo " pane 이동: Ctrl+b → 방향키 또는 Ctrl+b q (pane 번호)"
echo "========================================"
