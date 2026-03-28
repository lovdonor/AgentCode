#!/usr/bin/env python3
"""
convert.py — 파일 또는 디렉토리의 인코딩을 변환한다.
EUC-KR(CP949) ↔ UTF-8 양방향 변환 지원.

사용법:
    # 단일 파일 변환
    python convert.py --from euc-kr --to utf-8 <파일경로>

    # 디렉토리 일괄 변환 (재귀)
    python convert.py --from euc-kr --to utf-8 --recursive <디렉토리>

    # 확장자 필터 + 드라이런
    python convert.py --from euc-kr --to utf-8 --recursive --ext .c .h --dry-run <디렉토리>

    # UTF-8 BOM 제거 포함
    python convert.py --from utf-8 --to utf-8 --strip-bom <파일경로>

의존성:
    pip install chardet
"""

import sys
import os
import shutil
import argparse
import chardet

# 이진 파일로 간주하여 변환에서 제외할 확장자
BINARY_EXTENSIONS = {
    '.exe', '.dll', '.obj', '.lib', '.pdb', '.ilk',
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico',
    '.zip', '.gz', '.tar', '.7z', '.rar',
    '.bin', '.dat', '.hex',
}

# 지원 인코딩 별칭 정규화 테이블
ENCODING_ALIASES = {
    'euc-kr':  'euc-kr',
    'euckr':   'euc-kr',
    'cp949':   'cp949',
    'ms949':   'cp949',
    'utf-8':   'utf-8',
    'utf8':    'utf-8',
    'utf-8-bom': 'utf-8-sig',
    'utf8bom': 'utf-8-sig',
}


def normalize_encoding(enc: str) -> str:
    """인코딩 이름을 정규화한다."""
    key = enc.lower().replace(' ', '')
    normalized = ENCODING_ALIASES.get(key)
    if normalized is None:
        print(f'[오류] 지원하지 않는 인코딩: {enc}', file=sys.stderr)
        print(f'  지원 목록: {", ".join(ENCODING_ALIASES.keys())}', file=sys.stderr)
        sys.exit(1)
    return normalized


