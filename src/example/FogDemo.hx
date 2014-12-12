package example;

import babylon.cameras.FreeCamera;
import babylon.FogInfo;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.Scene;
import openfl.Lib;

class FogDemo extends BaseDemo
{
    override function onInit():Void
    {
		scene.fogInfo.fogMode = FogInfo.FOGMODE_EXP;
    	scene.fogInfo.fogDensity = 0.1;
		
    	var camera = new FreeCamera("Camera", new Vector3(0, 0, -20), scene);
		camera.setTarget(new Vector3(0, 0, 0));
		camera.attachControl(this.touchLayer);
		
    	var light = new PointLight("Omni", new Vector3(20, 100, 2), scene);
		
    	var sphere0 = MeshHelper.CreateSphere("Sphere0", 16, 3, scene);
    	var sphere1 = MeshHelper.CreateSphere("Sphere1", 16, 3, scene);
    	var sphere2 = MeshHelper.CreateSphere("Sphere2", 16, 3, scene);
		
    	var material0 = new StandardMaterial("mat0", scene);
    	material0.diffuseColor = new Color3(1, 0, 0);
    	sphere0.material = material0;
    	sphere0.position = new Vector3( -10, 0, 0);
		
    	var material1 = new StandardMaterial("mat1", scene);
    	material1.diffuseColor = new Color3(1, 1, 0);
    	sphere1.material = material1;
		
    	var material2 = new StandardMaterial("mat2", scene);
    	material2.diffuseColor = new Color3(1, 0, 1);
    	sphere2.material = material2;
    	sphere2.position = new Vector3(10, 0, 0);
    	
    	
    	var alpha = .0;
    	scene.registerBeforeRender(function() {
    		sphere0.position.z = 4 * Math.cos(alpha);
    		sphere1.position.z = 6 * Math.sin(alpha);
    		sphere2.position.z = 4 * Math.cos(alpha);
    		alpha += 0.1;
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
    	Lib.current.addChild(new FogDemo());
    }
}
