in vec4 aPosition;

out vec2 vUV;
out float vIndex;
out float vRed;
out float vSize;
out vec2 vFC;
out float vWP;

/**
 *  * Returns accurate MOD when arguments are approximate integers.
 *   */
float modI(float a,float b) {
	float m=a-floor((a+0.5)/b)*b;
	return floor(m+0.5);
}

void main()	{
  vUV = aPosition.xy;
	int i = gl_VertexID / 12;
	int rows = int(iResolution.x);
	int torusCount = 32;
	vIndex = float(i) / (float(rows) * float(rows));
	//float n = 512.0 * 512.0 / 32.0;

  int x = int(modI(float(i), float(rows)));
  int y = i / rows;
  vec4 particle = texelFetch(iChannel0, ivec2(x, y), 0);
	vec2 pos = particle.xy * 2.0 - 1.0;
	
	int particlesPerTorus = int(iResolution.x * iResolution.y / 32.0);
	int wp = int(sqrt(float(particlesPerTorus)));
	int pdIndex = toLinear(vec2(x, y), iResolution.xy);
	int index = pdIndex % particlesPerTorus;
	vec2 fc = vec2(fromLinear(index, vec2(wp)));
	vFC = fc;
	vWP = float(wp);
	//vRed = fc.x / float(wp);
	float c = 20.0;
	vRed = modI(fc.x + fc.y, c) / c; // float(wp);
	//vRed = modI(float(pdIndex), n) / n;

  //gl_Position = vec4(aPosition.xyz, 1.0);
	//pos += 0.002 * (1.0 - float(x) / float(rows)) * aPosition.xy;
	//pos += mix(0.005, 0.001, sinc(2.0 * iTime + 70.0 * vIndex)) * aPosition.xy;
	float sz = 1.0 - fc.x / float(wp);
	vSize = sz;
	sz *= 8.0;
	pos += 0.005 * sz * aPosition.xy;
	//pos += particle.zw * aPosition.xy;
	if (i == 0) {
		// Full screen quad
		gl_Position = vec4(aPosition.xy, 0.0, 1.0);
	} else {
		gl_Position = vec4(pos, 0.0, 1.0);
	}
	/*
	gl_Position = vec4(pos, 0.0, 1.0);
	*/
}
