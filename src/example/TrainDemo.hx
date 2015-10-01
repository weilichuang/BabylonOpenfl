package example;

import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.math.Matrix;
import babylon.Node;
import babylon.postprocess.BlackAndWhitePostProcess;
import babylon.postprocess.FilterPostProcess;
import babylon.utils.Logger;
import haxe.ui.toolkit.controls.Button;
import haxe.ui.toolkit.events.UIEvent;
import openfl.events.KeyboardEvent;
import openfl.Lib;
import openfl.ui.Keyboard;

class TrainDemo extends BaseDemo
{
	private var curIndex:Int = 0;
	private var cameraParent:Node;
	
	private var cameraButton:Button;
	
    override function onInit():Void
    {
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    	SceneLoader.Load(scene,"scenes/Train/", "Train.incremental.babylon", function():Void {
			this.scene.collisionsEnabled = false;
			
			for (index in 0...scene.cameras.length)
			{
				scene.cameras[index].minZ = 10;
				
				if (Std.is(scene.cameras[index], FreeCamera))
				{
					var c:FreeCamera = Std.instance(scene.cameras[index], FreeCamera);
					if(c.keysUp.indexOf(87) == -1)
						c.keysUp.push(87);
					if(c.keysDown.indexOf(83) == -1)
						c.keysDown.push(83);
					if(c.keysLeft.indexOf(65) == -1)
						c.keysLeft.push(65);
					if(c.keysRight.indexOf(68) == -1)
						c.keysRight.push(68);
				}
			}
			
			for (index in 0...scene.meshes.length)
			{
				var mesh = scene.meshes[index];

				mesh.isBlocker = mesh.checkCollisions;
			}
			
			var mat:StandardMaterial = Std.instance(scene.getMaterialByName("terrain_eau"), StandardMaterial);
			if(mat != null)
				mat.bumpTexture = null;
				
			Logger.log("scene.cameras.length:" + scene.cameras.length);
				
			// Postprocesses
			var bwPostProcess = new BlackAndWhitePostProcess("Black and White", 1.0, scene.cameras[2]);
			scene.cameras[2].name = "B&W";

			var sepiaKernelMatrix = Matrix.FromValues(
				0.393, 0.349, 0.272, 0,
				0.769, 0.686, 0.534, 0,
				0.189, 0.168, 0.131, 0,
				0, 0, 0, 0
			);
			var sepiaPostProcess = new FilterPostProcess("Sepia", sepiaKernelMatrix, 1.0, scene.cameras[3]);
			scene.cameras[3].name = "SEPIA";
			
			chooseCamera(0);

    		scene.executeWhenReady(function() {
    			engine.runRenderLoop(scene.render);
    		});
    	});

		cameraButton = new Button();
		cameraButton.text = "Next Camera";
		rootUI.addChild(cameraButton);
		cameraButton.x = (stage.stageWidth - cameraButton.width) / 2;
		cameraButton.y = stage.stageHeight - 100;
		cameraButton.addEventListener(UIEvent.CLICK,onCameraMouseDown);
    }
	
	private function onKeyDown(e:KeyboardEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (e.keyCode == Keyboard.SPACE)
		{
			if (curIndex >= scene.cameras.length)
				curIndex = 0;
			else
				curIndex++;
				
			chooseCamera(curIndex);
		}
	}

	private function onCameraMouseDown(e:UIEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (curIndex >= scene.cameras.length)
			curIndex = 0;
		else
			curIndex++;
			
		chooseCamera(curIndex);
	}
	
	private function chooseCamera(index:Int):Void
	{
		if (this.scene == null)
			return;
			
		if (scene.cameras[index] == null)
			return;
				
		scene.activeCamera.detachControl();
		scene.activeCamera = scene.cameras[index];
		
		if (scene.activeCamera != null)
		{
			cameraParent = scene.activeCamera.parent;

			scene.activeCamera.attachControl(this.touchLayer);
		}
	}

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new TrainDemo());
    }
}
