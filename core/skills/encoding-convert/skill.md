# 스킬: encoding-convert — EUC-KR ↔ UTF-8 인코딩 변환

## 개요

파일의 인코딩을 감지하고, EUC-KR(CP949) ↔ UTF-8 간 변환을 수행한다.
이 스킬의 스크립트는 `.ai/core/skills/encoding-convert/scripts/` 에 위치한다.

---

## 사전 요구사항

- Python 3.6 이상
- `chardet` 라이브러리 (`pip install chardet`)

---

## 작업 절차

### 1단계 — 인코딩 감지

변환 전 반드시 대상 파일의 인코딩을 먼저 확인한다.

```bash
python .ai/core/skills/encoding-convert/scripts/detect.py <파일_또는_디렉토리>
```

**출력 예시:**
```
파일                     감지 인코딩     신뢰도
src/order.c              EUC-KR          99%
src/main.cpp             UTF-8           95%
src/legacy/trade.h       CP949           97%
```

### 2단계 — 인코딩 변환

```bash
# 단일 파일: EUC-KR → UTF-8
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 <파일경로>

# 단일 파일: UTF-8 → EUC-KR
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from utf-8 --to euc-kr <파일경로>

# 디렉토리 일괄 변환 (재귀)
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 --recursive <디렉토리경로>

# 확장자 필터 적용
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 --recursive --ext .c .h .cpp \
    <디렉토리경로>

# 드라이런 (실제 변환 없이 대상 파일 목록만 확인)
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 --recursive --dry-run \
    <디렉토리경로>
```

---

## 판단 기준

| 상황 | 조치 |
|------|------|
| 신뢰도 < 70% | 사용자에게 인코딩을 직접 확인 요청 |
| 신뢰도 70~89% | 변환 전 사용자에게 확인 요청 |
| 신뢰도 ≥ 90% | 자동 변환 진행 가능 |
| ASCII 전용 파일 | 변환 불필요. 건너뜀 |
| Binary 파일 | 변환 금지. 건너뜀 |

---

## 안전 규칙

1. **백업 우선** — 변환 전 반드시 원본 파일을 백업한다.
   스크립트는 `.bak` 확장자로 자동 백업을 생성한다.
2. **드라이런 먼저** — 대량 일괄 변환 시 `--dry-run`으로 대상을 먼저 확인한다.
3. **git 상태 확인** — git 저장소 내 파일 변환 시, 변환 후 `git diff` 로 변경 범위를 검토한다.
4. **BOM 주의** — UTF-8 BOM(BOM이 있는 UTF-8)은 `--strip-bom` 옵션으로 제거할 수 있다.
5. **이진 파일 제외** — `.exe`, `.dll`, `.obj`, `.lib`, `.png`, `.jpg` 등 이진 파일은 자동 스킵된다.

---

## 에러 처리

| 에러 | 원인 | 대처 |
|------|------|------|
| `UnicodeDecodeError` | 감지 인코딩이 실제와 다름 | `--from` 인코딩을 수동 지정 |
| `PermissionError` | 파일 잠금(열려 있거나 읽기 전용) | 파일 닫은 후 재시도 |
| `chardet` 미설치 | 라이브러리 누락 | `pip install chardet` 실행 |

---

## 변환 후 검증

변환 완료 후 아래 절차로 결과를 검증한다:

```bash
# 1. 변환 결과 인코딩 재확인
python .ai/core/skills/encoding-convert/scripts/detect.py <변환된_파일>

# 2. git 저장소라면 diff 확인
git diff --stat

# 3. 한글 샘플 출력으로 육안 확인
python -c "print(open('<파일>', encoding='utf-8').read()[:200])"
```

---

## 사용 예시 (실전)

### KRX 레거시 C 소스 (EUC-KR) → UTF-8 마이그레이션

```bash
# 1. 전체 src/ 디렉토리 인코딩 감지
python .ai/core/skills/encoding-convert/scripts/detect.py src/

# 2. 드라이런으로 변환 대상 확인
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 --recursive --ext .c .h \
    --dry-run src/

# 3. 실제 변환 실행
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from euc-kr --to utf-8 --recursive --ext .c .h src/

# 4. 결과 검증
python .ai/core/skills/encoding-convert/scripts/detect.py src/
git diff --stat
```

### KRX 인터페이스 전송용 UTF-8 → EUC-KR 변환

```bash
python .ai/core/skills/encoding-convert/scripts/convert.py \
    --from utf-8 --to euc-kr output/krx_message.txt
```
