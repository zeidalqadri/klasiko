#!/usr/bin/env python3
"""
Create Windows .ico file from PNG images
Requires: pip install Pillow
"""

from PIL import Image

def create_ico():
    """Create a Windows .ico file from multiple PNG sizes"""
    sizes = [16, 32, 48, 64, 128, 256]
    images = []

    for size in sizes:
        img_path = f'packaging/windows/klasiko-{size}.png'
        try:
            img = Image.open(img_path)
            images.append(img)
            print(f"✓ Loaded {size}x{size} image")
        except FileNotFoundError:
            print(f"✗ Warning: {img_path} not found, skipping...")

    if images:
        # Save as .ico with all sizes
        output_path = 'packaging/windows/klasiko.ico'
        images[0].save(
            output_path,
            format='ICO',
            sizes=[(img.width, img.height) for img in images]
        )
        print(f"\n✓ Created {output_path} with {len(images)} sizes")
    else:
        print("✗ Error: No images found")
        exit(1)

if __name__ == '__main__':
    create_ico()
