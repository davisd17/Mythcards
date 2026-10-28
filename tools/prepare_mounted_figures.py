"""Package mounted sprite sources with one common scale and wheel/coil anchor."""

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
POSES = ["ready", "raise", "brace", "fire", "recoil", "recover"]
HOLDS = [100, 100, 130, 60, 90, 120]


def clean(image):
    image = image.convert("RGBA")
    image.putalpha(image.getchannel("A").point(lambda a: a if a >= 16 else 0))
    return image


def package(key, entry):
    review = ROOT / "docs/art-specs/mounted" / key
    runtime = ROOT / "game/assets/figures/mounted" / key
    (review / "sources").mkdir(parents=True, exist_ok=True)
    runtime.mkdir(parents=True, exist_ok=True)
    images, anchors, bounds = [], [], []
    for pose in POSES:
        source = ROOT / entry["sources"][pose]
        target = review / "sources" / (pose + ".png")
        if source.resolve() != target.resolve():
            shutil.copyfile(source, target)
        image = clean(Image.open(target))
        normalization = float(entry.get("source_normalization", {}).get(pose, 1.0))
        if normalization != 1.0:
            # Reviewed mount/body landmark correction, not independent effect-bound fitting.
            image = clean(image.resize((round(image.width * normalization), round(image.height * normalization)),
                                       Image.Resampling.LANCZOS))
        b = image.getchannel("A").getbbox()
        if b is None:
            raise ValueError(f"Empty mounted source: {key}/{pose}")
        # The lower half is mount, not a spell: center on wheels or supporting coil.
        y = (b[1] + b[3]) // 2
        lower = image.getchannel("A").crop((0, y, image.width, b[3])).getbbox()
        anchors.append(((lower[0] + lower[2]) / 2, b[3] - 1))
        bounds.append(b)
        images.append(image)
        entry["sources"][pose] = target.relative_to(ROOT).as_posix()
    scale = min(min(230 / max(1, ax - b[0]), 230 / max(1, b[2] - ax),
                    736 / max(1, ay - b[1])) for (ax, ay), b in zip(anchors, bounds))
    packed, registration, frames = [], [], []
    for index, (pose, image, anchor) in enumerate(zip(POSES, images, anchors)):
        resized = clean(image.resize((round(image.width * scale), round(image.height * scale)),
                                     Image.Resampling.LANCZOS))
        canvas = Image.new("RGBA", (512, 768))
        offset = (round(256 - anchor[0] * scale), 757 - resized.getchannel("A").getbbox()[3])
        canvas.alpha_composite(resized, offset)
        b = canvas.getchannel("A").getbbox()
        if b[0] < 24 or b[2] > 488 or b[1] < 18 or b[3] != 757:
            raise ValueError(f"Unsafe mounted frame {key}/{pose}: {b}")
        filename = f"attack-{index + 1}-{pose}.png"
        canvas.save(runtime / filename, optimize=True)
        if index == 0:
            canvas.save(runtime / "default.png", optimize=True)
        frames.append({"texture": f"res://assets/figures/mounted/{key}/{filename}",
                       "ms": HOLDS[index], **({"impact": True} if index == 3 else {})})
        registration.append({"pose": pose, "source_anchor": anchor, "offset": offset, "bounds": b,
            "source_normalization": entry.get("source_normalization", {}).get(pose, 1.0)})
        packed.append(canvas)
    (review / "registration.json").write_text(json.dumps({"shared_scale": scale,
        "canvas": [512, 768], "contact_anchor": [256, 756], "frames": registration}, indent=2) + "\n")
    sheet = Image.new("RGB", (6 * 256, 410), "#23312f")
    draw = ImageDraw.Draw(sheet)
    for index, (pose, image) in enumerate(zip(POSES, packed)):
        thumb = image.resize((256, 384), Image.Resampling.LANCZOS)
        sheet.paste(thumb, (index * 256, 24), thumb)
        draw.text((index * 256 + 10, 6), f"{index + 1} {pose}", fill="white")
    sheet.save(review / "contact-sheet.jpg", quality=93)
    gif_frames = []
    for image in packed:
        back = Image.new("RGBA", image.size, "#23312f")
        back.alpha_composite(image)
        gif_frames.append(back.convert("RGB"))
    gif_frames[0].save(review / "review.gif", save_all=True, append_images=gif_frames[1:] + [gif_frames[0]],
                       duration=HOLDS + [900], loop=0)
    return {"rider": entry["rider"], "mount": entry["mount"], "outfit": entry["outfit"],
            "revision": entry.get("revision", "mounted-v1"),
            "texture": f"res://assets/figures/mounted/{key}/default.png", "attack": frames}


def main():
    path = ROOT / "docs/art-specs/mounted/production-inputs.json"
    manifest = json.loads(path.read_text())
    catalog = {key: package(key, entry) for key, entry in manifest.items()}
    (ROOT / "game/assets/figures/mounted/catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    labels = ["Orlov / VERA-7", "Irina / VERA-7", "Sahu-Ren / Ahesu", "Meret-Anu / Ahesu"]
    overview = []
    for pose in POSES + ["ready"]:
        board = Image.new("RGB", (1024, 420), "#23312f")
        draw = ImageDraw.Draw(board)
        for index, key in enumerate(catalog):
            frame_index = POSES.index(pose) + 1
            image = Image.open(ROOT / f"game/assets/figures/mounted/{key}/attack-{frame_index}-{pose}.png")
            thumb = image.resize((256, 384), Image.Resampling.LANCZOS)
            board.paste(thumb, (index * 256, 28), thumb)
            draw.text((index * 256 + 14, 9), labels[index], fill="white")
        overview.append(board)
    review = ROOT / "docs/art-specs/mounted"
    overview[0].save(review / "mounted-pairings.jpg", quality=94)
    overview[0].save(review / "mounted-attacks.gif", save_all=True, append_images=overview[1:],
                     duration=HOLDS + [900], loop=0)
    ahesu_review = []
    for pose in POSES + ["ready"]:
        board = Image.new("RGB", (1024, 540), "#23312f")
        draw = ImageDraw.Draw(board)
        for index, key in enumerate(["sahu-ahesu", "meret-ahesu"]):
            frame_index = POSES.index(pose) + 1
            image = Image.open(ROOT / f"game/assets/figures/mounted/{key}/attack-{frame_index}-{pose}.png")
            # Fixed review crop removes blank canvas above the square giant composition.
            crop = image.crop((0, 256, 512, 768))
            board.paste(crop, (index * 512, 28), crop)
            draw.text((index * 512 + 20, 9), ["Sahu-Ren / Giant Ahesu", "Meret-Anu / Giant Ahesu"][index], fill="white")
        ahesu_review.append(board)
    ahesu_review[0].save(review / "ahesu-v2-pairings.jpg", quality=94)
    ahesu_review[0].save(review / "ahesu-v2-attacks.gif", save_all=True,
        append_images=ahesu_review[1:], duration=HOLDS + [900], loop=0)
    print(f"Packaged {len(catalog)} mounted pairings, 24 attack frames and four idle figures")


if __name__ == "__main__":
    main()
