package example;

import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import openfl.Lib;

class TheCarDemo extends BaseDemo
{
    override function onInit():Void
    {
    	SceneLoader.Load(scene,"scenes/TheCar/", "TheCar.incremental.babylon", function() {
    		scene.activeCamera = scene.cameras[0];
    		if (scene.activeCamera != null) {
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
    	Lib.current.addChild(new TheCarDemo());
    }
}
