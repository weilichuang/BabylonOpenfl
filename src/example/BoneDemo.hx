package example;

import babylon.bones.Skeleton;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.DirectionalLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.particles.ParticleSystem;
import openfl.Lib;

class BoneDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var light = new DirectionalLight("dir01", new Vector3(0, -0.5, -1.0), scene);
		light.position = new Vector3(20, 150, 70);
		
		var camera = new ArcRotateCamera("Camera", 0, 0, 10, new Vector3(0, 30, 0), scene);
		camera.setPosition(new Vector3(20, 70, 120));
		camera.minZ = 10.0;
		camera.attachControl(this.touchLayer);

		scene.ambientColor = new Color3(0.3, 0.3, 0.3);

		// Ground
		var ground = MeshHelper.CreateGround("ground", 1000, 1000, 1, scene, false);
		var groundMaterial = new StandardMaterial("ground", scene);
		groundMaterial.diffuseColor = new Color3(0.7, 0.7, 0.7);
		groundMaterial.specularColor = new Color3(0, 0, 0);
		ground.material = groundMaterial;
		ground.receiveShadows = true;

		// Shadows
		var shadowGenerator = new ShadowGenerator(1024, light);

		// Meshes
		SceneLoader.LoadMesh("Rabbit", "scenes/Rabbit/", "Rabbit.babylon", scene, 
		function (newMeshes:Array<AbstractMesh>,particlesSystems:Array<ParticleSystem>,skeletons:Array<Skeleton>):Void
		{
			var rabbit:Mesh = Std.instance(newMeshes[1], Mesh);
			
			rabbit.scaling = new Vector3(0.4, 0.4, 0.4);
			shadowGenerator.getShadowMap().renderList.push(rabbit);

			var rabbit2 = rabbit.clone("rabbit2");
			var rabbit3 = rabbit.clone("rabbit2");

			shadowGenerator.getShadowMap().renderList.push(rabbit2);
			shadowGenerator.getShadowMap().renderList.push(rabbit3);

			rabbit2.position = new Vector3(-50, 0, -20);
			rabbit2.skeleton = rabbit.skeleton.clone("clonedSkeleton","clonedSkeleton");

			rabbit3.position = new Vector3(50, 0, -20);
			rabbit3.skeleton = rabbit.skeleton.clone("clonedSkeleton2","clonedSkeleton2");

			scene.beginAnimation(skeletons[0], 0, 100, true, 0.8);
			scene.beginAnimation(rabbit2.skeleton, 73, 100, true, 0.8);
			scene.beginAnimation(rabbit3.skeleton, 0, 72, true, 0.8);
		});
		
		// Dude
		SceneLoader.LoadMesh("him", "Scenes/Dude/", "Dude.babylon", scene, 
		function (newMeshes2:Array<AbstractMesh>,particlesSystems2:Array<ParticleSystem>,skeletons2:Array<Skeleton>):Void 
		{
			var dude:Mesh = Std.instance(newMeshes2[0], Mesh);
			
			for (index in 0...newMeshes2.length)
			{
				shadowGenerator.getShadowMap().renderList.push(newMeshes2[index]);
			}

			dude.rotation.y = Math.PI;
			dude.position = new Vector3(0, 0, -80);
				
			scene.beginAnimation(skeletons2[0], 0, 100, true, 1.0);
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
    	Lib.current.addChild(new BoneDemo());
    }
}
