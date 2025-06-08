#!/usr/bin/env python3
"""
Script to generate icon files for R2MIDI applications.
Creates icons in various sizes and formats for different platforms.
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ PIL (Pillow) is required. Install with: pip install pillow")
    sys.exit(1)


def create_base_icon(size=512):
    """Create a base icon for R2MIDI with a simple but recognizable design."""
    
    # Create a new image with a transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Define colors
    primary_color = "#2D5A8A"  # Blue
    secondary_color = "#4A90C2"  # Lighter blue
    accent_color = "#F39C12"  # Orange
    text_color = "#FFFFFF"  # White
    
    # Draw circular background
    margin = size // 20
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill=primary_color,
        outline=secondary_color,
        width=size // 40
    )
    
    # Draw MIDI connector representation (5-pin DIN)
    center_x, center_y = size // 2, size // 2
    connector_radius = size // 8
    
    # Main connector circle
    draw.ellipse(
        [center_x - connector_radius, center_y - connector_radius,
         center_x + connector_radius, center_y + connector_radius],
        fill=accent_color,
        outline=text_color,
        width=size // 80
    )
    
    # 5 pins (simplified as dots)
    pin_radius = size // 40
    pin_positions = [
        (center_x, center_y - connector_radius // 2),  # Top
        (center_x - connector_radius // 3, center_y + connector_radius // 3),  # Bottom left
        (center_x + connector_radius // 3, center_y + connector_radius // 3),  # Bottom right
        (center_x - connector_radius // 2, center_y - connector_radius // 6),  # Left
        (center_x + connector_radius // 2, center_y - connector_radius // 6),  # Right
    ]
    
    for pin_x, pin_y in pin_positions:
        draw.ellipse(
            [pin_x - pin_radius, pin_y - pin_radius,
             pin_x + pin_radius, pin_y + pin_radius],
            fill=primary_color
        )
    
    # Add "R2" text at the top
    try:
        # Try to use a system font
        font_size = size // 8
        try:
            font = ImageFont.truetype("Arial", font_size)
        except (OSError, IOError):
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
            except (OSError, IOError):
                try:
                    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
                except (OSError, IOError):
                    font = ImageFont.load_default()
        
        # Get text dimensions
        bbox = draw.textbbox((0, 0), "R2", font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Position text at the top
        text_x = center_x - text_width // 2
        text_y = center_y - connector_radius - text_height - size // 20
        
        draw.text((text_x, text_y), "R2", fill=text_color, font=font)
        
    except Exception as e:
        print(f"⚠️ Could not add text to icon: {e}")
    
    # Add "MIDI" text at the bottom
    try:
        font_size_small = size // 12
        try:
            font_small = ImageFont.truetype("Arial", font_size_small)
        except (OSError, IOError):
            try:
                font_small = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size_small)
            except (OSError, IOError):
                try:
                    font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", font_size_small)
                except (OSError, IOError):
                    font_small = ImageFont.load_default()
        
        # Get text dimensions
        bbox = draw.textbbox((0, 0), "MIDI", font=font_small)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Position text at the bottom
        text_x = center_x - text_width // 2
        text_y = center_y + connector_radius + size // 20
        
        draw.text((text_x, text_y), "MIDI", fill=text_color, font=font_small)
        
    except Exception as e:
        print(f"⚠️ Could not add bottom text to icon: {e}")
    
    return img


def generate_icon_sizes(base_icon, output_dir, base_name):
    """Generate icons in various sizes required by different platforms."""
    
    # Standard icon sizes for different platforms
    sizes = {
        # macOS
        'icon_16x16.png': 16,
        'icon_32x32.png': 32,
        'icon_64x64.png': 64,
        'icon_128x128.png': 128,
        'icon_256x256.png': 256,
        'icon_512x512.png': 512,
        'icon_1024x1024.png': 1024,
        
        # Windows
        'icon_24x24.png': 24,
        'icon_48x48.png': 48,
        'icon_96x96.png': 96,
        
        # Generic/other
        'icon.png': 512,  # Default icon
        f'{base_name}.png': 512,  # Named icon
        f'{base_name}.ico': None,  # Will be created from multiple sizes
    }
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    ico_sizes = []
    
    for filename, size in sizes.items():
        output_path = output_dir / filename
        
        if filename.endswith('.ico'):
            # Create ICO file with multiple sizes
            ico_sizes = [16, 32, 48, 64, 128, 256]
            ico_images = []
            
            for ico_size in ico_sizes:
                ico_img = base_icon.resize((ico_size, ico_size), Image.Resampling.LANCZOS)
                ico_images.append(ico_img)
            
            try:
                ico_images[0].save(
                    output_path,
                    format='ICO',
                    sizes=[(s, s) for s in ico_sizes],
                    append_images=ico_images[1:]
                )
                print(f"✅ Created ICO: {output_path}")
            except Exception as e:
                print(f"⚠️ Could not create ICO file {output_path}: {e}")
        else:
            # Create PNG file
            if size:
                resized_icon = base_icon.resize((size, size), Image.Resampling.LANCZOS)
                resized_icon.save(output_path, format='PNG')
                print(f"✅ Created {size}x{size}: {output_path}")


def main():
    """Generate all icon files for R2MIDI applications."""
    
    print("🎨 Generating R2MIDI application icons...")
    
    # Create resources directory
    resources_dir = Path("resources")
    resources_dir.mkdir(exist_ok=True)
    
    # Generate base icon
    print("🖼️ Creating base icon design...")
    base_icon = create_base_icon(1024)  # Create high-resolution base
    
    # Generate icons for the main application
    print("📱 Generating icon sizes...")
    generate_icon_sizes(base_icon, resources_dir, "r2midi")
    
    # Create specific app icons if needed
    # You can customize these for server vs client if desired
    server_icon = base_icon.copy()
    client_icon = base_icon.copy()
    
    # Save the main icons
    (resources_dir / "r2midi_server.png").write_bytes(
        (resources_dir / "r2midi.png").read_bytes()
    )
    (resources_dir / "r2midi_client.png").write_bytes(
        (resources_dir / "r2midi.png").read_bytes()
    )
    
    print("✅ Icon generation complete!")
    print(f"📁 Icons saved to: {resources_dir.absolute()}")
    
    # List generated files
    print("\n📋 Generated files:")
    for icon_file in sorted(resources_dir.glob("*.png")) + sorted(resources_dir.glob("*.ico")):
        print(f"  - {icon_file.name}")


if __name__ == "__main__":
    main()
