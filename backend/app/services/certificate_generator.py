"""
VOLO - Premium Digital Minimalist Certificate Generator.
Generates beautiful dynamic certificates as high-resolution JPEGs (for Flutter display)
and high-quality PDFs (for printing/downloading).
"""

from __future__ import annotations

import os
import uuid
from typing import Optional, Tuple
from PIL import Image, ImageDraw, ImageFont

# ─── Font candidates ────────────────────────────────────────────────────
_FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
    "C:/Windows/Fonts/timesbd.ttf",
    "C:/Windows/Fonts/times.ttf",
]


def _font(
    size: int, bold: bool = False
) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    # Try bold fonts if requested
    candidates = _FONT_CANDIDATES
    if bold:
        candidates = [
            c for c in _FONT_CANDIDATES if "Bold" in c or "bd" in c
        ] + _FONT_CANDIDATES

    for path in candidates:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def get_hours_plural(hours: int) -> str:
    h = hours % 100
    if 11 <= h <= 19:
        return "ЧАСОВ"
    h = hours % 10
    if h == 1:
        return "ЧАС"
    if 2 <= h <= 4:
        return "ЧАСА"
    return "ЧАСОВ"


def draw_pixel_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    x_start: int,
    y_start: int,
    pixel_size: int = 4,
    fill: Tuple[int, int, int] = (58, 28, 72),
):
    """
    Draws beautifully pixelated text directly onto the canvas (no font required).
    Supports VOLO characters for stamps and logos.
    """
    patterns = {
        "V": [
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [0, 1, 0, 1, 0],
            [0, 0, 1, 0, 0],
        ],
        "O": [
            [0, 1, 1, 1, 0],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [0, 1, 1, 1, 0],
        ],
        "L": [
            [1, 0, 0, 0, 0],
            [1, 0, 0, 0, 0],
            [1, 0, 0, 0, 0],
            [1, 0, 0, 0, 0],
            [1, 1, 1, 1, 1],
        ],
        "K": [
            [1, 0, 0, 0, 1],
            [1, 0, 0, 1, 0],
            [1, 1, 1, 0, 0],
            [1, 0, 0, 1, 0],
            [1, 0, 0, 0, 1],
        ],
        "A": [
            [0, 1, 1, 1, 0],
            [1, 0, 0, 0, 1],
            [1, 1, 1, 1, 1],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
        ],
        "P": [
            [1, 1, 1, 1, 0],
            [1, 0, 0, 0, 1],
            [1, 1, 1, 1, 0],
            [1, 0, 0, 0, 0],
            [1, 0, 0, 0, 0],
        ],
        "R": [
            [1, 1, 1, 1, 0],
            [1, 0, 0, 0, 1],
            [1, 1, 1, 1, 0],
            [1, 0, 0, 1, 0],
            [1, 0, 0, 0, 1],
        ],
        "E": [
            [1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0],
            [1, 1, 1, 1, 0],
            [1, 0, 0, 0, 0],
            [1, 1, 1, 1, 1],
        ],
        "D": [
            [1, 1, 1, 1, 0],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [1, 0, 0, 0, 1],
            [1, 1, 1, 1, 0],
        ],
    }

    current_x = x_start
    for char in text.upper():
        if char in patterns:
            pattern = patterns[char]
            for r_idx, row in enumerate(pattern):
                for c_idx, val in enumerate(row):
                    if val == 1:
                        px = current_x + c_idx * pixel_size
                        py = y_start + r_idx * pixel_size
                        draw.rectangle(
                            [px, py, px + pixel_size - 1, py + pixel_size - 1],
                            fill=fill,
                        )
            current_x += 6 * pixel_size
        elif char == " ":
            current_x += 3 * pixel_size


async def _generate_dedication(
    volunteer_name: str, event_title: str, org_name: str
) -> str:
    """Fallback-friendly dedication line."""
    return f"выражает искреннюю благодарность за активное участие и неоценимый волонтерский вклад в проведение мероприятия «{event_title}»."


