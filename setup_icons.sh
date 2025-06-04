#!/bin/bash
# Script to set up icon resources for Briefcase builds

echo "Setting up icon resources for R2MIDI..."

# Create resources directory if it doesn't exist
mkdir -p resources

# Create a placeholder icon instruction file
cat > resources/CREATE_ICONS.md << 'EOF'
# Icon Requirements for R2MIDI

You need to create the following icon files:

## 1. Base Icon (PNG)
- **File**: `r2midi.png`
- **Size**: 512x512 pixels minimum (1024x1024 recommended)
- **Format**: PNG with transparency

## 2. Windows Icon
- **File**: `r2midi.ico`
- **Sizes**: Should contain multiple resolutions:
  - 16x16
  - 32x32
  - 48x48
  - 256x256
- **Tool**: Use ImageMagick or online converter

## 3. macOS Icon
- **File**: `r2midi.icns`
- **Sizes**: Should contain:
  - 16x16
  - 32x32
  - 128x128
  - 256x256
  - 512x512
  - 1024x1024
- **Tool**: Use `iconutil` on macOS or `png2icns`

## Creating Icons with ImageMagick

If you have ImageMagick installed:

```bash
# Create Windows .ico from PNG
convert r2midi.png -define icon:auto-resize=256,128,96,64,48,32,16 r2midi.ico

# For macOS, first create the iconset
mkdir r2midi.iconset
sips -z 16 16     r2midi.png --out r2midi.iconset/icon_16x16.png
sips -z 32 32     r2midi.png --out r2midi.iconset/icon_16x16@2x.png
sips -z 32 32     r2midi.png --out r2midi.iconset/icon_32x32.png
sips -z 64 64     r2midi.png --out r2midi.iconset/icon_32x32@2x.png
sips -z 128 128   r2midi.png --out r2midi.iconset/icon_128x128.png
sips -z 256 256   r2midi.png --out r2midi.iconset/icon_128x128@2x.png
sips -z 256 256   r2midi.png --out r2midi.iconset/icon_256x256.png
sips -z 512 512   r2midi.png --out r2midi.iconset/icon_256x256@2x.png
sips -z 512 512   r2midi.png --out r2midi.iconset/icon_512x512.png
sips -z 1024 1024 r2midi.png --out r2midi.iconset/icon_512x512@2x.png

# Then convert to .icns
iconutil -c icns r2midi.iconset
```

## Placeholder Icon

For testing, you can use a simple colored square or download a free MIDI-related icon from:
- https://www.flaticon.com/
- https://icons8.com/
- https://www.iconfinder.com/

Make sure any icon you use is properly licensed for your use case.
EOF

# Create a simple Python script to generate a placeholder icon
cat > resources/create_placeholder_icon.py << 'EOF'
#!/usr/bin/env python3
"""
Create a simple placeholder icon for R2MIDI
"""
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Please install Pillow: pip install Pillow")
    exit(1)

def create_placeholder_icon():
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
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 120)
    except:
        font = ImageFont.load_default()
    
    # Draw the text
    text = "R2\nMIDI"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    position = ((size - text_width) // 2, (size - text_height) // 2)
    draw.text(position, text, fill=(255, 255, 255, 255), font=font, align="center")
    
    # Save the icon
    img.save('r2midi.png', 'PNG')
    print("Created placeholder icon: r2midi.png")
    print("This is just a placeholder - please create a proper icon for production use!")

if __name__ == "__main__":
    create_placeholder_icon()
EOF

# Make the Python script executable
chmod +x resources/create_placeholder_icon.py

# Update pyproject.toml to reference the icon
echo "
Updating pyproject.toml to reference icons..."

# Note: This would need to be done manually or with a more sophisticated script
echo "
Please add the following to your pyproject.toml:

[tool.briefcase]
icon = \"resources/r2midi\"

This will make Briefcase look for:
- resources/r2midi.png
- resources/r2midi.ico (Windows)
- resources/r2midi.icns (macOS)
"

echo "
Icon setup instructions created in resources/CREATE_ICONS.md

To create a placeholder icon, run:
cd resources && python create_placeholder_icon.py

For production use, please create proper icons following the instructions.
"
