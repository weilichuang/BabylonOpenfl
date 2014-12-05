package example;

import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import openfl.Lib;

class HiillValleyDemo extends BaseDemo
{
    override function onInit():Void
    {
    	SceneLoader.Load(scene, "scenes/hillvalley/", "HillValley.incremental.babylon", function() {
			scene.collisionsEnabled = false;
			scene.lightsEnabled = false;
			//scene.createOrUpdateSelectionOctree();
			
			for (matIndex in 0...scene.materials.length)
			{
				scene.materials[matIndex].checkReadyOnEveryCall = false;
			}
				
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
    	Lib.current.addChild(new HiillValleyDemo());
    }
}
