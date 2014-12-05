package example;

import babylon.bones.Skeleton;
import babylon.cameras.FreeCamera;
import babylon.FogInfo;
import babylon.lights.DirectionalLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Axis;
import babylon.math.Color3;
import babylon.math.Space;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.GroundMesh;
import babylon.mesh.InstancedMesh;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.Node;
import babylon.particles.ParticleSystem;
import babylon.Scene;
import babylon.load.SceneLoader;
import openfl.Lib;

//地表检测时相当卡
class InstancesDemo extends BaseDemo
{
	private var light:DirectionalLight;
	private var camera:FreeCamera;
    override function onInit():Void
    {
    	light = new DirectionalLight("dir01", new Vector3(0, -1, -0.3), scene);
		camera = new FreeCamera("Camera", new Vector3(0, 10, -20), scene);
		camera.speed = 0.4;
		camera.attachControl(this);
		
		camera.keysUp.push(87);
		camera.keysDown.push(83);
		camera.keysLeft.push(65);
		camera.keysRight.push(68);

		light.position = new Vector3(20, 60, 30);

		scene.ambientColor = Color3.FromInts(10, 30, 10);
		scene.clearColor = Color3.FromInts(127, 165, 13);
		scene.gravity = new Vector3(0, -0.5, 0);
		scene.collisionsEnabled = true;

		// Fog
		scene.fogInfo.fogMode = FogInfo.FOGMODE_EXP;
		scene.fogInfo.fogDensity = 0.02;
		scene.fogInfo.fogColor = scene.clearColor;

		// Skybox
		var skybox = MeshHelper.CreateBox("skyBox", 150.0, scene);
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("textures/skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;
		skybox.infiniteDistance = true;

		// Invisible borders
		var border0 = MeshHelper.CreateBox("border0", 1, scene);
		border0.scaling = new Vector3(1, 100, 100);
		border0.position.x = -50.0;
		border0.checkCollisions = true;
		border0.isVisible = false;

		var border1 = MeshHelper.CreateBox("border1", 1, scene);
		border1.scaling = new Vector3(1, 100, 100);
		border1.position.x = 50.0;
		border1.checkCollisions = true;
		border1.isVisible = false;

		var border2 = MeshHelper.CreateBox("border2", 1, scene);
		border2.scaling = new Vector3(100, 100, 1);
		border2.position.z = 50.0;
		border2.checkCollisions = true;
		border2.isVisible = false;

		var border3 = MeshHelper.CreateBox("border3", 1, scene);
		border3.scaling = new Vector3(100, 100, 1);
		border3.position.z = -50.0;
		border3.checkCollisions = true;
		border3.isVisible = false;
		
		// Ground
		var ground:GroundMesh = MeshHelper.CreateGroundFromHeightMap("ground", "textures/heightMap.png", 100, 100, 20, 0, 5, scene, false, onReady);
		var groundMaterial:StandardMaterial = new StandardMaterial("ground", scene);
		var diffuseTexture:Texture = new Texture("textures/ground.jpg", scene);

		diffuseTexture.uScale = 6;
		diffuseTexture.vScale = 6;
		
		groundMaterial.diffuseTexture = diffuseTexture;
		
		groundMaterial.specularColor = new Color3(0, 0, 0);
		ground.material = groundMaterial;
		ground.receiveShadows = true;
		ground.checkCollisions = true;

    	scene.executeWhenReady(function() {
    		engine.runRenderLoop(scene.render);
    	});
    }
	
	private function onReady(node:Node):Void
	{
		var ground = Std.instance(node, GroundMesh);
		
		ground.optimize(20);

		// Shadows
		var shadowGenerator = new ShadowGenerator(1024, light);
		shadowGenerator.usePoissonSampling = true;
		shadowGenerator.setDarkness(0.8);

		// Trees
		SceneLoader.LoadMesh("", "scenes/Tree/", "tree.babylon", scene,  
		function(newMeshes:Array<AbstractMesh>,particlesSystems:Array<ParticleSystem>,skeletons:Array<Skeleton>):Void
		{
			trace("Tree Load Complete");
			
			var mesh:Mesh = Std.instance(newMeshes[0], Mesh);
			
			Std.instance(mesh.material,StandardMaterial).opacityTexture = null;
			mesh.material.backFaceCulling = true;

			mesh.position.y = ground.getHeightAtCoordinates(0, 0); // Getting height from ground object

			shadowGenerator.getShadowMap().renderList.push(mesh);
			
			var range:Float = 60;
			var count:Int = 100;
			for (index in 0...count)
			{
				var newInstance:InstancedMesh = mesh.createInstance("tree_instance" + index);
				var px = range / 2 - Math.random() * range;
				var pz = range / 2 - Math.random() * range;
				var py = ground.getHeightAtCoordinates(px, pz); // Getting height from ground object

				newInstance.position = new Vector3(px, py, pz);

				newInstance.rotate(Axis.Y(), Math.random() * Math.PI * 2, Space.WORLD);

				var scale = 0.5 + Math.random() * 2;
				newInstance.scaling.addInPlace(new Vector3(scale, scale, scale));
				
				shadowGenerator.getShadowMap().renderList.push(newInstance);
			}
			shadowGenerator.getShadowMap().refreshRate = 0; // We need to compute it just once

			// Collisions
			camera.checkCollisions = true;
			camera.applyGravity = true;
		});
	}

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new InstancesDemo());
    }
}
