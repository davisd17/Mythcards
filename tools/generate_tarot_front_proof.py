from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "assets" / "characters" / "nadia-belaya-the-star-character-card-art.png"
DEFAULT_OUTPUT = Path(
    r"D:\MythCards-working-images\card-fronts\mythcards-xvii-the-star-front-proof.png"
)

CANVAS_SIZE = (1400, 2400)
ART_BOX = (82, 82, 1318, 1936)


def fit_inside(image: Image.Image, box: tuple[int, int, int, int]) -> tuple[Image.Image, int, int]:
    left, top, right, bottom = box
    width = right - left
    height = bottom - top
    scale = min(width / image.width, height / image.height)
    size = (round(image.width * scale), round(image.height * scale))
    resized = image.resize(size, Image.Resampling.LANCZOS)
    x = left + (width - size[0]) // 2
    y = top + (height - size[1]) // 2
    return resized, x, y


def render_card(source: Path, output: Path, title: str) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)

    canvas = Image.new("RGB", CANVAS_SIZE, "#121416")
    draw = ImageDraw.Draw(canvas)

    art = Image.open(source).convert("RGB")
    fitted, art_x, art_y = fit_inside(art, ART_BOX)
    canvas.paste(fitted, (art_x, art_y))

    # Thin print-friendly keylines keep the image distinct without competing with it.
    art_bounds = (art_x - 3, art_y - 3, art_x + fitted.width + 2, art_y + fitted.height + 2)
    draw.rectangle(art_bounds, outline="#A5A39B", width=3)
    draw.rectangle((42, 42, 1357, 2357), outline="#5F6261", width=3)
    draw.rectangle((55, 55, 1344, 2344), outline="#67252B", width=2)

    font_size = 74
    title_font = ImageFont.truetype(r"C:\Windows\Fonts\georgia.ttf", font_size)
    title_box = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_box[2] - title_box[0]
    while title_width > 1040 and font_size > 50:
        font_size -= 2
        title_font = ImageFont.truetype(r"C:\Windows\Fonts\georgia.ttf", font_size)
        title_box = draw.textbbox((0, 0), title, font=title_font)
        title_width = title_box[2] - title_box[0]
    title_y = 2112
    draw.text(
        ((CANVAS_SIZE[0] - title_width) // 2, title_y),
        title,
        font=title_font,
        fill="#E0DDD4",
    )

    rule_y = 2040
    draw.line((330, rule_y, 1070, rule_y), fill="#777A77", width=2)

    canvas.save(output, dpi=(300, 300), optimize=True)


def main() -> None:
    render_card(DEFAULT_SOURCE, DEFAULT_OUTPUT, "XVII  -  THE STAR")
    print(DEFAULT_OUTPUT)


if __name__ == "__main__":
    main()
