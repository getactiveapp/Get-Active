#!/usr/bin/env python3
"""
Generate App Icon following Apple's best practices
Creates a 1024x1024 icon with rounded corners, gradient background, and logo
"""

from PIL import Image, ImageDraw, ImageFont
import math

def generate_app_icon():
    # Apple recommends 1024x1024 for app icons
    size = 1024
    icon = Image.new('RGB', (size, size), color='black')
    draw = ImageDraw.Draw(icon)
    
    # Create gradient background (dark grey with gradient)
    # Top color: lighter grey
    top_color = (64, 64, 69)  # #404045
    # Bottom color: darker grey
    bottom_color = (38, 38, 43)  # #26262B
    
    # Draw gradient
    for y in range(size):
        ratio = y / size
        r = int(top_color[0] * (1 - ratio) + bottom_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bottom_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bottom_color[2] * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b))
    
    # Calculate logo dimensions
    center_x, center_y = size // 2, size // 2
    logo_radius = int(size * 0.35)  # 35% of icon size
    
    # Draw red circle (C shape) - draw full circle first
    circle_bbox = [
        center_x - logo_radius,
        center_y - logo_radius,
        center_x + logo_radius,
        center_y + logo_radius
    ]
    
    # Draw red C shape (circle with opening on right)
    # Create a temporary image for the C shape
    circle_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    circle_draw = ImageDraw.Draw(circle_img)
    
    # Red colors for gradient
    red_color = (255, 51, 51)  # Bright red #FF3333
    darker_red = (217, 26, 26)  # Darker red #D91A1A
    
    # Draw C shape - circle with opening on right side
    # The opening should be from about -45 to 45 degrees (right side)
    opening_angle_start = -math.pi / 4  # -45 degrees
    opening_angle_end = math.pi / 4     # 45 degrees
    opening_start_radius = logo_radius * 0.55  # Start cutout from middle
    
    # Draw the C shape (circle minus the opening)
    for y in range(center_y - logo_radius, center_y + logo_radius):
        for x in range(center_x - logo_radius, center_x + logo_radius):
            dx = x - center_x
            dy = y - center_y
            distance = math.sqrt(dx*dx + dy*dy)
            angle = math.atan2(dy, dx)
            
            # Check if pixel is inside circle
            if distance <= logo_radius and distance >= logo_radius * 0.75:  # Make it a ring/thick C
                # Check if pixel is in the opening (right side)
                if opening_angle_start <= angle <= opening_angle_end and distance >= opening_start_radius:
                    continue  # Skip pixels in the opening
                
                # Create radial gradient
                ratio = (distance - logo_radius * 0.75) / (logo_radius * 0.25)
                ratio = max(0, min(1, ratio))
                r = int(red_color[0] * (1 - ratio * 0.4) + darker_red[0] * (ratio * 0.4))
                g = int(red_color[1] * (1 - ratio * 0.4) + darker_red[1] * (ratio * 0.4))
                b = int(red_color[2] * (1 - ratio * 0.4) + darker_red[2] * (ratio * 0.4))
                
                circle_draw.point((x, y), fill=(r, g, b, 255))
    
    # Also fill the inner area of C (make it a solid C shape)
    for y in range(center_y - logo_radius, center_y + logo_radius):
        for x in range(center_x - logo_radius, center_x + logo_radius):
            dx = x - center_x
            dy = y - center_y
            distance = math.sqrt(dx*dx + dy*dy)
            angle = math.atan2(dy, dx)
            
            # Fill inside the C (but not in opening)
            if distance < logo_radius * 0.75:
                # Skip opening area
                if not (opening_angle_start <= angle <= opening_angle_end):
                    ratio = distance / (logo_radius * 0.75)
                    r = int(red_color[0] * (1 - ratio * 0.3) + darker_red[0] * (ratio * 0.3))
                    g = int(red_color[1] * (1 - ratio * 0.3) + darker_red[1] * (ratio * 0.3))
                    b = int(red_color[2] * (1 - ratio * 0.3) + darker_red[2] * (ratio * 0.3))
                    circle_draw.point((x, y), fill=(r, g, b, 255))
    
    # Paste C shape onto main image
    icon = Image.alpha_composite(icon.convert('RGBA'), circle_img).convert('RGB')
    draw = ImageDraw.Draw(icon)
    
    # Draw white outline for C shape (arc with opening on right)
    outline_width = int(size * 0.015)  # 1.5% of size
    
    # Create outline layer
    outline_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    outline_draw = ImageDraw.Draw(outline_img)
    
    # Draw white outline arc (C shape) - avoid right side opening
    # Start from top (90 degrees) and draw around to bottom (270 degrees)
    for radius in [logo_radius - outline_width, logo_radius, logo_radius + outline_width]:
        points = []
        for angle_deg in range(45, 316):  # From top-right to bottom-right (avoiding opening)
            angle = math.radians(angle_deg)
            x = center_x + radius * math.cos(angle)
            y = center_y + radius * math.sin(angle)
            points.append((x, y))
        
        if len(points) > 1:
            # Draw thick outline
            for i in range(len(points) - 1):
                outline_draw.line([points[i], points[i+1]], fill='white', width=outline_width)
    
    # Combine outline with main icon
    icon = Image.alpha_composite(icon.convert('RGBA'), outline_img).convert('RGB')
    draw = ImageDraw.Draw(icon)
    
    # Draw letter A in the center
    # Try to load system font, fallback to default
    try:
        font_size = int(logo_radius * 1.4)
        # Use a bold font
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
    
    # Draw A letter with red fill and white outline
    text = "A"
    
    # Try to get a better bold font
    try:
        # Try Arial Bold or Helvetica Bold
        font_size = int(logo_radius * 1.5)
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", font_size)
            except:
                font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        font = ImageFont.load_default()
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Position A centered but slightly to the left (inside the C)
    text_x = center_x - text_width // 2 - int(logo_radius * 0.12)
    text_y = center_y - text_height // 2 + int(size * 0.02)  # Slight adjustment
    
    # Create text layer for better rendering
    text_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(text_img)
    
    # Draw white outline (stroke) first - thicker
    outline_thickness = int(size * 0.025)
    for adj_x in range(-outline_thickness, outline_thickness + 1):
        for adj_y in range(-outline_thickness, outline_thickness + 1):
            if adj_x * adj_x + adj_y * adj_y <= outline_thickness * outline_thickness:
                text_draw.text((text_x + adj_x, text_y + adj_y), text, font=font, fill=(255, 255, 255, 255))
    
    # Draw red fill on top
    text_draw.text((text_x, text_y), text, font=font, fill=(*red_color, 255))
    
    # Combine text with main icon
    icon = Image.alpha_composite(icon.convert('RGBA'), text_img).convert('RGB')
    draw = ImageDraw.Draw(icon)
    
    # Apply rounded corners (Apple's standard corner radius is 22.37% for 1024x1024)
    corner_radius = int(size * 0.2237)
    
    # Create mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    
    # Draw rounded rectangle mask
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=corner_radius, fill=255)
    
    # Apply mask to icon
    icon_alpha = icon.convert('RGBA')
    icon_alpha.putalpha(mask)
    
    # Save the icon
    output_path = "/Users/techsgivingsummit/Downloads/Get Active/Get Active/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    icon_alpha.save(output_path, 'PNG')
    print(f"App icon generated successfully at: {output_path}")
    print(f"Size: {size}x{size} pixels")
    print("Following Apple's design guidelines:")

if __name__ == "__main__":
    generate_app_icon()

