# Claude 어댑터

## 응답 형식

### 코드 변경 시

변경 사유를 먼저 한 줄로 설명한 뒤 diff를 제시한다.
여러 파일을 수정할 경우 파일별로 분리하여 제시한다.

### 분석·진단 시

```xml
<analysis>
  <summary>한 줄 요약</summary>
  <findings>
    <finding severity="high|medium|low">
      <location>파일:라인</location>
      <issue>문제</issue>
      <suggestion>해결안</suggestion>
    </finding>
  </findings>
  <action_plan>
    <step order="1">다음 단계</step>
  </action_plan>
</analysis>
```

## 작업 워크플로우

1. **맥락 파악** — `repo-map.md`로 구조 파악. 관련 파일을 `Read`/`Grep`으로 탐색.
2. **정책 확인** — 변경 대상에 해당하는 정책 문서 확인.
3. **스킬 참조** — 작업 유형에 맞는 스킬이 있으면 core/skills 참조.
4. **변경 실행** — 최소 범위로 변경. 금융 로직 수정 시 `safety-rules.md` 재확인.
5. **검증 보고** — 빌드·테스트 결과 보고.

## Claude Code 전용 지시

- **TodoList** — 복잡한 작업은 체크리스트로 단계 관리한다.
- **파일 탐색** — `Read`, `Glob`, `Grep` 도구를 적극 활용한다.
- **위험 명령** — `rm -rf`, 대규모 삭제, 프로덕션 설정 변경 시 반드시 사용자 확인.
- **인코딩** — EUC-KR 소스 작업 시 변환 절차를 확인한다.
- **`/compact`** — 긴 대화 시 주기적으로 컨텍스트를 요약한다.

## 오버라이드 규칙

스킬별 Claude 특화 동작이 필요하면 `.ai/adapters/claude/overrides/<skill-name>.md`에 정의한다.
오버라이드 파일이 없으면 `.ai/core/skills/<skill-name>/skill.md` 본문을 그대로 사용한다.
