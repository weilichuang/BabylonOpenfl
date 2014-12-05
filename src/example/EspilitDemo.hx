package example;

import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.math.Vector3;
import openfl.Lib;

class EspilitDemo extends BaseDemo
{
    override function onInit():Void
    {
		StandardMaterial.DiffuseTextureEnabled = true;
		StandardMaterial.AmbientTextureEnabled = true;
		StandardMaterial.OpacityTextureEnabled = true;
		StandardMaterial.ReflectionTextureEnabled = true;
		StandardMaterial.EmissiveTextureEnabled = true;
		StandardMaterial.SpecularTextureEnabled = true;
		StandardMaterial.BumpTextureEnabled = true ;
		
    	SceneLoader.Load(scene, "scenes/Espilit/", "Espilit.babylon", function():Void {
			scene.autoClear = true;
			scene.collisionsEnabled = true;
			scene.gravity = new Vector3(0, -0.5, 0);
			//octree有点问题
			//scene.createOrUpdateSelectionOctree();
				
    		scene.activeCamera = scene.cameras[0];
    		if (scene.activeCamera != null) {
    			scene.activeCamera.attachControl(this);
    			var _c:FreeCamera = Std.instance(scene.activeCamera, FreeCamera);
    			_c.keysUp.push(87);
    			_c.keysDown.push(83);
    			_c.keysLeft.push(65);
    			_c.keysRight.push(68);
    		};
    		scene.executeWhenReady(function() {
    			engine.runRenderLoop(scene.render);
    		});
    	});
    }

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new EspilitDemo());
    }
}
