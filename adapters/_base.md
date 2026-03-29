# 공통 에이전트 규칙

## 프로젝트 개요

본 프로젝트는 한국 금융권(KRX 연동) 하이브리드 OMS(Order Management System)이다.
CPU/FPGA 혼합 아키텍처 기반 주문 처리 시스템과 WPF 기반 트레이딩 UI로 구성된다.

## 핵심 원칙

1. **안전 최우선** — 금융 시스템이므로 모든 변경은 안전성 검증을 우선한다.
2. **단일 진실 소스** — 공통 정책·스킬은 `.ai/core/`에만 존재한다.
3. **점진적 변경** — 대규모 리팩토링보다 작고 검증 가능한 변경을 선호한다.
4. **인코딩 주의** — KRX 인터페이스는 EUC-KR(CP949), 내부 코드는 UTF-8. 경계에서 반드시 변환한다.

## 정책 참조

`.ai/core/policies/` 아래 정책을 숙지하고 모든 작업에 적용한다:

- `coding-standards.md` — 코딩 규약, 네이밍 컨벤션
- `architecture-rules.md` — 레이어 구조, 의존성 방향
- `testing-policy.md` — 테스트 커버리지 기준, 필수 테스트 유형
- `safety-rules.md` — 금융 안전 규칙, 주문 검증 체크리스트
- `repo-map.md` — 디렉토리 구조 및 모듈 설명

## 스킬 참조

작업 유형에 맞는 스킬이 있으면 `.ai/core/skills/<name>/skill.md`를 참조한다.
각 스킬의 `manifest.yaml`에 트리거 조건과 의존 정책이 선언되어 있다.
