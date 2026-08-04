#pragma header

uniform float force;

void main() {
    float f = force / 70.0; // scale factor
    vec4 col = vec4(1.0);
    col.r = texture2D(bitmap, vec2(openfl_TextureCoordv.x + f, openfl_TextureCoordv.y)).r;
    col.ga = texture2D(bitmap, openfl_TextureCoordv).ga;
    col.b = texture2D(bitmap, vec2(openfl_TextureCoordv.x - f, openfl_TextureCoordv.y)).b;
    gl_FragColor = col;
}