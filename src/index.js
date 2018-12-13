const THREE = require('three');

const $ = require('jquery');

const vertexShaderSource = require('./shaders/vertexShader.glsl');
const fragmentShaderSource  = require('./shaders/fragmentShader.glsl');
const copyShaderSource  = require('./shaders/copyShader.glsl');

const commonShader = require('./shaders/common.glsl');
const bufAShader = require('./shaders/bufA.glsl');
const bufBShader = require('./shaders/bufA.glsl');
const imageShader = require('./shaders/image.glsl');

console.log("Hello!");

function getTime(state) {
  return ((new Date()).getTime() - state.startTime) / 1000.0;
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
	$("body").css("border", "0px");
	$("body").css("margin", "0px");
  $("body").append("<canvas id='canvas' style='width: 100vw; height: 100vh; display: block;' />");
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

function createFB(gl, width, height) {
	// create to render to
	const targetTextureWidth = width;
	const targetTextureHeight = height;
	const targetTexture = gl.createTexture();
	gl.bindTexture(gl.TEXTURE_2D, targetTexture);
	 
	const level = 0;
	{
		// define size and format of level 0
		const internalFormat = gl.RGBA;
		const border = 0;
		const format = gl.RGBA;
		const type = gl.UNSIGNED_BYTE;
		const data = null;
		gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
									targetTextureWidth, targetTextureHeight, border,
									format, type, data);
	 
		// set the filtering so we don't need mips
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
	}

	// Create and bind the framebuffer
	const fb = gl.createFramebuffer();
	gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
	 
	// attach the texture as the first color attachment
	const attachmentPoint = gl.COLOR_ATTACHMENT0;
	gl.framebufferTexture2D(gl.FRAMEBUFFER, attachmentPoint, gl.TEXTURE_2D, targetTexture, level);

	return {
		tex: targetTexture,
		fb: fb
	};
}

function addContentGL(state) {
	const gl = state.gl;
	const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
	const program = createProgram(gl, vertexShader, fragmentShader);

  const copyFragmentShader = createShader(gl, gl.FRAGMENT_SHADER, copyShaderSource);
	const copyProgram = createProgram(gl, vertexShader, copyFragmentShader);

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

	const sz = 256;
	const fbTex = createFB(gl, sz, sz);

	const drawSets = [];
	drawSets.push({
		fb: fbTex.fb,
		tex: null,
		program: program
	});
	drawSets.push({
		fb: null,
		tex: fbTex.tex,
		program: copyProgram
	});
	
	for (let i = 0; i < drawSets.length; i++) {
		const drawSet = drawSets[i];
		const fb = drawSet.fb;
		const program = drawSet.program;
		drawSets[i].uResolutionLocation = gl.getUniformLocation(program, "uResolution");
		drawSets[i].uTimeLocation = gl.getUniformLocation(program, "uTime");
		drawSets[i].uTex = gl.getUniformLocation(program, "uTex");
	}

	state.renderFunctions.push(function() {
		for (let i = 0; i < drawSets.length; i++) {
			const drawSet = drawSets[i];
			const fb = drawSet.fb;
			const program = drawSet.program;

			// render to our targetTexture by binding the framebuffer
			gl.bindFramebuffer(gl.FRAMEBUFFER, fb);

			// Clear
			gl.clearColor(0, 0, 0, 0);
			gl.clear(gl.COLOR_BUFFER_BIT);

			// Tell it to use our program (pair of shaders)
			gl.useProgram(program);

			// Bind the attribute/buffer set we want.
			gl.bindVertexArray(vao);

			// Set uniforms
			gl.uniform2f(drawSet.uResolutionLocation, gl.canvas.width, gl.canvas.height);
			gl.uniform1f(drawSet.uTimeLocation, getTime(state));
			gl.uniform1i(drawSet.uTex, 0);

			// Bind textures
			gl.bindTexture(gl.TEXTURE_2D, drawSet.tex);

			// Draw
			const primitiveType = gl.TRIANGLES;
			const offset = 0;
			const count = 6;
			gl.drawArrays(primitiveType, offset, count);
		}
	});
}

function main(state) {
  //setup(state);
  //addContent(state);
  state.startTime = (new Date()).getTime();
  setupGL(state);
  addContentGL(state);
}

const state = {};
$(function() {
  main(state);
});
