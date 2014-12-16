package example;

import babylon.animations.Animation;
import babylon.animations.EasingFunction;
import babylon.animations.EasingFunction.CircleEase;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class EaseFunctionDemo extends BaseDemo
{
    override function onInit():Void
    {
		var light = new PointLight("Omni", new Vector3(0, 100, 100), scene);
		var camera = new ArcRotateCamera("Camera", 0, 0.8, 100, Vector3.Zero(), scene);
		camera.attachControl(this.touchLayer, true);

		// Torus
		var torus = MeshHelper.CreateTorus("torus", 8, 2, 32, scene, false);
		torus.position.x = 25;
		torus.position.z = 30;

		var materialBox = new StandardMaterial("texture1", scene);
		materialBox.diffuseColor = new Color3(0, 1, 0);//Green

		// -----------------------------------------
		// Creation of an easing animation within predefined easing functions
		// ------------------------------------------

		//Create a Vector3 animation at 30 FPS
		var animationTorus = new Animation("torusEasingAnimation", "position", 30, Animation.ANIMATIONTYPE_VECTOR3, Animation.ANIMATIONLOOPMODE_CYCLE);

		// the torus destination position
		var nextPos = torus.position.add(new Vector3(-80, 0, 0));

		// Animation keys
		var keysTorus = [];
		keysTorus.push({ frame: 0, value: torus.position });
		keysTorus.push({ frame: 120, value: nextPos });
		animationTorus.setKeys(keysTorus);

		// Adding an easing function
		// You can use :
		//1.	CircleEase()
		//2.	BackEase(amplitude)
		//3.	BounceEase(bounces, bounciness)
		//4.	CubicEase()
		//5.	ElasticEase(oscillations, springiness)
		//6.	ExponentialEase(exponent)
		//7.	PowerEase(power)
		//8.	QuadraticEase()
		//9.	QuarticEase()
		//10.	QuinticEase()
		//11.	SineEase()
		// And if you want a total control, you can use a Bezier Curve animation
		//12.   BezierCurveEase(x1, y1, x2, y2)
		var easingFunction = new CircleEase();

		// For each easing function, you can choose beetween EASEIN (default), EASEOUT, EASEINOUT
		easingFunction.setEasingMode(EasingFunction.EASINGMODE_EASEINOUT);

		// Adding easing function to my animation
		animationTorus.setEasingFunction(easingFunction);

		// Adding animation to my torus animations collection
		torus.animations.push(animationTorus);

		//Finally, launch animations on torus, from key 0 to key 120 with loop activated
		scene.beginAnimation(torus, 0, 120, true);

		// ------------------------------------------
		// Using Bezier curve to create a custom easing function
		// See here to see some samples and values : http://cubic-bezier.com/
		// -----------------------------------------

		// Torus
		var bezierTorus = MeshHelper.CreateTorus("torus", 8, 2, 32, scene, false);
		bezierTorus.position.x = 25;
		bezierTorus.position.z = 0;


		// Create the animation
		var animationBezierTorus = new Animation("animationBezierTorus", "position", 30, Animation.ANIMATIONTYPE_VECTOR3, Animation.ANIMATIONLOOPMODE_CYCLE);
		var keysBezierTorus = [];
		keysBezierTorus.push({ frame: 0, value: bezierTorus.position });
		keysBezierTorus.push({ frame: 120, value: bezierTorus.position.add(new Vector3(-80, 0, 0)) });
		animationBezierTorus.setKeys(keysBezierTorus);
		var bezierEase = new BezierCurveEase(0.32, -0.73, 0.69, 1.59);
		animationBezierTorus.setEasingFunction(bezierEase);
		bezierTorus.animations.push(animationBezierTorus);
		scene.beginAnimation(bezierTorus, 0, 120, true);

		// ------------------------------------------
		// Create a simple animation without easing functions
		// ------------------------------------------

		var torus0 = MeshHelper.CreateTorus("torus", 8, 2, 32, scene, false);
		torus0.position.x = 25;
		torus0.position.z = -30;
		torus0.material = materialBox;

		Animation.CreateAndStartAnimation("anim", torus0, "position", 30, 120,
				 torus0.position, torus0.position.add(new Vector3(-80, 0, 0)));
	
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
    	Lib.current.addChild(new EaseFunctionDemo());
    }
}
