const THREE = require('three');

const $ = require('jquery');

console.log("Hello!");

function setup(state) {
  // Set the scene size.
  const WIDTH = 1600;
  const HEIGHT = 1200;

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

  function update () {
    // Draw!
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
  const sphereMaterial =
    new THREE.MeshLambertMaterial(
      {
        color: 0xCC0000
      });


  // Set up the sphere vars
  const RADIUS = 0.2;
  const SEGMENTS = 16;
  const RINGS = 16;

  const sphere = new THREE.Mesh(
    new THREE.SphereGeometry(
      RADIUS,
      SEGMENTS,
      RINGS),
    sphereMaterial);
  sphere.position.z = -1;
  state.scene.add(sphere);

  const ground = new THREE.Mesh(
    new THREE.PlaneBufferGeometry(
      1,
      1,
      1,
      1),
    sphereMaterial);
  ground.rotation.x = -Math.PI / 4.0;
  ground.position.z = -1;
  state.scene.add(ground);

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
