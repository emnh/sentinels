precision mediump float;
precision mediump int;
uniform vec2 uResolution;
uniform float uTime;

void main()	{
  vec2 uv = gl_FragCoord.xy / uResolution.xy;
  vec4 color = vec4(0.0);
  color.r = sin( uv.x * 1.0 + uTime ) * 0.5;
  gl_FragColor = color;
}
