import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "game" / "assets" / "figures"
CANVAS_SIZE = (512, 768)
PADDING_X = 24
PADDING_TOP = 18
PADDING_BOTTOM = 12


def normalize_figure(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Figure sheet half has no visible pixels")
    figure = image.crop(bounds)
    max_width = CANVAS_SIZE[0] - PADDING_X * 2
    max_height = CANVAS_SIZE[1] - PADDING_TOP - PADDING_BOTTOM
    scale = min(max_width / figure.width, max_height / figure.height)
    size = (round(figure.width * scale), round(figure.height * scale))
    figure = figure.resize(size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - figure.width) // 2
    y = CANVAS_SIZE[1] - PADDING_BOTTOM - figure.height
    canvas.alpha_composite(figure, (x, y))
    return canvas


def split_sheet(sheet_path: Path, character_id: str, outfit_ids: tuple[str, str]) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    half_width = sheet.width // 2
    halves = (
        sheet.crop((0, 0, half_width, sheet.height)),
        sheet.crop((half_width, 0, sheet.width, sheet.height)),
    )
    character_dir = OUTPUT_DIR / character_id
    character_dir.mkdir(parents=True, exist_ok=True)
    for half, outfit_id in zip(halves, outfit_ids):
        output = character_dir / f"{outfit_id}.png"
        normalize_figure(half).save(output, optimize=True)
        print(output)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: prepare_board_figures.py FROST_SEER_SHEET ASTRAL_HARMONIC_SHEET")
    split_sheet(Path(sys.argv[1]), "r-seer", ("default", "aurora-rite"))
    split_sheet(Path(sys.argv[2]), "a-harmonic", ("default", "drowned-seraph"))


if __name__ == "__main__":
    main()
