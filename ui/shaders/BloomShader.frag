	#pragma header    
    uniform float funrange;
    uniform float funsteps;
    uniform float funthreshhold;
    uniform float funbrightness;

	uniform float iTime;

	void main() {

	vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;

    vec2 uv2 = fragCoord / iResolution.xy;
    gl_FragColor = flixel_texture2D(bitmap, uv2);
    
    for (float i = -funrange; i < funrange; i += funsteps) {
    
        float falloff = 1.0 - abs(i / funrange);
    
        vec4 blur = flixel_texture2D(bitmap, uv2 + i);
        if (blur.r + blur.g + blur.b > funthreshhold * 3.0) {
            gl_FragColor += blur * falloff * funsteps * funbrightness;
        }
        
        blur = flixel_texture2D(bitmap, uv2 + vec2(i, -i));
        if (blur.r + blur.g + blur.b > funthreshhold * 3.0) {
            gl_FragColor += blur * falloff * funsteps * funbrightness;
        }
    }
}
