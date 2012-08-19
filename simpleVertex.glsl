attribute vec4 aPosition;
attribute vec3 aNormal;

uniform vec4 uSourceColor;
uniform mat4 uMVMatrix;
uniform mat4 uMVPMatrix;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec4 vDestinationColor;

void main()
{
    vPosition = vec3(uMVMatrix * aPosition);
    
    vNormal = vec3(uMVMatrix * vec4(aNormal, 0.0));
    
    vDestinationColor = uSourceColor;
    
    gl_Position = uMVPMatrix * aPosition;
}