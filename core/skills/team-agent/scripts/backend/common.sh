#!/usr/bin/env bash
# backend/common.sh — team-agent 터미널 백엔드 공통 계층
#
# setup.sh / send-msg.sh / status.sh / whoami.sh 가 source 하여 사용한다.
# 백엔드(tmux | orca)는 "역할별 터미널을 열고, 특정 역할 터미널에 텍스트를 밀어 넣는" 일만 담당하고,
# 메시지 버스(.team/)·협업 프로토콜은 백엔드와 무관하게 동일하다.
#
# 백엔드 인터페이스 (backend/<name>.sh 가 반드시 구현):
#   be_name                              백엔드 이름 출력
#   be_available                         사용 가능하면 0
#   be_open_roles  <ROOT> <ROLE...>      역할별 터미널 생성(재사용) + role-map 기록 + 에이전트 기동
#   be_notify      <ROOT> <ROLE> <TEXT>  역할 터미널에 TEXT + Enter 전달 (실패 시 non-zero)
#   be_status      <ROOT>                터미널 상태 출력
#   be_self_role   <ROOT>                현재 셸이 어느 역할 터미널인지 출력 (모르면 non-zero)
#   be_attach_hint <ROOT>                사용자가 터미널을 보는 방법 안내 출력
#
# 백엔드 선택 순서 (team_resolve_backend):
#   1) 환경변수 TEAM_AGENT_BACKEND=tmux|orca
#   2) <ROOT>/.team/status/backend 파일 (setup.sh 가 기록 — 같은 팀은 같은 백엔드를 쓴다)
#   3) 자동 감지: Orca 터미널 안이고 Orca 런타임이 살아 있으면 orca, 아니면 tmux
#
# 기타 환경변수:
#   TEAM_AGENT_NO_LAUNCH=1        터미널만 열고 에이전트 CLI 는 기동하지 않음 (검증용)
#   TEAM_AGENT_CMD_<role>=<cmd>   역할별 기동 명령 오버라이드 (예: TEAM_AGENT_CMD_reviewer=codex)

TEAM_ROLES=("leader" "developer" "reviewer" "tester")
TEAM_BACKENDS=("tmux" "orca")

# 역할별 기본 에이전트 CLI
declare -A TEAM_ROLE_AGENT=(
  [leader]="claude"
  [developer]="claude"
  [reviewer]="codex"
  [tester]="agy"
)

TEAM_BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

team_is_valid_role() {
  local r
  for r in "${TEAM_ROLES[@]}"; do
    [ "$r" = "$1" ] && return 0
  done
  return 1
}

team_dir()           { printf '%s/.team' "$1"; }
team_role_map_file() { printf '%s/.team/status/role-map.sh' "$1"; }
team_backend_file()  { printf '%s/.team/status/backend' "$1"; }
team_session_name()  { printf 'team-agent-%s' "$(basename "$1")"; }

# 역할의 기동 명령. TEAM_AGENT_NO_LAUNCH=1 이면 빈 문자열.
team_agent_cmd() {
  local role="$1" var="TEAM_AGENT_CMD_${role}"
  if [ "${TEAM_AGENT_NO_LAUNCH:-0}" = "1" ]; then
    printf ''
    return 0
  fi
  printf '%s' "${!var:-${TEAM_ROLE_AGENT[$role]}}"
}

# role-map.sh 에서 역할의 터미널 타깃(tmux pane ID 또는 orca 터미널 핸들)을 읽는다.
# 구버전 pane-map.sh(PANE_<role>) 도 폴백으로 지원한다.
team_target_of() {
  local root="$1" role="$2" map var
  map="$(team_role_map_file "$root")"
  if [ -f "$map" ]; then
    # shellcheck source=/dev/null
    source "$map"
    var="TARGET_${role}"
    if [ -n "${!var:-}" ]; then
      printf '%s' "${!var}"
      return 0
    fi
  fi
  if [ -f "$root/.team/status/pane-map.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/.team/status/pane-map.sh"
    var="PANE_${role}"
    if [ -n "${!var:-}" ]; then
      printf '%s' "${!var}"
      return 0
    fi
  fi
  return 1
}

# role-map.sh 를 새로 쓴다. 인자: ROOT BACKEND, 이후 "role=target" 쌍들
team_write_role_map() {
  local root="$1" backend="$2" map pair
  shift 2
  map="$(team_role_map_file "$root")"
  mkdir -p "$(dirname "$map")"
  {
    echo "# role-map.sh — 역할 → 터미널 타깃 매핑 (setup.sh 자동 생성, 직접 편집 금지)"
    echo "# backend: $backend (tmux=pane ID, orca=terminal handle)"
    echo "ROLE_MAP_BACKEND=\"$backend\""
    for pair in "$@"; do
      echo "TARGET_${pair%%=*}=\"${pair#*=}\""
    done
  } > "$map"
  printf '%s\n' "$backend" > "$(team_backend_file "$root")"
}

# 역할 → 타깃 매핑을 "role target" 줄로 나열 (role-map 이 없으면 아무것도 출력 안 함)
team_list_role_targets() {
  local root="$1" role target
  for role in "${TEAM_ROLES[@]}"; do
    if target="$(team_target_of "$root" "$role")"; then
      printf '%s %s\n' "$role" "$target"
    fi
  done
}

# Orca 런타임이 현재 셸에서 도달 가능한가
team_orca_reachable() {
  command -v orca >/dev/null 2>&1 || return 1
  orca status 2>/dev/null | grep -q '^runtimeReachable: true' 
}

# 백엔드 이름을 결정해 출력한다. 인자: ROOT
team_resolve_backend() {
  local root="$1" stored
  if [ -n "${TEAM_AGENT_BACKEND:-}" ]; then
    printf '%s' "$TEAM_AGENT_BACKEND"
    return 0
  fi
  if [ -f "$(team_backend_file "$root")" ]; then
    stored="$(tr -d '[:space:]' < "$(team_backend_file "$root")")"
    if [ -n "$stored" ]; then
      printf '%s' "$stored"
      return 0
    fi
  fi
  if [ -n "${ORCA_TERMINAL_HANDLE:-}" ] && team_orca_reachable; then
    printf 'orca'
    return 0
  fi
  if command -v tmux >/dev/null 2>&1; then
    printf 'tmux'
    return 0
  fi
  return 1
}

# 백엔드 구현을 source 하고 인터페이스 함수 존재를 확인한다. 인자: BACKEND
team_load_backend() {
  local name="$1" fn
  case "$name" in
    tmux|orca) ;;
    *) echo "[backend] 알 수 없는 백엔드: '$name' (지원: ${TEAM_BACKENDS[*]})" >&2; return 1 ;;
  esac
  # shellcheck source=/dev/null
  source "$TEAM_BACKEND_DIR/$name.sh"
  for fn in be_name be_available be_open_roles be_notify be_status be_self_role be_attach_hint; do
    if ! declare -F "$fn" >/dev/null; then
      echo "[backend] $name.sh 에 $fn 이 없습니다" >&2
      return 1
    fi
  done
  return 0
}

# 결정 + 로드를 한 번에. 인자: ROOT. 실패 시 메시지 출력 후 non-zero.
team_init_backend() {
  local root="$1" name
  if ! name="$(team_resolve_backend "$root")"; then
    echo "[backend] 사용할 터미널 백엔드를 찾지 못했습니다 (tmux 미설치, Orca 미도달). TEAM_AGENT_BACKEND 로 지정하세요." >&2
    return 1
  fi
  team_load_backend "$name" || return 1
  TEAM_BACKEND="$name"
  export TEAM_BACKEND
  return 0
}
