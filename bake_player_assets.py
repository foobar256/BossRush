from PIL import Image, ImageDraw, ImageOps

def bake_player():
    # Load base image
    base = Image.open('assets/base.webp').convert('RGBA')
    w, h = base.size
    min_dim = min(w, h)
    
    # Square crop from center
    left = (w - min_dim) / 2
    top = (h - min_dim) / 2
    right = (w + min_dim) / 2
    bottom = (h + min_dim) / 2
    base_sq = base.crop((left, top, right, bottom))
    
    # Create the circular player image
    # We want a high-res version, let's say 512x512
    size = 512
    base_sq = base_sq.resize((size, size), Image.LANCZOS)
    
    # According to the GDScript:
    # radius = 48
    # outline_thickness = 6
    # target_size = (radius - 4) * 2 = 88
    # So sprite occupies 88/96 of the circle radius?
    # No, radius 48 is the center of the arc? 
    # draw_arc(..., radius, ..., outline_thickness, ...)
    # In Godot, draw_arc thickness grows both ways from the radius line.
    # So the total diameter is 48*2 + 6 = 102? No, 48*2 = 96 is the center line.
    # Inner radius: 48 - 6/2 = 45
    # Outer radius: 48 + 6/2 = 51
    # Sprite size: (48-4)*2 = 88 diameter -> 44 radius.
    
    # Scale to our 512px canvas
    # Let 512 be the absolute outer bound (radius 51 equivalent)
    # scale = 512 / (51 * 2) = 512 / 102 = 5.019
    # Border thickness = 6 * scale = 30.1
    # Border center radius = 48 * scale = 240.9
    # Sprite radius = 44 * scale = 220.8
    
    scale = size / 102.0
    border_thickness = 6 * scale
    border_radius = 48 * scale
    sprite_radius = 44 * scale
    
    # 1. Create player.webp (base + border + transparency)
    player = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Draw the sprite circle
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    center = size / 2
    mask_draw.ellipse([center - sprite_radius, center - sprite_radius, 
                       center + sprite_radius, center + sprite_radius], fill=255)
    
    # Apply mask to base
    sprite_part = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    sprite_part.paste(base_sq, (0, 0))
    # Note: the shader mixes with white, so let's preserve that if needed, 
    # but the user wants transparency outside the border.
    
    final_player = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final_player.paste(sprite_part, (0, 0), mask)
    
    # Draw border on final_player
    draw = ImageDraw.Draw(final_player)
    draw.ellipse([center - border_radius - border_thickness/2, center - border_radius - border_thickness/2,
                  center + border_radius + border_thickness/2, center + border_radius + border_thickness/2],
                 outline=(0, 0, 0, 255), width=int(border_thickness))
    
    final_player.save('assets/player.webp', 'WEBP')
    
    # 2. Create border.webp (just the border)
    border_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_img)
    border_draw.ellipse([center - border_radius - border_thickness/2, center - border_radius - border_thickness/2,
                         center + border_radius + border_thickness/2, center + border_radius + border_thickness/2],
                        outline=(0, 0, 0, 255), width=int(border_thickness))
    border_img.save('assets/border.webp', 'WEBP')

if __name__ == '__main__':
    bake_player()
