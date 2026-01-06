shader_type canvas_item;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    // 0.48 instead of 0.5 to clip slightly inside the edge
    if (dist > 0.48) {
        discard;
    }
    
    vec4 tex = texture(TEXTURE, UV);
    // Use a solid white background
    vec3 background = vec3(1.0, 1.0, 1.0);
    vec3 col = mix(background, tex.rgb, tex.a);
    COLOR = vec4(col, 1.0);
}