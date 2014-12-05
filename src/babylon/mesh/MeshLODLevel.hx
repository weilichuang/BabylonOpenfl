package babylon.mesh;

/**
 * ...
 * @author weilichuang
 */
class MeshLODLevel
{
	public var distance:Float;
	public var mesh:Mesh;

	public function new(distance:Float,mesh:Mesh) 
	{
		this.distance = distance;
		this.mesh = mesh;
	}
	
}