async def generate_personalized_certificate(
    *,
    template_url: Optional[str],
    volunteer_name: str,
    event_title: str,
    org_name: str,
    org_bin: str = "123456789012",
    event_date: str,
    hours: int,
    output_dir: str,
    base_dir: str,
) -> Tuple[str, str]:
    """
    Generates a beautifully styled digital minimalist certificate using Pillow.
    Saves BOTH a JPEG and a PDF copy for optimal compatibility and printing.
    """
    os.makedirs(output_dir, exist_ok=True)

    # Theme Logic
    theme = template_url if template_url else "style:classic"

    # Universal VOLO Color Palette
    bg_color = (255, 255, 255)
    if theme == "style:modern_left":
        bg_color = (250, 249, 252)

    primary_color = (152, 50, 150)
    accent_color = (152, 50, 150)
    text_color = (13, 13, 38)
    light_accent = (243, 243, 245)
    stamp_blue = (152, 50, 150)
    dev_color = (152, 50, 150)
    sig_color = (13, 13, 38)

    # 1. Create canvas in A4 aspect ratio (1200 x 850)
    w, h = 1200, 850
    img = Image.new("RGB", (w, h), bg_color)
    draw = ImageDraw.Draw(img)

    # Pre-calculate common strings
    name_display = volunteer_name.upper()
    badge_hours_text = f"{hours} {get_hours_plural(hours)}"
    date_display = f"Дата выдачи: {event_date}"

    if theme == "style:modern_left":
        # 1. Background Side Panel
        draw.rectangle([950, 0, w, h], fill=accent_color)

        # Rotated text on the side panel
        panel_text = "VOLO APPROVED"
        panel_font = _font(28, bold=True)
        txt_img = Image.new("RGBA", (h, 100), (255, 255, 255, 0))
        txt_draw = ImageDraw.Draw(txt_img)
        txt_w = txt_draw.textlength(panel_text, font=panel_font)
        # Add letter spacing manually for PIL
        txt_draw.text(
            ((h - txt_w) // 2, 30),
            panel_text,
            font=panel_font,
            fill=(255, 255, 255, 255),
        )
        txt_rotated = txt_img.rotate(270, expand=True)
        img.paste(txt_rotated, (1000, 0), txt_rotated)

        # 2. Text layout (Left aligned)
        margin_x = 100
        title_font = _font(64, bold=True)
        draw.text((margin_x, 180), "СЕРТИФИКАТ",
                  font=title_font, fill=accent_color)
        draw.line([margin_x, 260, margin_x + 180, 260],
                  fill=accent_color, width=3)

        name_font = _font(48, bold=True)
        draw.text((margin_x, 340), name_display,
                  font=name_font, fill=text_color)

        desc_font = _font(20)
        draw.text(
            (margin_x, 410),
            "За успешное участие в качестве волонтера в проекте:",
            font=desc_font,
            fill=text_color,
        )
        draw.text(
            (margin_x, 445),
            f"«{event_title}»",
            font=_font(22, bold=True),
            fill=primary_color,
        )

        draw.rounded_rectangle(
            [margin_x, 520, margin_x + 180, 570],
            radius=8,
            fill=light_accent,
            outline=accent_color,
            width=1,
        )
        draw.text(
            (margin_x + 20, 532),
            badge_hours_text,
            font=_font(20, bold=True),
            fill=primary_color,
        )

        draw.line([(margin_x, 700), (margin_x + 200, 700)],
                  fill=text_color, width=2)
        draw.text(
            (margin_x, 715),
            "ПОДПИСЬ ПАРТНЕРА",
            font=_font(12, bold=True),
            fill=text_color,
        )

        # Partner squiggly signature
        draw.line(
            [
                (margin_x + 10, 690),
                (margin_x + 25, 670),
                (margin_x + 40, 700),
                (margin_x + 55, 680),
                (margin_x + 70, 690),
                (margin_x + 85, 673),
                (margin_x + 105, 695),
            ],
            fill=sig_color,
            width=2,
        )

        # Partner circular stamp
        stamp_x_center = margin_x + 120
        draw.ellipse(
            [stamp_x_center - 45, 640, stamp_x_center + 45, 730],
            outline=stamp_blue,
            width=2,
        )
        draw.ellipse(
            [stamp_x_center - 38, 647, stamp_x_center + 31, 723],
            outline=stamp_blue,
            width=1,
        )

        org_words = org_name.split()
        line1 = org_words[0][:10] if org_words else "ОРГ"
        line2 = org_words[1][:10] if len(org_words) > 1 else ""
        if not line2 and len(org_name) > 10:
            line1 = org_name[:10]
            line2 = org_name[10:20]

        stamp_text_font = _font(8, bold=True)
        draw.text(
            (stamp_x_center -
             draw.textlength(
                 line1,
                 font=stamp_text_font) //
                2,
                660),
            line1,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        if line2:
            draw.text(
                (stamp_x_center -
                 draw.textlength(
                     line2,
                     font=stamp_text_font) //
                    2,
                    673,
                 ),
                line2,
                font=stamp_text_font,
                fill=stamp_blue,
            )

        bin_text = f"БИН {org_bin}"
        draw.text(
            (stamp_x_center -
             draw.textlength(
                 bin_text,
                 font=stamp_text_font) //
                2,
                690,
             ),
            bin_text,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        draw.text(
            (stamp_x_center -
             draw.textlength(
                 "★ APPROVED ★",
                 font=_font(
                     7,
                     bold=True)) //
                2,
                703,
             ),
            "★ APPROVED ★",
            font=_font(
                7,
                bold=True),
            fill=stamp_blue,
        )

        # VOLO developer stamp on modern_left
        dev_label = "РАЗРАБОТЧИК VOLO"
        dev_font = _font(12, bold=True)
        dev_w = draw.textlength(dev_label, font=dev_font)
        draw.text((880 - dev_w, 715), dev_label,
                  font=dev_font, fill=text_color)

        draw.line([(700, 700), (880, 700)], fill=text_color, width=1)
        draw.line(
            [
                (720, 695),
                (730, 670),
                (745, 700),
                (760, 675),
                (775, 690),
                (790, 670),
                (810, 685),
            ],
            fill=dev_color,
            width=2,
        )

        stamp_x_dev, stamp_y_dev = 800, 640
        stamp_size = 65
        draw.rectangle(
            [
                stamp_x_dev,
                stamp_y_dev,
                stamp_x_dev + stamp_size,
                stamp_y_dev + stamp_size,
            ],
            outline=accent_color,
            width=2,
        )
        draw.rectangle(
            [
                stamp_x_dev + 4,
                stamp_y_dev + 4,
                stamp_x_dev + stamp_size - 4,
                stamp_y_dev + stamp_size - 4,
            ],
            outline=primary_color,
            width=1,
        )
        draw_pixel_text(
            draw,
            "VOLO",
            x_start=stamp_x_dev + 9,
            y_start=stamp_y_dev + 11,
            pixel_size=2,
            fill=accent_color,
        )
        draw_pixel_text(
            draw,
            "APPROVED",
            x_start=stamp_x_dev + 8,
            y_start=stamp_y_dev + 27,
            pixel_size=1,
            fill=primary_color,
        )
        draw_pixel_text(
            draw,
            "2026",
            x_start=stamp_x_dev + 19,
            y_start=stamp_y_dev + 40,
            pixel_size=1,
            fill=primary_color,
        )

        draw.text((margin_x, 780), date_display,
                  font=_font(14), fill=text_color)

    elif theme == "style:minimal_bottom":
        # 1. Title Top Left
        title_font = _font(72, bold=True)
        draw.text((100, 100), "СЕРТИФИКАТ", font=title_font, fill=accent_color)

        draw_pixel_text(
            draw,
            "VOLO",
            x_start=950,
            y_start=110,
            pixel_size=6,
            fill=accent_color)

        # 2. Body Bottom Right
        name_font = _font(56, bold=True)
        name_w = draw.textlength(name_display, font=name_font)
        draw.text((w - 100 - name_w, 400), name_display,
                  font=name_font, fill=text_color)

        desc_text = f"За выдающийся вклад в проект «{event_title}»"
        desc_font = _font(22)
        desc_w = draw.textlength(desc_text, font=desc_font)
        draw.text((w - 100 - desc_w, 480), desc_text,
                  font=desc_font, fill=text_color)

        badge_w = draw.textlength(badge_hours_text, font=_font(24, bold=True))
        draw.text(
            (w - 100 - badge_w, 530),
            badge_hours_text,
            font=_font(24, bold=True),
            fill=primary_color,
        )

        draw.line([(w - 300, 700), (w - 100, 700)], fill=text_color, width=2)
        draw.text(
            (w - 250, 715),
            "ПОДПИСЬ ПАРТНЕРА",
            font=_font(12, bold=True),
            fill=text_color,
        )

        # Partner squiggly signature
        draw.line(
            [
                (w - 290, 690),
                (w - 275, 670),
                (w - 260, 700),
                (w - 245, 680),
                (w - 230, 690),
                (w - 215, 673),
                (w - 195, 695),
            ],
            fill=sig_color,
            width=2,
        )

        # Partner circular stamp
        stamp_x_center_min = w - 180
        draw.ellipse(
            [stamp_x_center_min - 45, 640, stamp_x_center_min + 45, 730],
            outline=stamp_blue,
            width=2,
        )
        draw.ellipse(
            [stamp_x_center_min - 38, 647, stamp_x_center_min + 31, 723],
            outline=stamp_blue,
            width=1,
        )

        org_words = org_name.split()
        line1 = org_words[0][:10] if org_words else "ОРГ"
        line2 = org_words[1][:10] if len(org_words) > 1 else ""
        if not line2 and len(org_name) > 10:
            line1 = org_name[:10]
            line2 = org_name[10:20]

        stamp_text_font = _font(8, bold=True)
        draw.text(
            (stamp_x_center_min -
             draw.textlength(
                 line1,
                 font=stamp_text_font) //
                2,
                660,
             ),
            line1,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        if line2:
            draw.text(
                (
                    stamp_x_center_min
                    - draw.textlength(line2, font=stamp_text_font) // 2,
                    673,
                ),
                line2,
                font=stamp_text_font,
                fill=stamp_blue,
            )

        bin_text = f"БИН {org_bin}"
        draw.text(
            (
                stamp_x_center_min
                - draw.textlength(bin_text, font=stamp_text_font) // 2,
                690,
            ),
            bin_text,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        draw.text(
            (stamp_x_center_min -
             draw.textlength(
                 "★ APPROVED ★",
                 font=_font(
                     7,
                     bold=True)) //
                2,
                703,
             ),
            "★ APPROVED ★",
            font=_font(
                7,
                bold=True),
            fill=stamp_blue,
        )

        # VOLO developer stamp on minimal_bottom
        dev_label = "РАЗРАБОТЧИК VOLO"
        dev_font = _font(12, bold=True)
        draw.text((100, 750), dev_label, font=dev_font, fill=text_color)

        draw.line([(100, 700), (280, 700)], fill=text_color, width=1)
        draw.line(
            [
                (120, 695),
                (130, 670),
                (145, 700),
                (160, 675),
                (175, 690),
                (190, 670),
                (210, 685),
            ],
            fill=dev_color,
            width=2,
        )

        stamp_x_dev2, stamp_y_dev2 = 200, 640
        stamp_size = 65
        draw.rectangle(
            [
                stamp_x_dev2,
                stamp_y_dev2,
                stamp_x_dev2 + stamp_size,
                stamp_y_dev2 + stamp_size,
            ],
            outline=accent_color,
            width=2,
        )
        draw.rectangle(
            [
                stamp_x_dev2 + 4,
                stamp_y_dev2 + 4,
                stamp_x_dev2 + stamp_size - 4,
                stamp_y_dev2 + stamp_size - 4,
            ],
            outline=primary_color,
            width=1,
        )
        draw_pixel_text(
            draw,
            "VOLO",
            x_start=stamp_x_dev2 + 9,
            y_start=stamp_y_dev2 + 11,
            pixel_size=2,
            fill=accent_color,
        )
        draw_pixel_text(
            draw,
            "APPROVED",
            x_start=stamp_x_dev2 + 8,
            y_start=stamp_y_dev2 + 27,
            pixel_size=1,
            fill=primary_color,
        )
        draw_pixel_text(
            draw,
            "2026",
            x_start=stamp_x_dev2 + 19,
            y_start=stamp_y_dev2 + 40,
            pixel_size=1,
            fill=primary_color,
        )

        draw.text((100, 780), date_display, font=_font(14), fill=text_color)
        draw.line([(100, 320), (w - 100, 320)], fill=light_accent, width=2)

    else:
        # style:classic
        draw.rectangle([30, 30, w - 30, h - 30], outline=accent_color, width=2)
        draw.rectangle([42, 42, w - 42, h - 42],
                       outline=primary_color, width=1)

        draw_pixel_text(
            draw,
            "VOLO",
            x_start=80,
            y_start=70,
            pixel_size=5,
            fill=accent_color)

        support_font = _font(15, bold=True)
        support_text = "ПРИ ПОДДЕРЖКЕ ТОО 'ZHANAT'"
        support_w = draw.textlength(support_text, font=support_font)
        draw.text(
            (w - 80 - support_w, 75),
            support_text,
            font=support_font,
            fill=primary_color,
        )

        title_font = _font(48, bold=True)
        title_text = "СЕРТИФИКАТ"
        title_w = draw.textlength(title_text, font=title_font)
        draw.text(((w - title_w) // 2, 190), title_text,
                  font=title_font, fill=primary_color)

        draw.line([w // 2 - 120, 260, w // 2 + 120, 260],
                  fill=accent_color, width=2)

        subtitle_font = _font(17)
        subtitle_text = "Настоящим подтверждается, что"
        sub_w = draw.textlength(subtitle_text, font=subtitle_font)
        draw.text(((w - sub_w) // 2, 300), subtitle_text,
                  font=subtitle_font, fill=text_color)

        name_font = _font(44, bold=True)
        name_w = draw.textlength(name_display, font=name_font)
        draw.text(((w - name_w) // 2, 360), name_display,
                  font=name_font, fill=primary_color)

        body_font = _font(16)
        desc_line1 = "успешно принял(а) участие в качестве волонтера"
        desc_w1 = draw.textlength(desc_line1, font=body_font)
        draw.text(((w - desc_w1) // 2, 440), desc_line1,
                  font=body_font, fill=text_color)

        desc_line2 = f"в мероприятии «{event_title}»"
        desc_w2 = draw.textlength(desc_line2, font=_font(18, bold=True))
        draw.text(
            ((w - desc_w2) // 2, 475),
            desc_line2,
            font=_font(18, bold=True),
            fill=primary_color,
        )

        badge_font = _font(22, bold=True)
        badge_text_w = draw.textlength(badge_hours_text, font=badge_font)
        badge_w = badge_text_w + 50
        badge_h = 50
        badge_x = (w - badge_w) // 2
        badge_y = 540

        draw.rounded_rectangle(
            [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h],
            radius=12,
            fill=light_accent,
            outline=accent_color,
            width=1,
        )
        draw.text(
            (badge_x + (badge_w - badge_text_w) // 2, badge_y + (badge_h - 26) // 2),
            badge_hours_text,
            font=badge_font,
            fill=primary_color,
        )

        org_label_font = _font(14, bold=True)
        org_label = org_name.upper()
        if len(org_label) > 28:
            org_label = org_label[:25] + "..."
        draw.text((150, 750), org_label, font=org_label_font, fill=text_color)

        draw.line(
            [
                (140, 715),
                (155, 695),
                (170, 725),
                (185, 705),
                (200, 715),
                (215, 698),
                (235, 720),
            ],
            fill=sig_color,
            width=2,
        )
        draw.line([(130, 725), (250, 723)], fill=sig_color, width=1)

        draw.ellipse([175, 660, 265, 750], outline=stamp_blue, width=2)
        draw.ellipse([182, 667, 258, 743], outline=stamp_blue, width=1)

        org_words = org_name.split()
        line1 = org_words[0][:10] if org_words else "ОРГ"
        line2 = org_words[1][:10] if len(org_words) > 1 else ""
        if not line2 and len(org_name) > 10:
            line1 = org_name[:10]
            line2 = org_name[10:20]

        stamp_text_font = _font(8, bold=True)
        draw.text(
            (220 - draw.textlength(line1, font=stamp_text_font) // 2, 680),
            line1,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        if line2:
            draw.text(
                (220 - draw.textlength(line2, font=stamp_text_font) // 2, 693),
                line2,
                font=stamp_text_font,
                fill=stamp_blue,
            )

        bin_text = f"БИН {org_bin}"
        draw.text(
            (220 - draw.textlength(bin_text, font=stamp_text_font) // 2, 710),
            bin_text,
            font=stamp_text_font,
            fill=stamp_blue,
        )
        draw.text(
            (220 -
             draw.textlength(
                 "★ APPROVED ★",
                 font=_font(
                     7,
                     bold=True)) //
                2,
                723),
            "★ APPROVED ★",
            font=_font(
                7,
                bold=True),
            fill=stamp_blue,
        )

        dev_label = "РАЗРАБОТЧИК VOLO"
        dev_w = draw.textlength(dev_label, font=org_label_font)
        draw.text((w - 150 - dev_w, 750), dev_label,
                  font=org_label_font, fill=text_color)

        draw.line(
            [
                (880, 718),
                (890, 695),
                (905, 725),
                (920, 700),
                (935, 715),
                (950, 695),
                (970, 710),
            ],
            fill=dev_color,
            width=2,
        )
        draw.line([(870, 725), (980, 723)], fill=dev_color, width=1)

        stamp_x, stamp_y = 940, 660
        stamp_size = 75
        draw.rectangle(
            [stamp_x, stamp_y, stamp_x + stamp_size, stamp_y + stamp_size],
            outline=accent_color,
            width=2,
        )
        draw.rectangle(
            [
                stamp_x + 5,
                stamp_y + 5,
                stamp_x + stamp_size - 5,
                stamp_y + stamp_size - 5,
            ],
            outline=primary_color,
            width=1,
        )

        draw_pixel_text(
            draw,
            "VOLO",
            x_start=stamp_x + 13,
            y_start=stamp_y + 16,
            pixel_size=2,
            fill=accent_color,
        )
        draw_pixel_text(
            draw,
            "APPROVED",
            x_start=stamp_x + 10,
            y_start=stamp_y + 36,
            pixel_size=1,
            fill=primary_color,
        )
        draw_pixel_text(
            draw,
            "2026",
            x_start=stamp_x + 23,
            y_start=stamp_y + 52,
            pixel_size=1,
            fill=primary_color,
        )

        date_font = _font(12)
        date_w = draw.textlength(date_display, font=date_font)
        draw.text(((w - date_w) // 2, 780), date_display,
                  font=date_font, fill=text_color)

    # 6. Save the certificate in BOTH formats
    filename = f"cert_{uuid.uuid4().hex[:12]}.jpg"
    abs_path = os.path.join(output_dir, filename)

    # Save high-res JPEG
    img.save(abs_path, "JPEG", quality=95)

    # Compile and save PDF next to it (with the exact same name)
    pdf_path = abs_path.replace(".jpg", ".pdf")
    img.save(pdf_path, "PDF")

    rel_url = f"/uploads/certificates/{filename}"
    return rel_url, abs_path
