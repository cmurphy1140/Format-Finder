#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import json

def create_icon(size):
    """Create a golf-themed Format Finder app icon"""
    # Create a new image with RGBA for transparency support
    img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create rounded square background with gradient
    corner_radius = int(size * 0.18)  # iOS-style rounded corners
    
    # Draw rounded rectangle with gradient effect
    for y in range(size):
        # Beautiful gradient from deep golf green to lighter green
        r = int(34 + (60 * (y / size)))
        g = int(139 + (40 * (y / size)))
        b = int(34 + (40 * (y / size)))
        
        # Only draw within rounded rectangle bounds
        for x in range(size):
            # Check if pixel is within rounded rectangle
            in_corner_x = x < corner_radius or x > size - corner_radius
            in_corner_y = y < corner_radius or y > size - corner_radius
            
            if in_corner_x and in_corner_y:
                # Check corner radius
                corner_x = min(x, size - x - 1)
                corner_y = min(y, size - y - 1)
                if corner_x * corner_x + corner_y * corner_y <= corner_radius * corner_radius:
                    img.putpixel((x, y), (r, g, b, 255))
            else:
                img.putpixel((x, y), (r, g, b, 255))
    
    # Draw a high-quality golf ball
    center_x = size // 2
    center_y = int(size * 0.45)  # Slightly above center
    ball_radius = int(size * 0.28)
    
    # Add subtle shadow under golf ball
    shadow_offset = int(size * 0.02)
    for i in range(5):
        alpha = 50 - (i * 10)
        draw.ellipse(
            [center_x - ball_radius - i + shadow_offset, 
             center_y - ball_radius - i + shadow_offset * 2,
             center_x + ball_radius + i + shadow_offset, 
             center_y + ball_radius + i + shadow_offset * 2],
            fill=(0, 0, 0, alpha)
        )
    
    # White circle for golf ball with gradient
    for r in range(ball_radius, 0, -1):
        intensity = 255 - int((ball_radius - r) * 2)
        draw.ellipse(
            [center_x - r, center_y - r, center_x + r, center_y + r],
            fill=(intensity, intensity, intensity)
        )
    
    # Add realistic dimple pattern
    dimple_size = max(1, int(size * 0.015))
    dimple_spacing = max(6, int(size * 0.04))
    
    for angle in range(0, 360, 30):
        for radius in range(dimple_spacing, ball_radius - dimple_spacing, dimple_spacing):
            import math
            x = center_x + int(radius * math.cos(math.radians(angle)))
            y = center_y + int(radius * math.sin(math.radians(angle)))
            
            # Only draw if within ball
            if ((x - center_x) ** 2 + (y - center_y) ** 2) < (ball_radius - dimple_size * 2) ** 2:
                draw.ellipse(
                    [x - dimple_size, y - dimple_size, 
                     x + dimple_size, y + dimple_size],
                    fill=(240, 240, 240)
                )
    
    # Draw an elegant magnifying glass
    glass_radius = int(size * 0.18)
    glass_x = center_x + int(ball_radius * 0.45)
    glass_y = center_y - int(ball_radius * 0.45)
    
    # Glass lens with gradient effect
    for r in range(glass_radius, 0, -1):
        alpha = min(180, 180 - (glass_radius - r) * 4)
        color = (30, 100, 30, alpha) if r == glass_radius else (100, 200, 100, alpha)
        draw.ellipse(
            [glass_x - r, glass_y - r, glass_x + r, glass_y + r],
            outline=color if r == glass_radius else None,
            width=max(4, int(size * 0.025)) if r == glass_radius else 0,
            fill=(255, 255, 255, 20) if r < glass_radius - 2 else None
        )
    
    # Glass handle with rounded end
    handle_width = max(4, int(size * 0.025))
    handle_start_x = glass_x + int(glass_radius * 0.7)
    handle_start_y = glass_y + int(glass_radius * 0.7)
    handle_end_x = glass_x + int(glass_radius * 1.6)
    handle_end_y = glass_y + int(glass_radius * 1.6)
    
    draw.line(
        [handle_start_x, handle_start_y, handle_end_x, handle_end_y],
        fill=(30, 100, 30), width=handle_width
    )
    
    # Rounded end cap for handle
    draw.ellipse(
        [handle_end_x - handle_width//2, handle_end_y - handle_width//2,
         handle_end_x + handle_width//2, handle_end_y + handle_width//2],
        fill=(30, 100, 30)
    )
    
    # Add a stylized "F" lettermark at the bottom for Format Finder
    if size >= 120:  # Only add text for larger sizes
        letter_size = int(size * 0.15)
        letter_x = center_x
        letter_y = int(size * 0.75)
        
        # Draw stylized F
        f_width = max(3, int(size * 0.02))
        # Vertical stroke
        draw.line(
            [letter_x - letter_size//2, letter_y - letter_size//2,
             letter_x - letter_size//2, letter_y + letter_size//2],
            fill=(255, 255, 255, 200), width=f_width
        )
        # Top horizontal
        draw.line(
            [letter_x - letter_size//2, letter_y - letter_size//2,
             letter_x + letter_size//3, letter_y - letter_size//2],
            fill=(255, 255, 255, 200), width=f_width
        )
        # Middle horizontal
        draw.line(
            [letter_x - letter_size//2, letter_y,
             letter_x + letter_size//4, letter_y],
            fill=(255, 255, 255, 200), width=f_width
        )
    
    return img

def generate_ios_icons():
    """Generate all required iOS app icon sizes"""
    
    # iOS App Icon sizes (in points, will be saved at 1x, 2x, 3x)
    icon_sizes = {
        # iPhone Notification
        "20x20@2x": 40,
        "20x20@3x": 60,
        # iPhone Settings
        "29x29@2x": 58,
        "29x29@3x": 87,
        # iPhone Spotlight
        "40x40@2x": 80,
        "40x40@3x": 120,
        # iPhone App
        "60x60@2x": 120,
        "60x60@3x": 180,
        # iPad Notification
        "20x20@1x": 20,
        "20x20@2x": 40,
        # iPad Settings
        "29x29@1x": 29,
        "29x29@2x": 58,
        # iPad Spotlight
        "40x40@1x": 40,
        "40x40@2x": 80,
        # iPad App
        "76x76@1x": 76,
        "76x76@2x": 152,
        # iPad Pro App
        "83.5x83.5@2x": 167,
        # App Store
        "1024x1024@1x": 1024
    }
    
    # Create output directory - write directly to the Xcode project
    output_dir = "/Users/connormurphy/Desktop/Format Finder/FormatFinder/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Contents.json for Asset Catalog
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    for name, size in icon_sizes.items():
        # Generate icon
        icon = create_icon(size)
        
        # Save icon
        filename = f"icon_{name}.png"
        filepath = os.path.join(output_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Generated: {filename} ({size}x{size}px)")
        
        # Parse size info for Contents.json
        base_size = name.split('@')[0]
        scale = name.split('@')[1] if '@' in name else "1x"
        width, height = base_size.split('x')
        
        # Determine idiom
        if "1024x1024" in name:
            idiom = "ios-marketing"
        elif int(width.replace('.5', '')) >= 76:
            idiom = "ipad"
        else:
            idiom = "iphone"
        
        # Add to contents
        image_info = {
            "filename": filename,
            "idiom": idiom,
            "scale": scale,
            "size": base_size
        }
        contents["images"].append(image_info)
    
    # Save Contents.json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"\nGenerated Contents.json at: {contents_path}")
    print("\nAll icons generated successfully!")

if __name__ == "__main__":
    print("Generating Format Finder app icons...")
    generate_ios_icons()