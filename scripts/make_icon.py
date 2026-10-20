"""Ícono de SportStats: una cápsula grande (mitad blanca, mitad tinta) sobre el gris cálido de la app."""
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

# Uso: python scripts/make_icon.py  (requiere Pillow: pip install pillow)
OUT = sys.argv[1] if len(sys.argv) > 1 else "Frontend/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
S = 2                      # sobremuestreo
N = 1024 * S
C = N // 2
L, T = 700 * S, 300 * S    # largo y grosor de la cápsula
ANGLE = 40


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def vgradient(size, top, bottom, y0=0, y1=None):
    w, h = size
    y1 = h if y1 is None else y1
    img = Image.new("RGB", size)
    px = img.load()
    a, b = hexrgb(top), hexrgb(bottom)
    for y in range(h):
        t = min(max((y - y0) / max(y1 - y0, 1), 0), 1)
        c = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def rotate(layer):
    return layer.rotate(ANGLE, resample=Image.BICUBIC, center=(C, C))


# Fondo
bg = vgradient((N, N), "F6F5F4", "DFDDDC").convert("RGBA")

# Forma de la cápsula sin rotar
x0, x1 = C - L // 2, C + L // 2
y0, y1 = C - T // 2, C + T // 2
shape = Image.new("L", (N, N), 0)
ImageDraw.Draw(shape).rounded_rectangle((x0, y0, x1, y1), radius=T // 2, fill=255)
left = Image.new("L", (N, N), 0)
ImageDraw.Draw(left).rectangle((0, 0, C, N), fill=255)
right = Image.new("L", (N, N), 0)
ImageDraw.Draw(right).rectangle((C, 0, N, N), fill=255)
left_mask = ImageChops.multiply(shape, left)
right_mask = ImageChops.multiply(shape, right)

# Sombra
shadow_mask = rotate(shape).filter(ImageFilter.GaussianBlur(34 * S))
shadow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
shadow.putalpha(shadow_mask.point(lambda v: int(v * 0.28)))
bg.alpha_composite(shadow, (0, 34 * S))

# Mitades con volumen (más claras arriba, más oscuras abajo)
pill = Image.new("RGBA", (N, N), (0, 0, 0, 0))
white = vgradient((N, N), "FFFFFF", "CFCED1", y0, y1).convert("RGBA")
ink = vgradient((N, N), "45454C", "0F0F11", y0, y1).convert("RGBA")
pill.paste(white, (0, 0), left_mask)
pill.paste(ink, (0, 0), right_mask)

# Unión entre mitades
seam = Image.new("L", (N, N), 0)
ImageDraw.Draw(seam).rectangle((C - 3 * S, 0, C + 3 * S, N), fill=255)
seam = ImageChops.multiply(seam, shape)
pill.paste((10, 10, 12, 255), (0, 0), seam)

# Brillo superior
gloss = Image.new("L", (N, N), 0)
inset = int(T * 0.30)
ImageDraw.Draw(gloss).rounded_rectangle(
    (x0 + inset, y0 + int(T * 0.12), x1 - inset, y0 + int(T * 0.30)),
    radius=int(T * 0.09), fill=255)
gloss = gloss.filter(ImageFilter.GaussianBlur(6 * S))
gloss_layer = Image.new("RGBA", (N, N), (255, 255, 255, 0))
gloss_layer.putalpha(gloss.point(lambda v: int(v * 0.55)))
pill.alpha_composite(gloss_layer)

bg.alpha_composite(rotate(pill))
bg.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(OUT)
print("ok", OUT)
