"""Ícono de SportStats: un tarro de proteína negro con etiqueta blanca y un rayo,
sobre el gris cálido de la app."""
import sys
from PIL import Image, ImageDraw, ImageFilter

# Uso: python scripts/make_icon.py  (requiere Pillow: pip install pillow)
OUT = sys.argv[1] if len(sys.argv) > 1 else "Frontend/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
S = 2                      # sobremuestreo
N = 1024 * S


def px(v):
    return int(v * S)


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(box, stops, horizontal):
    """Degradado por tramos dentro de box; stops = [(posición 0..1, "RRGGBB"), ...]."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    length = w if horizontal else h
    line = Image.new("RGB", (length, 1))
    for i in range(length):
        t = i / max(length - 1, 1)
        for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
            if p0 <= t <= p1:
                line.putpixel((i, 0), lerp(hexrgb(c0), hexrgb(c1), (t - p0) / max(p1 - p0, 1e-6)))
                break
    if horizontal:
        return line.resize((w, h))
    return line.transpose(Image.ROTATE_270).resize((w, h))


def paint(canvas, box, stops, radius, horizontal=True):
    """Pinta un rectángulo redondeado con degradado sobre canvas."""
    x0, y0, x1, y1 = box
    mask = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, x1 - x0 - 1, y1 - y0 - 1), radius=radius, fill=255)
    canvas.paste(gradient(box, stops, horizontal), (x0, y0), mask)


# Sombreado de cilindro: brillo a la izquierda, oscuro en los bordes
INK = [(0, "232328"), (0.22, "4A4A52"), (0.45, "26262B"), (1, "0C0C0E")]
LID = [(0, "1A1A1E"), (0.22, "3C3C44"), (0.45, "1E1E22"), (1, "08080A")]
LABEL = [(0, "D8D7DA"), (0.25, "FFFFFF"), (0.6, "F1F0F2"), (1, "BDBCC0")]

# Fondo
img = gradient((0, 0, N, N), [(0, "F6F5F4"), (1, "DFDDDC")], horizontal=False).convert("RGBA")

# Sombra del tarro
shadow = Image.new("L", (N, N), 0)
ImageDraw.Draw(shadow).ellipse((px(250), px(810), px(774), px(900)), fill=255)
shadow = shadow.filter(ImageFilter.GaussianBlur(px(26)))
dark = Image.new("RGBA", (N, N), (0, 0, 0, 0))
dark.putalpha(shadow.point(lambda v: int(v * 0.35)))
img.alpha_composite(dark)

# Cuerpo
body = (px(272), px(318), px(752), px(858))
paint(img, body, INK, px(70))

# Etiqueta blanca
label = (px(272), px(470), px(752), px(730))
paint(img, label, LABEL, 0)

# Rayo en la etiqueta
cx, cy = px(512), px(600)
bolt = [(-14, -112), (-62, 14), (-10, 14), (-30, 112), (58, -24), (6, -24), (34, -112)]
ImageDraw.Draw(img).polygon([(cx + px(x), cy + px(y)) for x, y in bolt], fill=hexrgb("1C1C1F"))

# Cuello entre cuerpo y tapa
paint(img, (px(292), px(296), px(732), px(336)), LID, px(8))

# Tapa con estrías
lid = (px(252), px(170), px(772), px(310))
paint(img, lid, LID, px(34))
draw = ImageDraw.Draw(img)
for x in range(292, 740, 30):
    draw.rectangle((px(x), px(196), px(x) + px(5), px(284)), fill=(0, 0, 0, 110))
# Brillo del borde superior de la tapa
gloss = Image.new("L", (N, N), 0)
ImageDraw.Draw(gloss).rounded_rectangle((px(300), px(184), px(560), px(196)), radius=px(6), fill=255)
gloss = gloss.filter(ImageFilter.GaussianBlur(px(4)))
shine = Image.new("RGBA", (N, N), (255, 255, 255, 0))
shine.putalpha(gloss.point(lambda v: int(v * 0.35)))
img.alpha_composite(shine)

img.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(OUT)
print("ok", OUT)
