"""Package a 2x2 generated pose sheet using one scale and registered foot anchors."""

import argparse
import io
import json
import statistics
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
NAMES = ["ready", "windup", "strike", "recover"]
DURATIONS = [120, 180, 100, 150]
SIZE = (512, 768)


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, "PNG")
    return buffer.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("--raise-pose", type=Path)
    parser.add_argument("--recoil-pose", type=Path)
    args = parser.parse_args()
    output = ROOT / "game/assets/figures/r-yuri-volkov"
    review = ROOT / "docs/art-specs/yuri-attack-pilot"
    review.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(args.sheet).convert("RGBA")
    reference = Image.open(output / "default.png").convert("RGBA")
    cells = []
    bounds = []
    anchors = []
    for index in range(4):
        col, row = index % 2, index // 2
        cell = sheet.crop((col * sheet.width // 2, row * sheet.height // 2,
                           (col + 1) * sheet.width // 2, (row + 1) * sheet.height // 2))
        cell.putalpha(cell.getchannel("A").point(lambda value: value if value >= 16 else 0))
        mask = cell.getchannel("A")
        bound = mask.getbbox()
        if bound is None:
            raise ValueError("Empty pose")
        # Registration uses boots, not the gun or the entire silhouette's midpoint.
        boots_top = round(bound[1] + (bound[3] - bound[1]) * 0.86)
        boots = mask.crop((0, boots_top, cell.width, bound[3])).getbbox()
        anchors.append(((boots[0] + boots[2]) / 2, bound[3] - 1))
        cells.append(cell)
        bounds.append(bound)
    ref_bound = reference.getchannel("A").point(lambda a: 255 if a >= 96 else 0).getbbox()
    body_scale = (ref_bound[3] - ref_bound[1]) / statistics.median(b[3] - b[1] for b in bounds)
    safe_scale = min(min(230 / max(1, ax - b[0]), 230 / max(1, b[2] - ax),
                         736 / max(1, ay - b[1]))
                     for (ax, ay), b in zip(anchors, bounds))
    scale = min(body_scale, safe_scale)
    frames = []
    registrations = []
    for index, (cell, (ax, ay)) in enumerate(zip(cells, anchors)):
        resized = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.LANCZOS)
        resized.putalpha(resized.getchannel("A").point(lambda value: value if value >= 16 else 0))
        resized_bounds = resized.getchannel("A").getbbox()
        offset = (round(256 - ax * scale), 757 - resized_bounds[3])
        canvas = Image.new("RGBA", SIZE)
        canvas.alpha_composite(resized, offset)
        visible = canvas.getchannel("A").getbbox()
        if visible[0] < 24 or visible[2] > 488 or visible[1] < 18 or visible[3] != 757:
            raise ValueError(f"Pose {NAMES[index]} violates safe area or foot baseline: {visible}")
        frames.append(canvas)
        registrations.append({"pose": NAMES[index], "source_foot_anchor": [ax, ay], "offset": offset})
    (review / "source-sheet.png").write_bytes(args.sheet.read_bytes())
    metadata = {
        "canvas": SIZE, "shared_scale": scale, "body_scale": body_scale,
        "foot_anchor": [256, 756], "frames": registrations,
        "note": "One shared scale; translation-only boot registration. No per-pose bounding-box fit."
    }
    names, durations = NAMES, DURATIONS
    if bool(args.raise_pose) != bool(args.recoil_pose):
        raise ValueError("Provide both additional poses for the six-frame sequence")
    if args.raise_pose:
        extras, extra_anchors, extra_bounds = [], [], []
        for path in [args.raise_pose, args.recoil_pose]:
            pose = Image.open(path).convert("RGBA")
            pose.putalpha(pose.getchannel("A").point(lambda a: a if a >= 16 else 0))
            bound = pose.getchannel("A").getbbox()
            boots_top = round(bound[1] + (bound[3] - bound[1]) * 0.86)
            boots = pose.getchannel("A").crop((0, boots_top, pose.width, bound[3])).getbbox()
            extra_anchors.append(((boots[0] + boots[2]) / 2, bound[3] - 1))
            extra_bounds.append(bound)
            extras.append(pose)
        target_height = statistics.median(f.getchannel("A").getbbox()[3] - f.getchannel("A").getbbox()[1] for f in frames)
        extra_scale = min(target_height / statistics.median(b[3] - b[1] for b in extra_bounds),
            min(min(230 / max(1, ax - b[0]), 230 / max(1, b[2] - ax), 736 / max(1, ay - b[1]))
                for (ax, ay), b in zip(extra_anchors, extra_bounds)))
        registered = []
        for pose, (ax, ay) in zip(extras, extra_anchors):
            resized = pose.resize((round(pose.width * extra_scale), round(pose.height * extra_scale)), Image.Resampling.LANCZOS)
            resized.putalpha(resized.getchannel("A").point(lambda a: a if a >= 16 else 0))
            offset = (round(256 - ax * extra_scale), 757 - resized.getchannel("A").getbbox()[3])
            canvas = Image.new("RGBA", SIZE)
            canvas.alpha_composite(resized, offset)
            bound = canvas.getchannel("A").getbbox()
            if bound[0] < 24 or bound[2] > 488 or bound[1] < 18 or bound[3] != 757:
                raise ValueError(f"Additional pose violates registration: {bound}")
            registered.append(canvas)
        frames = [frames[0], registered[0], frames[1], frames[2], registered[1], frames[3]]
        names = ["ready", "raise", "brace", "fire", "recoil", "recover"]
        durations = [100, 100, 130, 60, 90, 120]
        metadata["additional_poses_shared_scale"] = extra_scale
        metadata["additional_poses_source_anchors"] = extra_anchors
        metadata["sequence"] = [{"file": f"attack-{i + 1}-{name}.png", "duration_ms": duration}
                                for i, (name, duration) in enumerate(zip(names, durations))]
        (review / "raise-source.png").write_bytes(args.raise_pose.read_bytes())
        (review / "recoil-source.png").write_bytes(args.recoil_pose.read_bytes())
    for index, (name, frame) in enumerate(zip(names, frames)):
        frame.save(output / f"attack-{index + 1}-{name}.png", optimize=True)
    (review / "registration.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8", newline="\n")

    # OpenRaster stores each complete registered pose as an independently editable layer.
    root = ET.Element("image", {"w": "512", "h": "768", "name": "Yuri attack pilot"})
    stack = ET.SubElement(root, "stack")
    with zipfile.ZipFile(review / "r-yuri-volkov-attack.ora", "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        for index, frame in enumerate(frames):
            name = f"data/layer{index}.png"
            ET.SubElement(stack, "layer", {"name": f"{index + 1} {names[index]}", "src": name,
                "x": "0", "y": "0", "opacity": "1.0", "composite-op": "svg:src-over",
                "visibility": "visible" if index == 0 else "hidden"})
            archive.writestr(name, png_bytes(frame))
        archive.writestr("stack.xml", ET.tostring(root, encoding="utf-8", xml_declaration=True))
        archive.writestr("mergedimage.png", png_bytes(frames[0]))
        archive.writestr("Thumbnails/thumbnail.png", png_bytes(frames[0].resize((171, 256))))

    contact = Image.new("RGB", (256 * len(frames), 420), "#202a29")
    draw = ImageDraw.Draw(contact)
    previews = []
    for index, frame in enumerate(frames):
        small = frame.resize((256, 384), Image.Resampling.LANCZOS)
        contact.paste(small, (index * 256, 26), small)
        draw.text((index * 256 + 12, 8), f"{index + 1} {names[index]} / {durations[index]} ms", fill="white")
        preview = Image.new("RGBA", SIZE, "#202a29")
        preview.alpha_composite(frame)
        previews.append(preview.convert("RGB"))
    contact.save(review / "contact-sheet.png")
    previews[0].save(review / "attack-preview.gif", save_all=True, append_images=previews[1:],
                     duration=durations, loop=0, disposal=2)
    print(json.dumps({"shared_scale": scale, "output": str(output), "review": str(review)}))


if __name__ == "__main__":
    main()
