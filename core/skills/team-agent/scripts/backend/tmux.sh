#!/usr/bin/env bash
# backend/tmux.sh — tmux 백엔드
#
# 세션 team-agent-<프로젝트명> 의 단일 창 'team' 에 역할 수만큼 pane 을 tiled 로 배치하고,
# pane 타이틀 = 역할, role-map 의 타깃 = pane ID(%n) 로 기록한다.

TMUX_TEAM_WIN="team"

be_name() { printf 'tmux'; }

be_available() { command -v tmux >/dev/null 2>&1; }

be_attach_hint() {
  local session; session="$(team_session_name "$1")"
  echo " 세션 접속: tmux attach -t $session"
  echo " pane 이동: Ctrl+b → 방향키 또는 Ctrl+b q (pane 번호)"
}

be_open_roles() {
  local root="$1"; shift
  local roles=("$@")
  local session win="$TMUX_TEAM_WIN"
  session="$(team_session_name "$root")"

  # 1. 세션
  if tmux has-session -t "$session" 2>/dev/null; then
    echo "[tmux] 세션 '$session' 이미 존재합니다."
    # 구버전 멀티-윈도우 구조(역할별 별도 창) 감지 → 제거
    local old_wins
    old_wins=$(tmux list-windows -t "$session" -F "#{window_name}" \
      | grep -E "^(leader|developer|reviewer|tester)$" || true)
    if [ -n "$old_wins" ]; then
      echo "[tmux] 구버전 멀티-윈도우 구조 감지 → 단일 창 pane 레이아웃으로 전환합니다."
      local w
      for w in $old_wins; do tmux kill-window -t "$session:$w" 2>/dev/null || true; done
    fi
  else
    echo "[tmux] 세션 '$session' 생성 중..."
    tmux new-session -d -s "$session" -n "$win" -x 220 -y 50
  fi

  # 2. 'team' 창 확보
  if ! tmux list-windows -t "$session" -F "#{window_name}" | grep -qx "$win"; then
    local first
    first=$(tmux list-windows -t "$session" -F "#{window_name}" | head -1)
    tmux rename-window -t "$session:${first}" "$win" 2>/dev/null \
      || tmux new-window -t "$session" -n "$win"
  fi

  # 3. pane 수 맞추기 (매 split 후 tiled 로 공간 부족 방지)
  local current needed i=0
  current=$(tmux list-panes -t "$session:$win" | wc -l)
  needed=$(( ${#roles[@]} - current ))
  while [ "$i" -lt "$needed" ]; do
    tmux split-window -t "$session:$win" -d
    tmux select-layout -t "$session:$win" tiled
    i=$(( i + 1 ))
  done
  tmux select-layout -t "$session:$win" tiled

  # 4. pane 타이틀 = 역할, pane ID 수집, 에이전트 기동
  local pairs=() idx role pane_num pane_id cmd
  for idx in "${!roles[@]}"; do
    role="${roles[$idx]}"
    pane_num=$(( idx + 1 ))
    tmux select-pane -t "$session:$win.$pane_num" -T "$role" 2>/dev/null || true
    pane_id=$(tmux list-panes -t "$session:$win" -F "#{pane_index} #{pane_id}" \
      | awk -v n="$pane_num" '$1==n {print $2}' | head -1)
    pairs+=("$role=$pane_id")
    cmd="$(team_agent_cmd "$role")"
    if [ -n "$cmd" ]; then
      tmux send-keys -t "$pane_id" "cd \"$root\" && $cmd" Enter
      echo "[tmux] pane $pane_num ($role, $pane_id): $cmd 실행"
    else
      tmux send-keys -t "$pane_id" "cd \"$root\"" Enter
      echo "[tmux] pane $pane_num ($role, $pane_id): 에이전트 미기동 (TEAM_AGENT_NO_LAUNCH)"
    fi
  done

  team_write_role_map "$root" "tmux" "${pairs[@]}"
  echo "[tmux] 역할 → pane 매핑 저장: $(team_role_map_file "$root")"
}

be_notify() {
  local root="$1" role="$2" text="$3" session target
  session="$(team_session_name "$root")"
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "[tmux] 세션 '$session' 없음"
    return 1
  fi
  target="$(team_target_of "$root" "$role" || true)"
  # role-map 없으면 pane 타이틀로 폴백
  if [ -z "$target" ]; then
    target=$(tmux list-panes -t "$session:$TMUX_TEAM_WIN" -F "#{pane_id} #{pane_title}" 2>/dev/null \
      | awk -v r="$role" '$2==r {print $1}' | head -1)
  fi
  if [ -z "$target" ]; then
    echo "[tmux] pane '$role' 를 찾을 수 없습니다"
    return 1
  fi
  tmux send-keys -t "$target" "$text"
  sleep 1
  tmux send-keys -t "$target" Enter
  echo "[tmux] pane '$role' ($target) 에 알림 전송 완료"
}

be_status() {
  local root="$1" session
  session="$(team_session_name "$root")"
  if tmux has-session -t "$session" 2>/dev/null; then
    echo "  세션 '$session' 활성"
    if tmux list-windows -t "$session" -F "#{window_name}" 2>/dev/null | grep -qx "$TMUX_TEAM_WIN"; then
      echo "  창: $TMUX_TEAM_WIN (단일 창 multi-pane)"
      tmux list-panes -t "$session:$TMUX_TEAM_WIN" \
        -F "    pane #{pane_index}: #{pane_title} (#{pane_id}, #{pane_width}x#{pane_height})" 2>/dev/null
    else
      echo "  창 목록 (구버전):"
      tmux list-windows -t "$session" -F "    #I: #{window_name}" 2>/dev/null
    fi
  else
    echo "  세션 '$session' 비활성 (setup.sh 를 실행하세요)"
  fi
}

be_self_role() {
  local root="$1" me="${TMUX_PANE:-}" line
  # Bash 서브셸에서는 TMUX_PANE 이 비어 있을 수 있다 → 활성 pane 으로 폴백
  if [ -z "$me" ] && [ -n "${TMUX:-}" ]; then
    me="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
  fi
  [ -n "$me" ] || return 1
  while read -r line; do
    [ "${line#* }" = "$me" ] && { printf '%s' "${line%% *}"; return 0; }
  done < <(team_list_role_targets "$root")
  return 1
}
