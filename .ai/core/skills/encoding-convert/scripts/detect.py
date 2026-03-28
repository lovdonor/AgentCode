#!/usr/bin/env python3
"""
detect.py — 파일 또는 디렉토리의 인코딩을 감지한다.

사용법:
    python detect.py <파일_또는_디렉토리> [--ext .c .h ...]

의존성:
    pip install chardet
"""

import sys
import os
import argparse
import chardet

# 이진 파일로 간주하여 건너뛸 확장자
BINARY_EXTENSIONS = {
    '.exe', '.dll', '.obj', '.lib', '.pdb', '.ilk',
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico',
    '.zip', '.gz', '.tar', '.7z', '.rar',
    '.bin', '.dat', '.hex',
}


def detect_file(filepath: str) -> dict:
    """단일 파일의 인코딩 정보를 반환한다."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext in BINARY_EXTENSIONS:
        return {'file': filepath, 'encoding': 'BINARY', 'confidence': None, 'skip': True}

    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except PermissionError:
        return {'file': filepath, 'encoding': 'ERROR(권한없음)', 'confidence': None, 'skip': True}

    if len(raw) == 0:
        return {'file': filepath, 'encoding': 'EMPTY', 'confidence': None, 'skip': True}

    # BOM 확인
    if raw.startswith(b'\xef\xbb\xbf'):
        return {'file': filepath, 'encoding': 'UTF-8-BOM', 'confidence': 1.0, 'skip': False}
    if raw.startswith(b'\xff\xfe'):
        return {'file': filepath, 'encoding': 'UTF-16-LE', 'confidence': 1.0, 'skip': False}
    if raw.startswith(b'\xfe\xff'):
        return {'file': filepath, 'encoding': 'UTF-16-BE', 'confidence': 1.0, 'skip': False}

    result = chardet.detect(raw)
    return {
        'file': filepath,
        'encoding': (result.get('encoding') or 'UNKNOWN').upper(),
        'confidence': result.get('confidence', 0.0),
        'skip': False,
    }


def collect_files(path: str, extensions: list) -> list:
    """경로에서 처리 대상 파일 목록을 수집한다."""
    files = []
    if os.path.isfile(path):
        files.append(path)
    elif os.path.isdir(path):
        for root, _, filenames in os.walk(path):
            for fname in filenames:
                fpath = os.path.join(root, fname)
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
        description='파일 또는 디렉토리의 인코딩을 감지한다.'
    )
    parser.add_argument('path', help='감지할 파일 또는 디렉토리 경로')
    parser.add_argument(
        '--ext', nargs='+', metavar='EXT',
        help='처리할 확장자 필터 (예: .c .h .cpp). 미지정 시 전체 파일 처리'
    )
    args = parser.parse_args()

    extensions = [e.lower() if e.startswith('.') else f'.{e.lower()}' for e in (args.ext or [])]
    files = collect_files(args.path, extensions)

    if not files:
        print('대상 파일이 없습니다.')
        return

    # 헤더 출력
    print(f'\n{"파일":<55} {"인코딩":<16} {"신뢰도"}')
    print('-' * 85)

    low_confidence = []
    for filepath in files:
        info = detect_file(filepath)
        display_path = os.path.relpath(filepath, start=os.path.dirname(args.path))

        if info['skip']:
            print(f'{display_path:<55} {info["encoding"]:<16} (건너뜀)')
            continue

        confidence_str = f'{info["confidence"] * 100:.0f}%' if info['confidence'] is not None else '-'
        print(f'{display_path:<55} {info["encoding"]:<16} {confidence_str}')

        # 신뢰도 낮은 파일 수집 (경고용)
        if info['confidence'] is not None and info['confidence'] < 0.9:
            low_confidence.append(info)

    print()

    # 신뢰도 낮은 파일 경고
    if low_confidence:
        print('[경고] 신뢰도 90% 미만 파일 — 변환 전 수동 확인 권장:')
        for info in low_confidence:
            conf_str = f'{info["confidence"] * 100:.0f}%' if info['confidence'] else '-'
            print(f'  - {info["file"]}  ({info["encoding"]}, {conf_str})')
        print()


if __name__ == '__main__':
    main()
