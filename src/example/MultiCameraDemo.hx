package example;

import babylon.cameras.ArcRotateCamera;
import babylon.cameras.FreeCamera;
import babylon.Engine;
import babylon.lights.DirectionalLight;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.math.Viewport;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.Scene;
import babylon.load.SceneLoader;
import openfl.Lib;

class MultiCameraDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
		camera.setPosition(new Vector3( -5, 5, 0));
    	camera.attachControl(this.stage);
		
		var camera2 = new ArcRotateCamera("Camera2", 0, 0, 10, Vector3.Zero(), scene);
		camera2.setPosition(new Vector3( -5, 15, 0));
    	camera2.attachControl(this.stage);
		
		camera.viewport = new Viewport(0.5, 0, 0.5, 1.0);
		camera2.viewport = new Viewport(0, 0, 0.5, 1.0);
		
		scene.activeCameras.push(camera);
		scene.activeCameras.push(camera2);
		
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
    	Lib.current.addChild(new MultiCameraDemo());
    }
}
