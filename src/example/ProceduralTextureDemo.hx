package example;

import babylon.animations.Animation;
import babylon.cameras.ArcRotateCamera;
import babylon.lights.DirectionalLight;
import babylon.lights.PointLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.procedurals.BrickProceduralTexture;
import babylon.materials.textures.procedurals.CloudProceduralTexture;
import babylon.materials.textures.procedurals.GrassProceduralTexture;
import babylon.materials.textures.procedurals.MarbleProceduralTexture;
import babylon.materials.textures.procedurals.RoadProceduralTexture;
import babylon.materials.textures.procedurals.FireProceduralTexture;
import babylon.materials.textures.procedurals.WoodProceduralTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Space;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class ProceduralTextureDemo extends BaseDemo
{
    override function onInit():Void
    {
		function CreateBosquet(name, x, y, z, scene, shadowGenerator, woodMaterial, grassMaterial) {
			var bosquet = MeshHelper.CreateBox(name, 2, scene);
			bosquet.position = new Vector3(x, y, z);
			bosquet.material = grassMaterial;

			var bosquetbawl = MeshHelper.CreateBox(name + "bawl", 1, scene);
			bosquetbawl.position = new Vector3(x, y + 1, z);
			bosquetbawl.material = grassMaterial;

			shadowGenerator.getShadowMap().renderList.push(bosquet);
			shadowGenerator.getShadowMap().renderList.push(bosquetbawl);
		}

		function CreateTree(name, x, y, z, scene, shadowGenerator, woodMaterial, grassMaterial) {
			var trunk = MeshHelper.CreateCylinder(name + "trunk", 7, 2, 2, 12, 1, scene);
			trunk.position = new Vector3(x, y, z);
			trunk.material = woodMaterial;

			var leafs = MeshHelper.CreateSphere(name + "leafs", 20, 7, scene);
			leafs.position = new Vector3(x, y + 5.0, z);
			leafs.material = grassMaterial;

			shadowGenerator.getShadowMap().renderList.push(trunk);
			shadowGenerator.getShadowMap().renderList.push(leafs);
		}

		function createFontain(name, x, y, z, scene, shadowGenerator, marbleMaterial, fireMaterial) {
			var torus = MeshHelper.CreateTorus("torus", 5, 1, 20, scene);
			torus.position = new Vector3(x, y, z);
			torus.material = marbleMaterial;

			var fontainGround = MeshHelper.CreateBox("fontainGround", 4, scene);
			fontainGround.position = new Vector3(x, y - 2, z);
			fontainGround.material = marbleMaterial;

			var fontainSculptur1 = MeshHelper.CreateCylinder("fontainSculptur1", 2, 2, 1, 10, 1, scene);
			fontainSculptur1.position = new Vector3(x, y, z);
			fontainSculptur1.material = marbleMaterial;

			var fontainSculptur2 = MeshHelper.CreateSphere("fontainSculptur2", 7, 1.7, scene);
			fontainSculptur2.position = new Vector3(x, y + 0.9, z);
			fontainSculptur2.material = fireMaterial;
			fontainSculptur2.rotate(new Vector3(1.0, 0.0, 0.0), Math.PI / 2.0, Space.LOCAL);

			shadowGenerator.getShadowMap().renderList.push(torus);
			shadowGenerator.getShadowMap().renderList.push(fontainSculptur1);
			shadowGenerator.getShadowMap().renderList.push(fontainSculptur2);
		}

		function createTorch(name, x, y, z, scene, shadowGenerator, brickMaterial, woodMaterial, grassMaterial) {
			//createBrickBlock
			var brickblock = MeshHelper.CreateBox(name + "brickblock", 1, scene);
			brickblock.position = new Vector3(x, y, z);
			brickblock.material = brickMaterial;

			//createWood
			var torchwood = MeshHelper.CreateCylinder(name + "torchwood", 2, 0.25, 0.1, 12, 1, scene);
			torchwood.position = new Vector3(x, y + 1, z);
			torchwood.material = woodMaterial;

			//leafs
			var leafs2 = MeshHelper.CreateSphere(name + "leafs2", 10, 1.2, scene);
			leafs2.position = new Vector3(x, y + 2, z);
			leafs2.material = grassMaterial;

			shadowGenerator.getShadowMap().renderList.push(torchwood);
			shadowGenerator.getShadowMap().renderList.push(leafs2);
			shadowGenerator.getShadowMap().renderList.push(brickblock);
		}

		//Ok, enough helpers, let the building start 
		var camera = new ArcRotateCamera("Camera", 1, 1.2, 25, new Vector3(10, 0, 0), scene);
		camera.upperBetaLimit = 1.2;
		camera.attachControl(this.touchLayer);

		//Material declaration
		var woodMaterial = new StandardMaterial(name, scene);
		var woodTexture = new WoodProceduralTexture(name + "text", 1024, scene);
		woodTexture.ampScale = 50.0;
		woodMaterial.diffuseTexture = woodTexture;

		var grassMaterial = new StandardMaterial(name + "bawl", scene);
		var grassTexture = new GrassProceduralTexture(name + "textbawl", 256, scene);
		grassMaterial.ambientTexture = grassTexture;

		var marbleMaterial = new StandardMaterial("torus", scene);
		var marbleTexture = new MarbleProceduralTexture("marble", 512, scene);
		marbleTexture.numberOfTilesHeight = 5;
		marbleTexture.numberOfTilesWidth = 5;
		marbleMaterial.ambientTexture = marbleTexture;

		var fireMaterial = new StandardMaterial("fontainSculptur2", scene);
		var fireTexture = new FireProceduralTexture("fire", 256, scene);
		fireMaterial.diffuseTexture = fireTexture;
		fireMaterial.opacityTexture = fireTexture;

		var brickMaterial = new StandardMaterial(name, scene);
		var brickTexture = new BrickProceduralTexture(name + "text", 512, scene);
		brickTexture.numberOfBricksHeight = 2;
		brickTexture.numberOfBricksWidth = 3;
		brickMaterial.diffuseTexture = brickTexture;

		//light
		var light = new DirectionalLight("dir01", new Vector3(-0.5, -1, -0.5), scene);
		light.diffuse = new Color3(1, 1, 1);
		light.specular = new Color3(1, 1, 1);
		//light.groundColor = new Color3(0, 0, 0);
		light.position = new Vector3(20, 40, 20);

		//Create a square of grass using a custom procedural texture
		//var square = MeshHelper.CreateGround("square", 20, 20, 2, scene);
		//square.position = new Vector3(0, 0, 0);
		//var customMaterial = new StandardMaterial("custommat", scene);
		//var customProcText = new CustomProceduralTexture("customtext", "./textures/customProceduralTextures/land", 1024, scene);
		//customMaterial.ambientTexture = customProcText;
		//square.material = customMaterial;
		//square.receiveShadows = true;

		////Applying some shadows
		var shadowGenerator = new ShadowGenerator(1024, light);
		

		//Creating 4 bosquets
		CreateBosquet("b1", -9, 1, 9, scene, shadowGenerator, woodMaterial, grassMaterial);
		CreateBosquet("b2", -9, 1, -9, scene, shadowGenerator, woodMaterial, grassMaterial);
		CreateBosquet("b3", 9, 1, 9, scene, shadowGenerator, woodMaterial, grassMaterial);
		CreateBosquet("b4", 9, 1, -9, scene, shadowGenerator, woodMaterial, grassMaterial);
//
		CreateTree("a1", 0, 3.5, 0, scene, shadowGenerator, woodMaterial, grassMaterial);

		//Creating macadam
		var macadam = MeshHelper.CreateGround("square", 20, 20, 2, scene);
		macadam.position = new Vector3(20, 0, 0);
		var customMaterialmacadam = new StandardMaterial("macadam", scene);
		var customProcTextmacadam = new RoadProceduralTexture("customtext", 512, scene);
		customMaterialmacadam.diffuseTexture = customProcTextmacadam;
		macadam.material = customMaterialmacadam;
		macadam.receiveShadows = true;

		//Creating a fontain
		createFontain("fontain", 20, 0.25, 0, scene, shadowGenerator, marbleMaterial, fireMaterial);
		createTorch("torch1", 15, 0.5, 5, scene, shadowGenerator, brickMaterial, woodMaterial, grassMaterial);
		createTorch("torch2", 15, 0.5, -5, scene, shadowGenerator, brickMaterial, woodMaterial, grassMaterial);
		createTorch("torch3", 25, 0.5, 5, scene, shadowGenerator, brickMaterial, woodMaterial, grassMaterial);
		createTorch("torch4", 25, 0.5, -5, scene, shadowGenerator, brickMaterial, woodMaterial, grassMaterial);

		//Using a procedural texture to create the sky
		var boxCloud = MeshHelper.CreateSphere("boxCloud", 100, 1000, scene);
		boxCloud.position = new Vector3(0, 0, 12);
		var cloudMaterial = new StandardMaterial("cloudMat", scene);
		var cloudProcText = new CloudProceduralTexture("cloud", 1024, scene);
		cloudMaterial.emissiveTexture = cloudProcText;
		cloudMaterial.backFaceCulling = false;
		cloudMaterial.emissiveTexture.coordinatesMode = Texture.SKYBOX_MODE;
		boxCloud.material = cloudMaterial;

		scene.registerBeforeRender(function () {
			camera.alpha += 0.001 * scene.getAnimationRatio();
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
    	Lib.current.addChild(new ProceduralTextureDemo());
    }
}
