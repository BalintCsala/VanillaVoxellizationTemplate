#version 150

#moj_import <light.glsl>
#moj_import <voxelization.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;


out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out float dataFace;
out vec4 glpos;
flat out ivec2 cell;

const vec2[] OFFSETS = vec2[](
    vec2(0, 0),
    vec2(1, 0),
    vec2(1, 1),
    vec2(0, 1)
);

const vec3 MARKER_COLOR = vec3(1, 0, 1);

void main() {
    vec4 pos = vec4(Position + ChunkOffset, 1.0);
    vec4 textureColor = texture(Sampler0, UV0);
    vec3 diff = textureColor.rgb - MARKER_COLOR;
    if (dot(diff, diff) < 0.01) {
        vec2 offset = OFFSETS[gl_VertexID % 4];
        if (Normal.y > 0) {
            // Data face used for voxelization
            dataFace = 1.0;
            bool inside;
            
            cell = positionToCell(floor(Position + floor(ChunkOffset)), inside);
            if (!inside) {
                gl_Position = vec4(5, 5, 0, 1);
                return;
            }
            gl_Position = vec4(
                (vec2(cell) + offset) / GRID_SIZE * 2.0 - 1.0,
                -1,
                1
            );
            // TODO: Send data to the fragment shader through the vertex color
            vertexColor = vec4(floor(Position.xz) / 16, 0, 1);
            texCoord0 = offset;
        } else {
            // Data face used for chunk offset storage
            gl_Position = vec4(
                offset * vec2(3, 1) / GRID_SIZE * 2.0 - 1.0,
                -1,
                1
            );
            dataFace = 2.0;
        }
    } else {
        dataFace = 0.0;
        gl_Position = ProjMat * ModelViewMat * pos;

        vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
        vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
        texCoord0 = UV0;
    }
    glpos = gl_Position;
}
