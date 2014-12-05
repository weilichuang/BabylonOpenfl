package example;

import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.math.Matrix;
import babylon.Node;
import babylon.postprocess.BlackAndWhitePostProcess;
import babylon.postprocess.FilterPostProcess;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.ui.Keyboard;

class TrainDemo extends BaseDemo
{
	private var curIndex:Int = 0;
	private var cameraParent:Node;
	
	private var leftButton:CustomButton;
	private var rightButton:CustomButton;
	private var upButton:CustomButton;
	private var downButton:CustomButton;
	private var resetButton:CustomButton;
	
	private var isLeft:Bool = false;
	private var isRight:Bool = false;
	private var isUp:Bool = false;
	private var isDown:Bool = false;
	
	private var cameraButton:CustomButton;
	
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
			
			var mat:StandardMaterial = Std.instance(scene.getMaterialByName("terrain_eau"), StandardMaterial);
			if(mat != null)
				mat.bumpTexture = null;
				
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
		
		leftButton = new CustomButton("Left");
		this.addChild(leftButton);
		leftButton.x = 0;
		leftButton.y = Lib.current.stage.stageHeight - 250;
		leftButton.addEventListener(MouseEvent.MOUSE_DOWN, onLeftButtonMouseDown);
		leftButton.addEventListener(MouseEvent.MOUSE_UP, onLeftButtonMouseUp);
		
		rightButton = new CustomButton("Right");
		this.addChild(rightButton);
		rightButton.x = 200;
		rightButton.y = Lib.current.stage.stageHeight - 250;
		rightButton.addEventListener(MouseEvent.MOUSE_DOWN, onRightButtonMouseDown);
		rightButton.addEventListener(MouseEvent.MOUSE_UP, onRightButtonMouseUp);
		
		upButton = new CustomButton("Up");
		this.addChild(upButton);
		upButton.x = 100;
		upButton.y = Lib.current.stage.stageHeight - 350;
		upButton.addEventListener(MouseEvent.MOUSE_DOWN, onUpButtonMouseDown);
		upButton.addEventListener(MouseEvent.MOUSE_UP, onUpButtonMouseUp);
		
		downButton = new CustomButton("Down");
		this.addChild(downButton);
		downButton.x = 100;
		downButton.y = Lib.current.stage.stageHeight - 150;
		downButton.addEventListener(MouseEvent.MOUSE_DOWN, onDownButtonMouseDown);
		downButton.addEventListener(MouseEvent.MOUSE_UP, onDownButtonMouseUp);
		
		resetButton = new CustomButton("Reset");
		this.addChild(resetButton);
		resetButton.x = 0;
		resetButton.y = Lib.current.stage.stageHeight - 450;
		resetButton.addEventListener(MouseEvent.MOUSE_DOWN, onResetMouseDown);
		
		cameraButton = new CustomButton("Camera");
		this.addChild(cameraButton);
		cameraButton.x = 100;
		cameraButton.y = Lib.current.stage.stageHeight - 450;
		cameraButton.addEventListener(MouseEvent.MOUSE_DOWN, onCameraMouseDown);
		
		this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
	
	private function onEnterFrame(event:Event):Void
	{
		if (cameraParent != null)
		{
			//Logger.log("cameraParent.position : " + cameraParent.position);
			//if (cameraParent.parent != null)
				//Logger.log("cameraParent.parent.position : " + cameraParent.position);
		}
		
		if (this.scene != null)
		{
			if (isLeft)
				Std.instance(scene.activeCamera, FreeCamera).moveLeft();
				
			if (isUp)
				Std.instance(scene.activeCamera, FreeCamera).moveFront();
			
			if (isRight)
				Std.instance(scene.activeCamera, FreeCamera).moveRight();
			
			if (isDown)
				Std.instance(scene.activeCamera, FreeCamera).moveBehind();
		}
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
	
	private function onLeftButtonMouseDown(e:MouseEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (this.scene.activeCamera == null)
			return;
			
		isLeft = true;
		Std.instance(scene.activeCamera, FreeCamera).moveLeft();
	}
	
	private function onLeftButtonMouseUp(e:MouseEvent):Void
	{
		isLeft = false;
	}
	
	private function onDownButtonMouseDown(e:MouseEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (this.scene.activeCamera == null)
			return;
		
		isDown = true;
		Std.instance(scene.activeCamera, FreeCamera).moveBehind();
	}
	
	private function onDownButtonMouseUp(e:MouseEvent):Void
	{
		isDown = false;
	}
	
	private function onRightButtonMouseDown(e:MouseEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (this.scene.activeCamera == null)
			return;
			
		isRight = true;
		Std.instance(scene.activeCamera, FreeCamera).moveRight();
	}
	
	private function onRightButtonMouseUp(e:MouseEvent):Void
	{
		isRight = false;
	}
	
	private function onUpButtonMouseDown(e:MouseEvent):Void
	{
		if (this.scene == null)
			return;
			
		if (this.scene.activeCamera == null)
			return;
		
		isUp = true;
		Std.instance(scene.activeCamera, FreeCamera).moveFront();
	}
	
	private function onUpButtonMouseUp(e:MouseEvent):Void
	{
		isUp = false;
	}
	
	private function onResetMouseDown(e:MouseEvent):Void
	{
		isUp = false;
		isDown = false;
		isLeft = false;
		isRight = false;
	}
	
	private function onCameraMouseDown(e:MouseEvent):Void
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
				
		scene.activeCamera.detachControl(this);
		scene.activeCamera = scene.cameras[index];
		
		if (scene.activeCamera != null)
		{
			cameraParent = scene.activeCamera.parent;
			
			if (cameraParent != null)
			{
				//Logger.log("camera.parent is :" + cameraParent.name);
				//Logger.log("cameraParent.parent is :" + cameraParent.parent.name);
				//if (cameraParent.parent.parent != null)
					//Logger.log("cameraParent.parent is :" + cameraParent.parent.parent.name);
			}
			
			scene.activeCamera.attachControl(this);
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
