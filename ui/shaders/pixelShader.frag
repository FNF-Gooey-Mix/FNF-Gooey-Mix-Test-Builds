#pragma header

const vec4 RED = vec4(1,1,1,0);

float fuckinMath(float ogNum, float from, float to){ //dont ask me how i even figured this out
    return (ogNum-from)/(to-from);
}

vec4 getColor(float ratio){
    float block = 1.0/6.0;

    vec4 finalColor = RED;

    return finalColor;
}

void main()
{
	vec2 blocks = openfl_TextureSize /6.0;
    
    vec2 uvBend = openfl_TextureCoordv;


    vec2 newUV = floor(uvBend * blocks) / blocks;
    vec2 otherUV = floor(uvBend * (blocks/3.0)) / (blocks/3.0);

    vec4 color = flixel_texture2D(bitmap, newUV);



    //color =vec4(1);
    //color.rgb -= 0.2;
    /*color.rgb += vec3(cos(mix(-2.0, 2.0, uvBend.x)) * cos(1.45)*0.35);
    color.rgb += vec3(cos(mix(-2.0, 2.0, uvBend.y)) * cos(1.45)*0.35);*/

    gl_FragColor = color;
}