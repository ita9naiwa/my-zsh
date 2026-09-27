# my-zsh

macOS와 Linux에서 쓰는 작은 zsh 설정. zsh 5.9에서 검증했다.
프레임워크·서브모듈·폰트 설치 없이 자동완성, 공유 히스토리, Git 브랜치 프롬프트가 동작한다.

## 설치

```sh
git clone https://github.com/ita9naiwa/my-zsh.git
cd my-zsh
bash install.sh
```

**프로그램과 플러그인은 현재 계정의 홈에만 설치한다.** 시스템 패키지 설치나
`/etc/shells` 수정은 하지 않으며 root 실행을 거부한다. 셸 활성화는 다음 순서로 처리한다.

1. 계정의 기본 셸이 이미 선택한 zsh면 유지한다.
2. 허용 목록에 있는 zsh라면 `sudo -n chsh`로 **본인 계정만** 변경을 시도한다.
3. sudo가 없거나 비밀번호·권한이 필요하거나 변경이 실패하면 Bash 자동 전환을 설치한다.

`sudo -n`은 비밀번호 입력을 기다리지 않는다. 결과를 `Shell activation:` 줄로 출력한다.
실패 상세는 `~/.local/share/my-zsh/shell-change.log`에 남긴다.

- 설정: `${ZDOTDIR:-$HOME}/.zshrc` → 이 저장소의 설정 파일
- 플러그인: `~/.local/share/my-zsh/plugins/` (공식 릴리스 태그 고정)
- 실행기: `~/.local/bin/my-zsh`
- zsh가 없을 때: `~/.local/share/my-zsh/zsh-5.9.2/`에 소스 빌드
- 빌드 임시 파일: `~/.cache/my-zsh/` (종료 시 정리)

이미 설치된 zsh는 그대로 사용하고, 자동 제안·구문 강조는 계정 전용 복사본을 설치한다.
기존 Homebrew/시스템 패키지는 수정하거나 제거하지 않는다.
터미널에서 설치하면 마지막에 새 zsh로 들어간다.
Bash 자동 전환은 `.bashrc`와 기존 로그인 설정(`.bash_profile` → `.bash_login` → `.profile` 중 첫 파일)에
중복 없이 추가하고 원본을 백업한다. 로그인 설정이 없으면 `.bash_profile`을 만든다.
대화형 TTY에서만 전환하므로 일반 SSH 명령·배치 작업에서는 실행하지 않는다.

수동 시작도 가능하다.

```sh
~/.local/bin/my-zsh
```

기존 `.zshrc`는 `.my-zsh-backup.*`에 백업하고 `.zshrc.local`에서 계속 읽는다.
기존 설정을 이어 읽지 않으려면 `--no-preserve-current`를 사용한다.
설치 후 저장소를 이동/삭제하면 링크가 끊어지므로 위치를 유지한다.
옮긴 경우 `--no-preserve-current`로 다시 설치한다. 재설치는 동일한 링크와 플러그인을 유지한다.

```sh
bash install.sh --no-launch                   # 설치/자동 활성화 후 현재 셸 유지
bash install.sh --no-chsh                     # sudo 시도 없이 Bash 자동 전환
bash install.sh --no-shell-setup --no-launch  # 시작 파일/계정 셸 설정 변경 생략
bash install.sh --no-plugins --no-launch      # 플러그인 다운로드 생략
bash install.sh --build-zsh --no-launch       # 기존 zsh와 별개로 계정 전용 zsh 빌드
```

플러그인 다운로드에는 git과 네트워크가 필요하다.
zsh 소스 빌드에는 C 컴파일러, make, curl, xz 지원 tar, SHA-256 도구와
termcap/ncurses 개발 파일이 필요하다. 공식 소스의 고정 SHA-256을 검증한 뒤 빌드한다.
빌드 도구가 없으면 설명과 함께 중단하며 시스템 패키지 설치로 우회하지 않는다.
`--no-plugins`는 zsh가 없을 때의 소스 다운로드까지 끄지는 않는다.
자동 전환을 일시적으로 끄려면 `MY_ZSH_AUTOSTART=0 bash`를 사용한다.
영구 해제는 Bash 시작 파일에 추가된 `# my-zsh` 블록과 그 다음 source 줄을 제거한다.
이전에 직접 붙여넣은 `exec my-zsh` 블록이 있으면 그것도 별도로 제거해야 한다.

