#!/usr/bin/env bash
# backend/orca.sh — Orca(agent developer toolkit) 백엔드
#
# 프로젝트 워크트리에 역할별 Orca 터미널 탭(타이틀 = 역할)을 만들고,
# role-map 의 타깃 = Orca 터미널 핸들(term_…) 로 기록한다.
# 알림은 `orca terminal send --terminal <핸들> --text ... --enter` 로 전달한다.
#
# 전제: 프로젝트가 Orca 에 등록돼 있어야 한다 (`orca repo add <경로>` 또는 Orca UI 에서 열기).
# 주의: orca CLI 는 stderr 에 "[single-instance] ..." 경고를 낼 수 있으므로 stdout 만 파싱한다.

be_name() { printf 'orca'; }

be_available() { team_orca_reachable; }

be_attach_hint() {
  echo " 터미널 보기: Orca 앱의 워크트리 '$(basename "$1")' 탭 (타이틀 = 역할명)"
  echo " 목록 확인  : orca terminal list --worktree path:$1"
}

# 워크트리 셀렉터
_orca_wt() { printf 'path:%s' "$1"; }

# 현재 워크트리의 살아있는 터미널 핸들 목록 (stdout 의 term_… 만 추출)
_orca_live_handles() {
  orca terminal list --worktree "$(_orca_wt "$1")" --json 2>/dev/null \
    | grep -o '"term_[0-9a-f-]*"' | tr -d '"' | sort -u
}

_orca_handle_alive() {
  _orca_live_handles "$1" | grep -qx "$2"
}

be_open_roles() {
  local root="$1"; shift
  local roles=("$@")

  if ! team_orca_reachable; then
    echo "[orca] Orca 런타임에 도달할 수 없습니다 (orca status 확인). Orca 앱을 먼저 실행하세요." >&2
    return 1
  fi
  if ! orca worktree show --worktree "$(_orca_wt "$root")" >/dev/null 2>&1; then
    echo "[orca] 워크트리가 Orca 에 등록돼 있지 않습니다: $root" >&2
    echo "[orca]   → orca repo add $root   (또는 Orca 앱에서 폴더 열기) 후 다시 실행" >&2
    return 1
  fi

  local pairs=() role target cmd out
  for role in "${roles[@]}"; do
    target="$(team_target_of "$root" "$role" || true)"
    if [ -n "$target" ] && [[ "$target" == term_* ]] && _orca_handle_alive "$root" "$target"; then
      echo "[orca] '$role' 터미널 재사용: $target"
      pairs+=("$role=$target")
      continue
    fi

    cmd="$(team_agent_cmd "$role")"
    if [ -n "$cmd" ]; then
      out="$(orca terminal create --worktree "$(_orca_wt "$root")" --title "$role" --command "$cmd" --json 2>/dev/null)"
    else
      out="$(orca terminal create --worktree "$(_orca_wt "$root")" --title "$role" --json 2>/dev/null)"
    fi
    target="$(printf '%s' "$out" | grep -o '"term_[0-9a-f-]*"' | head -1 | tr -d '"')"
    if [ -z "$target" ]; then
      echo "[orca] '$role' 터미널 생성 실패. 출력: ${out:-<없음>}" >&2
      return 1
    fi
    pairs+=("$role=$target")
    if [ -n "$cmd" ]; then
      echo "[orca] '$role' 터미널 생성: $target ($cmd 실행)"
    else
      echo "[orca] '$role' 터미널 생성: $target (에이전트 미기동, TEAM_AGENT_NO_LAUNCH)"
    fi
  done

  team_write_role_map "$root" "orca" "${pairs[@]}"
  echo "[orca] 역할 → 터미널 핸들 매핑 저장: $(team_role_map_file "$root")"
}

be_notify() {
  local root="$1" role="$2" text="$3" target
  if ! team_orca_reachable; then
    echo "[orca] Orca 런타임에 도달할 수 없습니다"
    return 1
  fi
  target="$(team_target_of "$root" "$role" || true)"
  if [ -z "$target" ] || [[ "$target" != term_* ]]; then
    echo "[orca] '$role' 의 터미널 핸들이 role-map 에 없습니다 (setup.sh 를 먼저 실행하세요)"
    return 1
  fi
  if ! _orca_handle_alive "$root" "$target"; then
    echo "[orca] '$role' 터미널($target)이 살아있지 않습니다 (setup.sh 로 재생성)"
    return 1
  fi
  if orca terminal send --terminal "$target" --text "$text" --enter --json >/dev/null 2>&1; then
    echo "[orca] 터미널 '$role' ($target) 에 알림 전송 완료"
  else
    echo "[orca] 터미널 '$role' ($target) 알림 전송 실패"
    return 1
  fi
}

be_status() {
  local root="$1" line role target alive
  if ! team_orca_reachable; then
    echo "  Orca 런타임 비도달 (orca status 확인)"
    return 0
  fi
  echo "  워크트리: $root"
  local found=0
  while read -r role target; do
    found=1
    if _orca_handle_alive "$root" "$target"; then alive="live"; else alive="닫힘"; fi
    printf '    %-10s %s (%s)\n' "$role" "$target" "$alive"
  done < <(team_list_role_targets "$root")
  [ "$found" = 1 ] || echo "  역할 터미널 없음 (setup.sh 를 실행하세요)"
}

be_self_role() {
  local root="$1" me="${ORCA_TERMINAL_HANDLE:-}" line
  [ -n "$me" ] || return 1
  while read -r line; do
    [ "${line#* }" = "$me" ] && { printf '%s' "${line%% *}"; return 0; }
  done < <(team_list_role_targets "$root")
  return 1
}
