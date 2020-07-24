#version 330 compatibility

uniform float uKa, uKd, uKs;
uniform vec4 uColor;
uniform vec4 uSpecularColor;
uniform float uShininess;
uniform float uLightX, uLightY, uLightZ;
uniform float uLevel1;
uniform float uLevel2;
uniform float uTol;
uniform int uNumOctaves;

vec3 vLf;
vec3 vEf;
in vec3 gNormal;
in vec4 gPos;

vec3 eyeLightPosition = vec3(uLightX, uLightY, uLightZ);

const vec3 BLUE = vec3( 0.1, 0.1, 0.5 );
const vec3 GREEN = vec3( 0.0, 0.8, 0.0 );
const vec3 BROWN = vec3( 0.6, 0.3, 0.1 );
const vec3 WHITE = vec3( 1.0, 1.0, 1.0 );

vec3 getColor(float height)
{
    height = height/ 10.;

    vec3 color = BLUE;
    if( height > 0. )
    {
        float t = smoothstep( uLevel1-uTol, uLevel1+uTol, height );
        color = mix( GREEN, BROWN, t );
    }
    if( height > uLevel1+uTol )
    {
        float t = smoothstep( uLevel2-uTol, uLevel2+uTol, height );
        color = mix( BROWN, WHITE, t );
    }
    return color;
}


float random (in vec2 st) 
{
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
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

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (in vec2 _st) 
{
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < uNumOctaves; i++) {
        value += amplitude * noise(_st);
        _st *= 2.;
        amplitude *= .5;
    }
    return value;
}


void main( )
{
    vec4 ECPosition = gl_ModelViewMatrix * gPos; // get eye-coordinates from the above defined Model Coordinates
	
	vLf = eyeLightPosition - ECPosition.xyz; // vector from the point to the light position
	vEf = vec3( 0., 0., 0. ) - ECPosition.xyz; // vector from the point to the eye position
    
    vec3 Normal = normalize(gl_NormalMatrix * gNormal);
    vec3 Light = normalize(vLf);
    vec3 Eye = normalize(vEf);
    
    if(gPos.y < 0)
        discard;
    else
    {
        vec3 color = vec3(0.0);
        color += fbm((gl_FragCoord.xy/vec2(800.0)) * 3.0);
        color += getColor(gPos.y);

        // LIGHTING
        vec4 ambient = uKa * vec4(color, 1);
        float d = max( dot(Normal,Light), 0. );
        vec4 diffuse = uKd * d * vec4(color, 1);
        float s = 0.;
        if( dot(Normal,Light) > 0. ) // only do specular if the light can see the point
        {
            vec3 ref = normalize( 2. * Normal * dot(Normal,Light) - Light );
            s = pow( max( dot(Eye,ref),0. ), uShininess );
        }
        vec4 specular = uKs * s * uSpecularColor;
        gl_FragColor = vec4( ambient.rgb + diffuse.rgb + specular.rgb, 1. );
        // gl_FragColor = vec4( col.rgb, 1. );
    }
}