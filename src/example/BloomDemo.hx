package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.DirectionalLight;
import babylon.materials.Effect;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.postprocess.BlurPostProcess;
import babylon.postprocess.PassPostProcess;
import babylon.postprocess.PostProcess;
import openfl.Lib;

//TODO SKYBox不显示的问题,CPP下FPS显示有问题
class BloomDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
		camera.attachControl(this.touchLayer);
		
		var light = new DirectionalLight("dir01", new Vector3(0, -1, -0.2), scene);
		var light2 = new DirectionalLight("dir02", new Vector3(-1, -2, -1), scene);
		light.position = new Vector3(0, 30, 0);
		light2.position = new Vector3(10, 20, 10);

		light.intensity = 0.6;
		light2.intensity = 0.6;

		camera.setPosition(new Vector3(-40, 40, 0));
		camera.lowerBetaLimit = (Math.PI / 2) * 0.9;
		
		// Skybox
		var skybox = MeshHelper.CreateBox("skyBox", 1000.0, scene);
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;
		
		// Spheres
		var sphere0 = MeshHelper.CreateSphere("Sphere0", 16, 10, scene);
		var sphere1 = MeshHelper.CreateSphere("Sphere1", 16, 10, scene);
		var sphere2 = MeshHelper.CreateSphere("Sphere2", 16, 10, scene);
		

		var sm:StandardMaterial = new StandardMaterial("white", scene);
		sm.diffuseColor = new Color3(0, 0, 0);
		sm.specularColor = new Color3(0, 0, 0);
		sm.emissiveColor = new Color3(1.0, 1.0, 1.0);
		sphere0.material = sm;
		
		sphere1.material = sm;
		sphere2.material = sm;
		
		var cm:StandardMaterial = new StandardMaterial("red", scene);
		cm.diffuseColor = new Color3(0, 0, 0);
		cm.specularColor = new Color3(0, 0, 0);
		cm.emissiveColor = new Color3(1.0, 0, 0);
		
		var cube = MeshHelper.CreateBox("Cube", 10.0, scene);
		cube.material = cm;  
		
		// Post-process
		var blurWidth = 1.0;
		var postProcess0 = new PassPostProcess("Scene copy", 1.0, camera);
		var postProcess1 = new PostProcess("Down sample", "postprocesses/downsample", ["screenSize", "highlightThreshold"], null, 0.25, camera, Texture.BILINEAR_SAMPLINGMODE);
		postProcess1.onApply = function (effect:Effect):Void {
			effect.setFloat2("screenSize", postProcess1.width, postProcess1.height);
			effect.setFloat("highlightThreshold", 0.90);
		};
		var postProcess2 = new BlurPostProcess("Horizontal blur", new Vector2(1.0, 0), blurWidth, 0.25, camera);
		var postProcess3 = new BlurPostProcess("Vertical blur", new Vector2(0, 1.0), blurWidth, 0.25, camera);
		var postProcess4 = new PostProcess("Final compose", "postprocesses/compose", ["sceneIntensity", "glowIntensity", "highlightIntensity"], ["sceneSampler"], 1, camera);
		postProcess4.onApply = function (effect:Effect):Void {
			effect.setTextureFromPostProcess("sceneSampler", postProcess0);
			effect.setFloat("sceneIntensity", 0.5);
			effect.setFloat("glowIntensity", 0.4);
			effect.setFloat("highlightIntensity", 1.0);
		};
		
		// Animations
		var alpha = 0.;
		scene.registerBeforeRender(function() {
			sphere0.position = new Vector3(20 * Math.sin(alpha), 0, 20 * Math.cos(alpha));
			sphere1.position = new Vector3(20 * Math.sin(alpha), 0, -20 * Math.cos(alpha));
			sphere2.position = new Vector3(20 * Math.cos(alpha), 0, 20 * Math.sin(alpha));

			cube.rotation.y += 0.01;
			cube.rotation.z += 0.01;

			alpha += 0.01;
		});
		
    	scene.executeWhenReady(function() {
    		engine.runRenderLoop(scene.render);
    	});
    }

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new BloomDemo());
    }
}
