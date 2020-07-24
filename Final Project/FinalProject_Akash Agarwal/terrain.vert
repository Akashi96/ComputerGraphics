#version 330 compatibility

uniform sampler2D Noise2;
uniform float uNoiseAmp;
uniform float uNoiseFreq;

// uniform float uLightX, uLightY, uLightZ;

// out vec3 vLf;
// out vec3 vEf;

// vec3 eyeLightPosition = vec3(uLightX, uLightY, uLightZ);

void main( )
{
    vec3 pos = gl_Vertex.xyz;

    // vec4 ECPosition = gl_ModelViewMatrix * vec4(pos, 1.0); // get eye-coordinates from the above defined Model Coordinates
	
	// vLf = eyeLightPosition - ECPosition.xyz; // vector from the point to the light position
	// vEf = vec3( 0., 0., 0. ) - ECPosition.xyz; // vector from the point to the eye position

    gl_Position = vec4(pos, 1);
}