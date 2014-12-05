package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.MeshHelper;
import openfl.Lib;

//SkyBox bug
class BugTest extends BaseDemo
{
    override function onInit():Void
    {
		//左下角是0,0
    	var camera_01 = new ArcRotateCamera("Camera_01", 1, 0.8, 10, new Vector3(0, 0, 0), scene);

		var light0 = new PointLight("Omni_0", new Vector3(0, 0, 10), scene);
		var light1 = new PointLight("Omni_1", new Vector3(0, 10, 0), scene);
		var light2 = new PointLight("Omni_2", new Vector3(10, 0, 0), scene);
		
		light0.diffuse = new Color3(0.8, 0, 0);
    	light0.specular = new Color3(0.8, 0, 0);
		
		light1.diffuse = new Color3(0, 0.8, 0);
    	light1.specular = new Color3(0, 0.8, 0);
		
		light2.diffuse = new Color3(0, 0, 0.8);
    	light2.specular = new Color3(0, 0, 0.8);

		var sm:StandardMaterial = new StandardMaterial("yellow", scene);
		sm.diffuseColor = new Color3(1, 1, 1);
		sm.specularColor = new Color3(0, 0, 0);
		sm.emissiveColor = new Color3(0.2, 0.2, 0.2);
		
		//var box = MeshHelper.CreateBox("Box", 3.0, scene);
		//box.showBoundingBox = true;
		//box.material = sm;
		
		// Skybox
		var skybox = MeshHelper.CreateBox("skyBox", 100.0, scene);
		skybox.showBoundingBox = true;
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;

		camera_01.attachControl(this.stage);

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
    	Lib.current.addChild(new BugTest());
    }
}
