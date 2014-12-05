package babylon.mesh;

import babylon.collisions.PickingInfo;
import babylon.math.Matrix;
import babylon.math.Ray;
import babylon.math.Vector3;
import babylon.Scene;

class GroundMesh extends Mesh
{
	public var generateOctree:Bool = false;

	private var _worldInverse:Matrix;
	
	public var subdivisions: Int;

	public function new(name:String, scene:Scene) 
	{
		super(name, scene);
		
		_worldInverse  = new Matrix();
	}

	public function optimize(chunksCount: Int): Void
	{
		this.subdivisions = chunksCount;
		this.subdivide(this.subdivisions);
		this.createOrUpdateSubmeshesOctree(32);
	}

	public function getHeightAtCoordinates(x: Float, z: Float): Float
	{
		var ray:Ray = new Ray(new Vector3(x, this.getBoundingInfo().boundingBox.maximumWorld.y + 1, z), new Vector3(0, -1, 0));

		this.getWorldMatrix().invertToRef(this._worldInverse);

		ray = Ray.Transform(ray, this._worldInverse);

		var pickInfo:PickingInfo = this.intersects(ray);
		if (pickInfo.hit) 
		{
			return pickInfo.pickedPoint.y;
		}

		return 0;
	}
}