#!/usr/bin/env python3
"""setpad 아이콘 일습을 다시 만든다.

    python3 tool/icon.py            # 프로젝트 아이콘 전부 갱신
    python3 tool/icon.py --store    # 스토어 등록용 1024/512 도 함께

**왜 스크립트인가.** 아이콘이 iOS 15개 + Android 레거시 5개 + adaptive
foreground 5개 + 런치 이미지 3개로 28장이다. 색 하나 바꾸려고 28장을 손으로
다시 만들 수는 없다. 마크가 코드로 정의돼 있으면 인주색을 바꾸든 숫자를
바꾸든 한 번 돌리면 끝난다.

**마크가 왜 이 모양인가.** 화면에 실제로 찍히는 표기 그대로다 —
editor.dart 의 입력 힌트가 '100  20' 이고 keypad.dart 에 스페이스 키가
숫자키와 나란히 있다. 무게와 횟수를 스페이스로 갈라 쳐 내려가는 앱이라는
뜻이고, 거기에 텍스트 커서를 붙인 것이 이 마크다. 루틴을 짜는 앱이 아니라
쳐서 기록하는 앱이라는 차이가 아이콘에 그대로 있어야 한다.

Pillow 가 필요하다: pip3 install Pillow
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SS = 4                                     # 수퍼샘플링 배율
SEAL = (0xC3, 0x37, 0x2A, 255)             # 인주색 — lib/main.dart 의 _seal
WHITE = (255, 255, 255, 255)
MONO = '/System/Library/Fonts/Menlo.ttc'   # index 1 = Bold. 앱의 monospace 와 결을 맞춘다
GREY = (0.9137, 0.9137, 0.9255)            # #E9E9EC — scaffoldBackgroundColor


def draw(size, *, scale=1.0, transparent=False):
    """'80▮' 마크 — 무게 한 줄과 텍스트 커서.

    두 줄('100' 위 '10▮')이던 것을 한 줄로 줄였다. 홈 화면 크기(80px 안팎)
    에서 두 줄은 뭉쳐 읽히고, 숫자가 둘이면 계산기처럼 보인다. 한 줄이면
    '80'이 무게로 읽히고, 뒤에 붙은 커서가 "여기다 친다"를 말한다.
    """
    im = Image.new('RGBA', (size * SS, size * SS), (0, 0, 0, 0) if transparent else SEAL)
    d = ImageDraw.Draw(im)
    u = size / 1024.0 * SS                 # 1024 기준 좌표 → 실제 픽셀
    f = ImageFont.truetype(MONO, int(390 * u * scale), index=1)
    l, t, r, b = d.textbbox((0, 0), '80', font=f)
    tw, th = r - l, b - t
    cursor, gap = 118 * u * scale, 34 * u * scale
    ox = (size * SS - (tw + gap + cursor)) / 2
    oy = (size * SS - th) / 2
    d.text((ox - l, oy - t), '80', font=f, fill=WHITE)
    cx = ox + tw + gap
    d.rounded_rectangle([cx, oy, cx + cursor, oy + th], radius=20 * u * scale, fill=WHITE)
    return im.resize((size, size), Image.LANCZOS)


def app_icons():
    """iOS 는 Contents.json 이 요구하는 크기를 그대로 만든다."""
    ios = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    wanted = {}
    for i in json.loads((ios / 'Contents.json').read_text())['images']:
        px = round(float(i['size'].split('x')[0]) * float(i['scale'].rstrip('x')))
        wanted[i['filename']] = max(wanted.get(i['filename'], 0), px)
    for name, px in wanted.items():
        # 앱스토어는 1024 에 알파가 있으면 거부한다 → 전부 RGB 로 저장
        draw(px).convert('RGB').save(ios / name)
    print(f'iOS 아이콘 {len(wanted)}개')

    for dens, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        draw(px).convert('RGB').save(ROOT / f'android/app/src/main/res/mipmap-{dens}/ic_launcher.png')
    print('Android 레거시 아이콘 5개')


def adaptive():
    """adaptive 레이어는 108dp 인데 72dp 만 보인다. iOS 타일과 같은 시각
    비율이 되도록 그 비율(72/108)만 채운다 — 66dp 안전원 안쪽이다."""
    res = ROOT / 'android/app/src/main/res'
    for dens, px in {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}.items():
        draw(px, transparent=True, scale=0.667).save(res / f'mipmap-{dens}/ic_launcher_foreground.png')
    print('Android adaptive foreground 5개')


def launch():
    """런치 화면은 시스템이 마스킹해주지 않으므로 모서리를 직접 둥글린다."""
    li = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for scale, name in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
        px = 120 * scale
        im = draw(px).convert('RGBA')
        m = Image.new('L', (px * 4, px * 4), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=int(px * 4 * 0.225), fill=255)
        im.putalpha(m.resize((px, px), Image.LANCZOS))
        im.save(li / name)
    print('런치 이미지 3개')


def store():
    out = ROOT / 'build/store'
    out.mkdir(parents=True, exist_ok=True)
    draw(1024).convert('RGB').save(out / 'ios-1024.png')
    draw(512).convert('RGB').save(out / 'play-512.png')
    print(f'스토어용 자산 → {out}')


if __name__ == '__main__':
    app_icons(); adaptive(); launch()
    if '--store' in sys.argv:
        store()
