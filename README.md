# my-zsh

macOS와 Linux에서 쓰는 작은 zsh 설정. zsh 5.9에서 검증했다.
프레임워크·서브모듈·폰트 설치 없이 자동완성, 공유 히스토리, Git 브랜치 프롬프트가 동작한다.

## 설치

```sh
git clone https://github.com/ita9naiwa/my-zsh.git
cd my-zsh
zsh install.sh
exec zsh
```

기존 `.zshrc`는 `${ZDOTDIR:-$HOME}/.my-zsh-backup.*`에 백업한다.
기존 설정도 계속 실행하려면 먼저 내용을 확인하고 `zsh install.sh --preserve-current`로 설치한다.
이 옵션은 백업한 설정을 `.zshrc.local`에서 불러온다. 오래된 이 저장소의 자기 수정 `.zshrc`에는 사용하지 않는다.
이미 설치한 상태에서 재실행하면 파일을 변경하지 않는다. 설치는 네트워크나 패키지 관리자를 실행하지 않는다.

`.zshrc`가 저장소를 가리키므로 설치 후 저장소 디렉터리를 이동하거나 삭제하지 않는다.
다른 위치로 옮길 때는 `--preserve-current` 없이 다시 설치한다.
`.zprofile`, `.zshenv`, `.zlogin`은 변경하지 않으며 이전 Prezto 설치에서 남은 설정은 별도로 확인한다.

## 구성

| 파일 | 역할 |
| --- | --- |
| `.zshrc` | 공통 설정, 자동완성, 프롬프트, 선택 도구 연동 |
| `shortcut.sh` | IREE CPU 컴파일 단축 명령 |
| `.zshrc.local.example` | Conda·Cloud SDK·개인 빌드 경로 예시 |
| `install.sh` | 기존 설정 백업 및 링크 설치 |
| `check.zsh` | 임시 HOME/ZDOTDIR에서 설치·기동 회귀 검사 |

개인 설정은 `${ZDOTDIR:-$HOME}/.zshrc.local`에 둔다. 저장소에 자격 증명을 넣지 않는다.
기존 Mac의 `~/.config/zsh/terminal-keys.zsh`가 있으면 마지막에 읽어 방향키 설정을 유지한다.

## 선택 기능

설치된 실행 파일만 연동한다. 기본 설정은 아래 도구 없이도 동작한다.

- **Atuin**: Ctrl-R 히스토리 검색. 위쪽 방향키는 기본 탐색 유지. 로그인·동기화 설정은 하지 않는다.
- **fzf 0.48 이상**: Ctrl-T 파일, Alt-C 디렉터리 선택. Atuin도 있으면 Ctrl-R은 Atuin이 담당한다.
- **zoxide**: `z`/`zi`로 자주 쓰는 디렉터리 이동. 이전 zsh-z 데이터는 자동 변환하지 않는다.
- **zsh-autosuggestions**: Homebrew의 `/opt/homebrew` 또는 `/usr/local` 설치 경로에 있으면 로드한다.

## 설치만 하면 쓰는 편의 기능

```sh
brew install zsh-autosuggestions zsh-syntax-highlighting
```

과거 명령의 나머지가 회색으로 보이며 줄 끝에서 `→`로 수락한다.
구문 강조는 없는 명령과 입력 구문을 색으로 구분한다.
`ssh`처럼 명령 일부를 입력하고 `↑`/`↓`를 누르면 해당 접두어의 기록만 탐색한다.
입력이 비어 있으면 전체 기록을 탐색한다. Shift/Ctrl/Option 방향키의 기존 이동 설정은 유지한다.

## Wave Terminal

`wave/settings.json`은 macOS용 추천 설정이다. 실제 설정 파일은
`~/.config/waveterm/settings.json`이며 기존 값을 보존하면서 이 프리셋의 키를 병합한다.
`install.sh`는 Wave 설정을 자동 변경하지 않는다. 이 Mac에는 백업 후 이미 병합했다.
Wave UI에서 바꾼 값이 저장소를 수정하지 않도록 실제 파일은 심볼릭 링크로 연결하지 않았다.

- `/bin/zsh` 로그인 셸을 사용해 이 저장소의 설정을 읽는다.
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
자동 제안·구문 강조 로드 및 Wave 시작 경로를 macOS에서 확인했다. Wave 화면의 시각적 확인과 Linux 기동은 검증하지 않았다.

복구할 때는 설치 출력의 백업 경로를 사용한다. **아래 `BACKUP`은 실제 경로로 바꾼다.**

```sh
TARGET=${ZDOTDIR:-$HOME}
BACKUP="$TARGET/.my-zsh-backup.실제접미사"
# 설치된 링크만 제거하고 원래 파일/링크를 되돌린다.
[[ -L "$TARGET/.zshrc" ]] && unlink "$TARGET/.zshrc"
cp -P "$BACKUP/.zshrc" "$TARGET/.zshrc"
```

`--preserve-current`를 사용했다면 `.zshrc.local`에 추가된 `source .../previous.zsh` 줄도 지운다.
기존 `.zshrc.local`이 있었다면 백업본으로 복원할 수 있다. 처음부터 `.zshrc`가 없었다면 링크 제거만 하면 된다.

참고: [zsh completion](https://zsh.sourceforge.io/Doc/Release/Completion-System.html),
[zsh history 옵션](https://zsh.sourceforge.io/Doc/Release/Options.html),
[Atuin 키 설정](https://docs.atuin.sh/main/reference/init/),
[fzf 공식 문서](https://github.com/junegunn/fzf).
