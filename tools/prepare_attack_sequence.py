"""Register six generated source poses with one shared scale and foot baseline."""

import argparse
import io
import json
import statistics
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
POSES = ["ready", "raise", "brace", "fire", "recoil", "recover"]
HOLDS = [100, 100, 130, 60, 90, 120]


def png(image):
    buffer = io.BytesIO()
    image.save(buffer, "PNG")
    return buffer.getvalue()


def clean_alpha(image):
    image = image.convert("RGBA")
    image.putalpha(image.getchannel("A").point(lambda a: a if a >= 16 else 0))
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("character")
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    output = (ROOT / "game/assets/figures" / args.character).resolve()
    if output.parent != (ROOT / "game/assets/figures").resolve():
        raise ValueError("Invalid character id")
    idle = clean_alpha(Image.open(output / "default.png"))
    review = ROOT / "docs/art-specs/attack-art" / args.character
    (review / "sources").mkdir(parents=True, exist_ok=True)
    sources = json.loads(args.manifest.read_text(encoding="utf-8"))
    originals, anchors, bounds = [], [], []
    for name in POSES:
        path = ROOT / sources[name]
        image = clean_alpha(Image.open(path))
        bound = image.getchannel("A").getbbox()
        if bound is None:
            raise ValueError(f"Empty pose: {name}")
        boot_top = round(bound[1] + (bound[3] - bound[1]) * 0.86)
        boot_bounds = image.getchannel("A").crop((0, boot_top, image.width, bound[3])).getbbox()
        anchors.append(((boot_bounds[0] + boot_bounds[2]) * 0.5, bound[3] - 1))
        originals.append(image)
        bounds.append(bound)
        destination = review / "sources" / f"{name}.png"
        if path.resolve() != destination.resolve():
            destination.write_bytes(path.read_bytes())
    if len({im.size for im in originals}) != 1:
        raise ValueError("Source canvases must have equal dimensions for a shared scale")
    idle_bound = idle.getchannel("A").getbbox()
    scale = min((idle_bound[3] - idle_bound[1]) / statistics.median(b[3] - b[1] for b in bounds),
        min(min(230 / max(1, ax - b[0]), 230 / max(1, b[2] - ax), 736 / max(1, ay - b[1]))
            for (ax, ay), b in zip(anchors, bounds)))
    frames, registrations = [], []
    for name, image, (ax, ay), ms in zip(POSES, originals, anchors, HOLDS):
        scaled = clean_alpha(image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS))
        offset = (round(256 - ax * scale), 757 - scaled.getchannel("A").getbbox()[3])
        frame = Image.new("RGBA", (512, 768))
        frame.alpha_composite(scaled, offset)
        visible = frame.getchannel("A").getbbox()
        if visible[0] < 24 or visible[2] > 488 or visible[1] < 18 or visible[3] != 757:
            raise ValueError(f"Unsafe pose {name}: {visible}")
        index = len(frames)
        filename = f"attack-{index + 1}-{name}.png"
        frame.save(output / filename, optimize=True)
        frames.append(frame)
        registrations.append({"pose": name, "file": filename, "ms": ms, "impact": name == "fire",
                              "source_anchor": [ax, ay], "offset": offset, "bounds": visible})
    (review / "registration.json").write_text(json.dumps({"character": args.character,
        "canvas": [512, 768], "shared_scale": scale, "foot_anchor": [256, 756],
        "frames": registrations}, indent=2) + "\n", encoding="utf-8", newline="\n")
    root = ET.Element("image", {"w": "512", "h": "768", "name": args.character + " attack"})
    stack = ET.SubElement(root, "stack")
    with zipfile.ZipFile(review / f"{args.character}-attack.ora", "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        for index, frame in enumerate(frames):
            path = f"data/{POSES[index]}.png"
            ET.SubElement(stack, "layer", {"name": POSES[index], "src": path, "x": "0", "y": "0",
                "opacity": "1.0", "composite-op": "svg:src-over", "visibility": "visible" if index == 0 else "hidden"})
            archive.writestr(path, png(frame))
        archive.writestr("stack.xml", ET.tostring(root, encoding="utf-8", xml_declaration=True))
        archive.writestr("mergedimage.png", png(frames[0]))
        archive.writestr("Thumbnails/thumbnail.png", png(frames[0].resize((171, 256))))
    proof = Image.new("RGB", (1200, 350), "#25332f")
    draw = ImageDraw.Draw(proof)
    preview = []
    for index, frame in enumerate(frames):
        small = frame.resize((200, 300), Image.Resampling.LANCZOS)
        proof.paste(small, (index * 200, 25), small)
        draw.text((index * 200 + 8, 8), f"{index + 1} {POSES[index]} / {HOLDS[index]} ms", fill="white")
        still = Image.new("RGBA", (256, 384), "#25332f")
        still.alpha_composite(frame.resize((256, 384), Image.Resampling.LANCZOS))
        preview.append(still.convert("RGB"))
    proof.save(review / "contact-sheet.png")
    animated, times = [], []
    for index, frame in enumerate(preview):
        fade = 20 if POSES[index] == "fire" else 30
        animated.append(frame)
        times.append(HOLDS[index] - fade)
        for step in range(1, fade // 10 + 1):
            animated.append(Image.blend(frame, preview[(index + 1) % 6], step / (fade // 10)))
            times.append(10)
    animated[0].save(review / "attack-preview.gif", save_all=True, append_images=animated[1:],
                     duration=times, loop=0, disposal=2)
    print(json.dumps({"character": args.character, "shared_scale": scale, "poses": 6, "duration_ms": sum(HOLDS)}))


if __name__ == "__main__":
    main()
