package babylon.collisions;
import babylon.mesh.Geometry;
import babylon.Scene;
import babylon.mesh.AbstractMesh;
import babylon.collisions.Collider;
import babylon.math.Vector3;

/**
 * ...
 * @author 
 */
class CollisionCoordinatorWorker implements ICollisionCoordinator
{

	public function new() 
	{
		
	}
	
	/* INTERFACE babylon.collisions.ICollisionCoordinator */
	
	public function getNewPosition(position:Vector3, velocity:Vector3, collider:Collider, maximumRetry:Int, excludedMesh:AbstractMesh, onNewPosition:Int->Vector3->AbstractMesh->Void, collisionIndex:Int):Void 
	{
		
	}
	
	public function init(scene:Scene):Void 
	{
		
	}
	
	public function destroy():Void 
	{
		
	}
	
	public function onMeshAdded(mesh:AbstractMesh):Void 
	{
		
	}
	
	public function onMeshUpdated(mesh:AbstractMesh):Void 
	{
		
	}
	
	public function onMeshRemoved(mesh:AbstractMesh):Void 
	{
		
	}
	
	public function onGeometryAdded(geometry:Geometry):Void 
	{
		
	}
	
	public function onGeometryUpdated(geometry:Geometry):Void 
	{
		
	}
	
	public function onGeometryDeleted(geometry:Geometry):Void 
	{
		
	}
	
}