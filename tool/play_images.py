#!/usr/bin/env python3
"""Play 스토어 그래픽을 만든다 — 피처 그래픽과 화면 비율 맞추기.

**왜 여백을 붙이는가.** Play 는 스크린샷 가로세로비를 16:9~9:16 사이로 받는다.
요즘 아이폰 화면은 1320x2868 (약 1:2.17) 이라 그 범위 밖이다. 잘라내면 키패드나
목록이 잘리므로, 화면 그대로 두고 좌우에 앱 배경색을 덧대 9:16 안으로 넣는다.
"""
import pathlib, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tool'))
from metadata import LOCALES, T  # noqa: E402

MIN_RATIO = 0.5625  # 9:16
KO_FONT = '/System/Library/Fonts/AppleSDGothicNeo.ttc'
FALLBACK = '/System/Library/Fonts/Helvetica.ttc'
SEAL = (150, 99, 0)
BG = (255, 255, 255)


def pad_to_ratio(src: Image.Image) -> Image.Image:
    """Widen with the screenshot's own background until it is within Play's range."""
    w, h = src.size
    if w / h >= MIN_RATIO:
        return src
    target_w = int(h * MIN_RATIO) + 1
    fill = src.getpixel((2, h // 2))
    out = Image.new('RGB', (target_w, h), fill)
    out.paste(src.convert('RGB'), ((target_w - w) // 2, 0))
    return out


def font(size: int):
    for path in (KO_FONT, FALLBACK):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def feature_graphic(subtitle: str) -> Image.Image:
    img = Image.new('RGB', (1024, 500), BG)
    d = ImageDraw.Draw(img)
    name_f, sub_f = font(104), font(38)
    # Wordmark and tagline stacked, left of centre — Play crops the right edge
    # on some surfaces, so nothing important goes there.
    d.text((72, 176), 'setpad', font=name_f, fill=SEAL)
    d.text((78, 306), subtitle, font=sub_f, fill=(90, 90, 95))
    d.line([(76, 292), (76 + 340, 292)], fill=(233, 185, 73), width=4)
    return img


def main():
    n_shots = n_feat = 0
    for key, (_, play_dir) in LOCALES.items():
        shot_key = {'zh-Hans': 'zhHans', 'zh-Hant': 'zhHant'}.get(key, key)
        images = ROOT / 'fastlane' / 'metadata' / 'android' / play_dir / 'images'
        phone = images / 'phoneScreenshots'
        tablet = images / 'tenInchScreenshots'
        phone.mkdir(parents=True, exist_ok=True)
        tablet.mkdir(parents=True, exist_ok=True)
        for i, shot in enumerate(('1-pad', '2-list', '3-memo', '4-dark'), start=1):
            src = ROOT / 'shots' / 'iphone' / f'{shot_key}-{shot}.png'
            if src.exists():
                pad_to_ratio(Image.open(src)).save(phone / f'{i}_{shot}.png')
                n_shots += 1
            src = ROOT / 'shots' / 'ipad' / f'{shot_key}-{shot}.png'
            if src.exists():
                pad_to_ratio(Image.open(src)).save(tablet / f'{i}_{shot}.png')
                n_shots += 1
        feature_graphic(T[key]['subtitle']).save(images / 'featureGraphic.png')
        n_feat += 1
    print(f'스크린샷 {n_shots}장, 피처 그래픽 {n_feat}장')


if __name__ == '__main__':
    main()
