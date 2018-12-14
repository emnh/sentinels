const THREE = require('three');

const $ = require('jquery');

const vertexShaderSource = require('./shaders/vertexShader.glsl');
const fragmentShaderSource  = require('./shaders/fragmentShader.glsl');
const copyShaderSource  = require('./shaders/copyShader.glsl');

const preamble = require('./shaders/preamble.glsl');
const shaderMain = require('./shaders/main.glsl');
const commonShader = preamble + require('./shaders/common.glsl');
const bufAShader = commonShader + require('./shaders/bufA.glsl') + shaderMain;
const bufBShader = commonShader + require('./shaders/bufB.glsl') + shaderMain;
const imageShader = commonShader + require('./shaders/image.glsl') + shaderMain;

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

  const lext1 = gl.getExtension('EXT_color_buffer_float');
	if (!lext1) {
		$("body").html("<h1>No WebGL 2 Extension: EXT_color_buffer_float!</h1>");
		return;
	}

  const lext2 = gl.getExtension('OES_texture_float_linear');
	if (!lext2) {
		$("body").html("<h1>No WebGL 2 Extension: OES_texture_float_linear!</h1>");
		return;
	}
	state.gl = gl;

	resize(gl.canvas);
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
		const internalFormat = gl.RGBA32F;
		const border = 0;
		const format = gl.RGBA;
		const type = gl.FLOAT;
		const data = null;
		gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
									targetTextureWidth, targetTextureHeight, border,
									format, type, data);
	 
		// set the filtering so we don't need mips
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
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

	const prog = function(text, fragmentShaderSource) {
		console.log("Compiling: ", text);
		const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
		const program = createProgram(gl, vertexShader, fragmentShader);
		return program;
	}
  
	const programA = prog("bufA", bufAShader);
	const programB = prog("bufB", bufBShader);
	const programImage = prog("image", imageShader);
	//const copyProgram = prog("copy", copyShaderSource);

	const positionAttributeLocation = gl.getAttribLocation(programA, "aPosition");
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

	//const w = 512;
	//const h = 512;
	const w = gl.canvas.width;
	const h = gl.canvas.height;
	const w2 = gl.canvas.width;
	const h2 = gl.canvas.height;
	const fbTexA1 = createFB(gl, w, h);
	const fbTexA2 = createFB(gl, w, h);
	const fbTexB1 = createFB(gl, w2, h2);
	const fbTexB2 = createFB(gl, w2, h2);

	const alternate = function(a, b) {
		return function(iFrame) {
			if (iFrame % 2 == 0) {
				return a;
			} else {
				return b;
			}
		};
	};

	const nullf = function(iFrame) { return null; };

	const drawSets = [];
	drawSets.push({
		fb: alternate(fbTexA1.fb, fbTexA2.fb),
		iChannel0tex: alternate(fbTexA2.tex, fbTexA1.tex),
		iChannel1tex: nullf,
		iChannel2tex: nullf,
		iChannel3tex: nullf,
		program: programA,
		w: w,
		h: h
	});
	drawSets.push({
		fb: alternate(fbTexB1.fb, fbTexB2.fb),
		iChannel0tex: alternate(fbTexA1.tex, fbTexA2.tex),
		iChannel1tex: alternate(fbTexB2.tex, fbTexB1.tex),
		iChannel2tex: nullf,
		iChannel3tex: nullf,
		program: programB,
		w: w2,
		h: h2
	});
	drawSets.push({
		fb: nullf,
		iChannel0tex: alternate(fbTexA1.tex, fbTexA2.tex),
		iChannel1tex: alternate(fbTexB1.tex, fbTexB2.tex),
		iChannel2tex: nullf,
		iChannel3tex: nullf,
		program: programImage,
		w: gl.canvas.width,
		h: gl.canvas.height
	});
	
	for (let i = 0; i < drawSets.length; i++) {
		const drawSet = drawSets[i];
		const fb = drawSet.fb;
		const program = drawSet.program;
		drawSets[i].iResolutionLocation = gl.getUniformLocation(program, "iResolution");
		drawSets[i].iCanvasResolutionLocation = gl.getUniformLocation(program, "iCanvasResolution");
		drawSets[i].iTimeLocation = gl.getUniformLocation(program, "iTime");
		drawSets[i].iFrameLocation = gl.getUniformLocation(program, "iFrame");
		drawSets[i].iChannel0 = gl.getUniformLocation(program, "iChannel0");
		drawSets[i].iChannel1 = gl.getUniformLocation(program, "iChannel1");
		drawSets[i].iChannel2 = gl.getUniformLocation(program, "iChannel2");
		drawSets[i].iChannel3 = gl.getUniformLocation(program, "iChannel3");
	}

	// Disable blending
	gl.disable(gl.BLEND);

	state.renderFunctions.push(function() {
		for (let i = 0; i < drawSets.length; i++) {
			const drawSet = drawSets[i];
			const fb = drawSet.fb(state.iFrame);
			const program = drawSet.program;

			// render to our targetTexture by binding the framebuffer
			gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
			
			// Resize
			if (fb == null) {
				resize(gl.canvas);
				gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
			} else {
				gl.viewport(0, 0, w, h);
			}

			// Clear
			gl.clearColor(0, 0, 0, 0);
			gl.clear(gl.COLOR_BUFFER_BIT);

			// Tell it to use our program (pair of shaders)
			gl.useProgram(program);

			// Bind the attribute/buffer set we want.
			gl.bindVertexArray(vao);

			// Set uniforms
			gl.uniform3f(drawSet.iCanvasResolutionLocation, gl.canvas.width, gl.canvas.height, 0.0);
			gl.uniform3f(drawSet.iResolutionLocation, w, h, 0.0);
			gl.uniform1f(drawSet.iTimeLocation, getTime(state));
			gl.uniform1i(drawSet.iFrameLocation, state.iFrame);

			// Bind textures
			gl.uniform1i(drawSet.iChannel0, 0);
			gl.uniform1i(drawSet.iChannel1, 1);
			gl.uniform1i(drawSet.iChannel2, 2);
			gl.uniform1i(drawSet.iChannel3, 3);
			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, drawSet.iChannel0tex(state.iFrame));
			gl.activeTexture(gl.TEXTURE1);
			gl.bindTexture(gl.TEXTURE_2D, drawSet.iChannel1tex(state.iFrame));
			gl.activeTexture(gl.TEXTURE2);
			gl.bindTexture(gl.TEXTURE_2D, drawSet.iChannel2tex(state.iFrame));
			gl.activeTexture(gl.TEXTURE3);
			gl.bindTexture(gl.TEXTURE_2D, drawSet.iChannel3tex(state.iFrame));
	
			// Draw
			const primitiveType = gl.TRIANGLES;
			const offset = 0;
			const count = 6;
			gl.drawArrays(primitiveType, offset, count);
		}
		state.iFrame++;
	});
}

function main(state) {
  //setup(state);
  //addContent(state);
  state.startTime = (new Date()).getTime();
	state.iFrame = 0;
  setupGL(state);
  addContentGL(state);
}

const state = {};
$(function() {
	window.state = state;
  main(state);
});
