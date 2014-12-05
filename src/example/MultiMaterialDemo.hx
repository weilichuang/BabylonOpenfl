package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.MultiMaterial;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.mesh.SubMesh;
import openfl.Lib;

class MultiMaterialDemo extends BaseDemo
{
    override function onInit():Void
    {
    	var camera = new ArcRotateCamera("Camera", 0, 0, 10, Vector3.Zero(), scene);
    	camera.attachControl(this.stage);
		
    	var light = new PointLight("Omni", new Vector3(20, 100, 2), scene);
		
    	var material0 = new StandardMaterial("mat0", scene);
    	material0.diffuseColor = new Color3(1, 0, 0);
    	material0.bumpTexture = new Texture("img/normalMap.jpg", scene);
		
    	var material1 = new StandardMaterial("mat1", scene);
    	material1.diffuseColor = new Color3(0, 0, 1);
		
    	var material2 = new StandardMaterial("mat2", scene);
    	material2.emissiveColor = new Color3(0.4, 0, 0.4);
		
    	var multimat = new MultiMaterial("multi", scene);
    	multimat.subMaterials.push(material0);
    	multimat.subMaterials.push(material1);
    	multimat.subMaterials.push(material2);
		
    	var sphere = MeshHelper.CreateSphere("Sphere0", 16, 3, scene);
    	sphere.material = multimat;
    	sphere.subMeshes = [];
		
    	var verticesCount = sphere.getTotalVertices();
    	sphere.subMeshes.push(new SubMesh(0, 0, verticesCount, 0, 900, sphere));
    	sphere.subMeshes.push(new SubMesh(1, 0, verticesCount, 900, 900, sphere));
    	sphere.subMeshes.push(new SubMesh(2, 0, verticesCount, 1800, 2088, sphere));
		
    	camera.setPosition(new Vector3(-3, 3, 0));
    	scene.registerBeforeRender(function() {
    		sphere.rotation.y += 0.01;
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
    	Lib.current.addChild(new MultiMaterialDemo());
    }
}
