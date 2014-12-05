package babylon.physics;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;

class PhysicsEngine
{
	// Statics
	public static inline var NoImpostor:Int = 0;
	public static inline var SphereImpostor:Int = 1;
	public static inline var BoxImpostor:Int = 2;
	public static inline var PlaneImpostor:Int = 3;
	public static inline var CompoundImpostor:Int = 4;
	public static inline var MeshImpostor:Int = 4;
	public static inline var CapsuleImpostor:Int = 5;
	public static inline var ConeImpostor:Int = 6;
	public static inline var CylinderImpostor:Int = 7;
	public static inline var ConvexHullImpostor:Int = 8;
	
	public static var Epsilon:Float = 0.001;

	public var gravity: Vector3;

	private var _currentPlugin: IPhysicsEnginePlugin;

	public function new(plugin: IPhysicsEnginePlugin = null)
	{
		this._currentPlugin = plugin != null ? plugin : new OimoPlugin();
	}

	public function initialize(gravity: Vector3 = null):Void
	{
		this._currentPlugin.initialize();
		this.setGravity(gravity);
	}

	public function runOneStep(delta: Float): Void
	{
		if (delta > 0.1)
		{
			delta = 0.1;
		} 
		else if (delta <= 0)
		{
			delta = 1.0 / 60.0;
		}

		this._currentPlugin.runOneStep(delta);
	}

	public function setGravity(gravity: Vector3 = null): Void
	{
		if (gravity == null)
			gravity = new Vector3(0, -9.82, 0);
		this.gravity = gravity;
		this._currentPlugin.setGravity(this.gravity);
	}

	public function registerMesh(mesh: AbstractMesh, impostor: Int, options: PhysicsBodyCreationOptions): Dynamic
	{
		return this._currentPlugin.registerMesh(mesh, impostor, options);
	}

	public function registerMeshesAsCompound(parts: Array<PhysicsCompoundBodyPart>, options: PhysicsBodyCreationOptions): Dynamic
	{
		return this._currentPlugin.registerMeshesAsCompound(parts, options);
	}

	public function unregisterMesh(mesh: AbstractMesh): Void
	{
		this._currentPlugin.unregisterMesh(mesh);
	}

	public function applyImpulse(mesh: AbstractMesh, force: Vector3, contactPoint: Vector3): Void
	{
		this._currentPlugin.applyImpulse(mesh, force, contactPoint);
	}

	public function createLink(mesh1: AbstractMesh, mesh2: AbstractMesh, pivot1: Vector3, pivot2: Vector3): Bool
	{
		return this._currentPlugin.createLink(mesh1, mesh2, pivot1, pivot2);
	}

	public function dispose(): Void
	{
		this._currentPlugin.dispose();
	}

	public function isSupported(): Bool 
	{
		return this._currentPlugin.isSupported();
	}
	
}