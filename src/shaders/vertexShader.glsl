#version 300 es

precision mediump float;
precision mediump int;

in vec4 aPosition;

uniform vec2 uResolution;
uniform float uTime;

void main()	{
  //gl_Position = projectionMatrix * modelViewMatrix * vec4(aPosition, 1.0);
  gl_Position = vec4(aPosition.xyz, 1.0);
}
