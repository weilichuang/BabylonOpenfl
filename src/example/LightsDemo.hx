package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.DirectionalLight;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class LightsDemo extends BaseDemo
{
	private var camera:ArcRotateCamera;
    override function onInit():Void
    {
    	camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
    	camera.attachControl(this.touchLayer);
		camera.setPosition(new Vector3( -10, 10, 0));
		
    	var light0 = new PointLight("Omni0", new Vector3(0, 10, 0), scene);
		light0.diffuse = new Color3(1, 0, 0);
    	light0.specular = new Color3(1, 0, 0);
		
    	var light1 = new PointLight("Omni1", new Vector3(0, -10, 0), scene);
		light1.diffuse = new Color3(0, 1, 0);
    	light1.specular = new Color3(0, 1, 0);
		
    	var light2 = new PointLight("Omni2", new Vector3(10, 0, 0), scene);
		light2.diffuse = new Color3(0, 0, 1);
    	light2.specular = new Color3(0, 0, 1);
		
    	var light3 = new DirectionalLight("Dir0", new Vector3(1, -1, 0), scene);
		light3.parent = camera;
		light3.diffuse = new Color3(1, 1, 1);
    	light3.specular = new Color3(1, 1, 1);

    	var lightSphere0 = MeshHelper.CreateSphere("Sphere0", 16, 0.5, scene);
    	var lightSphere1 = MeshHelper.CreateSphere("Sphere1", 16, 0.5, scene);
    	var lightSphere2 = MeshHelper.CreateSphere("Sphere2", 16, 0.5, scene);

		var material0:StandardMaterial = new StandardMaterial("red", scene);
    	material0.diffuseColor = new Color3(0, 0, 0);
    	material0.specularColor = new Color3(0, 0, 0);
    	material0.emissiveColor = new Color3(1, 0, 0);
		lightSphere0.material = material0;
		
		var material1:StandardMaterial = new StandardMaterial("green", scene);
    	material1.diffuseColor = new Color3(0, 0, 0);
    	material1.specularColor = new Color3(0, 0, 0);
    	material1.emissiveColor = new Color3(0, 1, 0);
		lightSphere1.material = material1;
		
		var material2:StandardMaterial = new StandardMaterial("blue", scene);
    	material2.diffuseColor = new Color3(0, 0, 0);
    	material2.specularColor = new Color3(0, 0, 0);
    	material2.emissiveColor = new Color3(0, 0, 1);
		lightSphere2.material = material2;
		
		var material = new StandardMaterial("kosh", scene);
    	material.diffuseColor = new Color3(1, 1, 1);
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
		
		
    	var alpha = .0;
    	scene.registerBeforeRender(function() {
    		light0.position = new Vector3(10 * Math.sin(alpha), 0, 10 * Math.cos(alpha));
    		light1.position = new Vector3(10 * Math.sin(alpha), 0, -10 * Math.cos(alpha));
    		light2.position = new Vector3(10 * Math.cos(alpha), 0, 10 * Math.sin(alpha));
    		lightSphere0.position = light0.position;
    		lightSphere1.position = light1.position;
    		lightSphere2.position = light2.position;
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
    	Lib.current.addChild(new LightsDemo());
    }
}
