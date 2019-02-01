in vec2 vUV;
in float vIndex;
in float vRed;
in float vSize;
in vec2 vFC;
in float vWP;

void mainImage(out vec4 fragColor, in vec2 fragCoord)	{
	//float d = length(vUV) / length(vec2(1.0, 1.0));
	vec2 uv = vUV;
	float d = length(uv);
	//fragColor.rgb = vec3(d);
	if (vIndex == 0.0) {
		// TODO: Draw background
		fragColor.rgba = vec4(0.0, 0.0, 0.2, 1.0);
	} else {
		if (d <= 1.0) {
			float dod = d;
			if (vFC.x <= 1.0) {
				float c = 0.5;
				uv = mod(vUV, c) / c;
				d = distance(uv, vec2(0.5));
			}

			//float f = 0.5 - d;
			//float f = 1.0 - d;
			//vec3 hsv = vec3(vFC.x / vWP, 1.0, 1.0);
			//vec3 hsv = vec3((vFC.x + vFC.y) / vWP, 1.0, 1.0);
			//vec3 hsv = vec3(vIndex, 1.0, 1.0);
			//vec3 hsv = vec3((fragCoord.x + fragCoord.y) / (iCanvasResolution.x + iCanvasResolution.y), 1.0, 1.0);
			float ha = vIndex;
			float hb = vFC.x / vWP;
			float hc = (fragCoord.x + fragCoord.y) / (iCanvasResolution.x + iCanvasResolution.y);
			vec3 hsv = vec3(ha + hb + hc, 1.0, 1.0);
			vec3 rgb = hsv2rgb(hsv);
			//fragColor.rgb = f * mix(vec3(1.0, 0.0, 0.0), vec3(1.0), f);
			//fragColor.rgb = f * mix(vec3(1.0, 0.0, 0.0), vec3(1.0), vRed == 0.0 ? 0.0 : 1.0);
			//fragColor.rgb = f * mix(vec3(1.0, 0.0, 0.0), vec3(0.0), vRed);
			//fragColor.rgb = vec3(f, 0.0, 0.0);
			d /= vSize;
			float e1 = 0.0;
			float e2 = 0.5;
			float ddf = smoothstep(e1, e2, 1.0 / d);
			ddf *= smoothstep(e1, e2, d);
			fragColor.rgb = mix(rgb, vec3(0.0), ddf); //smoothstep(0.5, 1.0, d));
			fragColor.a = 1.0;
			float angmod = mod(atan(vUV.y, vUV.x), 3.14 * 0.5);
			float angt = 0.1;
			if (vFC.x >= 0.0 && angmod <= angt) {
				float rc = (angmod / angt) * (1.0 - vFC.x / vWP);
				//fragColor.r = rc;
				//fragColor.rgba = vec4(rc, 0.0, 0.0, 1.0);
			}
			//hsv = vec3(atan(vUV.y, vUV.x) * 0.05 + iTime * 0.1, 1.0, 1.0);
			//fragColor.rgb = hsv2rgb(hsv);

			// Soften the sentinel head
			if (vFC.x <= 1.0) {
				fragColor.rgb = fragColor.rgb * (1.0 - dod) + mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), dod);
				fragColor.a = 0.0;
			}

			if (length(fragColor.rgb) < 0.001) {
				fragColor.a = length(fragColor.rgb);
			}
		} else {
			discard;
		}
	}
}
