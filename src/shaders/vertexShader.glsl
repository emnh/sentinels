precision mediump float;
precision mediump int;
uniform mat4 modelViewMatrix; // optional
uniform mat4 projectionMatrix; // optional

attribute vec3 position;

void main()	{
  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}
