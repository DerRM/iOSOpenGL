attribute vec4 aPosition;
attribute vec3 aNormal;
attribute vec2 aTexCoord;

uniform vec4 uSourceColor;
uniform mat4 uMVMatrix;
uniform mat4 uMVPMatrix;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec4 vDestinationColor;
varying vec2 vTexCoord;

void main()
{
    vPosition = vec3(uMVMatrix * aPosition);
    
    vTexCoord = aTexCoord;
    
    vNormal = vec3(uMVMatrix * vec4(aNormal, 0.0));
    
    vDestinationColor = uSourceColor;
    
    gl_Position = uMVPMatrix * aPosition;
}