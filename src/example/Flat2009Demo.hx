package example;

import babylon.cameras.FreeCamera;
import babylon.materials.StandardMaterial;
import babylon.load.SceneLoader;
import openfl.Lib;

class Flat2009Demo extends BaseDemo
{
    override function onInit():Void
    {
    	SceneLoader.Load(scene, "scenes/Flat2009/", "Flat2009.babylon", function() {
			scene.createOrUpdateSelectionOctree();
    		scene.activeCamera = scene.cameras[0];
    		if (scene.activeCamera != null) {
				scene.activeCamera.maxZ = 3000;
    			scene.activeCamera.attachControl(this.touchLayer);
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
    	Lib.current.addChild(new Flat2009Demo());
    }
}
