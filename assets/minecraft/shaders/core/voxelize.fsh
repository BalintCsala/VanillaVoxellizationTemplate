#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>
#moj_import <voxelization.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec3 ChunkOffset;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in float dataFace;
in vec4 glpos;
flat in ivec2 cell;

out vec4 fragColor;

void main() {
    ivec2 screenSize = getScreenSize(gl_FragCoord.xy, glpos);
    discardControl(gl_FragCoord.xy, float(screenSize.x));
    if (dataFace < 0.5) {
        vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
        if (color.a < 0.5) {
            discard;
        }
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    } else if (dataFace < 1.5) {
        fragColor = vertexColor;
        ivec2 pixel = cellToPixel(cell, screenSize);
        if (ivec2(gl_FragCoord.xy) != pixel)
            discard;
    } else {
        vec3 storedChunkOffset = mod(ChunkOffset, vec3(16)) / 16.0;
        fragColor = vec4(encodeFloat(storedChunkOffset[int(gl_FragCoord.x)]), 1);
    }
}
