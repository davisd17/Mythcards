"""Normalize isolated object artwork for consistent Godot tile placement."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TYPES = ["barricade", "pylon", "stone", "vault", "leak"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="JSON mapping object types to source PNGs")
    args = parser.parse_args()
    sources = json.loads(args.manifest.read_text(encoding="utf-8"))
    output = ROOT / "game/assets/objects"
    review = ROOT / "docs/art-specs/placed-objects"
    output.mkdir(parents=True, exist_ok=True)
    (review / "sources").mkdir(parents=True, exist_ok=True)
    proof = Image.new("RGB", (1200, 310), "#263632")
    draw = ImageDraw.Draw(proof)
    for index, kind in enumerate(TYPES):
        path = Path(sources[kind])
        image = Image.open(path).convert("RGBA")
        image.putalpha(image.getchannel("A").point(lambda a: a if a >= 16 else 0))
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Empty source: {kind}")
        sprite = image.crop(bounds)
        max_height = 440 if kind == "pylon" else (280 if kind == "leak" else 320)
        scale = min(460 / sprite.width, max_height / sprite.height)
        sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (512, 512))
        x = (512 - sprite.width) // 2
        y = (512 - sprite.height) // 2 if kind == "leak" else 470 - sprite.height
        canvas.alpha_composite(sprite, (x, y))
        canvas.save(output / f"{kind}.png", optimize=True)
        (review / "sources" / f"{kind}.png").write_bytes(path.read_bytes())
        draw.text((index * 240 + 14, 12), kind.upper(), fill="#f1e6ca")
        large = canvas.resize((220, 220), Image.Resampling.LANCZOS)
        proof.paste(large, (index * 240 + 10, 35), large)
        small = canvas.resize((56, 56), Image.Resampling.LANCZOS)
        proof.paste(small, (index * 240 + 92, 250), small)
        print(kind, canvas.getchannel("A").getbbox())
    proof.save(review / "object-art-proof.png")


if __name__ == "__main__":
    main()
