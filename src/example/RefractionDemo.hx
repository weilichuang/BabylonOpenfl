package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lensflare.LensFlare;
import babylon.lensflare.LensFlareSystem;
import babylon.lights.DirectionalLight;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.postprocess.RefractionPostProcess;
import openfl.Lib;

class RefractionDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 100, Vector3.Zero(), scene);

    	var light = new DirectionalLight("dir01", new Vector3(0, -1, -0.2), scene);
    	var light2 = new DirectionalLight("dir02", new Vector3(-1, -2, -1), scene);
    	var light3 = new PointLight("Omni0", new Vector3(21.84, 50, -28.26), scene);
    	light.position = new Vector3(0, 30, 0);
    	light2.position = new Vector3(10, 20, 10);
    	light.intensity = 0.6;
    	light2.intensity = 0.6;
		
    	camera.setPosition(new Vector3(-60, 60, 0));
    	camera.lowerBetaLimit = (Math.PI / 2) * 0.8;
    	camera.attachControl(this.stage);
		
    	var lensFlareSystem = new LensFlareSystem("lensFlareSystem", light3, scene);
    	var flare00 = new LensFlare(lensFlareSystem,0.2, 0, new Color3(1, 1, 1), "img/lens5.png");
    	var flare01 = new LensFlare(lensFlareSystem,0.5, 0.2, new Color3(0.5, 0.5, 1), "img/lens4.png");
    	var flare02 = new LensFlare(lensFlareSystem,0.2, 1.0, new Color3(1, 1, 1), "img/lens4.png");
    	var flare03 = new LensFlare(lensFlareSystem,0.4, 0.4, new Color3(1, 0.5, 1), "img/Flare.png");
    	var flare04 = new LensFlare(lensFlareSystem,0.1, 0.6, new Color3(1, 1, 1), "img/lens5.png");
		
    	var skybox = MeshHelper.CreateBox("skyBox", 1000.0, scene);
    	var skyboxMaterial = new StandardMaterial("skyBox", scene);
    	skyboxMaterial.backFaceCulling = false;
    	skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
    	skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
    	skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
    	skyboxMaterial.specularColor = new Color3(0, 0, 0);
    	skybox.material = skyboxMaterial;
		
    	var sphere0 = MeshHelper.CreateSphere("Sphere0", 16, 10, scene);
    	var sphere1 = MeshHelper.CreateSphere("Sphere1", 16, 10, scene);
    	var sphere2 = MeshHelper.CreateSphere("Sphere2", 16, 10, scene);
		
		
    	var sm:StandardMaterial = new StandardMaterial("red", scene);
    	sm.specularColor = new Color3(0, 0, 0);
    	sm.diffuseColor = new Color3(1.0, 0, 0);
		
		sphere0.material = sm;
		
    	sm = new StandardMaterial("green", scene);
    	sm.specularColor = new Color3(0, 0, 0);
    	sm.diffuseColor = new Color3(0, 1.0, 0);
		
		sphere1.material = sm;
		
    	sm = new StandardMaterial("blue", scene);
    	sm.specularColor = new Color3(0, 0, 0);
    	sm.diffuseColor = new Color3(0, 0, 1.0);
		
		sphere2.material = sm;
		
    	var postProcess = new RefractionPostProcess("Refraction", "img/refMap.jpg", new Color3(1.0, 1.0, 1.0), 0.5, 0.5, 1.0, camera);
		
    	var alpha = .0;
    	scene.registerBeforeRender(function() {
    		sphere0.position = new Vector3(20 * Math.sin(alpha), 0, 20 * Math.cos(alpha));
    		sphere1.position = new Vector3(20 * Math.sin(alpha), 0, -20 * Math.cos(alpha));
    		sphere2.position = new Vector3(20 * Math.cos(alpha), 0, 20 * Math.sin(alpha));
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
    	Lib.current.addChild(new RefractionDemo());
    }
}
