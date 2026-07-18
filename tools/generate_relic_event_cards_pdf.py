import json
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "cards" / "relic_events.json"
CARDS = json.loads(DATA_PATH.read_text(encoding="utf-8"))


RUSSIAN = colors.HexColor("#b91c1c")
RUSSIAN_LIGHT = colors.HexColor("#f5dddd")
ATLANTEAN = colors.HexColor("#0369a1")
ATLANTEAN_LIGHT = colors.HexColor("#dff3fb")
RELIC = colors.HexColor("#6d4c1d")
EVENT = colors.HexColor("#374151")
INK = colors.HexColor("#171717")
MUTED = colors.HexColor("#5f6368")
PAPER = colors.HexColor("#fffdf8")


def fit_font(c, text, font, max_size, min_size, width):
    size = max_size
    while size > min_size and stringWidth(text, font, size) > width:
        size -= 0.5
    return size


def paragraph(c, text, x, y, w, h, size=8.0, leading=9.0):
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
    faction_color = ATLANTEAN if is_atlantean else RUSSIAN
    light = ATLANTEAN_LIGHT if is_atlantean else RUSSIAN_LIGHT
    kind_color = RELIC if card["kind"] == "Relic" else EVENT

    c.setFillColor(PAPER)
    c.setStrokeColor(faction_color)
    c.setLineWidth(1.5)
    c.roundRect(x, y, w, h, 7, fill=1, stroke=1)

    header_h = 0.56 * inch
    c.setFillColor(faction_color)
    c.roundRect(x, y + h - header_h, w, header_h, 7, fill=1, stroke=0)
    c.rect(x, y + h - header_h, w, header_h * 0.5, fill=1, stroke=0)

    c.setFillColor(colors.white)
    name_size = fit_font(c, card["name"], "Helvetica-Bold", 11, 7, w - 0.16 * inch)
    c.setFont("Helvetica-Bold", name_size)
    c.drawString(x + 0.08 * inch, y + h - 0.19 * inch, card["name"])
    c.setFont("Helvetica", 6.2)
    c.drawString(x + 0.08 * inch, y + h - 0.36 * inch, card["faction"].upper())
    c.drawRightString(x + w - 0.08 * inch, y + h - 0.36 * inch, card["kind"].upper())

    badge_y = y + h - header_h - 0.34 * inch
    c.setFillColor(kind_color)
    c.roundRect(x + 0.08 * inch, badge_y, w - 0.16 * inch, 0.24 * inch, 4, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 8)
    c.drawCentredString(x + w / 2, badge_y + 0.075 * inch, f"{card['kind']} - {card['duration']}")

    box_x = x + 0.1 * inch
    box_w = w - 0.2 * inch
    effect_y = badge_y - 1.32 * inch
    c.setFillColor(colors.white)
    c.setStrokeColor(colors.HexColor("#c7ccd1"))
    c.roundRect(box_x, effect_y, box_w, 1.2 * inch, 5, fill=1, stroke=1)
    c.setFillColor(MUTED)
    c.setFont("Helvetica-Bold", 6)
    c.drawString(box_x + 0.05 * inch, effect_y + 1.06 * inch, "EFFECT")
    paragraph(c, card["effect"], box_x + 0.05 * inch, effect_y + 0.08 * inch, box_w - 0.1 * inch, 0.93 * inch)

    note_y = y + 0.28 * inch
    c.setFillColor(light)
    c.setStrokeColor(colors.HexColor("#c7ccd1"))
    c.roundRect(box_x, note_y, box_w, 0.48 * inch, 5, fill=1, stroke=1)
    c.setFillColor(MUTED)
    c.setFont("Helvetica-Bold", 5.8)
    c.drawString(box_x + 0.05 * inch, note_y + 0.35 * inch, "PLAYTEST NOTE")
    paragraph(c, card["note"], box_x + 0.05 * inch, note_y + 0.055 * inch, box_w - 0.1 * inch, 0.27 * inch, size=6.6, leading=7.2)

    c.setFillColor(MUTED)
    c.setFont("Helvetica", 5.8)
    c.drawCentredString(x + w / 2, y + 0.1 * inch, "Shared deck card - either player may be affected")


def main():
    output = "printable_relic_event_cards.pdf"
    c = canvas.Canvas(output, pagesize=letter)
    page_w, page_h = letter

    margin_x = 0.28 * inch
    margin_y = 0.25 * inch
    gap_x = 0.12 * inch
    gap_y = 0.12 * inch
    card_w = 2.52 * inch
    card_h = 3.3 * inch

    c.setTitle("MythCards Printable Relic And Event Cards")

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
