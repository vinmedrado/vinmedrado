from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(r"C:\Users\vinimedrado\profile-readme")
REPOS = ROOT / "_repos"

CANVAS = (960, 540)
FPS_DELAY = 30  # ~3.3 fps; enough for a compact GIF with readable motion


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\calibri.ttf",
    ]
    if bold:
        candidates = [
            r"C:\Windows\Fonts\segoeuib.ttf",
            r"C:\Windows\Fonts\arialbd.ttf",
            r"C:\Windows\Fonts\calibrib.ttf",
        ] + candidates
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def open_image(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def center_crop(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    return ImageOps.fit(img, (target_w, target_h), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def ease(t: float) -> float:
    return t * t * (3 - 2 * t)


def make_frame(base: Image.Image, focus: tuple[float, float], zoom: float, title: str, steps: list[str]) -> Image.Image:
    src_w, src_h = base.size
    canvas_w, canvas_h = CANVAS
    scale = max(canvas_w / src_w, canvas_h / src_h) * zoom
    resized = base.resize((int(src_w * scale), int(src_h * scale)), Image.Resampling.LANCZOS)
    rw, rh = resized.size

    fx, fy = focus
    cx = int(rw * fx)
    cy = int(rh * fy)
    left = max(0, min(rw - canvas_w, cx - canvas_w // 2))
    top = max(0, min(rh - canvas_h, cy - canvas_h // 2))
    crop = resized.crop((left, top, left + canvas_w, top + canvas_h))

    frame = Image.new("RGBA", CANVAS, "#050816")
    frame.paste(crop, (0, 0))

    overlay = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.rounded_rectangle((42, 36, 1238, 110), radius=24, fill=(4, 8, 22, 185), outline=(96, 165, 250, 120), width=2)
    d.rounded_rectangle((42, 604, 1238, 688), radius=24, fill=(4, 8, 22, 185), outline=(96, 165, 250, 120), width=2)

    title_font = font(30, bold=True)
    label_font = font(18, bold=True)
    body_font = font(22)
    small_font = font(16)

    d.text((72, 56), title, font=title_font, fill="white")
    d.text((72, 78), "Demonstração curta • fluxo real • visual leve", font=small_font, fill=(203, 213, 225))

    pills = [
        ("01", steps[0]),
        ("02", steps[1]),
        ("03", steps[2]),
    ]
    x = 72
    for idx, label in pills:
        w = 120 if len(label) < 18 else 170
        d.rounded_rectangle((x, 622, x + w, 656), radius=17, fill=(15, 23, 42, 235), outline=(71, 85, 105, 200), width=1)
        d.text((x + 14, 632), idx, font=label_font, fill=(148, 163, 184))
        d.text((x + 48, 632), label, font=small_font, fill="white")
        x += w + 12

    d.text((72, 642), "Captura preparada para GitHub README", font=body_font, fill=(226, 232, 240))
    frame = Image.alpha_composite(frame, overlay)
    return frame.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)


def animate_single_image(src: Path, out: Path, title: str, steps: list[tuple[float, float, float, str]], repeat_last: bool = True) -> None:
    img = open_image(src)
    frames: list[Image.Image] = []
    segment_frames = 12

    for i in range(len(steps) - 1):
        (fx1, fy1, z1, _), (fx2, fy2, z2, _) = steps[i], steps[i + 1]
        for f in range(segment_frames):
            t = ease(f / segment_frames)
            focus = (lerp(fx1, fx2, t), lerp(fy1, fy2, t))
            zoom = lerp(z1, z2, t)
            frames.append(make_frame(img, focus, zoom, title, [steps[0][3], steps[1][3], steps[2][3]]))

    if repeat_last:
        for _ in range(4):
            frames.append(make_frame(img, (steps[-1][0], steps[-1][1]), steps[-1][2], title, [steps[0][3], steps[1][3], steps[2][3]]))

    out.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=FPS_DELAY * 10,
        loop=0,
        optimize=True,
        disposal=2,
    )


def animate_portfolio(srcs: list[Path], out: Path, title: str) -> None:
    images = [center_crop(open_image(p), *CANVAS) for p in srcs]
    frames: list[Image.Image] = []
    hold = 4
    fade = 3
    for i, img in enumerate(images):
        next_img = images[(i + 1) % len(images)]
        for _ in range(hold):
            frames.append(make_frame(img, (0.5, 0.5), 1.0, title, ["case studies", "project cards", "contact"]))
        for f in range(fade):
            t = ease(f / fade)
            blended = Image.blend(img, next_img, t)
            frames.append(make_frame(blended, (0.5, 0.5), 1.0, title, ["case studies", "project cards", "contact"]))

    out.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=FPS_DELAY * 10,
        loop=0,
        optimize=True,
        disposal=2,
    )


def main() -> None:
    jobs = [
        (
            REPOS / "applymize" / "assets" / "demo" / "overview.jpg",
            REPOS / "applymize" / "assets" / "demo" / "demo.gif",
            "Applymize",
            [(0.50, 0.30, 1.04, "abertura"), (0.38, 0.56, 1.14, "navegação"), (0.72, 0.60, 1.10, "IA / automação")],
        ),
        (
            REPOS / "marketplace-seller-platform" / "assets" / "demo" / "overview.png",
            REPOS / "marketplace-seller-platform" / "assets" / "demo" / "demo.gif",
            "Marketplace Seller Platform",
            [(0.52, 0.32, 1.03, "abertura"), (0.43, 0.53, 1.12, "dashboard"), (0.72, 0.58, 1.08, "pricing / ML")],
        ),
        (
            REPOS / "Lumyra" / "assets" / "demo" / "overview.png",
            REPOS / "Lumyra" / "assets" / "demo" / "demo.gif",
            "Lumyra",
            [(0.50, 0.30, 1.03, "abertura"), (0.42, 0.56, 1.10, "RSVP / operação"), (0.73, 0.58, 1.08, "realtime / analytics")],
        ),
        (
            REPOS / "football-decision-lab" / "assets" / "demo" / "overview.png",
            REPOS / "football-decision-lab" / "assets" / "demo" / "demo.gif",
            "Football Decision Lab",
            [(0.50, 0.30, 1.03, "abertura"), (0.40, 0.54, 1.12, "validação"), (0.72, 0.58, 1.08, "backtest / sinais")],
        ),
        (
            REPOS / "vinance" / "assets" / "demo" / "overview.png",
            REPOS / "vinance" / "assets" / "demo" / "demo.gif",
            "Vinance",
            [(0.50, 0.30, 1.03, "abertura"), (0.40, 0.55, 1.12, "dashboard"), (0.72, 0.60, 1.08, "IA / finanças")],
        ),
        (
            REPOS / "meu-carro-vale" / "assets" / "demo" / "overview.png",
            REPOS / "meu-carro-vale" / "assets" / "demo" / "demo.gif",
            "Meu Carro Vale",
            [(0.50, 0.30, 1.03, "abertura"), (0.40, 0.55, 1.12, "avaliação"), (0.72, 0.58, 1.08, "comparáveis / laudo")],
        ),
    ]

    for src, out, title, steps in jobs:
        animate_single_image(src, out, title, steps)
        print(f"wrote {out}")

    portfolio_srcs = [
        REPOS / "portfolio" / "images" / "og-cover.png",
        REPOS / "portfolio" / "images" / "marketplace.png",
        REPOS / "portfolio" / "images" / "applymize.jpg",
        REPOS / "portfolio" / "images" / "lumyra.png",
        REPOS / "portfolio" / "images" / "vinance.png",
        REPOS / "portfolio" / "images" / "meucarrovale.png",
        REPOS / "portfolio" / "images" / "footballdecisionlab.png",
    ]
    animate_portfolio(portfolio_srcs, REPOS / "portfolio" / "assets" / "demo" / "demo.gif", "Vinicius Medrado Portfolio")
    print("wrote portfolio gif")


if __name__ == "__main__":
    main()
