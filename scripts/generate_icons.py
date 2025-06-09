#!/usr/bin/env python3
"""
Generate icon files for R2MIDI applications.

This script generates the required icon files in various formats
for different platforms (Windows .ico, macOS .icns, Linux .png).
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Pillow is required. Install with: pip install pillow")
    sys.exit(1)


def create_base_icon(size=1024):
    """Create a base R2MIDI icon."""
    # Create a new image with a gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a gradient background
    for i in range(size):
        color = int(255 * (1 - i / size))
        draw.rectangle([(0, i), (size, i + 1)], fill=(0, color, 255, 255))
    
    # Draw a circle
    margin = size // 8
    draw.ellipse(
        [(margin, margin), (size - margin, size - margin)],
        fill=(255, 255, 255, 200),
        outline=(0, 0, 0, 255),
        width=size // 50
    )
    
    # Draw text
    text = "R2"
    try:
        # Try to use a nice font if available
        font_size = size // 3
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    # Get text bbox
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Draw text centered
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    draw.text((x, y), text, fill=(0, 0, 0, 255), font=font)
    
    # Draw "MIDI" text below
    text2 = "MIDI"
    try:
        font2 = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size // 3)
    except:
        font2 = font
    
    bbox2 = draw.textbbox((0, 0), text2, font=font2)
    text_width2 = bbox2[2] - bbox2[0]
    text_height2 = bbox2[3] - bbox2[1]
    
    x2 = (size - text_width2) // 2
    y2 = y + text_height + size // 20
    draw.text((x2, y2), text2, fill=(0, 0, 0, 255), font=font2)
    
    return img


def generate_windows_ico(base_img, output_path):
    """Generate Windows .ico file with multiple sizes."""
    sizes = [16, 32, 48, 64, 128, 256]
    images = []
    
    for size in sizes:
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        images.append(resized)
    
    # Save as ICO
    images[0].save(output_path, format='ICO', sizes=[(s, s) for s in sizes])
    print(f"✅ Created Windows icon: {output_path}")


def generate_macos_icns(base_img, output_path):
    """Generate macOS .icns file."""
    # For simplicity, we'll create a temporary iconset
    import tempfile
    import subprocess
    
    with tempfile.TemporaryDirectory() as tmpdir:
        iconset_path = Path(tmpdir) / "icon.iconset"
        iconset_path.mkdir()
        
        # macOS icon sizes
        sizes = {
            'icon_16x16.png': 16,
            'icon_16x16@2x.png': 32,
            'icon_32x32.png': 32,
            'icon_32x32@2x.png': 64,
            'icon_128x128.png': 128,
            'icon_128x128@2x.png': 256,
            'icon_256x256.png': 256,
            'icon_256x256@2x.png': 512,
            'icon_512x512.png': 512,
            'icon_512x512@2x.png': 1024,
        }
        
        for filename, size in sizes.items():
            resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(iconset_path / filename)
        
        # Convert to icns using iconutil
        try:
            subprocess.run(
                ['iconutil', '-c', 'icns', str(iconset_path), '-o', str(output_path)],
                check=True
            )
            print(f"✅ Created macOS icon: {output_path}")
        except subprocess.CalledProcessError:
            print(f"⚠️  Failed to create macOS icon (iconutil not available)")
            # Fallback: save as PNG
            base_img.save(output_path.with_suffix('.png'))
            print(f"✅ Created PNG fallback: {output_path.with_suffix('.png')}")


def generate_linux_png(base_img, output_path):
    """Generate Linux PNG icons."""
    sizes = [16, 32, 48, 64, 128, 256, 512]
    
    for size in sizes:
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        size_path = output_path.parent / f"r2midi-{size}x{size}.png"
        resized.save(size_path)
        print(f"✅ Created Linux icon: {size_path}")
    
    # Also save the full size
    base_img.save(output_path)
    print(f"✅ Created Linux icon: {output_path}")


def main():
    """Generate all required icon files."""
    # Create resources directory
    resources_dir = Path("resources")
    resources_dir.mkdir(exist_ok=True)
    
    print("🎨 Generating R2MIDI icons...")
    
    # Create base icon
    base_icon = create_base_icon(1024)
    
    # Generate icons for each platform
    generate_windows_ico(base_icon, resources_dir / "r2midi.ico")
    
    if sys.platform == "darwin":
        generate_macos_icns(base_icon, resources_dir / "r2midi.icns")
    else:
        print("⚠️  Skipping macOS .icns generation (not on macOS)")
        base_icon.save(resources_dir / "r2midi.png")
    
    generate_linux_png(base_icon, resources_dir / "r2midi.png")
    
    print("\n✅ Icon generation complete!")
    print(f"📁 Icons saved to: {resources_dir.absolute()}")


if __name__ == "__main__":
    main()
