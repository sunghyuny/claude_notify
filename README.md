# claude-notify

Claude Code가 **답변을 끝냈을 때**나 **승인·입력을 기다릴 때** 원하는 소리와 함께 화면 중앙에 알림 카드를 띄워 주는 Windows용 플러그인입니다. 다른 창에서 일하고 있어도 Claude가 끝났는지 바로 알 수 있습니다.

```
┌──────────────────────────────┐
│ ● Claude Code              ✕ │
│                              │
│ 답변이 완료되었습니다         │
│ my-project                   │
└──────────────────────────────┘
```

## 기능

- **두 가지 상황에서 알림**
  - 답변 완료: 초록 점
  - 승인·입력 대기: 주황 점. Claude가 무엇을 기다리는지도 함께 표시됩니다(예: `Claude needs your permission to use Bash`).
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
/plugin marketplace add sunghyuny/claude-notify
/plugin install claude-notify@claude-notify
```

설치가 끝나면 바로 동작합니다. 알림이 안 뜨면 Claude Code를 한 번 다시 시작해 주세요.

## 소리와 문구 바꾸기

처음 알림이 뜰 때 아래 폴더가 자동으로 만들어집니다.

```
C:\Users\<사용자명>\.claude\claude-notify\
├─ config.json   문구와 소리 설정
└─ sounds\       내 소리 파일을 넣는 곳
```

이 폴더는 플러그인을 업데이트하거나 다시 설치해도 그대로 남습니다.

### 소리 바꾸기

`sounds\` 폴더에 원하는 소리 파일을 아래 이름으로 넣으면 바로 적용됩니다.

| 상황 | 파일 이름 | 파일이 없을 때 |
|---|---|---|
| 답변 완료 | `done.wav` | 윈도우 `tada.wav` |
| 승인·입력 대기 | `attention.wav` | 윈도우 `chimes.wav` |

다른 이름이나 `.mp3` 파일을 쓰려면 `config.json`에서 `sound`를 바꿉니다.

### 문구 바꾸기

`config.json`을 메모장으로 열어 `message`를 고칩니다.

```json
{
  "Stop": {
    "message": "답변이 완료되었습니다",
    "sound": "sounds/done.wav"
  },
  "Notification": {
    "message": "Claude가 확인을 기다립니다",
    "sound": "sounds/attention.wav"
  }
}
```

- `sound`에는 `sounds/done.wav`처럼 이 폴더 기준 경로를 쓰거나, `D:/music/bell.mp3`처럼 전체 경로를 씁니다.
- 경로에는 `/`를 쓰는 것을 권장합니다. `\`를 쓰려면 `\\`처럼 두 번 써야 합니다.
- 설정 파일이 잘못되어도 알림은 기본 문구와 기본 소리로 계속 동작합니다.

## 사용법

설치 후에는 따로 할 일이 없습니다. Claude Code를 평소처럼 쓰면 됩니다.

- Claude가 답변을 끝내면 초록 점 카드가 뜨고 소리가 납니다.
- Claude가 권한 승인이나 입력을 기다리면 주황 점 카드가 뜹니다.
- 카드를 닫으려면 ✕나 카드 아무 곳을 클릭하거나, `Esc` 또는 `Enter`를 누릅니다.

## 끄기·업데이트·삭제

`/plugin`을 입력해서 나오는 메뉴에서 `claude-notify`를 선택하면 끄기, 업데이트, 삭제를 할 수 있습니다.

내 설정과 소리까지 지우려면 `C:\Users\<사용자명>\.claude\claude-notify\` 폴더도 지웁니다.

## 문제 해결

| 증상 | 확인할 것 |
|---|---|
| 알림이 전혀 안 뜸 | `/plugin`에서 `claude-notify`가 켜져 있는지 확인하고 Claude Code를 다시 시작합니다. |
| 알림이 두 번 뜸 | `settings.json`에 직접 등록한 알림 훅이 따로 있는지 확인하고 지웁니다. |
| 카드는 뜨는데 소리가 안 남 | 윈도우 볼륨을 확인합니다. |
| 내 소리 대신 기본 소리가 남 | `config.json`의 `sound` 경로에 실제로 파일이 있는지 확인합니다. |

## 라이선스

MIT

