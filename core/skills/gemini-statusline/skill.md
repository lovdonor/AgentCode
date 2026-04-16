# gemini-statusline

Gemini CLI의 하단 상태바(footer)를 설정하여 컨텍스트 사용량, 토큰 수, 모델 정보를 표시한다.

## 언제 사용하는가

사용자가 다음과 같이 요청할 때:
- "Gemini 상태바를 설정해줘"
- "컨텍스트 사용량을 보고 싶어"
- "상태바에 토큰 정보를 표시해줘"

## 동작 방식

Gemini CLI는 `settings.json`의 `ui.footer` 설정을 통해 하단 상태바의 컴포넌트를 제어한다. 별도의 외부 스크립트 없이 내장 기능을 활용하여 실시간 컨텍스트 정보를 노출한다.

## 설정 절차

### 1) settings.json 수정

`~/.gemini/settings.json` (또는 프로젝트 루트의 `.gemini/settings.json`)에 아래 설정을 추가하거나 병합한다. 하드코딩된 프로젝트 이름 대신 CWD(현재 작업 디렉토리)를 동적으로 표시하도록 구성한다.

```json
{
  "ui": {
    "footer": {
      "hideCWD": false,
      "hideModelInfo": false,
      "hideContextPercentage": false,
      "showLabels": true,
      "items": ["cwd", "model", "context-percentage", "sandbox-status"]
    },
    "dynamicWindowTitle": true
  }
}
```

### 2) 표시 항목 설명

- **cwd**: 현재 프로젝트 디렉토리명을 표시 (하드코딩 방지)
- **model**: 사용 중인 모델명과 현재 소모된 **입력/출력 토큰 수** 표시
- **context-percentage**: 전체 컨텍스트 윈도우(예: 1M, 2M) 대비 **현재 사용 중인 컨텍스트 비율(%)** 표시
- **sandbox-status**: 현재 샌드박스 보안 상태 표시

## 커스터마이징 포인트

- **라벨 숨기기**: 라벨(예: /model)이 너무 길면 `showLabels: false`로 설정하여 수치만 간결하게 표시할 수 있다.
- **순서 변경**: `items` 배열의 순서를 조정하여 상태바의 배치 순서를 바꿀 수 있다.

## 검증

Gemini CLI를 실행하거나 `/settings reload` 명령을 실행한 후, 하단 푸터에 다음과 같은 형식의 정보가 실시간으로 업데이트되는지 확인한다.

`[Mirage] /model gemini-2.0-flash-exp (1.2k tokens) /context 0.1%`
