package example;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.HemisphericLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class TorusKnotDemo extends BaseDemo
{

	override function onInit():Void
    {
		// Create a rotating camera
		var camera = new ArcRotateCamera("Camera", 0, Math.PI / 2, 12, Vector3.Zero(), scene);
	
		// Attach it to handle user inputs (keyboard, mouse, touch)
		camera.attachControl(this.touchLayer);
	
		// Add a light
		var light = new HemisphericLight("hemi", new Vector3(0, 1, 0), scene);
	
		// Create a builtin shape
		var knot = MeshHelper.CreateTorusKnot("mesh", 2, 0.5, 128, 64, 2, 3, scene);
	
		// Define a simple material
		var material = new StandardMaterial("std", scene);
		material.diffuseColor = new Color3(0.5, 0, 0.5);
	
		knot.material = material;
			
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
    	Lib.current.addChild(new TorusKnotDemo());
    }
	
}