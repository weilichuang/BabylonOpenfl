package example;

import babylon.cameras.ArcRotateCamera;
import babylon.cameras.FreeCamera;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.MirrorTexture;
import babylon.math.Color3;
import babylon.math.Plane;
import babylon.math.Vector3;
import babylon.mesh.MeshHelper;
import openfl.Lib;

class DanceMoveDemo extends BaseDemo
{
    override function onInit():Void
    {
    	SceneLoader.Load(scene, "scenes/DanceMoves/", "DanceMoves.babylon", function() {
			
			var groundMaterial:StandardMaterial = new StandardMaterial("ground", scene);
            groundMaterial.reflectionTexture = new MirrorTexture("mirror", 1024, scene, true);
            cast(groundMaterial.reflectionTexture,MirrorTexture).mirrorPlane = new Plane(0, -1.0, 0, 0);
            cast(groundMaterial.reflectionTexture,MirrorTexture).renderList = [scene.meshes[0], scene.meshes[1]];
            cast(groundMaterial.reflectionTexture,MirrorTexture).level = 0.5;

            // Ground
            var ground = MeshHelper.CreateGround("ground", 1000, 1000, 1, scene, false);

            groundMaterial.diffuseColor = new Color3(1.0, 1.0, 1.0);
            groundMaterial.specularColor = new Color3(0, 0, 0);
 
            ground.material = groundMaterial;
            ground.receiveShadows = true;

            scene.beginAnimation(scene.skeletons[0], 2, 100, true, 0.05);
			
    		scene.activeCamera = scene.cameras[0];
    		if (scene.activeCamera != null) {
				scene.activeCamera.minZ = 10;
    			scene.activeCamera.attachControl(this);
    			var _c:FreeCamera = Std.instance(scene.activeCamera, FreeCamera);
    			_c.keysUp.push(87);
    			_c.keysDown.push(83);
    			_c.keysLeft.push(65);
    			_c.keysRight.push(68);
    		};
    		scene.executeWhenReady(function() {
    			engine.runRenderLoop(scene.render);
    		});
    	});
    }

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new DanceMoveDemo());
    }
}
