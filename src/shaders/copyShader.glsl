#version 300 es

precision mediump float;
precision mediump int;

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D iChannel0;

out vec4 outColor;

void main()	{
  vec2 uv = gl_FragCoord.xy / uResolution.xy;
  outColor = texture(iChannel0, uv);
}