def is_binary(filepath: str) -> bool:
    """파일이 이진 파일인지 확인한다."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext in BINARY_EXTENSIONS:
        return True
    # 내용 기반 이진 판별 (첫 8KB 검사)
    try:
        with open(filepath, 'rb') as f:
            chunk = f.read(8192)
        # NULL 바이트가 있으면 이진 파일로 간주
        return b'\x00' in chunk
    except Exception:
        return True


def detect_encoding(filepath: str) -> str | None:
    """파일의 인코딩을 자동 감지한다. 감지 실패 시 None 반환."""
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except Exception:
        return None

    # BOM 확인
    if raw.startswith(b'\xef\xbb\xbf'):
        return 'utf-8-sig'

    result = chardet.detect(raw)
    enc = result.get('encoding')
    confidence = result.get('confidence', 0)

    if enc is None or confidence < 0.7:
        return None
    return enc


def convert_file(
    filepath: str,
    from_enc: str,
    to_enc: str,
    strip_bom: bool = False,
    dry_run: bool = False,
    backup: bool = True,
) -> dict:
    """
    단일 파일의 인코딩을 변환한다.

    Returns:
        dict: {'status': 'ok'|'skip'|'error', 'message': str}
    """
    if is_binary(filepath):
        return {'status': 'skip', 'message': '이진 파일 — 건너뜀'}

    if dry_run:
        return {'status': 'ok', 'message': f'[드라이런] {from_enc} → {to_enc} 변환 예정'}

    # 원본 읽기
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except PermissionError:
        return {'status': 'error', 'message': '권한 없음 — 파일을 열 수 없음'}

    if len(raw) == 0:
        return {'status': 'skip', 'message': '빈 파일 — 건너뜀'}

    # 디코딩
    try:
        text = raw.decode(from_enc)
    except (UnicodeDecodeError, LookupError) as e:
        return {'status': 'error', 'message': f'디코딩 실패 ({from_enc}): {e}'}

    # BOM 제거 옵션
    if strip_bom and text.startswith('\ufeff'):
        text = text[1:]

    # 인코딩
    try:
        encoded = text.encode(to_enc)
    except (UnicodeEncodeError, LookupError) as e:
        return {'status': 'error', 'message': f'인코딩 실패 ({to_enc}): {e}'}

    # 백업 생성
    if backup:
        backup_path = filepath + '.bak'
        try:
            shutil.copy2(filepath, backup_path)
        except Exception as e:
            return {'status': 'error', 'message': f'백업 실패: {e}'}

    # 변환 결과 저장
    try:
        with open(filepath, 'wb') as f:
            f.write(encoded)
    except PermissionError:
        # 백업에서 원본 복원 시도
        if backup:
            shutil.copy2(filepath + '.bak', filepath)
        return {'status': 'error', 'message': '파일 쓰기 실패 — 원본 복원됨'}

    return {'status': 'ok', 'message': f'{from_enc} → {to_enc} 변환 완료'}


def collect_files(path: str, extensions: list, recursive: bool) -> list:
    """변환 대상 파일 목록을 수집한다."""
    files = []
    if os.path.isfile(path):
        files.append(path)
    elif os.path.isdir(path):
        if recursive:
            for root, _, filenames in os.walk(path):
                for fname in filenames:
                    fpath = os.path.join(root, fname)
                    ext = os.path.splitext(fname)[1].lower()
                    if extensions and ext not in extensions:
                        continue
                    files.append(fpath)
        else:
            for fname in os.listdir(path):
                fpath = os.path.join(path, fname)
                if not os.path.isfile(fpath):
                    continue
                ext = os.path.splitext(fname)[1].lower()
                if extensions and ext not in extensions:
                    continue
                files.append(fpath)
    else:
        print(f'[오류] 경로를 찾을 수 없음: {path}', file=sys.stderr)
        sys.exit(1)
    return sorted(files)


def main():
    parser = argparse.ArgumentParser(
        description='파일의 인코딩을 EUC-KR ↔ UTF-8 간 변환한다.'
    )
    parser.add_argument('path', help='변환할 파일 또는 디렉토리 경로')
    parser.add_argument('--from', dest='from_enc', required=True,
                        help='원본 인코딩 (euc-kr | cp949 | utf-8 | utf-8-bom)')
    parser.add_argument('--to', dest='to_enc', required=True,
                        help='대상 인코딩 (euc-kr | cp949 | utf-8 | utf-8-bom)')
    parser.add_argument('--ext', nargs='+', metavar='EXT',
                        help='처리할 확장자 필터 (예: .c .h .cpp)')
    parser.add_argument('--recursive', action='store_true',
                        help='디렉토리 재귀 처리')
    parser.add_argument('--dry-run', action='store_true',
                        help='실제 변환 없이 대상 목록만 출력')
    parser.add_argument('--no-backup', action='store_true',
                        help='백업 파일(.bak) 생성 안 함 (주의: 원본 손실 위험)')
    parser.add_argument('--strip-bom', action='store_true',
                        help='UTF-8 BOM(\\xEF\\xBB\\xBF) 제거')
    args = parser.parse_args()

    from_enc = normalize_encoding(args.from_enc)
    to_enc = normalize_encoding(args.to_enc)
    extensions = [e.lower() if e.startswith('.') else f'.{e.lower()}'
                  for e in (args.ext or [])]
    backup = not args.no_backup

    files = collect_files(args.path, extensions, args.recursive)

    if not files:
        print('대상 파일이 없습니다.')
        return

    if args.dry_run:
        print(f'\n[드라이런] {from_enc} → {to_enc} 변환 대상 파일:\n')

    # 통계
    count_ok = 0
    count_skip = 0
    count_error = 0

    for filepath in files:
        display_path = os.path.relpath(filepath, start=os.path.dirname(args.path))
        result = convert_file(
            filepath,
            from_enc=from_enc,
            to_enc=to_enc,
            strip_bom=args.strip_bom,
            dry_run=args.dry_run,
            backup=backup,
        )

        status = result['status']
        msg = result['message']

        if status == 'ok':
            status_icon = '✓'
            count_ok += 1
        elif status == 'skip':
            status_icon = '-'
            count_skip += 1
        else:
            status_icon = '✗'
            count_error += 1

        print(f'{status_icon} {display_path:<60} {msg}')

    # 요약 출력
    print()
    print(f'완료: {count_ok}개  건너뜀: {count_skip}개  오류: {count_error}개')

    if not args.dry_run and backup and count_ok > 0:
        print(f'백업 파일(.bak)이 원본과 같은 경로에 생성되었습니다.')
        print(f'백업 제거: Get-ChildItem -Recurse -Filter "*.bak" | Remove-Item  (PowerShell)')
        print(f'           find . -name "*.bak" -delete  (bash)')

    if count_error > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
