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
        "name": "Gymnast",
        "type": "Common",
        "stats": (2, 1, 3, 1),
        "l1": "Passive: Vault may move through 1 adjacent allied character during movement.",
        "l2": "+1 MOVE. Vault may pass through enemies but cannot end on their tile.",
        "l3": "After Vaulting, may make a 1-damage attack against an adjacent enemy.",
        "role": "Agile tester piece for movement tricks and edge runs.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "White Siberian Tiger",
        "type": "Mount",
        "stats": (4, 2, 4, 1),
        "l1": "Passive: Pounce makes this character's attack deal +1 damage if it moved at least 3 tiles in a straight line this turn.",
        "l2": "+1 HP. Pounce also pushes the target 1 tile if possible.",
        "l3": "Snow Stalker: Once per turn, ignores the first 1 damage it would take after moving.",
        "role": "Fast pressure piece. Can carry an allied Hero or Leader.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Sniper",
        "type": "Warrior",
        "stats": (3, 2, 2, 4),
        "l1": "Passive: Aim gives this character's basic attack +1 RANGE if it did not move this turn.",
        "l2": "Piercing Shot: Attacks ignore 1 shield or damage reduction.",
        "l3": "Mark Target: After damaging an enemy, the next allied attack against that enemy deals +1 damage.",
        "role": "Lane control and long-range threat.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Army General",
        "type": "Leader",
        "stats": (5, 1, 2, 1),
        "l1": "AP Ability: Command chooses an allied character within 2 tiles. That ally gains +1 ATK on its next attack this turn or may move 1 tile without spending an action.",
        "l2": "Command range becomes 3.",
        "l3": "Tactical Order: Once per turn, Command may instead refresh an adjacent ally's action point.",
        "role": "Support commander. Unique: only 1 Leader. May mount an allied Mount.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Bogatyr Champion",
        "type": "Hero",
        "stats": (6, 2, 2, 1),
        "l1": "Passive: Stand Firm gives +1 maximum and current HP while this character is on or adjacent to the center tile.",
        "l2": "Heroic Guard: Adjacent allies take -1 damage from attacks.",
        "l3": "Last Oath: The first time this character would be defeated, it remains at 1 HP instead.",
        "role": "Protect this piece. Unique: only 1 Hero. Enemy wins if captured. May mount an allied Mount.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Winter Engineer",
        "type": "Specialist",
        "stats": (3, 1, 2, 1),
        "l1": "AP Ability: Barricade creates 1 barricade on an adjacent empty tile, or repairs an adjacent barricade or placed object by 1 HP. Barricades block movement and have 2 HP.",
        "l2": "Barricades have 3 HP and adjacent allies gain +1 defense against ranged attacks.",
        "l3": "Frozen Works: Once per turn, may place a frost tile instead of a barricade. Enemies entering frost stop moving.",
        "role": "Board control and defensive setup.",
    },
    {
        "faction": "Russian-Inspired",
        "name": "Frost Seer",
        "type": "Mystic",
        "stats": (3, 1, 2, 3),
        "l1": "AP Ability: Chill deals 1 damage at range 3. Target's MOVE is reduced by 1 and it cannot mount or dismount on its next turn.",
        "l2": "Winter Veil: May shield an ally within 3 tiles for 1 damage prevention.",
        "l3": "Deep Freeze: Chill also prevents the target from using reaction or bonus movement effects next turn.",
        "role": "Control mystic, slows enemy advances.",
    },
    {
        "faction": "Atlantean",
        "name": "Quartz Attendant",
        "type": "Common",
        "stats": (2, 1, 2, 1),
        "l1": "Passive: Synchronize gives +1 ATK while adjacent to another Atlantean.",
        "l2": "Shared Pulse: Adjacent Atlanteans gain +1 defense against the first attack each turn.",
        "l3": "Collective Step: If adjacent to another Atlantean, may move 1 extra tile.",
        "role": "Hive-mind common that rewards formation play.",
    },
    {
        "faction": "Atlantean",
        "name": "Manta Glider",
        "type": "Mount",
        "stats": (3, 1, 4, 1),
        "l1": "Passive: Glide may move over occupied tiles but must end on an empty tile. If carrying a Hero or Leader, the mounted pair may also glide.",
        "l2": "+1 ATK after moving over any character this turn.",
        "l3": "Phase Current: Once per turn, may ignore terrain and barricades during movement.",
        "role": "Mobile flanker and edge-run threat. Can carry an allied Hero or Leader.",
    },
    {
        "faction": "Atlantean",
        "name": "Resonance Guard",
        "type": "Warrior",
        "stats": (5, 1, 2, 1),
        "l1": "Passive: Quartz Armor reduces ranged attack damage by 1.",
        "l2": "Redirect: Once per turn, may take damage for an adjacent ally.",
        "l3": "Resonant Counter: After reducing damage, deals 1 damage back to the attacker if within range 2.",
        "role": "Protective frontline and anti-ranged anchor.",
    },
    {
        "faction": "Atlantean",
        "name": "Divine Conductor",
        "type": "Leader",
        "stats": (4, 1, 2, 3),
        "l1": "AP Ability: Link Mind chooses an ally within 3 tiles. Until end of turn, that ally may use the Conductor's RANGE for its ability if valid, and may ignore one allied character for line-of-sight.",
        "l2": "Link Mind may target 2 allies if both are within 2 tiles of each other.",
        "l3": "Perfect Chord: Once per turn, when a linked ally defeats an enemy, refresh that ally's action point.",
        "role": "Hive-mind coordinator. Unique: only 1 Leader. May mount an allied Mount.",
    },
    {
        "faction": "Atlantean",
        "name": "Oracle Sovereign",
        "type": "Hero",
        "stats": (5, 1, 2, 3),
        "l1": "AP Ability: Foresight reveals the next shared relic/event card. You may place it on the bottom of the deck. Then give one adjacent ally a 1-damage shield.",
        "l2": "Spirit Mantle: Gains a 1-damage shield at the start of your turn.",
        "l3": "Collective Ascension: Once per match, all adjacent allies heal 1 and gain +1 MOVE this turn.",
        "role": "Protect this piece. Unique: only 1 Hero. Enemy wins if captured. May mount an allied Mount.",
    },
    {
        "faction": "Atlantean",
        "name": "Crystal Architect",
        "type": "Specialist",
        "stats": (3, 1, 2, 2),
        "l1": "AP Ability: Pylon places a quartz pylon on an adjacent empty tile, or moves an existing allied pylon 1 tile. Allies within 2 tiles of a pylon gain +1 RANGE on abilities.",
        "l2": "Pylons also count as adjacent Atlanteans for Synchronize effects.",
        "l3": "Relay Gate: Once per turn, an ally adjacent to a pylon may teleport to another pylon within 4 tiles.",
        "role": "Quartz technology and board shaping.",
    },
    {
        "faction": "Atlantean",
        "name": "Astral Harmonic",
        "type": "Mystic",
        "stats": (3, 1, 2, 3),
        "l1": "AP Ability: Resonance Shield shields an ally within 3 tiles for 1 damage prevention. If that ally is mounted, the shield prevents 2 damage instead.",
        "l2": "Harmonic Bind: Shielded allies also cannot be pushed or displaced this turn.",
        "l3": "Astral Echo: After shielding an ally, may deal 1 damage to an enemy within 2 tiles of that ally.",
        "role": "Spiritual protection and counter-pressure.",
    },
]


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
