package babylon.mesh;
import babylon.math.Vector3;
import babylon.tools.Tools;
import flash.display.BitmapData;

class MeshHelper
{
	// Statics
	public static function CreateBox(name: String, size:Float, scene: Scene, updatable:Bool = false): Mesh
	{
		var box = new Mesh(name, scene);
		
		var vertexData = VertexData.CreateBox(size);

		vertexData.applyToMesh(box, updatable);

		return box;
	}

	public static function CreateSphere(name: String, segments:Int, diameter:Float, scene: Scene, updatable:Bool = false): Mesh
	{
		var sphere = new Mesh(name, scene);
		
		var vertexData = VertexData.CreateSphere(segments, diameter);

		vertexData.applyToMesh(sphere, updatable);

		return sphere;
	}

	// Cylinder and cone (Code inspired by SharpDX.org)
	public static function CreateCylinder(name: String, 
										height:Float, diameterTop:Float,
										diameterBottom:Float, 
										tessellation:Int,subdivisions:Int,
										scene: Scene, updatable:Bool = false): Mesh 
	{
		var cylinder = new Mesh(name, scene);
		var vertexData = VertexData.CreateCylinder(height, diameterTop, diameterBottom, tessellation, subdivisions);

		vertexData.applyToMesh(cylinder, updatable);

		return cylinder;
	}

	// Torus  (Code from SharpDX.org)
	public static function CreateTorus(name: String, 
										diameter:Float, 
										thickness:Float, 
										tessellation:Int, 
										scene: Scene, 
										updatable:Bool = false): Mesh
	{
		var torus = new Mesh(name, scene);
		var vertexData = VertexData.CreateTorus(diameter, thickness, tessellation);

		vertexData.applyToMesh(torus, updatable);

		return torus;
	}

	public static function CreateTorusKnot(name: String, 
											radius:Float, 
											tube:Float,
											radialSegments:Int, 
											tubularSegments:Int, 
											p:Float, 
											q:Float, 
											scene: Scene, 
											updatable:Bool = false): Mesh 
	{
		var torusKnot = new Mesh(name, scene);
		var vertexData = VertexData.CreateTorusKnot(radius, tube, radialSegments, tubularSegments, p, q);

		vertexData.applyToMesh(torusKnot, updatable);

		return torusKnot;
	}

	// Plane & ground
	public static function CreatePlane(name: String, size:Float, scene: Scene, updatable:Bool = false): Mesh 
	{
		var plane = new Mesh(name, scene);
		var vertexData = VertexData.CreatePlane(size);

		vertexData.applyToMesh(plane, updatable);

		return plane;
	}
	
	public static function CreateLines(name: String, points: Array<Vector3>, scene: Scene, updatable: Bool = false): LinesMesh 
	{
		var lines = new LinesMesh(name, scene, updatable);

		var vertexData = VertexData.CreateLines(points);

		vertexData.applyToMesh(lines, updatable);

		return lines;
	}

	public static function CreateGround(name: String, 
										width:Float, height:Float, 
										subdivisions:Int, 
										scene: Scene, 
										updatable:Bool = false): Mesh
	{
		var ground:GroundMesh = new GroundMesh(name, scene);
		ground._setReady(false);
		
		ground.subdivisions = subdivisions;

		var vertexData = VertexData.CreateGround(width, height, subdivisions);

		vertexData.applyToMesh(ground, updatable);

		ground._setReady(true);

		return ground;
	}
	
	public static function CreateTiledGround(name: String, xmin: Float, zmin: Float, xmax: Float, zmax: Float, 
											subdivisions: { w: Int, h: Int }, 
											precision: { w: Int, h: Int }, 
											scene: Scene, updatable: Bool = false): Mesh 
	{
		var tiledGround:Mesh = new Mesh(name, scene);

		var vertexData = VertexData.CreateTiledGround(xmin, zmin, xmax, zmax, subdivisions, precision);

		vertexData.applyToMesh(tiledGround, updatable);

		return tiledGround;
    }

	public static function CreateGroundFromHeightMap(name: String, 
													url: String, 
													width:Float, height:Float, 
													subdivisions:Int, 
													minHeight:Float, maxHeight:Float, 
													scene: Scene, updatable:Bool = false, onReady:Node-> Void = null): GroundMesh
	{
		var ground:GroundMesh = new GroundMesh(name, scene);
		ground.onReady = onReady;
		ground.subdivisions = subdivisions;

		ground._setReady(false);

		//由于cpp中瞬间完成了此操作，如果onReady放在外部定义的话，_setReady(true)时onReady还是为null,会导致执行不了
		Tools.LoadImage(url, function(img:BitmapData):Void {
			var vertexData = VertexData.CreateGroundFromHeightMap(width, height, subdivisions, minHeight, maxHeight, img);
			vertexData.applyToMesh(ground, updatable);
			ground._setReady(true);
		});

		return ground;
	}
	
	// Tools
	public static function MinMax(meshes: Array<AbstractMesh>): BabylonMinMax
	{
		var minVector:Vector3 = null;
		var maxVector:Vector3 = null;
		for (mesh in meshes) 
		{
			var boundingBox = mesh.getBoundingInfo().boundingBox;
			if (minVector == null) 
			{
				minVector = boundingBox.minimumWorld;
				maxVector = boundingBox.maximumWorld;
				continue;
			}
			
			minVector.minimizeInPlace(boundingBox.minimumWorld);
			maxVector.maximizeInPlace(boundingBox.maximumWorld);
		}

		return {
			minimum: minVector,
			maximum: maxVector
		};
	}

	public static function Center(meshesOrMinMaxVector:Dynamic): Vector3
	{
		var minMaxVector:BabylonMinMax = meshesOrMinMaxVector;
		
		if (Std.is(meshesOrMinMaxVector, AbstractMesh))
		{
			minMaxVector = MeshHelper.MinMax([Std.instance(meshesOrMinMaxVector, AbstractMesh)]);
		}
		return Vector3.Center(minMaxVector.minimum, minMaxVector.maximum);
	}

	public function new() 
	{
		
	}
	
}