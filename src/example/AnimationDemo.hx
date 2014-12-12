package example;

import babylon.animations.Animation;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class AnimationDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var light = new PointLight("Omni", new Vector3(0, 100, 100), scene);
		var camera = new ArcRotateCamera("Camera", 0, 0.8, 100, Vector3.Zero(), scene);
		camera.attachControl(this.touchLayer, false);

		//Boxes
		var box1 = MeshHelper.CreateBox("Box1", 10.0, scene);
		box1.position.x = -20;
		var box2 = MeshHelper.CreateBox("Box2", 10.0, scene);

		var materialBox = new StandardMaterial("texture1", scene);
		materialBox.diffuseColor = new Color3(0, 1, 0);//Green
		var materialBox2 = new StandardMaterial("texture2", scene);

		//Applying materials
		box1.material = materialBox;
		box2.material = materialBox2;

		//Positioning box
		box2.position.x = 20;

		// Creation of a basic animation with box 1
		//----------------------------------------

		//Create a scaling animation at 30 FPS
		var animationBox = new Animation("tutoAnimation", "scaling.x", 30, Animation.ANIMATIONTYPE_FLOAT,
																		Animation.ANIMATIONLOOPMODE_CYCLE);
		//Here we have chosen a loop mode, but you can change to :
		//  Use previous values and increment it (Animation.ANIMATIONLOOPMODE_RELATIVE)
		//  Restart from initial value (Animation.ANIMATIONLOOPMODE_CYCLE)
		//  Keep the final value (Animation.ANIMATIONLOOPMODE_CONSTANT)

		// Animation keys
		var keys = [];
		//At the animation key 0, the value of scaling is "1"
		keys.push({
			frame: 0,
			value: 1.0
		});

		//At the animation key 20, the value of scaling is "0.2"
		keys.push({
			frame: 20,
			value: 0.2
		});

		//At the animation key 100, the value of scaling is "1"
		keys.push({
			frame: 100,
			value: 1.0
		});

		//Adding keys to the animation object
		animationBox.setKeys(keys);

		//Then add the animation object to box1
		box1.animations.push(animationBox);

		//Finally, launch animations on box1, from key 0 to key 100 with loop activated
		scene.beginAnimation(box1, 0, 100, true);
	
		scene.registerBeforeRender(function () {
			//The color is defined at run time with random()
			Std.instance(box2.material,StandardMaterial).diffuseColor = new Color3(Math.random(), Math.random(), Math.random());
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
    	Lib.current.addChild(new AnimationDemo());
    }
}
