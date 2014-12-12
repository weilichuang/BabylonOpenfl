package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lensflare.LensFlare;
import babylon.lensflare.LensFlareSystem;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class LensFlaresDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
    	var light0 = new PointLight("Omni0", new Vector3(21.84, 50, -28.26), scene);
    	camera.alpha = 2.8;
    	camera.beta = 2.25;
    	camera.attachControl(this.touchLayer);
		
    	var lensFlareSystem = new LensFlareSystem("lensFlareSystem", light0, scene);
    	var flare00 = new LensFlare(0.2, 0, lensFlareSystem, new Color3(1, 1, 1), "img/lens5.png");
    	var flare01 = new LensFlare(0.5, 0.2, lensFlareSystem, new Color3(0.5, 0.5, 1), "img/lens4.png");
    	var flare02 = new LensFlare(0.2, 1.0, lensFlareSystem, new Color3(1, 1, 1), "img/lens4.png");
    	var flare03 = new LensFlare(0.4, 0.4, lensFlareSystem, new Color3(1, 0.5, 1), "img/Flare.png");
    	var flare04 = new LensFlare(0.1, 0.6, lensFlareSystem, new Color3(1, 1, 1), "img/lens5.png");
		
    	var skybox = MeshHelper.CreateBox("skyBox", 100.0, scene);
    	var skyboxMaterial = new StandardMaterial("skyBox", scene);
    	skyboxMaterial.backFaceCulling = false;
    	skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
    	skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
    	skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
    	skyboxMaterial.specularColor = new Color3(0, 0, 0);
    	skybox.material = skyboxMaterial;
		
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
    	Lib.current.addChild(new LensFlaresDemo());
    }
}
