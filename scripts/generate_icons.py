#!/usr/bin/env python3
"""
Generate icon files for R2MIDI applications
"""
import os
import sys
import subprocess
from pathlib import Path

def create_placeholder_icon():
    """Create a placeholder icon using the existing script"""
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Installing Pillow...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        from PIL import Image, ImageDraw, ImageFont

    # Create a new image with a gradient background
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw a rounded rectangle background
    padding = 50
    draw.rounded_rectangle(
        [(padding, padding), (size-padding, size-padding)],
        radius=50,
        fill=(41, 128, 185, 255),  # Nice blue color
        outline=(255, 255, 255, 255),
        width=5
    )

    # Try to use a nice font, fall back to default if not available
    try:
        # Try common system fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",  # macOS
            "/Library/Fonts/Arial.ttf",             # macOS
            "/Windows/Fonts/arial.ttf",             # Windows
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",  # Linux
        ]

        font = None
        for path in font_paths:
            if os.path.exists(path):
                font = ImageFont.truetype(path, 120)
                break

        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Draw the text
    text = "R2\nMIDI"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    position = ((size - text_width) // 2, (size - text_height) // 2)
    draw.text(position, text, fill=(255, 255, 255, 255), font=font, align="center")

    return img

def save_png(img, output_dir):
    """Save the image as PNG"""
    png_path = os.path.join(output_dir, "r2midi.png")
    img.save(png_path, 'PNG')
    print(f"Created PNG icon: {png_path}")
    return png_path

def create_icns(png_path, output_dir):
    """Create macOS .icns file from PNG"""
    # Create iconset directory
    iconset_dir = os.path.join(output_dir, "r2midi.iconset")
    os.makedirs(iconset_dir, exist_ok=True)

    # Generate different sizes
    sizes = [16, 32, 128, 256, 512]
    for size in sizes:
        # Regular resolution
        output_path = os.path.join(iconset_dir, f"icon_{size}x{size}.png")
        subprocess.run(["sips", "-z", str(size), str(size), png_path, "--out", output_path], 
                      check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Retina resolution (2x)
        if size * 2 <= 1024:  # Don't exceed 1024
            output_path = os.path.join(iconset_dir, f"icon_{size}x{size}@2x.png")
            subprocess.run(["sips", "-z", str(size*2), str(size*2), png_path, "--out", output_path],
                          check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Convert iconset to icns
    icns_path = os.path.join(output_dir, "r2midi.icns")
    try:
        subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
        print(f"Created ICNS icon: {icns_path}")
    except subprocess.CalledProcessError:
        print("Failed to create ICNS file. This is expected on non-macOS platforms.")
        # Create an empty file as a placeholder
        Path(icns_path).touch()
        print(f"Created empty placeholder ICNS file: {icns_path}")

    return icns_path

def create_ico(png_path, output_dir):
    """Create Windows .ico file from PNG"""
    try:
        from PIL import Image
        img = Image.open(png_path)

        # Create different sizes for ICO
        sizes = [16, 32, 48, 64, 128, 256]
        ico_path = os.path.join(output_dir, "r2midi.ico")

        # Resize and save as ICO
        img.save(ico_path, sizes=[(size, size) for size in sizes])
        print(f"Created ICO icon: {ico_path}")
        return ico_path
    except Exception as e:
        print(f"Failed to create ICO file: {e}")
        # Create an empty file as a placeholder
        ico_path = os.path.join(output_dir, "r2midi.ico")
        Path(ico_path).touch()
        print(f"Created empty placeholder ICO file: {ico_path}")
        return ico_path

def main():
    # Determine output directory - default to resources folder
    output_dir = os.environ.get("ICON_OUTPUT_DIR", "resources")

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Create placeholder icon
    img = create_placeholder_icon()

    # Save as PNG
    png_path = save_png(img, output_dir)

    # Create platform-specific icons
    create_icns(png_path, output_dir)
    create_ico(png_path, output_dir)

    print(f"All icon files generated in {output_dir}")

if __name__ == "__main__":
    main()
