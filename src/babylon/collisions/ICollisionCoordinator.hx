package babylon.collisions;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Geometry;

/**
 * @author 
 */

interface ICollisionCoordinator 
{
	function getNewPosition(position: Vector3, velocity: Vector3, collider: Collider, maximumRetry: Int, 
					excludedMesh: AbstractMesh, 
					onNewPosition: Int->Vector3->AbstractMesh->Void, 
					collisionIndex: Int): Void;
	function init(scene: Scene): Void;
	function destroy(): Void;

	//Update meshes and geometries
	function onMeshAdded(mesh: AbstractMesh):Void;
	function onMeshUpdated(mesh: AbstractMesh):Void;
	function onMeshRemoved(mesh: AbstractMesh):Void;
	function onGeometryAdded(geometry: Geometry):Void;
	function onGeometryUpdated(geometry: Geometry):Void;
	function onGeometryDeleted(geometry: Geometry):Void;
}