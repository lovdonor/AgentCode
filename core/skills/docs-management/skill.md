# docs-management — 프로젝트 문서 라우팅 관리

프로젝트 문서는 `docs/INDEX.md`를 첫 진입점으로 관리한다. 목적은 긴 문서 요약이 아니라, 에이전트가 어떤 문서를 먼저 읽어야 하는지 즉시 판단하게 하는 것이다.

## 기본 절차

1. 문서 작업이나 코드 변경 전 `docs/INDEX.md`가 있으면 먼저 읽는다.
2. 없으면 `docs/`의 파일 목록과 각 문서의 1~3단계 heading을 확인한 뒤 `docs/INDEX.md`를 만든다.
3. 새 문서를 추가하거나 문서 성격을 바꾸면 같은 변경에서 `docs/INDEX.md`도 갱신한다.
4. 정본 문서와 보조 문서가 충돌하면 `docs/INDEX.md`의 `source_of_truth` 표시를 우선한다. 표시가 없으면 사용자에게 확인한다.

## INDEX.md 최소 구조

`docs/INDEX.md`는 다음 섹션을 유지한다.

- `읽는 순서`: 새 에이전트가 작업 시작 시 따라갈 순서.
- `Source Of Truth`: 도메인별 정본 문서, 상태, 읽는 시점.
- `문서 분류`: architecture, policy, plan, review, ops, data, scratch 등으로 구분.
- `문서 추가 규칙`: 새 문서 작성 시 index 갱신 기준.

## 상태값

문서 상태는 짧고 기계적으로 관리한다.

| 상태 | 의미 |
|---|---|
| `active` | 현재 기준으로 유효한 정본 또는 사용 문서 |
| `draft` | 작성 중이며 구현 기준으로 쓰면 안 됨 |
| `review` | 검토 결과 또는 검토 대기 문서 |
| `superseded` | 새 문서에 대체됨 |
| `archive` | 과거 기록 보존용 |
| `scratch` | 임시 메모, 입력 데이터, 정리 전 자료 |

## 분류 기준

| 종류 | 용도 |
|---|---|
| `architecture` | 시스템 구조, 데이터 모델, 책임 경계 |
| `policy` | 반드시 지켜야 하는 규범, 스케일/인코딩/안전 규칙 |
| `plan` | 구현 순서, 마일스톤, acceptance |
| `review` | 계획/구현 검토 결과 |
| `ops` | 빌드, 실행, 배포, 운영 절차 |
| `data` | 외부 입력 자료, 포트표, 샘플 데이터 |
| `scratch` | 미정리 메모 |

## 권장 frontmatter

새 Markdown 문서를 만들 때 가능하면 아래 frontmatter를 붙인다. 기존 문서에 대량 소급 적용하지 말고, 문서를 실제로 수정할 때 점진적으로 붙인다.

```yaml
---
status: active
kind: architecture
domain: marketdata
source_of_truth: true
last_reviewed: 2026-07-05
supersedes: []
related: []
---
```

## 운영 규칙

- `docs/INDEX.md`는 문서 본문을 길게 복제하지 않는다. 파일 역할과 읽는 시점만 적는다.
- index가 낡았다고 의심되면 `rg -n '^#{1,3} ' docs`로 heading을 확인하고 최소 수정한다.
- `*_ARCH.md`와 `*_IMPLEMENTATION_PLAN.md`가 모두 있으면 일반적으로 architecture를 정본, implementation plan을 작업 순서로 둔다.
- `*_REVIEW.md`는 정본이 아니라 검토 결과다. 리뷰에서 채택된 내용은 정본 문서나 계획 문서에 반영되었는지 확인한다.
- 임시 `.txt`, 샘플, 외부 자료는 `scratch` 또는 `data`로 분류하고 구현 기준으로 직접 사용하지 않는다.
- 문서 충돌이 금융 로직, 주문, 시세 스케일, IPC 계약에 영향을 주면 임의 판단하지 말고 사용자 확인을 받는다.
