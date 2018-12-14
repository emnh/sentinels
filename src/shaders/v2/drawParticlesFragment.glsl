in vec2 vUV;
in float vIndex;

void mainImage(out vec4 fragColor, in vec2 fragCoord)	{
	//float d = length(vUV) / length(vec2(1.0, 1.0));
	float d = length(vUV);
	//fragColor.rgb = vec3(d);
	if (d <= 1.0) {
		//float f = 0.1 - d;
		float f = 1.0 - d;
		vec3 hsv = vec3(vIndex, 1.0, 1.0);
		fragColor.rgb = hsv2rgb(hsv) * vec3(f);
		//fragColor.rgb = vec3(f, 0.0, 0.0);
		//fragColor.a = 0.001 / pow(d, 1.0);
		//fragColor.a = 0.2 - d;
		fragColor.a = d; 
	} else {
		/*
		fragColor.rgb = vec3(0.0);
		fragColor.a = 1.0;
		*/
		discard;
	}
}
