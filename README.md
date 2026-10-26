# notify-card

Claude Code가 **답변을 끝냈을 때**나 **승인·입력을 기다릴 때** 원하는 소리와 함께 화면 중앙에 알림 카드를 띄워 주는 Windows용 플러그인입니다. 다른 창에서 일하고 있어도 Claude가 끝났는지 바로 알 수 있습니다.

```
┌──────────────────────────────────────────┐
│ ● Claude Code                          ✕ │
│                                          │
│ 답변이 완료되었습니다                     │
│ my-project                               │
│                                          │
│ ⚠ 확인 필요 2건                           │
│   src\config.py:2  Anthropic/OpenAI 키    │
│   → 코드에 직접 들어 있습니다. .env로 …    │
│   .env  .gitignore에 없음                 │
│   → 깃헙에 올라갈 수 있습니다. …           │
│                                          │
│ 수정한 파일 3개                            │
│   + src\config.py                        │
│   + .env                                 │
│   ~ src\app.py                           │
└──────────────────────────────────────────┘
```

## 기능

- **두 가지 상황에서 알림**
  - 답변 완료: 초록 점
  - 승인·입력 대기: 주황 점. Claude가 무엇을 기다리는지도 함께 표시됩니다(예: `Claude needs your permission to use Bash`).
- **수정한 파일 목록:** 답변이 끝나면 이번 답변에서 Claude가 만들거나 고친 파일을 보여 줍니다. `+`는 새 파일, `~`는 수정한 파일입니다.
- **깃헙에 올라가면 안 되는 것 경고:** 답변이 끝날 때 아래를 검사해서 "확인 필요"로 빨갛게 표시합니다.
  - 수정한 파일 안에 API 키, 토큰, 비밀번호, 개인 키가 코드에 직접 들어 있는 경우
  - `.env`, `*.pem`, `*.key`, `credentials.json` 같은 파일이 `.gitignore`에 없는 경우
  - 그런 파일이 이미 git에 포함된 경우 (`git rm --cached` 방법도 함께 알려 줍니다)
- **원하는 소리 재생:** `.wav`, `.mp3` 파일을 지원합니다. 따로 넣지 않으면 윈도우 기본 소리가 납니다.
- **팝업은 하나만:** 새 알림이 오면 이전 카드는 자동으로 닫힙니다.
- **Claude를 막지 않음:** 카드를 닫지 않아도 Claude는 바로 다음 작업을 이어갑니다.
- **프로젝트명 표시:** 여러 프로젝트를 동시에 돌려도 어느 프로젝트의 알림인지 알 수 있습니다.

## 요구 사항

