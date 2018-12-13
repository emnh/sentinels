const THREE = require('three');

const $ = require('jquery');

const vertexShaderSource = require('./shaders/vertexShader.glsl');
const fragmentShaderSource  = require('./shaders/fragmentShader.glsl');

const commonShader = require('./shaders/common.glsl');
const bufAShader = require('./shaders/bufA.glsl');
const bufBShader = require('./shaders/bufA.glsl');
const imageShader = require('./shaders/image.glsl');

console.log("Hello!");

function getTime(state) {
  return ((new Date()).getTime() - state.startTime) / 1000.0;
}

function setup(state) {

  state.startTime = (new Date()).getTime();

  // Set the scene size.
  const WIDTH = 1600;
  const HEIGHT = 1200;
  state.width = WIDTH;
  state.height = HEIGHT;

  // Set some camera attributes.
  const VIEW_ANGLE = 45;
  const ASPECT = WIDTH / HEIGHT;
  const NEAR = 0.1;
  const FAR = 10000;

  // Get the DOM element to attach to
  const container =
      document.querySelector('body');

  // Create a WebGL renderer, camera
  // and a scene
  const renderer = new THREE.WebGLRenderer();
  const camera =
      new THREE.PerspectiveCamera(
          VIEW_ANGLE,
          ASPECT,
          NEAR,
          FAR
      );

  const scene = new THREE.Scene();

  // Add the camera to the scene.
  scene.add(camera);

  // Start the renderer.
  renderer.setSize(WIDTH, HEIGHT);

  // Attach the renderer-supplied
  // DOM element.
  container.appendChild(renderer.domElement);

  state.renderFunctions = [];

  function update () {
    // Draw!
    for (let i = 0; i < state.renderFunctions.length; i++) {
      state.renderFunctions[i](state);
    }
    renderer.render(scene, camera);

    // Schedule the next frame.
    requestAnimationFrame(update);
  }

  // Schedule the first frame.
  requestAnimationFrame(update);

  state.container = container;
  state.renderer = renderer;
  state.camera = camera;
  state.scene = scene;
}

function createQuad(state, fragmentShader) {
  const material =
    new THREE.RawShaderMaterial(
      {
        uniforms: {
          uResolution: { value: [state.width, state.height] },
          uTime: { value: 0.0 }
        },
        vertexShader: vertexShader,
        fragmentShader: commonShader + fragmentShader
      });

  state.renderFunctions.push(function(state) {
    material.uniforms.uTime.value = getTime(state);
  });

  const quadGeometry = new THREE.PlaneBufferGeometry(2, 2, 1, 1);
  const quad = new THREE.Mesh(quadGeometry, material);
  state.scene.add(quad);
  quad.position.z = -1;

  return quad;
}

function addContent(state) {

  const bufAQuad = createQuad(state, bufAShader);
  const bufBQuad = createQuad(state, bufBShader);
  const imageQuad = createQuad(state, imageShader);

  // create a point light
  const pointLight =
    new THREE.PointLight(0xFFFFFF);

  // set its position
  pointLight.position.x = 10;
  pointLight.position.y = 50;
  pointLight.position.z = 130;

  // add to the scene
  state.scene.add(pointLight);
}

function resize(canvas) {
  // Lookup the size the browser is displaying the canvas.
  var displayWidth  = canvas.clientWidth;
  var displayHeight = canvas.clientHeight;

  // Check if the canvas is not the same size.
  if (canvas.width  !== displayWidth ||
      canvas.height !== displayHeight) {

    // Make the canvas the same size
    canvas.width  = displayWidth;
    canvas.height = displayHeight;
  }
}

function drawGL(state) {
	const gl = state.gl;
	resize(gl.canvas);
	gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

	// Draw!
	for (let i = 0; i < state.renderFunctions.length; i++) {
		state.renderFunctions[i](state);
	}

	requestAnimationFrame(function() {
		drawGL(state);
	});
}

function setupGL(state) {
  $("body").append("<canvas id='canvas' style='width: 100%; height: 100%;' />");
  state.canvas = $("#canvas");
  const gl = canvas.getContext("webgl2");
	if (!gl) {
		$("body").html("<h1>No WebGL 2!</h1>");
		return;
	}
	state.gl = gl;

  state.renderFunctions = [];
	requestAnimationFrame(function() {
		drawGL(state);
	});
}

function createShader(gl, type, source) {
	var shader = gl.createShader(type);
	gl.shaderSource(shader, source);
	gl.compileShader(shader);
	var success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
	if (success) {
		return shader;
	}
 
	console.log(gl.getShaderInfoLog(shader));
	gl.deleteShader(shader);
}

function createProgram(gl, vertexShader, fragmentShader) {
	var program = gl.createProgram();
	gl.attachShader(program, vertexShader);
	gl.attachShader(program, fragmentShader);
	gl.linkProgram(program);
	var success = gl.getProgramParameter(program, gl.LINK_STATUS);
	if (success) {
		return program;
	}
 
	console.log(gl.getProgramInfoLog(program));
	gl.deleteProgram(program);
}

function addContentGL(state) {
  state.startTime = (new Date()).getTime();

	const gl = state.gl;
	const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
	const program = createProgram(gl, vertexShader, fragmentShader);

	const positionAttributeLocation = gl.getAttribLocation(program, "aPosition");
	const positionBuffer = gl.createBuffer();

	const quadPositions = [
			// First triangle:
			 1.0,  1.0,
			-1.0,  1.0,
			-1.0, -1.0,
			// Second triangle:
			-1.0, -1.0,
			 1.0, -1.0,
			 1.0,  1.0
	];
	gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(quadPositions), gl.STATIC_DRAW);

	const vao = gl.createVertexArray();
	gl.bindVertexArray(vao);
	gl.enableVertexAttribArray(positionAttributeLocation);

	const size = 2;          // 2 components per iteration
  const type = gl.FLOAT;   // the data is 32bit floats
  const normalize = false; // don't normalize the data
  const stride = 0;        // 0 = move forward size * sizeof(type) each iteration to get the next position
  const offset = 0;        // start at the beginning of the buffer
  gl.vertexAttribPointer(positionAttributeLocation, size, type, normalize, stride, offset)

	const uResolutionLocation = gl.getUniformLocation(program, "uResolution");
	const uTimeLocation = gl.getUniformLocation(program, "uTime");

	state.renderFunctions.push(function() {
		// Clear the canvas
		gl.clearColor(0, 0, 0, 0);
		gl.clear(gl.COLOR_BUFFER_BIT);

		// Tell it to use our program (pair of shaders)
    gl.useProgram(program);

		// Bind the attribute/buffer set we want.
    gl.bindVertexArray(vao);

		// Set uniforms
		gl.uniform2f(uResolutionLocation, gl.canvas.width, gl.canvas.height);
		gl.uniform1f(uTimeLocation, getTime(state));

		const primitiveType = gl.TRIANGLES;
		const offset = 0;
		const count = 6;
		gl.drawArrays(primitiveType, offset, count);
	});
}

function main(state) {
  //setup(state);
  //addContent(state);
  setupGL(state);
  addContentGL(state);
}

const state = {};
$(function() {
  main(state);
});
