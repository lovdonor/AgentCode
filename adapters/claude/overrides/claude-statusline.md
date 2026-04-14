# claude-statusline

Claude Code의 상태바(statusLine)를 커스터마이징하여 시간, 컨텍스트 사용률, 모델명, 토큰 수를 한 줄로 표시한다.

## 언제 사용하는가

사용자가 다음과 같이 요청할 때:
- "Claude 상태바를 꾸미고 싶어"
- "상태바에 토큰/모델/컨텍스트% 표시하고 싶어"
- "statusline 설정"

## 동작 방식

Claude Code는 `settings.json`의 `statusLine.command`에 지정된 명령을 주기적으로 실행하고, stdin으로 JSON을 넘긴다. stdin JSON 구조:

```json
{
  "model": { "display_name": "Opus 4.6 (1M context)" },
  "transcript_path": "C:/Users/.../session.jsonl",
  "exceeds_200k_tokens": true
}
```

스크립트는 `transcript_path`의 JSONL을 역순으로 읽어 마지막 `usage` 항목에서 토큰을 합산하고, stdout에 한 줄을 출력한다.

## 설치 절차

### 1) 스크립트 배치

`~/.claude/statusline.js` 에 아래 내용을 작성한다:

```js
#!/usr/bin/env node
// Claude Code statusline: time | context% | model | tokens
const fs = require('fs');

const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const model = input?.model?.display_name || 'N/A';
const transcript = input?.transcript_path || '';

const limit = (input?.exceeds_200k_tokens || /1M/.test(model)) ? 1_000_000 : 200_000;

let tokens = 0;
if (transcript && fs.existsSync(transcript)) {
  const lines = fs.readFileSync(transcript, 'utf8').split(/\r?\n/);
  for (let i = lines.length - 1; i >= 0; i--) {
    if (!lines[i] || !lines[i].includes('"usage"')) continue;
    try {
      const obj = JSON.parse(lines[i]);
      const u = obj?.message?.usage || obj?.usage;
      if (u) {
        tokens = (u.input_tokens || 0)
               + (u.cache_read_input_tokens || 0)
               + (u.cache_creation_input_tokens || 0)
               + (u.output_tokens || 0);
        break;
      }
    } catch {}
  }
}

const pct = ((tokens / limit) * 100).toFixed(1);
const fmtTokens = n =>
  n >= 1_000_000 ? (n / 1_000_000).toFixed(2) + 'M'
  : n >= 1_000   ? (n / 1_000).toFixed(1) + 'k'
  :               String(n);

const now = new Date();
const hh = String(now.getHours()).padStart(2, '0');
const mm = String(now.getMinutes()).padStart(2, '0');
const ss = String(now.getSeconds()).padStart(2, '0');

process.stdout.write(`${hh}:${mm}:${ss} | Context: ${pct}% | Model: ${model} | Tokens: ${fmtTokens(tokens)}\n`);
```

### 2) settings.json 연동

`~/.claude/settings.json` 에 다음 블록을 추가(또는 병합)한다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js",
    "refreshInterval": 5
  }
}
```

### 3) 적용

Claude Code를 재시작한다. 하단 상태바에 다음과 같이 표시된다:

```
14:23:05 | Context: 12.3% | Model: Opus 4.6 (1M context) | Tokens: 123.4k
```

## 커스터마이징 포인트

- **컨텍스트 한도**: `exceeds_200k_tokens` 또는 모델명에 `1M` 포함 시 1M, 그 외 200k. 다른 한도를 쓴다면 `limit` 계산식을 고친다.
- **표시 항목 추가**: git 브랜치, 작업 디렉터리, 비용 등은 stdin JSON 추가 필드나 외부 명령(`git symbolic-ref`)을 호출해 덧붙일 수 있다.
- **색상**: ANSI escape(`\x1b[36m` 등)로 색을 넣을 수 있다. Windows 터미널에서 호환 확인 필요.
- **갱신 주기**: `refreshInterval`(초). 너무 짧으면 깜빡임, 너무 길면 지연.

## 주의사항

- stdin을 반드시 JSON으로 파싱해야 한다. `fs.readFileSync(0, 'utf8')`가 동기 방식으로 stdin을 읽는 관용적 패턴.
- 출력은 **한 줄**만 한다. 여러 줄을 출력하면 상태바가 깨진다.
- transcript 파일이 수백 MB까지 커질 수 있으므로 `역순 라인 스캔`으로 최신 usage만 찾는 것이 핵심. 전체 JSON.parse 금지.
- Windows에서 `~/.claude/...` 경로는 Node가 해석하지 못할 수 있다. 필요 시 `%USERPROFILE%` 또는 절대경로를 사용한다. 테스트된 환경에서는 `node ~/.claude/statusline.js`가 동작함.
- `settings.json`을 수정하므로 기존 설정을 덮어쓰지 말고 `statusLine` 키만 병합할 것.

## 검증

설치 후 Claude Code를 재시작하고 하단에 한 줄이 보이는지 확인한다. 값이 `N/A`로 뜨거나 토큰이 0으로만 나오면:

1. `node ~/.claude/statusline.js <<< '{}'` 로 직접 실행해 에러 확인
2. `transcript_path`가 실제로 존재하는지 확인
3. `settings.json`의 JSON 문법 확인
