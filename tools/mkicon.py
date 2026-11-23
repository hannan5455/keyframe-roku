"""Draw the screensaver icon: two stacked photo prints on a teal gradient. No dependencies."""
import math
import struct
import sys
import zlib

SS = 4  # supersampling per axis


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def over(dst, src, alpha):
    return lerp(dst, src, alpha)


def local(px, py, cx, cy, deg):
    a = math.radians(-deg)
    dx, dy = px - cx, py - cy
    return dx * math.cos(a) - dy * math.sin(a), dx * math.sin(a) + dy * math.cos(a)


def in_rrect(u, v, w, h, r):
    dx, dy = abs(u) - (w / 2 - r), abs(v) - (h / 2 - r)
    return math.hypot(max(dx, 0), max(dy, 0)) <= r and dx <= r and dy <= r


def landscape(s, t, aspect):
    col = lerp((108, 182, 255), (255, 208, 160), t)
    if math.hypot((s - 0.73) * aspect, t - 0.30) < 0.13:
        col = (255, 240, 170)
    if t >= 0.52 + abs(s - 0.70) * 1.5:
        col = (40, 96, 150)
    if t >= 0.36 + abs(s - 0.33) * 1.75:
        col = (22, 58, 104)
    return col


def sunset(s, t, aspect):
    return lerp((255, 150, 120), (255, 96, 150), (s + t) / 2)


def sample(x, y, W, H):
    k = H / 218.0
    g = (x / W + y / H) / 2
    col = lerp((9, 32, 60), (20, 128, 132), g)

    cards = [
        (W / 2 - 22 * k, H / 2 - 6 * k, -11, sunset),
        (W / 2 + 12 * k, H / 2 + 6 * k, 6, landscape),
    ]
    cw, ch, border, rad = 150 * k, 112 * k, 8 * k, 7 * k
    for cx, cy, deg, paint in cards:
        su, sv = local(x, y, cx + 4 * k, cy + 6 * k, deg)
        if in_rrect(su, sv, cw + 4 * k, ch + 4 * k, rad + 2 * k):
            col = over(col, (0, 0, 0), 0.30)
        u, v = local(x, y, cx, cy, deg)
        if in_rrect(u, v, cw, ch, rad):
            iw, ih = cw - 2 * border, ch - 2 * border
            if abs(u) <= iw / 2 and abs(v) <= ih / 2:
                col = paint(u / iw + 0.5, v / ih + 0.5, iw / ih)
            else:
                col = (250, 250, 246)
    return col


def png(path, W, H):
    rows = bytearray()
    n = SS * SS
    for py in range(H):
        rows.append(0)
        for px in range(W):
            acc = [0.0, 0.0, 0.0]
            for j in range(SS):
                for i in range(SS):
                    c = sample(px + (i + 0.5) / SS, py + (j + 0.5) / SS, W, H)
                    acc[0] += c[0]
                    acc[1] += c[1]
                    acc[2] += c[2]
            rows.extend(int(round(v / n)) for v in acc)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(rows), 9)))
        f.write(chunk(b"IEND", b""))


out = sys.argv[1]
png(out + "/icon_hd.png", 290, 218)
png(out + "/icon_sd.png", 246, 140)