## 구성

| 파일 | 역할 |
| --- | --- |
| `.zshrc` | 공통 설정, 자동완성, 프롬프트, 선택 도구 연동 |
| `shortcut.sh` | IREE CPU 컴파일 단축 명령 |
| `.zshrc.local.example` | Conda·Cloud SDK·개인 빌드 경로 예시 |
| `install.sh` | 계정 전용 플러그인·설정·실행기 설치 |
| `build-zsh.sh` | zsh가 없을 때 홈 디렉터리에 검증된 소스 빌드 |
| `check.zsh` | 임시 HOME/ZDOTDIR에서 설치·기동 회귀 검사 |

개인 설정은 `${ZDOTDIR:-$HOME}/.zshrc.local`에 둔다. 저장소에 자격 증명을 넣지 않는다.
기존 Mac의 `~/.config/zsh/terminal-keys.zsh`가 있으면 마지막에 읽어 방향키 설정을 유지한다.

## 선택 기능

설치된 실행 파일만 연동한다. 기본 설정은 아래 도구 없이도 동작한다.

- **Atuin**: Ctrl-R 히스토리 검색. 위쪽 방향키는 기본 탐색 유지. 로그인·동기화 설정은 하지 않는다.
- **fzf 0.48 이상**: Ctrl-T 파일, Alt-C 디렉터리 선택. Atuin도 있으면 Ctrl-R은 Atuin이 담당한다.
- **zoxide**: `z`/`zi`로 자주 쓰는 디렉터리 이동. 이전 zsh-z 데이터는 자동 변환하지 않는다.
- **zsh-autosuggestions**: 계정 전용 경로를 우선하며 기존 시스템 설치 경로도 읽을 수 있다.

## Bash 설정 상속

**Bash 재실행 상속은 기본으로 꺼져 있다.** 일부 클러스터 `.bashrc`가 재실행 중 멈추는 사례를 확인했다.
이미 export된 환경변수는 셸 전환 시 정상적으로 유지된다.
필요하면 `.zshenv`에 `export MY_ZSH_IMPORT_BASH=1`을 넣어 명시적으로 켠다.
자동 전환 경로에서는 다시 실행하지 않도록 `MY_ZSH_IMPORT_BASH=0`을 설정한다.

켜면 `~/.bashrc`를 별도 Bash에서 읽고, 추가·변경된 일반 변수와 export 환경변수,
간단한 alias만 현재 zsh에 가져온다. 공백·개행·달러 문자는 값 그대로 유지한다.
Bash 함수·배열·프롬프트·히스토리·셸 내부 변수는 가져오지 않는다. `.bash_profile`은 별도로 읽지 않는다.
`alias work='cd /some/path'`처럼 현재 디렉터리를 바꾸는 간단한 alias도 동작한다.
Bash 전용 문법이 들어간 복잡한 alias는 zsh용으로 직접 바꿔야 한다.

매번 현재 `.bashrc`를 실행하므로 그 파일의 초기화 비용과 부수 효과도 발생한다.
함수나 비대화형 작업을 자동으로 zsh로 전환하지 않는다.
기존 `.zshrc.local`은 이후 읽으므로 기기별 zsh 설정이 우선한다.

## 설치만 하면 쓰는 편의 기능

`install.sh`가 두 플러그인을 홈 디렉터리에 설치한다. 계정 전용 복사본이 있으면 재설치하지 않는다.

과거 명령의 나머지가 회색으로 보이며 줄 끝에서 `→`로 수락한다.
구문 강조는 없는 명령과 입력 구문을 색으로 구분한다.
`ssh`처럼 명령 일부를 입력하고 `↑`/`↓`를 누르면 해당 접두어의 기록만 탐색한다.
입력이 비어 있으면 전체 기록을 탐색한다. Shift/Ctrl/Option 방향키의 기존 이동 설정은 유지한다.

## Wave Terminal

`wave/settings.json`은 macOS용 추천 설정이다. 실제 설정 파일은
`~/.config/waveterm/settings.json`이며 기존 값을 보존하면서 이 프리셋의 키를 병합한다.
`install.sh`는 Wave 설정을 자동 변경하지 않는다. 이 Mac에는 백업 후 이미 병합했다.
Wave UI에서 바꾼 값이 저장소를 수정하지 않도록 실제 파일은 심볼릭 링크로 연결하지 않았다.

