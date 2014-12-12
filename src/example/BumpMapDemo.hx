package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class BumpMapDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
		camera.setPosition(new Vector3( -5, 5, 0));
    	camera.attachControl(this.touchLayer);
		
    	var light = new PointLight("Omni", new Vector3(20, 100, 2), scene);
		
		var material:StandardMaterial = new StandardMaterial("kosh", scene);
    	material.bumpTexture = new Texture("img/normalMap.jpg", scene);
    	material.diffuseColor = new Color3(1, 0, 0);
		
    	var sphere = MeshHelper.CreateSphere("Sphere", 16, 3, scene);
    	sphere.material = material;
		
		var skybox = MeshHelper.CreateBox("skyBox", 100.0, scene);
    	var skyboxMaterial = new StandardMaterial("skyBox", scene);
    	skyboxMaterial.backFaceCulling = false;
    	skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
    	skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
    	skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
    	skyboxMaterial.specularColor = new Color3(0, 0, 0);
    	skybox.material = skyboxMaterial;
		
    	scene.registerBeforeRender(function() {
    		sphere.rotation.y += 0.02;
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
    	Lib.current.addChild(new BumpMapDemo());
    }
}