- Windows 10 또는 11 (Windows PowerShell 5.1은 기본으로 설치되어 있습니다)
- [Claude Code](https://claude.com/claude-code)

## 설치

Claude Code에서 아래 두 명령을 차례로 입력합니다.

```
/plugin marketplace add sunghyuny/claude_notify
/plugin install notify-card@notify-card
```

설치가 끝나면 바로 동작합니다. 알림이 안 뜨면 Claude Code를 한 번 다시 시작해 주세요.

## 소리와 문구 바꾸기

처음 알림이 뜰 때 아래 폴더가 자동으로 만들어집니다.

```
C:\Users\<사용자명>\.claude\notify-card\
├─ config.json   문구와 소리 설정
├─ sounds\       내 소리 파일을 넣는 곳
└─ cache\        링크로 받은 소리가 저장되는 곳 (자동)
```

이 폴더는 플러그인을 업데이트하거나 다시 설치해도 그대로 남습니다.

### 소리 바꾸기

소리는 **파일**로 넣거나 **링크**로 지정할 수 있습니다. 둘 다 `.mp3`, `.wav`를 지원합니다.

| 상황 | 기본 파일 이름 | 지정한 소리가 없을 때 |
|---|---|---|
| 답변 완료 | `sounds\done.wav` | 윈도우 `tada.wav` |
| 승인·입력 대기 | `sounds\attention.wav` | 윈도우 `chimes.wav` |

#### 방법 1. 파일로 넣기

`sounds\` 폴더에 소리 파일을 위 표의 이름으로 넣으면 바로 적용됩니다.

다른 이름이나 `.mp3` 파일을 쓰려면 `config.json`의 `sound`에 파일 경로를 적습니다.

```json
"sound": "sounds/my-sound.mp3"
```

#### 방법 2. 링크로 지정하기

`config.json`의 `sound`에 링크를 그대로 붙여 넣습니다.

```json
"sound": "https://www.myinstants.com/ko/instant/indian-song-26519/"
```

- **[myinstants](https://www.myinstants.com) 같은 소리 페이지 링크:** 공유 버튼으로 복사한 링크를 그대로 써도 됩니다. 페이지에서 소리 파일을 찾아 받습니다.
- **`.mp3`나 `.wav`로 끝나는 직접 링크:** 예를 들어 `https://example.com/bell.mp3`처럼 쓰면 됩니다.

링크로 지정한 소리는 처음 한 번만 받아서 `cache\` 폴더에 저장하고, 그다음부터는 인터넷 없이 저장된 파일을 씁니다. 그래서 첫 알림만 소리가 조금 늦게 날 수 있습니다. 링크가 잘못됐거나 받기에 실패하면 기본 소리가 납니다.

### 문구 바꾸기

`config.json`을 메모장으로 열어 `message`를 고칩니다. 아래는 답변 완료는 링크로, 대기는 파일로 지정한 예시입니다.

```json
{
  "Stop": {
    "message": "답변이 완료되었습니다",
    "sound": "https://www.myinstants.com/ko/instant/indian-song-26519/"
  },
  "Notification": {
    "message": "Claude가 확인을 기다립니다",
    "sound": "sounds/attention.mp3"
  }
}
```

- `sound`에는 링크를 쓰거나, `sounds/done.wav`처럼 이 폴더 기준 경로, 또는 `D:/music/bell.mp3`처럼 전체 경로를 씁니다.
- 링크를 바꾸면 새 링크의 소리를 다시 받습니다. 같은 링크의 소리를 새로 받고 싶으면 `cache\` 폴더를 지웁니다.
- 경로에는 `/`를 쓰는 것을 권장합니다. `\`를 쓰려면 `\\`처럼 두 번 써야 합니다.
- 설정 파일이 잘못되어도 알림은 기본 문구와 기본 소리로 계속 동작합니다.

## 수정한 파일·보안 검사

답변 완료 카드에는 이번 답변에서 Claude가 고친 파일과, 깃헙에 올리기 전에 직접 확인해야 할 것이 함께 표시됩니다. 아무것도 고치지 않았고 경고도 없으면 예전처럼 간단한 카드만 뜹니다.

### 잡아내는 것

| 검사 | 대상 | 예시 |
|---|---|---|
| 코드에 직접 들어간 키 | 이번 답변에서 수정한 파일 | `sk-ant-…`, `sk-…`, `AKIA…`(AWS), `ghp_…`(GitHub), `AIza…`(Google), `xoxb-…`(Slack), `-----BEGIN PRIVATE KEY-----`, `password = "…"` |
| `.gitignore`에 없는 민감한 파일 | 프로젝트 전체 (git 저장소일 때) | `.env`, `.env.local`, `*.pem`, `*.key`, `*.p12`, `id_rsa`, `credentials.json` |
| 이미 git에 포함된 민감한 파일 | 프로젝트 전체 (git 저장소일 때) | 위와 같음 |

### 경고하지 않는 것

- `YOUR_API_KEY`, `xxxx`, `<토큰>`, `${API_KEY}`처럼 자리표시자로 보이는 값
- `os.environ[...]`, `process.env...`, `getenv(...)`처럼 환경 변수에서 읽는 코드
- `.env.example`, `.env.sample`, `.env.template` 파일
- `.env` 파일 안의 키 (키는 원래 `.env`에 두는 게 맞으므로, `.env`는 `.gitignore`에 있는지만 검사합니다)

### 한계

- **목록에 안 잡히는 파일:** 수정한 파일 목록은 Claude가 파일 편집 도구로 고친 파일만 보여 줍니다. 터미널 명령으로 만든 파일은 목록에 나오지 않습니다. 단, `.gitignore` 검사는 프로젝트 전체를 보기 때문에 그런 파일도 잡아냅니다.
- **패턴 검사의 한계:** 키는 정해진 패턴으로만 찾으므로 모든 비밀 정보를 찾아내지는 못합니다. 올리기 전에 `git diff`로 한 번 더 확인하세요.

### 끄기

`config.json`의 `Review`에서 켜고 끌 수 있습니다.

```json
"Review": {
  "changedFiles": true,
  "security": true
}
```

## 직접 수정하기

고칠 곳은 두 군데뿐입니다.

| 누가 | 파일 | 바꿀 수 있는 것 |
|---|---|---|
| **사용자** | `C:\Users\<사용자명>\.claude\notify-card\config.json` | 알림 문구, 소리(파일 또는 링크), 수정 파일·보안 검사 켜고 끄기 |
| **코드를 고쳐 쓰는 사람** | `scripts/notify-popup.ps1` 맨 위 `Design` 블록 | 카드 크기·색·글꼴·위치, 자동으로 닫히는 시간 |

### 사용자: `config.json`

플러그인을 업데이트해도 그대로 남는 내 설정입니다. 자세한 내용은 위의 [소리와 문구 바꾸기](#소리와-문구-바꾸기)를 보세요.

| 항목 | 설명 | 예시 |
|---|---|---|
| `Stop.message` | 답변 완료 알림 문구 | `"답변이 완료되었습니다"` |
| `Stop.sound` | 답변 완료 소리 | `"sounds/done.wav"`, 링크 |
| `Notification.message` | 승인·입력 대기 알림 문구 | `"Claude가 확인을 기다립니다"` |
| `Notification.sound` | 승인·입력 대기 소리 | `"sounds/attention.mp3"`, 링크 |
| `Review.changedFiles` | 수정한 파일 목록 표시 | `true` / `false` |
| `Review.security` | 키·`.env` 보안 검사 | `true` / `false` |

처음 설치했을 때 `config.json`에 `Review`가 없으면 둘 다 켜진 것으로 동작합니다.

### 코드를 고쳐 쓰는 사람: `scripts/notify-popup.ps1`

이 저장소를 포크해서 카드 모양을 바꾸려면 파일 맨 위의 `Design` 블록만 고치면 됩니다.

```powershell
$Design = @{
    Width             = 380            # 카드 너비
    Padding           = 22             # 안쪽 여백
    CornerRadius      = 14             # 모서리 둥글기
    Position          = 'Center'       # Center | TopCenter | BottomRight
    AutoCloseSeconds  = 0              # 0이면 직접 닫을 때까지 유지
    Title             = 'Claude Code'  # 카드 맨 위 제목
    Background        = '#FFFFFF'      # 배경색
    TextColor         = '#111827'      # 본문 글자색
    SubTextColor      = '#6B7280'      # 회색 글자색
    BorderColor       = '#E5E7EB'      # 테두리색
    StopColor         = '#22C55E'      # 답변 완료 점 색
    NotificationColor = '#F59E0B'      # 승인·입력 대기 점 색
    WarningColor      = '#DC2626'      # "확인 필요" 제목 색
    ReviewWidth       = 460            # 수정 파일·경고가 있을 때 카드 너비
    MaxFiles          = 6              # 이보다 많으면 "외 N개"로 줄임
    CodeFont          = 'Consolas'     # 파일 경로 글꼴
    TitleFont         = 'Segoe UI Semibold'
    TitleSize         = 9.5
    MessageFont       = 'Malgun Gothic'
    MessageSize       = 13
    DetailSize        = 9.5
}
```

그 밖의 동작을 바꾸려면 아래를 보세요.

| 바꾸고 싶은 것 | 위치 |
|---|---|
| 기본 문구, 기본 소리(소리를 지정하지 않았을 때) | `scripts/notify.ps1`의 `$defaults` |
| 처음 설치할 때 만들어지는 `config.json` 내용 | `scripts/config.template.json` |
| 찾아낼 키 패턴, 민감한 파일 이름, 경고 문구 | `scripts/review.ps1`의 `$patterns`, `$sensitive`, `Get-Review` |
| 알림을 띄울 상황(예: 서브에이전트 완료 `SubagentStop` 추가) | `hooks/hooks.json` |
| 플러그인 이름, 버전, 설명 | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |

`.ps1` 파일은 반드시 **UTF-8 (BOM 포함)** 으로 저장하세요. BOM이 없으면 한글이 깨집니다. VS Code에서는 오른쪽 아래 인코딩 표시를 눌러 `Save with Encoding` → `UTF-8 with BOM`을 고르면 됩니다.

고친 뒤에는 Claude 없이 바로 확인할 수 있습니다.

```powershell
'{"hook_event_name":"Stop","cwd":"C:\\test\\demo"}' | powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify.ps1
'{"hook_event_name":"Notification","message":"Claude needs your permission to use Bash","cwd":"C:\\test\\demo"}' | powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify.ps1
```

## 사용법

설치 후에는 따로 할 일이 없습니다. Claude Code를 평소처럼 쓰면 됩니다.

- Claude가 답변을 끝내면 초록 점 카드가 뜨고 소리가 납니다.
- Claude가 권한 승인이나 입력을 기다리면 주황 점 카드가 뜹니다.
- 카드를 닫으려면 ✕나 카드 아무 곳을 클릭하거나, `Esc` 또는 `Enter`를 누릅니다.

## 끄기·업데이트·삭제

`/plugin`을 입력해서 나오는 메뉴에서 `notify-card`를 선택하면 끄기, 업데이트, 삭제를 할 수 있습니다.

내 설정과 소리까지 지우려면 `C:\Users\<사용자명>\.claude\notify-card\` 폴더도 지웁니다.

## 문제 해결

| 증상 | 확인할 것 |
|---|---|
| 알림이 전혀 안 뜸 | `/plugin`에서 `notify-card`가 켜져 있는지 확인하고 Claude Code를 다시 시작합니다. |
| 알림이 두 번 뜸 | `settings.json`에 직접 등록한 알림 훅이 따로 있는지 확인하고 지웁니다. |
| 카드는 뜨는데 소리가 안 남 | 윈도우 볼륨을 확인합니다. |
| 내 소리 대신 기본 소리가 남 | 파일이면 `sound` 경로에 실제로 파일이 있는지 확인합니다. 링크면 브라우저에서 그 링크가 열리는지, 인터넷이 연결돼 있는지 확인합니다. |

## 라이선스

MIT

