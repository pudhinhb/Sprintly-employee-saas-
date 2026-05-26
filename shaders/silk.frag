#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform vec4 uColor;
uniform float uSpeed;
uniform float uScale;
uniform float uNoiseIntensity;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float time = uTime * uSpeed * 0.2;
    
    // Multi-layered sine waves for silk effect
    float noise = sin(uv.x * uScale * 5.0 + time) * 0.5;
    noise += sin(uv.y * uScale * 3.0 - time * 0.8) * 0.3;
    noise += sin((uv.x + uv.y) * uScale * 2.0 + time * 1.5) * 0.2;
    
    // Add secondary noise layer
    float noise2 = sin(uv.x * uScale * 10.0 - time * 1.2) * 0.1;
    noise2 += sin(uv.y * uScale * 8.0 + time * 0.5) * 0.1;
    
    float finalNoise = (noise + noise2) * uNoiseIntensity;
    
    // Silk color manipulation
    vec3 baseColor = uColor.rgb;
    
    // Iridescence / Highlights - Tone down intensity
    // We add some shine and variation based on the waves
    vec3 highlight = vec3(0.05) * pow(max(0.0, finalNoise + 0.5), 4.0);
    vec3 shadow = baseColor * (1.0 + finalNoise * 0.1);
    
    vec3 color = shadow + highlight;
    
    // Blend with original color more strongly to maintain theme sync
    color = mix(baseColor, color, 0.5);
    
    fragColor = vec4(color, uColor.a);
}
