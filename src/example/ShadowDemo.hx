package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.DirectionalLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.lights.SpotLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class ShadowDemo extends BaseDemo
{
	private var tAlpha:Float = 0;
    override function onInit():Void
    {
    	// Setup environment
		var camera = new ArcRotateCamera("Camera", 0, 0.8, 90, Vector3.Zero(), scene);
		camera.lowerBetaLimit = 0.1;
		camera.upperBetaLimit = (Math.PI / 2) * 0.9;
		camera.lowerRadiusLimit = 30;
		camera.upperRadiusLimit = 150;
		camera.attachControl(this.touchLayer);

		// light1
		var light = new DirectionalLight("dir01", new Vector3(-1, -2, -1), scene);
		light.position = new Vector3(20, 40, 20);
		light.intensity = 0.5;

		var lightSphere = MeshHelper.CreateSphere("sphere", 10, 2, scene);
		lightSphere.position = light.position;
		lightSphere.material = new StandardMaterial("light", scene);
		Std.instance(lightSphere.material,StandardMaterial).emissiveColor = new Color3(1, 1, 0);

		// light2
		var light2 = new SpotLight("spotLight02", new Vector3(30, 40, 20), new Vector3(-1, -2, -1), 60, 1, scene);
		//light2.position = new Vector3(30, 40, 20);
		light2.intensity = 0.5;

		var lightSphere2 = MeshHelper.CreateSphere("sphere", 10, 2, scene);
		lightSphere2.position = light2.position;
		lightSphere2.material = new StandardMaterial("light", scene);
		Std.instance(lightSphere2.material,StandardMaterial).emissiveColor = new Color3(1, 1, 0);

		// Ground
		var ground = MeshHelper.CreateGroundFromHeightMap("ground", "textures/heightMap.png", 100, 100, 100, 0, 10, scene, false);
		var groundMaterial = new StandardMaterial("ground", scene);
		var groundTexture = new Texture("textures/ground.jpg", scene);
		groundTexture.uScale = 6;
		groundTexture.vScale = 6;
		groundMaterial.diffuseTexture = groundTexture;
		groundMaterial.specularColor = new Color3(0, 0, 0);
		ground.position.y = -2.05;
		ground.material = groundMaterial;

		// Torus
		var torus = MeshHelper.CreateTorus("torus", 4, 2, 30, scene, false);
		torus.renderOutline = true;
		torus.outlineWidth = 0.25;

		// Shadows
		var shadowGenerator:ShadowGenerator = new ShadowGenerator(1024, light);
		shadowGenerator.getShadowMap().renderList.push(torus);
		shadowGenerator.usePoissonSampling = true;

		var shadowGenerator2 = new ShadowGenerator(1024, light2);
		shadowGenerator2.getShadowMap().renderList.push(torus);
		shadowGenerator2.useVarianceShadowMap = true;

		ground.receiveShadows = true;

    	scene.registerBeforeRender(function() {
    		torus.rotation.x += 0.01;
			torus.rotation.z += 0.02;

			torus.position = new Vector3(Math.cos(tAlpha) * 30, 10, Math.sin(tAlpha) * 30);
			tAlpha += 0.01;
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
    	Lib.current.addChild(new ShadowDemo());
    }
}
