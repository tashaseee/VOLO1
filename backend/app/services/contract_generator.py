"""
VOLO - Automated Organization Legal Contract PDF Generator.
Generates highly formal, legally-binding cooperation agreements (contracts) in Russian,
incorporating strict volunteer safety regulations, dynamic org profiles, seals, and signatures.
"""

from __future__ import annotations

import os
from datetime import datetime
from PIL import Image, ImageDraw
from .certificate_generator import _font, draw_pixel_text


def _wrap_contract_text(
    draw: ImageDraw.ImageDraw, text: str, font, max_width: int
) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        test = "{current} {word}"
        if draw.textlength(test, font=font) <= max_width:
            current = test
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def generate_organization_contract(
    *,
    org_name: str,
    org_bin: str,
    org_email: str,
    output_dir: str,
) -> str:
    """
    Generates a highly formal, legal partnership contract PDF.
    Renders dynamic organization info, strict liability clauses in Russian,
    and automatic signatures/stamps at the bottom.
    Returns the absolute path to the generated PDF contract.
    """
    os.makedirs(output_dir, exist_ok=True)

    # Portrait A4 aspect ratio at high resolution
    w, h = 1200, 1680
    # Official white background
    img = Image.new("RGB", (w, h), (255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Theme colors
    ink_color = (15, 23, 42)  # Deep slate/black
    blue_stamp = (30, 80, 180)  # Zhanat/Org blue stamp
    purple_stamp = (152, 50, 150)  # VOLO stamp
    accent_color = (100, 110, 120)  # Neutral gray for legal headers

    # Borders
    draw.rectangle([40, 40, w - 40, h - 40], outline=ink_color, width=2)
    draw.rectangle([48, 48, w - 48, h - 48], outline=accent_color, width=1)

    # Header section
    draw_pixel_text(
        draw, "VOLO", x_start=80, y_start=80, pixel_size=5, fill=purple_stamp
    )

    header_title = "СОГЛАШЕНИЕ О СОТРУДНИЧЕСТВЕ И ПАРТНЕРСТВЕ"
    header_font = _font(18, bold=True)
    header_w = draw.textlength(header_title, font=header_font)
    draw.text((w - 80 - header_w, 88), header_title,
              font=header_font, fill=ink_color)

    # Title of document
    title_font = _font(22, bold=True)
    doc_title = "ДОГОВОР-ОФЕРТА № VOLO-" + datetime.now().strftime("%Y%m%d")
    title_w = draw.textlength(doc_title, font=title_font)
    draw.text(((w - title_w) // 2, 180), doc_title,
              font=title_font, fill=ink_color)

    # Date and location
    meta_font = _font(14)
    datetime.now().strftime("%d.%m.%Y")
    draw.text((80, 230), "г. Алматы", font=meta_font, fill=ink_color)
    date_w = draw.textlength("Дата: {current_date}", font=meta_font)
    draw.text(
        (w - 80 - date_w,
         230),
        "Дата: {current_date}",
        font=meta_font,
        fill=ink_color)

    draw.line([80, 260, w - 80, 260], fill=ink_color, width=1)

    # Parties definition
    parties_text = (
        "Администрация волонтерской платформы «VOLO», именуемая в дальнейшем «Платформа», "
        "с одной стороны, и Некоммерческая/Коммерческая организация «{org_name}» "
        "(БИН: {org_bin}, Email: {org_email}), в лице руководителя, именуемая в дальнейшем «Партнер», "
        "с другой стороны, совместно именуемые «Стороны», заключили настоящее Соглашение о нижеследующем:")

    party_font = _font(13)
    lines = _wrap_contract_text(draw, parties_text, party_font, w - 160)
    y = 290
    for line in lines:
        draw.text((80, y), line, font=party_font, fill=ink_color)
        y += 24

    # Helper to draw sections
    def draw_section_header(title: str, curr_y: int) -> int:
        header_f = _font(14, bold=True)
        draw.text((80, curr_y + 15), title, font=header_f, fill=ink_color)
        return curr_y + 40

    def draw_body_text(text: str, curr_y: int, bold_prefix: str = "") -> int:
        text_f = _font(13)
        bold_f = _font(13, bold=True)

        prefix_w = 0
        if bold_prefix:
            draw.text((80, curr_y), bold_prefix, font=bold_f, fill=ink_color)
            prefix_w = draw.textlength(bold_prefix, font=bold_f) + 5

        lines = _wrap_contract_text(
            draw, text, text_f, w - 160 - int(prefix_w))

        is_first = True
        for line in lines:
            x_pos = 80 + prefix_w if is_first else 80
            draw.text((x_pos, curr_y), line, font=text_f, fill=ink_color)
            curr_y += 22
            is_first = False

        return curr_y + 8

    # Section 1: Предмет Соглашения
    y = draw_section_header("1. ПРЕДМЕТ СОГЛАШЕНИЯ", y)
    y = draw_body_text(
        "Настоящее Соглашение определяет условия партнерства при привлечении волонтеров "
        "для проведения социально-значимых, экологических, спортивных и культурных мероприятий Партнера посредством мобильного приложения VOLO.",
        y,
        "1.1.",
    )

    # Section 2: Обязанности и ограничения (Строгие правила!)
    y = draw_section_header(
        "2. СТРОГИЕ ОБЯЗАТЕЛЬСТВА И ОГРАНИЧЕНИЯ ПАРТНЕРА", y)

    y = draw_body_text(
        "Категорически запрещается привлекать волонтеров к тяжелому физическому труду, "
        "переноске тяжестей свыше норм, установленных законодательством РК, работе на высоте, в опасных или вредных для жизни условиях.",
        y,
        "2.1. ЗАПРЕТ НА ЧРЕЗМЕРНЫЙ ФИЗИЧЕСКИЙ ТРУД:",
    )

    y = draw_body_text(
        "Партнер обязуется жестко соблюдать временные рамки мероприятий. Категорически запрещается "
        "привлекать волонтера к деятельности дольше часов, официально указанных в карточке мероприятия. Сверхурочная работа не допускается.",
        y,
        "2.2. ЛИМИТ РАБОЧЕГО ВРЕМЕНИ ВОЛОНТЕРОВ:",
    )

    y = draw_body_text(
        "Партнер обязуется в полном объеме и безвозмездно предоставить волонтерам все условия координации, "
        "питания, питьевой воды, трансфера и экипировки, которые были официально указаны им в тексте заявки при публикации мероприятия.",
        y,
        "2.3. БЕЗУСЛОВНОЕ ОБЕСПЕЧЕНИЕ ЗАЯВЛЕННЫХ УСЛОВИЙ:",
    )

    y = draw_body_text(
        "Партнер обязан провести предварительный инструктаж по технике безопасности и несет единоличную "
        "ответственность за жизнь, безопасность и здоровье волонтеров в течение всего периода проведения мероприятия.",
        y,
        "2.4. БЕЗОПАСНОСТЬ НА МЕСТЕ ПРОВЕДЕНИЯ:",
    )

    # Section 3: Ответственность и суды
    y = draw_section_header("3. ОТВЕТСТВЕННОСТЬ И ПРАВОВЫЕ ПОСЛЕДСТВИЯ", y)

    y = draw_body_text(
        "В случае выявления любых нарушений прав волонтеров, непредставления заявленных условий или превышения "
        "лимита часов, Платформа оставляет за собой право немедленной и пожизненной блокировки аккаунта Партнера без права восстановления.",
        y,
        "3.1. БЛОКИРОВКА АККАУНТА:",
    )

    y = draw_body_text(
        "В соответствии с Гражданским и Уголовным кодексами Республики Казахстан, Партнер несет прямую "
        "имущественную и уголовную ответственность за любой ущерб, причиненный жизни, здоровью или личному имуществу волонтера на мероприятии.",
        y,
        "3.2. ЗАКОНОДАТЕЛЬНАЯ ОТВЕТСТВЕННОСТЬ:",
    )

    y = draw_body_text(
        "При несоблюдении Партнером условий настоящего договора, Администрация Платформы VOLO и пострадавшие "
        "волонтеры имеют законное право на незамедлительное обращение в Судебные Органы Республики Казахстан для принудительного взыскания компенсаций "
        "материального ущерба и морального вреда, а также инициирования уголовного преследования руководителей Партнера.",
        y,
        "3.3. СУДЕБНОЕ ПРЕСЛЕДОВАНИЕ:",
    )

    # Section 4: Разрешение споров
    y = draw_section_header("4. СРОК ДЕЙСТВИЯ И РАЗРЕШЕНИЕ СПОРОВ", y)
    y = draw_body_text(
        "Настоящий договор вступает в силу с момента подтверждения (активации) профиля Партнера Администратором Платформы и действует бессрочно. "
        "Все споры, не урегулированные мирным путем, подлежат рассмотрению в Специализированном межрайонном экономическом суде г. Алматы.",
        y,
        "4.1.",
    )

    # Footer section: Signatures and Seals
    y_sig = 1350
    draw.line([80, y_sig - 20, w - 80, y_sig - 20], fill=ink_color, width=1)

    sig_title_font = _font(14, bold=True)
    draw.text((80, y_sig), "ОТ ПЛАТФОРМЫ «VOLO»:",
              font=sig_title_font, fill=ink_color)
    draw.text((w // 2 + 80, y_sig), "ОТ ЛИЦА ПАРТНЕРА:",
              font=sig_title_font, fill=ink_color)

    y_lines = y_sig + 60
    sig_font = _font(12)

    # VOLO Signature Line
    draw.text((80, y_lines), "Администратор VOLO",
              font=sig_font, fill=ink_color)
    draw.line([(80, y_lines - 15), (280, y_lines - 15)],
              fill=ink_color, width=1)

    # VOLO Signature squiggly representation
    draw.line(
        [
            (140, y_lines - 35),
            (150, y_lines - 50),
            (165, y_lines - 20),
            (180, y_lines - 40),
            (195, y_lines - 30),
            (220, y_lines - 45),
        ],
        fill=(70, 30, 80),
        width=2,
    )

    # VOLO Purple Seal
    # Center at (220, y_lines - 40), size 90
    draw.rectangle([170, y_lines - 85, 260, y_lines + 5],
                   outline=purple_stamp, width=2)
    draw.rectangle([175, y_lines - 80, 255, y_lines],
                   outline=purple_stamp, width=1)
    draw_pixel_text(
        draw,
        "VOLO",
        x_start=188,
        y_start=y_lines - 65,
        pixel_size=2,
        fill=purple_stamp)
    draw_pixel_text(
        draw,
        "CONTRACT",
        x_start=181,
        y_start=y_lines - 45,
        pixel_size=1,
        fill=purple_stamp,
    )
    draw_pixel_text(
        draw,
        "OFFICIAL",
        x_start=183,
        y_start=y_lines - 30,
        pixel_size=1,
        fill=purple_stamp,
    )

    # Partner Signature Line
    clean_org_label = org_name
    if len(clean_org_label) > 28:
        clean_org_label = clean_org_label[:25] + "..."
    draw.text(
        (w // 2 + 80,
         y_lines),
        clean_org_label,
        font=sig_font,
        fill=ink_color)
    draw.line([(w // 2 + 80, y_lines - 15), (w - 80, y_lines - 15)],
              fill=ink_color, width=1)

    # Partner Signature squiggly representation
    draw.line(
        [
            (w // 2 + 140, y_lines - 32),
            (w // 2 + 155, y_lines - 48),
            (w // 2 + 170, y_lines - 18),
            (w // 2 + 185, y_lines - 38),
            (w // 2 + 200, y_lines - 28),
            (w // 2 + 225, y_lines - 42),
        ],
        fill=(30, 40, 90),
        width=2,
    )

    # Partner Blue Circular Seal
    # Center at (w // 2 + 220, y_lines - 40), radius 45
    cx, cy = w // 2 + 210, y_lines - 40
    draw.ellipse([cx - 45, cy - 45, cx + 45, cy + 45],
                 outline=blue_stamp, width=2)
    draw.ellipse([cx - 38, cy - 38, cx + 38, cy + 38],
                 outline=blue_stamp, width=1)

    stamp_text_f = _font(7, bold=True)
    # Split partner name for stamp
    p_words = org_name.split()
    p_line1 = p_words[0][:9] if p_words else "ПАРТНЕР"
    p_line2 = p_words[1][:9] if len(p_words) > 1 else ""
    if not p_line2 and len(org_name) > 9:
        p_line1 = org_name[:9]
        p_line2 = org_name[9:18]

    draw.text(
        (cx - draw.textlength(p_line1, font=stamp_text_f) // 2, cy - 25),
        p_line1,
        font=stamp_text_f,
        fill=blue_stamp,
    )
    if p_line2:
        draw.text(
            (cx - draw.textlength(p_line2, font=stamp_text_f) // 2, cy - 12),
            p_line2,
            font=stamp_text_f,
            fill=blue_stamp,
        )

    bin_t = "БИН {org_bin}"
    draw.text(
        (cx - draw.textlength(bin_t, font=stamp_text_f) // 2, cy + 6),
        bin_t,
        font=stamp_text_f,
        fill=blue_stamp,
    )
    draw.text(
        (cx -
         draw.textlength(
             "ПАРТНЕРСТВО",
             font=_font(
                 6,
                 bold=True)) //
         2,
         cy +
         18),
        "ПАРТНЕРСТВО",
        font=_font(
            6,
            bold=True),
        fill=blue_stamp,
    )

    # Save PDF
    filename = "contract_{uuid.uuid4().hex[:12]}.pdf"
    pdf_path = os.path.join(output_dir, filename)
    img.save(pdf_path, "PDF")

    return pdf_path
