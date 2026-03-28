# AI Rules — 멀티 에이전트 공유 규칙 저장소

## 구조

```
.ai/
├── core/                    # 단일 진실 소스 (모델 무관)
│   ├── policies/            # 코딩 규약, 아키텍처, 테스트, 안전 규칙
│   ├── skills/              # 스킬 본문 + manifest.yaml
│   │   └── <skill-name>/
│   │       ├── manifest.yaml
│   │       ├── skill.md
│   │       ├── checklist.md (선택)
│   │       └── scripts/     (선택)
│   └── templates/           # plan, PR, report 등 템플릿
│
├── adapters/                # 모델별 어댑터
│   ├── _base.md             # 공통 프리앰블
│   ├── claude/
│   │   ├── preamble.md      # Claude 전용 지시
│   │   └── overrides/       # 스킬별 오버라이드 (필요한 것만)
│   ├── codex/
│   │   ├── preamble.md
│   │   └── overrides/
│   └── gemini/
│       ├── preamble.md
│       └── overrides/
│
└── scripts/
    └── generate.sh          # 루트 CLAUDE.md/AGENTS.md/GEMINI.md 생성
```

## 사용법

### 전체 생성
```bash
.ai/scripts/generate.sh
```

### 특정 모델만
```bash
.ai/scripts/generate.sh claude
```

### 프로젝트에 submodule로 추가
```bash
cd my-project
git submodule add git@github.com:yourorg/ai-rules.git .ai
.ai/scripts/generate.sh
git add CLAUDE.md AGENTS.md GEMINI.md
```

### 프로젝트 전용 규칙 추가
프로젝트 레포에 `.ai-local/` 디렉토리를 만들면 generate.sh가 자동으로 머지한다:
```
my-project/
├── .ai          → submodule (이 레포)
├── .ai-local/   → 프로젝트 전용 (프로젝트 레포에 커밋)
│   ├── policies/
│   └── skills/
├── CLAUDE.md    → 생성됨
└── ...
```

## 규칙

- **스킬 추가**: `core/skills/<n>/` 에 `manifest.yaml` + `skill.md` 작성
- **오버라이드 추가**: `adapters/<model>/overrides/<skill-name>.md` 작성 (필요할 때만)
- **루트 파일 직접 수정 금지**: 항상 `generate.sh`로 재생성
