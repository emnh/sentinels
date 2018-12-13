const THREE = require('three');

const $ = require('jquery');

const vertexShader = require('./shaders/vertexShader.glsl');
const fragmentShader  = require('./shaders/fragmentShader.glsl');

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

function addContent(state) {
  // create the sphere's material
  const quadMaterial =
    new THREE.RawShaderMaterial(
      {
        uniforms: {
          uResolution: { value: [state.width, state.height] },
          uTime: { value: 0.0 }
        },
        vertexShader: vertexShader,
        fragmentShader, fragmentShader
      });

  state.quadMaterial = quadMaterial;

  state.renderFunctions.push(function(state) {
    state.quadMaterial.uniforms.uTime.value = getTime(state);
  });

  const quad = new THREE.Mesh(
    new THREE.PlaneBufferGeometry(
      2,
      2,
      1,
      1),
    quadMaterial);
  quad.position.z = -1;
  state.scene.add(quad);

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

function main(state) {
  setup(state);
  addContent(state);
}

const state = {};
$(function() {
  main(state);
});
