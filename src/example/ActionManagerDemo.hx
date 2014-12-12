package example;

import babylon.actions.ActionManager;
import babylon.actions.CombineAction;
import babylon.actions.DoNothingAction;
import babylon.actions.IncrementValueAction;
import babylon.actions.InterpolateValueAction;
import babylon.actions.SetStateAction;
import babylon.actions.SetValueAction;
import babylon.actions.StateCondition;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.Light;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class ActionManagerDemo extends BaseDemo
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

		var light1 = new PointLight("omni", new Vector3(0, 50, 0), scene);
		var light2 = new PointLight("omni", new Vector3(0, 50, 0), scene);
		var light3 = new PointLight("omni", new Vector3(0, 50, 0), scene);

		light1.diffuse = Color3.Red();
		light2.diffuse = Color3.Green();
		light3.diffuse = Color3.Blue();

		// Define states
		light1.state = "on";
		light2.state = "on";
		light3.state = "on";

		// Ground
		var ground:Mesh = MeshHelper.CreateGround("ground", 1000, 1000, 1, scene, false);
		var groundMaterial:StandardMaterial = new StandardMaterial("ground", scene);
		groundMaterial.specularColor = Color3.Black();
		ground.material = groundMaterial;
		ground.position.y -= 20;

		// Boxes
		var redBox:Mesh = MeshHelper.CreateBox("red", 20, scene);
		var redMat:StandardMaterial = new StandardMaterial("red", scene);
		redMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		redMat.specularColor = new Color3(0.4, 0.4, 0.4);
		redMat.emissiveColor = Color3.Red();
		redBox.material = redMat;
		redBox.position.x -= 100;

		var greenBox:Mesh = MeshHelper.CreateBox("green", 20, scene);
		var greenMat:StandardMaterial = new StandardMaterial("green", scene);
		greenMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		greenMat.specularColor = new Color3(0.4, 0.4, 0.4);
		greenMat.emissiveColor = Color3.Green();
		greenBox.material = greenMat;
		greenBox.position.z -= 100;

		var blueBox:Mesh = MeshHelper.CreateBox("blue", 20, scene);
		var blueMat:StandardMaterial = new StandardMaterial("blue", scene);
		blueMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		blueMat.specularColor = new Color3(0.4, 0.4, 0.4);
		blueMat.emissiveColor = Color3.Blue();
		blueBox.material = blueMat;
		blueBox.position.x += 100;

		// Sphere
		var sphere:Mesh = MeshHelper.CreateSphere("sphere", 16, 20, scene);
		var sphereMat:StandardMaterial = new StandardMaterial("sphere", scene);
		sphereMat.diffuseColor = new Color3(0.4, 0.4, 0.4);
		sphereMat.specularColor = new Color3(0.4, 0.4, 0.4);
		sphereMat.emissiveColor = Color3.Purple();
		sphere.material = sphereMat;
		sphere.position.z += 100;

		// Rotating donut
		var donut:Mesh = MeshHelper.CreateTorus("donut", 20, 8, 16, scene);
	
		// On pick interpolations
		var prepareButton = function(mesh:AbstractMesh, color:Color3, light:Light):Void
		{
			var goToColorAction = new InterpolateValueAction(ActionManager.OnPickTrigger, null, light, "diffuse", color, 1000, null, true);

			mesh.actionManager = new ActionManager(scene);
			mesh.actionManager.registerAction(
				new InterpolateValueAction(ActionManager.OnPickTrigger,null, light, "diffuse", Color3.Black(), 1000))
				.then(new CombineAction(ActionManager.NothingTrigger,null, [ // Then is used to add a child action used alternatively with the root action. 
					goToColorAction,                                                 // First click: root action. Second click: child action. Third click: going back to root action and so on...   
					new SetValueAction(ActionManager.NothingTrigger,null, mesh.material, "wireframe", false)
				]));
			mesh.actionManager.registerAction(new SetValueAction(ActionManager.OnPickTrigger,null, mesh.material, "wireframe", true))
				.then(new DoNothingAction());
			mesh.actionManager.registerAction(new SetStateAction(ActionManager.OnPickTrigger,null, light, "off"))
				.then(new SetStateAction(ActionManager.OnPickTrigger, null, light, "on"));
		}

		prepareButton(redBox, Color3.Red(), light1);
		prepareButton(greenBox, Color3.Green(), light2);
		prepareButton(blueBox, Color3.Blue(), light3);

		// Conditions
		sphere.actionManager = new ActionManager(scene);
		var condition1 = new StateCondition(sphere.actionManager, light1, "off");
		var condition2 = new StateCondition(sphere.actionManager, light1, "on");

		sphere.actionManager.registerAction(new InterpolateValueAction(ActionManager.OnLeftPickTrigger, null, camera, "alpha", 0, 500, condition1));
		sphere.actionManager.registerAction(new InterpolateValueAction(ActionManager.OnLeftPickTrigger, null, camera, "alpha", Math.PI, 500, condition2));

		// Over/Out
		var makeOverOut = function(mesh:AbstractMesh):Void
		{
			mesh.actionManager.registerAction(new SetValueAction(ActionManager.OnPointerOutTrigger, null, mesh.material, "emissiveColor", Std.instance(mesh.material, StandardMaterial).emissiveColor));
			mesh.actionManager.registerAction(new SetValueAction(ActionManager.OnPointerOverTrigger, null, mesh.material, "emissiveColor", Color3.White()));
			mesh.actionManager.registerAction(new InterpolateValueAction(ActionManager.OnPointerOutTrigger, null, mesh, "scaling", new Vector3(1, 1, 1), 150));
			mesh.actionManager.registerAction(new InterpolateValueAction(ActionManager.OnPointerOverTrigger, null, mesh, "scaling", new Vector3(1.1, 1.1, 1.1), 150));
		}

		makeOverOut(redBox);
		makeOverOut(greenBox);
		makeOverOut(blueBox);
		makeOverOut(sphere);

		// scene's actions
		scene.actionManager = new ActionManager(scene);

		function rotate(mesh:AbstractMesh):Void
		{
			scene.actionManager.registerAction(new IncrementValueAction(ActionManager.OnEveryFrameTrigger, null, mesh, "rotation.y", 0.01));
		}

		rotate(redBox);
		rotate(greenBox);
		rotate(blueBox);
		
		// Intersections
		donut.actionManager = new ActionManager(scene);

		donut.actionManager.registerAction(new SetValueAction(ActionManager.OnIntersectionEnterTrigger,sphere, 
			donut, "scaling", new Vector3(1.2, 1.2, 1.2)));

		donut.actionManager.registerAction(new SetValueAction(ActionManager.OnIntersectionExitTrigger, sphere, donut, "scaling", new Vector3(1, 1, 1)));

		// Animations
		var alpha:Float = 0;
		scene.registerBeforeRender(function():Void {
			donut.position.x = 100 * Math.cos(alpha);
			donut.position.y = 5;
			donut.position.z = 100 * Math.sin(alpha);
			alpha += 0.01;
		});
		
    	scene.executeWhenReady(function():Void
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
    	Lib.current.addChild(new ActionManagerDemo());
    }
}
