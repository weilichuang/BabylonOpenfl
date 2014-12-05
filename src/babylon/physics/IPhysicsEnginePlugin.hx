package babylon.physics;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;

interface IPhysicsEnginePlugin 
{
	function initialize(iterations: Int = 0):Void;
	function setGravity(gravity: Vector3): Void;
	function runOneStep(delta: Float): Void;
	function registerMesh(mesh: AbstractMesh, impostor: Int, options: PhysicsBodyCreationOptions): Dynamic;
	function registerMeshesAsCompound(parts: Array<PhysicsCompoundBodyPart>, options: PhysicsBodyCreationOptions): Dynamic;
	function unregisterMesh(mesh: AbstractMesh):Void;
	function applyImpulse(mesh: AbstractMesh, force: Vector3, contactPoint: Vector3): Void;
	function createLink(mesh1: AbstractMesh, mesh2: AbstractMesh, pivot1: Vector3, pivot2: Vector3, options:Dynamic = null): Bool;
	function dispose(): Void;
	function isSupported(): Bool;
}