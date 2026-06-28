from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


CARDS = [
    {
        "faction": "Russian-Inspired",
        "name": "Winter Palace Standard",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Your Hero and Leader each gain +1 maximum HP while this relic is active.",
        "note": "Simple durability plan for important pieces.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Iron Birch Talisman",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Your Common and Warrior each gain +1 maximum HP while this relic is active.",
        "note": "Makes the front line sturdier.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "General's War Map",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Once each turn, one of your characters gains +1 RANGE on its next attack or ability.",
        "note": "Build around longer threat lines.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Whiteout",
        "kind": "Event",
        "duration": "1 round",
        "effect": "All ranged attacks and ranged abilities have -1 RANGE, minimum 1.",
        "note": "Temporarily softens snipers, mystics, and leaders.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Frozen Center",
        "kind": "Event",
        "duration": "1 round",
        "effect": "The center row and center tile count as frost. A character entering frost stops moving.",
        "note": "Turns the 7x7 center lane into a slowdown zone.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Rally From The Snow",
        "kind": "Event",
        "duration": "Immediate",
        "effect": "The active player heals 1 HP on one damaged character.",
        "note": "Simple recovery for one key piece.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Long Winter March",
        "kind": "Event",
        "duration": "1 turn",
        "effect": "The active player's first movement action this turn gains +1 MOVE.",
        "note": "Useful for level-up runs or repositioning.",
    },
    {
        "faction": "Atlantean",
        "name": "Quartz Heart Core",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Your shields prevent +1 additional damage while this relic is active.",
        "note": "Build around shield-heavy play.",
    },
    {
        "faction": "Atlantean",
        "name": "Hall Of Shared Minds",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Your adjacent characters gain +1 RANGE on abilities.",
        "note": "Rewards tight hive-mind formations.",
    },
    {
        "faction": "Atlantean",
        "name": "Tideglass Obelisk",
        "kind": "Relic",
        "duration": "Persistent",
        "effect": "Your characters adjacent to a placed object gain +1 RANGE on attacks and abilities.",
        "note": "Build around pylons, barricades, and board objects.",
    },
    {
        "faction": "Atlantean",
        "name": "Resonance Surge",
        "kind": "Event",
        "duration": "1 turn",
        "effect": "The active player's first ability this turn has +1 RANGE.",
        "note": "Simple ability reach for one turn.",
    },
    {
        "faction": "Atlantean",
        "name": "Psychic Undertow",
        "kind": "Event",
        "duration": "1 turn",
        "effect": "The active player's first attack this turn may push or pull the target 1 tile.",
        "note": "Adds one clear positioning choice.",
    },
    {
        "faction": "Atlantean",
        "name": "Crystal Tide",
        "kind": "Event",
        "duration": "1 round",
        "duration": "1 turn",
        "effect": "The active player's characters have +1 RANGE on abilities this turn.",
        "note": "A full-turn ability range boost.",
    },
    {
        "faction": "Atlantean",
        "name": "Dream Of The Deep City",
        "kind": "Event",
        "duration": "Immediate",
        "effect": "Reveal the next shared relic/event card. The active player may leave it on top or place it on the bottom of the deck.",
        "note": "Lets the active player shape the next moment.",
    },
]


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
