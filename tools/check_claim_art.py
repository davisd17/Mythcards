"""Check produced claim packages without implying runtime integration."""

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    roster = json.loads((ROOT / "data/ember_lines.json").read_text())
    count = 0
    for character in roster:
        review = ROOT / "docs/art-specs/ember-claim" / character
        record = json.loads((review / "registration.json").read_text())
        frames = record["frames"]
        assert [f["pose"] for f in frames] == ["gather", "hold", "settle"], character
        assert [f["ms"] for f in frames] == [120, 360, 120], character
        for frame in frames:
            path = ROOT / "game/assets/figures" / character / frame["file"]
            with Image.open(path) as sprite:
                assert sprite.size == (512, 768) and sprite.mode == "RGBA", path
                assert sprite.getpixel((0, 0))[3] == 0, path
                bounds = sprite.getchannel("A").getbbox()
                assert bounds is not None, path
                assert bounds[0] >= 24 and bounds[2] <= 488, (path, bounds)
                assert bounds[1] >= 18 and bounds[3] == 757, (path, bounds)
            count += 1
        for name in ("PROMPTS.md", "sources.json", "body-landmarks.json",
                     "contact-sheet.png", "claim-preview.gif", f"{character}-claim.ora"):
            assert (review / name).exists(), (character, name)
    print(f"PASS: {len(roster)} packages, {count} RGBA candidates; timing, bounds, "
          "baseline and review artifacts valid. In-game verification remains separate.")


if __name__ == "__main__":
    main()
