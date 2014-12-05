package example;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.sprites.Sprite;
import babylon.sprites.SpriteManager;
import openfl.Lib;

class SpriteDemo extends BaseDemo
{
	override function onInit():Void
    {
		// Create camera and light
		var light = new PointLight("Point", new Vector3(5, 10, 5), scene);
		var camera = new ArcRotateCamera("Camera", 1, 0.8, 8, new Vector3(0, 0, 0), scene);
		camera.attachControl(this.stage);
		
		// Create a sprite manager to optimize GPU ressources
		// Parameters : name, imgUrl, capacity, cellSize, scene
		var spriteManagerTrees = new SpriteManager("treesManager", "textures/palm.png", 2000, 800, scene);

		//We create 2000 trees at random positions
		var tree:Sprite;
		for (i in 0...2000)
		{
			tree = new Sprite("tree", spriteManagerTrees);
			tree.position.x = Math.random() * 100 - 50;
			tree.position.z = Math.random() * 100 - 50;

			//Some "dead" trees
			if (Math.round(Math.random() * 5) == 0)
			{
				tree.angle = Math.PI * 90 / 180;
				tree.position.y = -0.3;
			}
		}

		//Create a manager for the player's sprite animation
		var spriteManagerPlayer = new SpriteManager("playerManager", "textures/player.png", 2, 64, scene);

		// First animated player
		var player = new Sprite("player", spriteManagerPlayer);
		player.playAnimation(0, 40, true, 100);
		player.position.y = -0.3;
		player.size = 0.3;

		// Second standing player
		var player2 = new Sprite("player2", spriteManagerPlayer);
		player2.stopAnimation(); // Not animated
		player2.cellIndex = 2; // Going to frame number 2
		player2.position.y = -0.3;
		player2.position.x = 1;
		player2.size = 0.3;
		player2.invertU = false; //Change orientation
		
		var skybox = MeshHelper.CreateBox("skyBox", 100.0, scene);
    	var skyboxMaterial = new StandardMaterial("skyBox", scene);
    	skyboxMaterial.backFaceCulling = false;
    	skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
    	skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
    	skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
    	skyboxMaterial.specularColor = new Color3(0, 0, 0);
    	skybox.material = skyboxMaterial;
	
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
    	Lib.current.addChild(new SpriteDemo());
    }
}