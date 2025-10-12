#!/usr/bin/env zsh

set -euo pipefail
setopt EXTENDED_GLOB NO_NOMATCH

# 간단한 로그 헬퍼
log() {
  print -- "[*] $*"
}

# 경고 메시지 출력
warn() {
  print -- "[!] $*" >&2
}

# 기존 파일이나 링크를 백업
backup_file() {
  local path=$1
  local backup_suffix=$2

  [[ -e $path || -L $path ]] || return 0

  local backup_path="${path}.${backup_suffix}.bak"
  if ! command -v mv >/dev/null 2>&1; then
    if ! zmodload -F zsh/files b:mv 2>/dev/null; then
      if ! zmodload zsh/files 2>/dev/null; then
        warn "mv 명령을 찾을 수 없어 백업을 건너뜁니다: $path"
        return 0
      fi
    fi
  fi
  mv "$path" "$backup_path"
  log "기존 파일을 백업했습니다: $path -> $backup_path"
}

# 안전하게 심볼릭 링크를 생성
ensure_symlink() {
  local target=$1
  local link_path=$2
  local backup_suffix=$3

  if [[ -L $link_path ]]; then
    local current_target
    current_target=$(readlink "$link_path")
    if [[ $current_target == "$target" ]]; then
      log "이미 연결된 심볼릭 링크를 유지합니다: $link_path -> $target"
      return 0
    fi
  fi

  if [[ -e $link_path || -L $link_path ]]; then
    backup_file "$link_path" "$backup_suffix"
  fi

  ln -s "$target" "$link_path"
  log "심볼릭 링크를 생성했습니다: $link_path -> $target"
}

# 필요한 줄을 한 번만 추가
append_line_if_missing() {
  local file=$1
  local line=$2

  touch "$file"
  if ! grep -Fqx -- "$line" "$file" 2>/dev/null; then
    print -- "$line" >>"$file"
    log "설정을 추가했습니다: $file -> $line"
  else
    log "이미 존재하는 설정을 건너뜁니다: $file -> $line"
  fi
}

main() {
  local repo_dir=${0:A:h}
  local target_zdotdir=${ZDOTDIR:-$HOME}
  local backup_suffix
  backup_suffix=$(date +%Y%m%d_%H%M%S)

  # 1. 기본 정보와 백업용 접미사 준비
  log "작업 디렉터리: $repo_dir"
  log "ZDOTDIR 대상: $target_zdotdir"

  # 2. 서브모듈과 외부 도구 준비
  if command -v git >/dev/null 2>&1; then
    log "git submodule을 초기화합니다."
    git -C "$repo_dir" submodule update --init --recursive
  else
    warn "git 명령을 찾을 수 없어 submodule 초기화를 건너뜁니다."
  fi

  if ! command -v atuin >/dev/null 2>&1; then
    if command -v curl >/dev/null 2>&1; then
      log "Atuin이 없어서 설치 스크립트를 실행합니다."
      if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
        warn "Atuin 설치에 실패했습니다. 네트워크나 설치 권한을 확인해주세요."
      fi
    else
      warn "curl 명령을 찾을 수 없어 Atuin 설치를 건너뜁니다."
    fi
  else
    log "Atuin이 이미 설치되어 있어 건너뜁니다."
  fi

  # 3. prezto runcom 심볼릭 링크 구성
  local prezto_link="$target_zdotdir/.zprezto"
  if [[ -d $repo_dir/prezto ]]; then
    ensure_symlink "$repo_dir/prezto" "$prezto_link" "$backup_suffix"
  else
    warn "prezto 서브모듈이 비어 있습니다. 먼저 git submodule 명령이 성공했는지 확인하세요."
  fi

  if [[ -d $repo_dir/prezto/runcoms ]]; then
    for rcfile in "$repo_dir"/prezto/runcoms/^README.md(.N); do
      local dest="$target_zdotdir/.${rcfile:t}"
      ensure_symlink "$rcfile" "$dest" "$backup_suffix"
    done
  else
    warn "prezto runcoms 디렉터리를 찾을 수 없어 기본 설정 링크 생성을 건너뜁니다."
  fi

  # 4. 사용자 스크립트와 서드파티 플러그인 배치
  mkdir -p "$HOME/my"
  if [[ -f $repo_dir/shortcut.sh ]]; then
    ensure_symlink "$repo_dir/shortcut.sh" "$HOME/my/shortcut.sh" "$backup_suffix"
  else
    warn "shortcut.sh 파일이 없어 개인 단축키 연결을 건너뜁니다."
  fi

  if [[ -d $repo_dir/zsh-z ]]; then
    ensure_symlink "$repo_dir/zsh-z" "$target_zdotdir/.zsh-z" "$backup_suffix"
  else
    warn "zsh-z 서브모듈을 찾을 수 없어 플러그인 연결을 건너뜁니다."
  fi

  local zshrc_local="$target_zdotdir/.zshrc.local"
  local zpreztorc_local="$target_zdotdir/.zpreztorc.local"

  # 5. 로컬 설정 파일 구성
  append_line_if_missing "$zshrc_local" "# My common scripts"
  append_line_if_missing "$zshrc_local" "source \"\$HOME/my/shortcut.sh\""
  append_line_if_missing "$zshrc_local" "export PATH=\"\$HOME/miniconda3/bin:\$PATH\""
  append_line_if_missing "$zshrc_local" "source \"\${ZDOTDIR:-\$HOME}/.zsh-z/zsh-z.plugin.zsh\""

  append_line_if_missing "$zpreztorc_local" "# prezto 추가 설정은 여기에서 관리하세요."

  log "설치가 완료되었습니다. 새 zsh 세션을 시작하거나 'exec zsh'로 현재 세션을 갱신하세요."
}

main "$@"
