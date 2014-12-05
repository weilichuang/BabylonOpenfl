package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.SpotLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class HeightMapDemo extends BaseDemo
{
    override function onInit():Void
    {
    	// Light
		var spot = new SpotLight("spot", new Vector3(0, 30, 10), new Vector3(0, -1, 0), 17, 1, scene);
		spot.diffuse = new Color3(1, 1, 1);
		spot.specular = new Color3(0, 0, 0);
		spot.intensity = 0.3;

		// Camera
		var camera = new ArcRotateCamera("Camera", 0, 0.8, 100, Vector3.Zero(), scene);
		camera.lowerBetaLimit = 0.1;
		camera.upperBetaLimit = (Math.PI / 2) * 0.9;
		camera.lowerRadiusLimit = 30;
		camera.upperRadiusLimit = 150;
		camera.attachControl(this.stage);

		// Ground
		var groundMaterial = new StandardMaterial("ground", scene);
		groundMaterial.diffuseTexture = new Texture("textures/earth.jpg", scene);

		var ground = MeshHelper.CreateGroundFromHeightMap("ground", "textures/worldHeightMap.jpg", 200, 200, 250, 0, 50, scene, false);
		ground.material = groundMaterial;

		//Sphere to see the light's position
		var sun = MeshHelper.CreateSphere("sun", 10, 4, scene);
		sun.material = new StandardMaterial("sun", scene);
		Std.instance(sun.material,StandardMaterial).emissiveColor = new Color3(1, 1, 0);

		// Skybox
		var skybox = MeshHelper.CreateBox("skyBox", 800.0, scene);
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;

    	scene.registerBeforeRender(function() {
    		sun.position = spot.position;
			spot.position.x -= 0.5;
			if (spot.position.x < -90)
				spot.position.x = 100;
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
    	Lib.current.addChild(new HeightMapDemo());
    }
}
