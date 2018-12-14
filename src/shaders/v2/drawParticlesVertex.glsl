in vec4 aPosition;

out vec2 vUV;
out float vIndex;

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
  int x = int(modI(float(i), float(rows)));
  int y = i / rows;
  vec4 particle = texelFetch(iChannel0, ivec2(x, y), 0);
	vec2 pos = particle.xy * 2.0 - 1.0;
  //gl_Position = vec4(aPosition.xyz, 1.0);
	//pos += 0.002 * (1.0 - float(x) / float(rows)) * aPosition.xy;
	pos += 0.005 * aPosition.xy;
	//pos += particle.zw * aPosition.xy;
  gl_Position = vec4(pos, 0.0, 1.0);
}
