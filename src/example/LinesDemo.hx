package example;
import babylon.math.Color4;
import babylon.mesh.LinesMesh;
import babylon.mesh.MeshHelper;
import babylon.mesh.VertexBuffer;
import babylon.cameras.ArcRotateCamera;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.mesh.Mesh;
import openfl.Lib;

class LinesDemo extends BaseDemo
{
	override function onInit():Void
    {
    	var camera:ArcRotateCamera = new ArcRotateCamera("Camera", 0, 0, 10, new Vector3(0, 0, 0), scene);
		camera.setPosition(new Vector3(20, 200, 400));
		camera.attachControl(this.stage);

		camera.maxZ = 20000;

		camera.lowerRadiusLimit = 150;

		scene.clearColor = new Color3(0, 0, 0);

		// Create a whirlpool
		var points = [];

		var radius = 0.5;
		var angle:Float = 0;
		for (index in 0...1000) 
		{
			points.push(new Vector3(radius * Math.cos(angle), 0, radius * Math.sin(angle)));
			radius += 0.3;
			angle += 0.1;
		}

		var whirlpool:LinesMesh = MeshHelper.CreateLines("whirlpool", points, scene, true);
		whirlpool.color = new Color4(1, 1, 1, 1);

		var positionData:Array<Float> = whirlpool.getVerticesData(VertexBuffer.PositionKind);
		var heightRange:Float = 10;
		var alpha:Float = 0;
		scene.registerBeforeRender(function():Void
		{
			for (index in 0...1000) 
			{
				positionData[index * 3 + 1] = heightRange * Math.sin(alpha + index * 0.1);
			}

			whirlpool.updateVerticesData(VertexBuffer.PositionKind, positionData);

			alpha += 0.05;
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
    	Lib.current.addChild(new LinesDemo());
    }
}