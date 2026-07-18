import json
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "cards" / "characters.json"
CARDS = json.loads(DATA_PATH.read_text(encoding="utf-8"))


RUSSIAN = colors.HexColor("#b91c1c")
RUSSIAN_LIGHT = colors.HexColor("#f5dddd")
ATLANTEAN = colors.HexColor("#0369a1")
ATLANTEAN_LIGHT = colors.HexColor("#dff3fb")
INK = colors.HexColor("#171717")
MUTED = colors.HexColor("#5f6368")
PAPER = colors.HexColor("#fffdf8")


def fit_font(c, text, font, max_size, min_size, width):
    size = max_size
    while size > min_size and stringWidth(text, font, size) > width:
        size -= 0.5
    return size


def paragraph(c, text, x, y, w, h, size=6.6, leading=7.3):
    style = ParagraphStyle(
        "card_text",
        fontName="Helvetica",
        fontSize=size,
        leading=leading,
        textColor=INK,
        spaceAfter=0,
        spaceBefore=0,
    )
    p = Paragraph(text, style)
    p.wrapOn(c, w, h)
    p.drawOn(c, x, y + h - p.height)


def draw_card(c, card, x, y, w, h):
    is_atlantean = card["faction"] == "Atlantean"
    main = ATLANTEAN if is_atlantean else RUSSIAN
    light = ATLANTEAN_LIGHT if is_atlantean else RUSSIAN_LIGHT

    c.setFillColor(PAPER)
    c.setStrokeColor(main)
    c.setLineWidth(1.5)
    c.roundRect(x, y, w, h, 7, fill=1, stroke=1)

    header_h = 0.46 * inch
    c.setFillColor(main)
    c.roundRect(x, y + h - header_h, w, header_h, 7, fill=1, stroke=0)
    c.rect(x, y + h - header_h, w, header_h * 0.5, fill=1, stroke=0)

    c.setFillColor(colors.white)
    name_size = fit_font(c, card["name"], "Helvetica-Bold", 11, 7, w - 0.16 * inch)
    c.setFont("Helvetica-Bold", name_size)
    c.drawString(x + 0.08 * inch, y + h - 0.19 * inch, card["name"])
    c.setFont("Helvetica", 6.2)
    c.drawString(x + 0.08 * inch, y + h - 0.34 * inch, card["faction"].upper())
    type_text = card["type"].upper()
    c.drawRightString(x + w - 0.08 * inch, y + h - 0.34 * inch, type_text)

    stat_y = y + h - header_h - 0.32 * inch
    stat_w = w / 4
    labels = ["HP", "ATK", "MOVE", "RANGE"]
    for i, value in enumerate(card["stats"]):
        sx = x + i * stat_w
        c.setStrokeColor(colors.HexColor("#1f2933"))
        c.setLineWidth(0.6)
        c.rect(sx, stat_y, stat_w, 0.32 * inch, fill=0, stroke=1)
        c.setFillColor(MUTED)
        c.setFont("Helvetica-Bold", 5.5)
        c.drawCentredString(sx + stat_w / 2, stat_y + 0.21 * inch, labels[i])
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", 11)
        c.drawCentredString(sx + stat_w / 2, stat_y + 0.065 * inch, str(value))

    box_x = x + 0.08 * inch
    box_w = w - 0.16 * inch
    box_h = 0.52 * inch
    gap = 0.055 * inch
    start_y = stat_y - gap - box_h
    entries = [
        ("LEVEL 1", card["l1"], colors.white),
        ("LEVEL 2", card["l2"], light),
        ("LEVEL 3", card["l3"], light),
    ]

    for idx, (label, text, fill) in enumerate(entries):
        by = start_y - idx * (box_h + gap)
        c.setFillColor(fill)
        c.setStrokeColor(colors.HexColor("#c7ccd1"))
        c.roundRect(box_x, by, box_w, box_h, 4, fill=1, stroke=1)
        c.setFillColor(MUTED)
        c.setFont("Helvetica-Bold", 5.4)
        c.drawString(box_x + 0.045 * inch, by + box_h - 0.11 * inch, label)
        paragraph(c, text, box_x + 0.045 * inch, by + 0.04 * inch, box_w - 0.09 * inch, box_h - 0.16 * inch)

    c.setFillColor(MUTED)
    c.setFont("Helvetica", 5.8)
    paragraph(c, "Role: " + card["role"], box_x, y + 0.07 * inch, box_w, 0.22 * inch, size=5.8, leading=6.4)


def main():
    output = "printable_cards.pdf"
    c = canvas.Canvas(output, pagesize=letter)
    page_w, page_h = letter

    margin_x = 0.28 * inch
    margin_y = 0.25 * inch
    gap_x = 0.12 * inch
    gap_y = 0.12 * inch
    card_w = 2.52 * inch
    card_h = 3.3 * inch

    c.setTitle("MythCards Printable Prototype Cards")

    for idx, card in enumerate(CARDS):
        pos = idx % 9
        if idx and pos == 0:
            c.showPage()
        col = pos % 3
        row = pos // 3
        x = margin_x + col * (card_w + gap_x)
        y = page_h - margin_y - card_h - row * (card_h + gap_y)
        draw_card(c, card, x, y, card_w, card_h)

    c.save()


if __name__ == "__main__":
    main()
