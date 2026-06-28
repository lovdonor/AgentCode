<!--
  이 파일을 프로젝트의 .ai-local/policies/agent-knowledge.md 로 복사하고
  '위치' 경로를 그 PC의 실제 AgentKnowledge repo 경로로 수정한다.
  generate.sh 가 이 내용을 "프로젝트 전용 규칙" 섹션으로 컨텍스트에 병합한다.
-->
## 경험 지식 베이스 (AgentKnowledge)

- 위치: `/home/fpga/workspace/AgentKnowledge/`   ← 이 PC의 단일 원본 (실제 경로로 수정)
- 읽기: 어떤 작업을 시작할 때 위치의 `INDEX.md`에서 하려는 작업을 `task`로 매칭 → entry 1개만 열고 「올바른 방법」부터. (막혔을 땐 `symptoms`로도)
- 쓰기: 어려운 작업을 한 번에 해낸 뒤 "KB로 정리"가 오면 위치의 `templates/entry-template.md`로 가이드 entry 작성 후 `python3 scripts/build_index.py`.
- 전체 프로토콜·스키마: 위치의 `AGENTS.md` (단일 진실원본).
