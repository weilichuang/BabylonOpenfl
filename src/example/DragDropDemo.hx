package example;
import babylon.cameras.ArcRotateCamera;
import babylon.collisions.PickingInfo;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.events.MouseEvent;
import openfl.Lib;


class DragDropDemo extends BaseDemo
{

	 override function onInit():Void
	{
		var camera = new ArcRotateCamera("Camera", 0, 0, 10, new Vector3(0, 0, 0), scene);
		camera.setPosition(new Vector3(20, 200, 400));
		camera.attachControl(this.touchLayer);

		camera.lowerBetaLimit = 0.1;
		camera.upperBetaLimit = (Math.PI / 2) * 0.99;
		camera.lowerRadiusLimit = 150;

		scene.clearColor = new Color3(0, 0, 0);

		// Light
		var light = new PointLight("omni", new Vector3(0, 50, 0), scene);

		// Ground
		var ground = MeshHelper.CreateGround("ground", 1000, 1000, 1, scene, false);
		var groundMaterial = new StandardMaterial("ground", scene);
		groundMaterial.specularColor = Color3.Black();
		ground.material = groundMaterial;

		// Meshes
		var redSphere = MeshHelper.CreateSphere("red", 32, 20, scene);
		var redMat = new StandardMaterial("ground", scene);
		redMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		redMat.specularColor = new Color3(0.4, 0.4, 0.4);
		redMat.emissiveColor = Color3.Red();
		redSphere.material = redMat;
		redSphere.position.y = 10;
		redSphere.position.x -= 100;

		var greenBox = MeshHelper.CreateBox("green", 20, scene);
		var greenMat = new StandardMaterial("ground", scene);
		greenMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		greenMat.specularColor = new Color3(0.4, 0.4, 0.4);
		greenMat.emissiveColor = Color3.Green();
		greenBox.material = greenMat;
		greenBox.position.z -= 100;
		greenBox.position.y = 10;

		var blueBox = MeshHelper.CreateBox("blue", 20, scene);
		var blueMat = new StandardMaterial("ground", scene);
		blueMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		blueMat.specularColor = new Color3(0.4, 0.4, 0.4);
		blueMat.emissiveColor = Color3.Blue();
		blueBox.material = blueMat;
		blueBox.position.x += 100;
		blueBox.position.y = 10;


		var purpleDonut = MeshHelper.CreateTorus("red", 30, 10, 32, scene);
		var purpleMat = new StandardMaterial("ground", scene);
		purpleMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		purpleMat.specularColor = new Color3(0.4, 0.4, 0.4);
		purpleMat.emissiveColor = Color3.Purple();
		purpleDonut.material = purpleMat;
		purpleDonut.position.y = 10;
		purpleDonut.position.z += 100;

		var startingPoint:Vector3;
		var currentMesh:AbstractMesh;

		var getGroundPosition = function (evt:MouseEvent):Vector3
		{
			// Use a predicate to get position on the ground
			var pickinfo:PickingInfo = scene.pick(scene.pointerX, scene.pointerY, 
									function (mesh:AbstractMesh):Bool
									{
										return mesh == ground; 
									});
			if (pickinfo.hit) 
			{
				return pickinfo.pickedPoint;
			}

			return null;
		}

		var onPointerDown = function (evt:MouseEvent)
		{
			// check if we are under a mesh
			var pickInfo:PickingInfo = scene.pick(scene.pointerX, scene.pointerY, 
									function (mesh:AbstractMesh):Bool { 
										return mesh != ground; 
									});
			if (pickInfo.hit)
			{
				currentMesh = pickInfo.pickedMesh;
				startingPoint = getGroundPosition(evt);

				if (startingPoint != null)
				{ 
					// we need to disconnect camera from canvas
					camera.detachControl();
				}
			}
		}

		var onPointerUp = function (evt:MouseEvent):Void
		{
			if (startingPoint != null)
			{
				camera.attachControl(this.touchLayer);
				startingPoint = null;
				return;
			}
		}

		var onPointerMove = function (evt:MouseEvent):Void
		{
			if (startingPoint == null)
			{
				return;
			}

			var current = getGroundPosition(evt);

			if (current == null)
			{
				return;
			}

			var diff:Vector3 = current.subtract(startingPoint);
			currentMesh.position.addInPlace(diff);

			startingPoint = current;
		}

		this.touchLayer.addEventListener(MouseEvent.MOUSE_DOWN, onPointerDown, false);
		this.touchLayer.addEventListener(MouseEvent.MOUSE_UP, onPointerUp, false);
		this.touchLayer.addEventListener(MouseEvent.MOUSE_MOVE, onPointerMove, false);

		scene.executeWhenReady(function()
		{
    		engine.runRenderLoop(scene.render);
    	});
	}
	
	 public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new DragDropDemo());
    }
}