attribute vec4 aPosition;

uniform vec4 uSourceColor;
uniform mat4 uProjection;
uniform mat4 uModelView;

varying vec4 vDestinationColor;

void main()
{
    vDestinationColor = uSourceColor;
    gl_Position = uProjection * uModelView * aPosition;
    gl_PointSize = 5.0;
}