- 기본 프리셋은 macOS의 `/bin/zsh`를 사용한다. 계정 전용 빌드를 사용하려면
  `term:localshellpath`를 `/Users/사용자명/.local/share/my-zsh/zsh-5.9.2/bin/zsh`로 지정한다.
- 글꼴 14px, 스크롤백 20,000줄, 깜빡이지 않는 커서, 소리 없는 벨 표시.
- Option을 Meta로 사용해 단어 단위 이동/삭제가 가능하다.
- 선택 즉시 복사, 복사 시 줄 끝 공백 제거, bracketed paste 활성화.
- 앱/창 종료 확인을 켠다. 기존 테마와 AI 설정은 유지한다.

Wave가 임시 `ZDOTDIR`을 쓰더라도 사용자 `.zshrc.local`, completion 캐시와 히스토리는
원래 HOME에서 읽는다. 사용자 정의 ZDOTDIR은 Wave 임시 경로와 다를 때 그대로 존중한다.
기존 Wave 셸 통합을 유지하므로 현재 디렉터리·명령 상태 추적도 계속 동작한다.
새 터미널 블록에서 셸 설정이 적용된다. 개별 블록에 지정한 글꼴 등은 전역 설정보다 우선한다.
설치된 Wave 0.14.5의 JSON 스키마와 실제 Wave zsh startup 파일로 검증했다.

## 변경 이유

기존 `.zshrc`는 실행할 때마다 자신에게 Pure 설정 4줄을 덧붙였고, Atuin 환경도 두 번 읽었다.
설치 스크립트는 저장소의 설정 대신 Prezto 기본 runcom을 링크해 실제 사용 설정과 저장소가 어긋났다.
이제 관리하는 파일 하나를 직접 연결한다. Prezto/Pure/zsh-z 서브모듈은 제거했다.
Pure의 비동기 Git 상태·stash 표시는 제공하지 않으며 기본 프롬프트는 브랜치만 표시한다.
컴파일러를 ccache로 바꾸는 전역 별칭과 고정 LLVM/Conda PATH는 개인 설정 예시로 옮겼다.
`compinit -i`로 안전하지 않은 completion 디렉터리는 로드하지 않는다.

## 확인과 복구

```sh
zsh check.zsh
```

검사는 새 설치, 공백 포함 ZDOTDIR, 기존 설정 보존, 중복 설치, 자동완성, Delete 키,
설정 파일 자기 수정 방지, 깨진 심볼릭 링크와 잘못된 인수를 확인한다.
자동 제안·구문 강조 로드, Wave 시작 경로, Bash 변수·alias 상속을 macOS에서 확인했다.
계정 전용 실행기·플러그인 우선순위, 비밀번호 없는 sudo 성공/거절/미설치,
허용되지 않은 셸, 중복 방지와 비대화형 작업 보호를 검사한다. sudo/chsh는 테스트 대역으로만 실행한다.
macOS 임시 HOME에서 zsh 5.9.2 공식 소스의 실제 빌드·설치·자동완성·실행기 기동도 확인했다.
Wave 화면의 시각적 확인과 Linux 기동은 검증하지 않았다.

복구할 때는 설치 출력의 백업 경로를 사용한다. **아래 `BACKUP`은 실제 경로로 바꾼다.**

```sh
TARGET=${ZDOTDIR:-$HOME}
BACKUP="$TARGET/.my-zsh-backup.실제접미사"
# 설치된 링크만 제거하고 원래 파일/링크를 되돌린다.
[[ -L "$TARGET/.zshrc" ]] && unlink "$TARGET/.zshrc"
cp -P "$BACKUP/.zshrc" "$TARGET/.zshrc"
```

기존 설정을 보존했다면 `.zshrc.local`에 추가된 `source .../previous.zsh` 줄도 지운다.
기존 `.zshrc.local`이 있었다면 백업본으로 복원할 수 있다. 처음부터 `.zshrc`가 없었다면 링크 제거만 하면 된다.

참고: [zsh completion](https://zsh.sourceforge.io/Doc/Release/Completion-System.html),
[zsh history 옵션](https://zsh.sourceforge.io/Doc/Release/Options.html),
[Atuin 키 설정](https://docs.atuin.sh/main/reference/init/),
[fzf 공식 문서](https://github.com/junegunn/fzf).
