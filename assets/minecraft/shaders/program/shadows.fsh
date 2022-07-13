#version 150

in vec2 texCoord;
in vec3 sunDir;
in mat4 projMat;
in mat4 modelViewMat;
in vec3 chunkOffset;
in vec3 rayDir;
in float near;
in float far;
in mat4 projInv;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;

uniform vec2 OutSize;

out vec4 fragColor;

const ivec2 GRID_SIZE = ivec2(1024, 705);
const int AREA_SIDE_LENGTH = int(pow(float(GRID_SIZE.x * GRID_SIZE.y / 2), 1.0 / 3.0));

ivec2 positionToCell(vec3 position, out bool inside) {
    ivec3 sides = ivec3(AREA_SIDE_LENGTH);

    ivec3 iPosition = ivec3(floor(position));
    iPosition += sides / 2;

    inside = true;
    if (clamp(iPosition, ivec3(0), sides - 1) != iPosition) {
        inside = false;
        return ivec2(-1);
    }

    int index = (iPosition.y * sides.z + iPosition.z) * sides.x + iPosition.x;
    
    int halfWidth = GRID_SIZE.x / 2;
    ivec2 result = ivec2(
        (index % halfWidth) * 2,
        index / halfWidth + 1
    );
    result.x += result.y % 2;

    return result;
}

ivec2 cellToPixel(ivec2 cell, ivec2 screenSize) {
    return ivec2(round(vec2(cell) / GRID_SIZE * screenSize));
}

vec3 depthToView(vec2 texCoord, float depth, mat4 projInv) {
    vec4 ndc = vec4(texCoord, depth, 1.0) * 2.0 - 1.0;
    vec4 viewPos = projInv * ndc;
    return viewPos.xyz / viewPos.w;
}

void main() {
    float depth = texture(DiffuseDepthSampler, texCoord).r;
    vec3 viewPos = depthToView(texCoord, depth, projInv) * 1.0001;    

    fragColor = texture(DiffuseSampler, texCoord);
    vec3 blockPos = ceil(viewPos - fract(chunkOffset));

    float shadow = 1.0;
    vec3 p = viewPos - fract(chunkOffset) + sunDir * 0.03;
    for (int i = 0; i < 50; i++) {
        bool inside;
        ivec2 cell = positionToCell(floor(p), inside);
        ivec2 pix = cellToPixel(cell, ivec2(OutSize));

        if (inside && texelFetch(DataDepthSampler, pix, 0).r < 0.001) {
            shadow = 0.0;
            break;
        }
        p += sunDir * exp(float(i) / 48) * 0.3;
    }   
    fragColor.rgb *= max(shadow, 0.5);
}