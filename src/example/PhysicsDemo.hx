package example ;

import babylon.cameras.FreeCamera;
import babylon.collisions.PickingInfo;
import babylon.lights.DirectionalLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.physics.OimoPlugin;
import babylon.physics.PhysicsEngine;
import example.BaseDemo;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.ui.Keyboard;

/**
 * ...
 * @author weilichuang
 */
class PhysicsDemo extends BaseDemo
{

	override function onInit():Void
    {
    	//scene.clearColor = Color3.Purple();

		var camera = new FreeCamera("Camera", new Vector3(0, 0, -20), scene);
		camera.checkCollisions = true;
		camera.applyGravity = true;
		camera.setTarget(new Vector3(0, 0, 0));
		camera.attachControl(this);
		
		if(camera.keysUp.indexOf(87) == -1)
			camera.keysUp.push(87);
		if(camera.keysDown.indexOf(83) == -1)
			camera.keysDown.push(83);
		if(camera.keysLeft.indexOf(65) == -1)
			camera.keysLeft.push(65);
		if(camera.keysRight.indexOf(68) == -1)
			camera.keysRight.push(68);

		var light = new DirectionalLight("dir02", new Vector3(0.2, -1, 0), scene);
		light.position = new Vector3(0, 80, 0);

		// Material
		var materialAmiga = new StandardMaterial("amiga", scene);
		materialAmiga.diffuseTexture = new Texture("textures/amiga.jpg", scene);
		materialAmiga.emissiveColor = new Color3(0.5, 0.5, 0.5);
		cast(materialAmiga.diffuseTexture,Texture).uScale = 5;
		cast(materialAmiga.diffuseTexture,Texture).vScale = 5;

		var materialAmiga2 = new StandardMaterial("amiga", scene);
		materialAmiga2.diffuseTexture = new Texture("textures/mosaic.jpg", scene);
		materialAmiga2.emissiveColor = new Color3(0.5, 0.5, 0.5);

		// Shadows
		var shadowGenerator = new ShadowGenerator(2048, light);

		// Physics
		scene.enablePhysics(null, new OimoPlugin());

		// Spheres
		var sphere:Mesh;
		var y = 0;
		for (index in 0...100)
		{
			sphere = MeshHelper.CreateSphere("Sphere0", 16, 3, scene);
			sphere.material = materialAmiga;

			sphere.position = new Vector3(Math.random() * 20 - 10, y, Math.random() * 10 - 5);

			shadowGenerator.getShadowMap().renderList.push(sphere);

			sphere.setPhysicsState(PhysicsEngine.SphereImpostor, { mass: 1 });

			y += 2;
		}

		// Link
		var spheres:Array<Mesh> = [];
		for (index in 0...10)
		{
			sphere = MeshHelper.CreateSphere("Sphere0", 16, 1, scene);
			spheres.push(sphere);
			sphere.material = materialAmiga2;
			sphere.position = new Vector3(Math.random() * 20 - 10, y, Math.random() * 10 - 5);
			sphere.checkCollisions = true;

			shadowGenerator.getShadowMap().renderList.push(sphere);

			sphere.setPhysicsState(PhysicsEngine.SphereImpostor, { mass: 1,restitution:1 });
		}

		for (index in 0...10)
		{
			spheres[index].setPhysicsLinkWith(spheres[index + 1], new Vector3(0, 0.5, 0), new Vector3(0, -0.5, 0));
		}

		// Box
		var box0 = MeshHelper.CreateBox("Box0", 3, scene);
		box0.position = new Vector3(3, 30, 0);
		var materialWood = new StandardMaterial("wood", scene);
		materialWood.diffuseTexture = new Texture("textures/wood.jpg", scene);
		materialWood.emissiveColor = new Color3(0.5, 0.5, 0.5);
		box0.material = materialWood;
		box0.checkCollisions = true;

		shadowGenerator.getShadowMap().renderList.push(box0);
		
		box0.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 2, friction: 0.4, restitution: 0.3 });

		// Compound
		var part0 = MeshHelper.CreateBox("part0", 3, scene);
		part0.position = new Vector3(3, 30, 0);
		part0.material = materialWood;

		var part1 = MeshHelper.CreateBox("part1", 3, scene);
		part1.parent = part0; // We need a hierarchy for compound objects
		part1.position = new Vector3(0, 3, 0);
		part1.material = materialWood;

		shadowGenerator.getShadowMap().renderList.push(part0);
		shadowGenerator.getShadowMap().renderList.push(part1);

		scene.createCompoundImpostor([
			{ mesh: part0, impostor: PhysicsEngine.BoxImpostor },
			{ mesh: part1, impostor: PhysicsEngine.BoxImpostor } ],
			{mass: 2, friction: 0.4, restitution: 0.3});

		var groundMat = new StandardMaterial("groundMat", scene);
		groundMat.diffuseColor = new Color3(0.5, 0.5, 0.5);
		groundMat.emissiveColor = new Color3(0.2, 0.2, 0.2);
		groundMat.backFaceCulling = false;
		
		// Playground
		var ground = MeshHelper.CreateBox("Ground", 1, scene);
		ground.scaling = new Vector3(100, 1, 100);
		ground.position.y = -5.0;
		ground.checkCollisions = true;
		ground.material = groundMat;
		ground.receiveShadows = true;
		ground.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 0, friction: 0.5, restitution: 0.7 });

		var border0 = MeshHelper.CreateBox("border0", 1, scene);
		border0.scaling = new Vector3(1, 100, 100);
		border0.position.y = -5.0;
		border0.position.x = -50.0;
		border0.checkCollisions = true;
		border0.material = groundMat;
		border0.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 0, friction: 0, restitution: 0 });

		var border1 = MeshHelper.CreateBox("border1", 1, scene);
		border1.scaling = new Vector3(1, 100, 100);
		border1.position.y = -5.0;
		border1.position.x = 50.0;
		border1.checkCollisions = true;
		border1.material = groundMat;
		border1.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 0, friction: 0, restitution: 0 });

		var border2 = MeshHelper.CreateBox("border2", 1, scene);
		border2.scaling = new Vector3(100, 100, 1);
		border2.position.y = -5.0;
		border2.position.z = 50.0;
		border2.checkCollisions = true;
		border2.material = groundMat;
		border2.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 0, friction: 0, restitution: 0 });

		var border3 = MeshHelper.CreateBox("border3", 1, scene);
		border3.scaling = new Vector3(100, 100, 1);
		border3.position.y = -5.0;
		border3.position.z = -50.0;
		border3.checkCollisions = true;
		border3.material = groundMat;
		border3.setPhysicsState(PhysicsEngine.BoxImpostor, { mass: 0, friction: 0, restitution: 0 });

    	scene.executeWhenReady(function() {
    		engine.runRenderLoop(scene.render);
    	});
		
		this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		scene.onPointerDown = function(event:MouseEvent, pickResult:PickingInfo):Void
		{
			if (pickResult.hit) 
			{
				var dir:Vector3 = pickResult.pickedPoint.subtract(scene.activeCamera.position);
				dir.normalize();
				pickResult.pickedMesh.applyImpulse(dir.scale(10), pickResult.pickedPoint);
			}
		}
		scene.attachControl();
    }
	
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.SPACE)
		{
			this.scene.activePhysics(!this.scene.isPhysicsActive());
		}
	}

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new PhysicsDemo());
    }
	
}