#version 330 compatibility

#extension GL_EXT_gpu_shader4: enable
#extension GL_EXT_geometry_shader4: enable

uniform bool uWire;


layout (triangles) in;
layout (triangle_strip, max_vertices=256) out;



uniform int uLevel;
uniform float uNoiseAmp;
uniform float uNoiseFreq;
uniform int uNumOctaves;

out vec4 gPos;
out vec3 gNormal;


// 2D Random
float random (in vec2 st) 
{
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}


// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) 
{
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec2 u = f*f*(3.0-2.0*f);
    vec2 u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}


float octaves (vec2 _st) 
{
    float v = 0.0;
    float a = uNoiseAmp;
    float f = uNoiseFreq * 0.1;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < uNumOctaves; ++i) {
        v += a * noise(_st * f);
        _st = rot * _st + shift;
        f *= 2.0;
        a *= 0.5;
    }
    return abs(v);

    // // Initial values
    // float value = 0.0;
    // float amplitude = uNoiseAmp;
    // // float frequency = 0.;
    // //
    // // Loop of octaves
    // for (int i = 0; i < uNumOctaves; i++) {
    //     value += amplitude * abs(noise(_st));
    //     _st *= 2.;
    //     amplitude *= .5;
    // }
    // return value;
}


vec3 getNormal(vec3 pos)
{
    vec3 off = vec3(1.0, 1.0, 0.0);

    float hL = octaves(pos.xy - off.xz);
    float hR = octaves(pos.xy + off.xz);
    float hD = octaves(pos.xy - off.zy);
    float hU = octaves(pos.xy + off.zy);

    // deduce terrain normal
    gNormal.x = hL - hR;
    gNormal.y = hD - hU;
    gNormal.z = 2.0;
    gNormal = normalize(gNormal);
    return gNormal;
}


void main() 
{
    vec4 v0 = gl_in[0].gl_Position;
    vec4 v1 = gl_in[1].gl_Position;
    vec4 v2 = gl_in[2].gl_Position;
    float dx = abs(v0.x-v2.x)/uLevel;
    float dy = 0.5/uLevel;
    float dz = abs(v0.z-v1.z)/uLevel;
    float x=v0.x;
    float z=v0.z;
    float y = 0;

    for(int j=0;j<uLevel*uLevel;j++) 
    {
        y = octaves(vec2(x, z));
        // if(y < 0)   y = 0;
        gl_Position =  gl_ModelViewProjectionMatrix * vec4(x,y,z,1);
        gPos = vec4(x,y,z,1);
        gNormal = getNormal(vec3(x, y, z));
        EmitVertex();

        y = octaves(vec2(x, z+dz));
        // if(y < 0)   y = 0;
        gl_Position =  gl_ModelViewProjectionMatrix * vec4(x,y,z+dz,1);
        gNormal = getNormal(vec3(x, y, z + dz));
        gPos = vec4(x,y,z+dz,1);
        EmitVertex();

        y = octaves(vec2(x+dx, z));
        // if(y < 0)   y = 0;
        gl_Position =  gl_ModelViewProjectionMatrix * vec4(x+dx,y,z,1);
        gNormal = getNormal(vec3(x + dx, y, z));
        gPos = vec4(x+dx,y,z,1);
        EmitVertex();

        y = octaves(vec2(x+dx, z+dz));
        // if(y < 0)   y = 0;
        gNormal = getNormal(vec3(x + dx, y, z + dz));
        gl_Position =  gl_ModelViewProjectionMatrix * vec4(x+dx,y,z+dz,1);
        gPos = vec4(x+dx,y,z+dz,1);
        EmitVertex();


        // x y z

        // x+dx, y, z
        // x, y+dy, z
        // x, y, z+dz

        // x+dx, y+dy, z
        // x, y+dy, z+dz
        // x+dx, y, z+dz

        // x+dx, y+dy, z+dz


        EndPrimitive();
        x+=dx;

        if((j+1) % uLevel == 0) 
        {
            x=v0.x;
            z+=dz;
        }
    }
}