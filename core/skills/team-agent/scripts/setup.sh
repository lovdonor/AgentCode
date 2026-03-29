#!/usr/bin/env bash
# setup.sh — team-agent tmux 세션 및 메시지 디렉토리 초기화
# 사용법: bash .ai/core/skills/team-agent/scripts/setup.sh [프로젝트_루트]

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SESSION="team-agent"
TEAM_DIR="$PROJECT_ROOT/.team"

# ── 1. tmux 세션 생성 ────────────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[setup] 세션 '$SESSION' 이미 존재합니다. 기존 세션을 사용합니다."
else
  echo "[setup] tmux 세션 '$SESSION' 생성 중..."
  tmux new-session -d -s "$SESSION" -n "leader"
fi

# ── 2. 창(window) 생성 — 고정 이름 부여 ─────────────────────────────────────
WINDOWS=("leader" "developer" "reviewer" "tester" "docs")

for WIN in "${WINDOWS[@]}"; do
  if tmux list-windows -t "$SESSION" -F "#{window_name}" | grep -qx "$WIN"; then
    echo "[setup] 창 '$WIN' 이미 존재합니다."
  else
    echo "[setup] 창 '$WIN' 생성 중..."
    tmux new-window -t "$SESSION" -n "$WIN"
  fi
done

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

# ── 4. 각 창에서 프로젝트 루트로 이동 ────────────────────────────────────────
echo "[setup] 각 창을 프로젝트 루트로 이동 중..."
for WIN in "${WINDOWS[@]}"; do
  tmux send-keys -t "$SESSION:$WIN" "cd \"$PROJECT_ROOT\"" Enter
done

# ── 5. 완료 메시지 ───────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo " team-agent 환경 준비 완료"
echo "========================================"
echo " 세션  : $SESSION"
echo " 창    : ${WINDOWS[*]}"
echo " 메시지: $TEAM_DIR"
echo ""
echo " 세션 접속: tmux attach -t $SESSION"
echo " 창 이동  : Ctrl+b → 창 이름 클릭 또는 Ctrl+b n/p"
echo "========================================"
