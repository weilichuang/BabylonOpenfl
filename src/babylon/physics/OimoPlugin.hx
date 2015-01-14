package babylon.physics;
import babylon.culling.BoundingBox;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Quaternion;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.physics.PhysicsBodyCreationOptions;
import babylon.physics.PhysicsCompoundBodyPart;
import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.dynamics.RigidBody;
import com.element.oimo.physics.dynamics.World;
import com.element.oimo.physics.OimoBody;
import com.element.oimo.physics.OimoLink;
import com.element.oimo.physics.OimoPhysics;

typedef OimoMesh = {
	var mesh:AbstractMesh;
	var body:OimoBody;
	@:optional var delta:Vector3;
}

/**
 * ...
 * 
 */
class OimoPlugin implements IPhysicsEnginePlugin
{
	private var _world:World;
	private var _registeredMeshes:Array<OimoMesh> = [];
	private var _tmpMatrix:Matrix = new Matrix();
	
	public function new() 
	{
		initialize();
	}
	
	private inline function _checkWithEpsilon(value: Float): Float 
	{
		return value < PhysicsEngine.Epsilon ? PhysicsEngine.Epsilon : value;
	}

	public function initialize(iterations:Int = 0):Void 
	{
		_world = new World();
		_world.clear();
	}
	
	public function setGravity(gravity:Vector3):Void 
	{
		_world.gravity.setTo(gravity.x, gravity.y, gravity.z);
	}
	
	public function runOneStep(delta:Float):Void 
	{
		_world.step();

		// Update the position of all registered meshes
		var i:Int = _registeredMeshes.length;
		while (i-- > 0) 
		{
			var oimoMesh:OimoMesh = _registeredMeshes[i];
			
			var body:RigidBody = oimoMesh.body.body;
			if (body.shapes == null)
				continue;
				
			var mesh:AbstractMesh = oimoMesh.mesh;

			if (!body.sleeping)
			{
				_tmpMatrix.fromArray(body.getMatrix());
				
				if (body.shapes.next != null) 
				{
					var parentShape:Shape = _getLastShape(body);
					mesh.position.x = parentShape.position.x * OimoPhysics.WORLD_SCALE;
					mesh.position.y = parentShape.position.y * OimoPhysics.WORLD_SCALE;
					mesh.position.z = parentShape.position.z * OimoPhysics.WORLD_SCALE;
				} 
				else
				{
					// Body position
					var bodyX:Float = _tmpMatrix.m[12];
					var bodyY:Float = _tmpMatrix.m[13];
					var bodyZ:Float = _tmpMatrix.m[14];

					if (oimoMesh.delta == null)
					{
						mesh.position.setTo(bodyX, bodyY, bodyZ);
					}
					else 
					{
						mesh.position.x = bodyX + oimoMesh.delta.x;
						mesh.position.y = bodyY + oimoMesh.delta.y;
						mesh.position.z = bodyZ + oimoMesh.delta.z;
					}
				}
				
				if (mesh.rotationQuaternion == null)
				{
					mesh.rotationQuaternion = new Quaternion(0, 0, 0, 1);
				}
				mesh.rotationQuaternion.fromRotationMatrix(_tmpMatrix);
				mesh.computeWorldMatrix();
			}
		}
	}
	
	public function registerMesh(mesh:AbstractMesh, impostor:Int, options:PhysicsBodyCreationOptions):Dynamic 
	{
		unregisterMesh(mesh);
		mesh.computeWorldMatrix(true);

		var body:OimoBody = null;
		var bbox:BoundingBox = null;
		// register mesh
		switch (impostor)
		{
			case PhysicsEngine.SphereImpostor:
				bbox = mesh.getBoundingInfo().boundingBox;
				var radiusX:Float = bbox.maximumWorld.x - bbox.minimumWorld.x;
				var radiusY:Float = bbox.maximumWorld.y - bbox.minimumWorld.y;
				var radiusZ:Float = bbox.maximumWorld.z - bbox.minimumWorld.z;

				var size = Math.max(_checkWithEpsilon(radiusX), Math.max(_checkWithEpsilon(radiusY), _checkWithEpsilon(radiusZ))) / 2;

				// The delta between the mesh position and the mesh bounding box center
				var deltaPosition:Vector3 = mesh.position.subtract(bbox.center);

				body = new OimoBody( {
					name:mesh.name,
					type: ['sphere'],
					size: [size,size,size],
					pos: [bbox.center.x, bbox.center.y, bbox.center.z],
					rot: [mesh.rotation.x * FastMath.DEGS_PER_RAD, 
						mesh.rotation.y * FastMath.DEGS_PER_RAD,
						mesh.rotation.z * FastMath.DEGS_PER_RAD],
					move: options.mass != 0,
					config: options,
					world: _world
				});
				_registeredMeshes.push( { mesh:mesh, body:body, delta:  deltaPosition } );

			case PhysicsEngine.PlaneImpostor,PhysicsEngine.BoxImpostor:
				bbox = mesh.getBoundingInfo().boundingBox;
				var min:Vector3 = bbox.minimumWorld;
				var max:Vector3 = bbox.maximumWorld;
				var box:Vector3 = max.subtract(min);
				var sizeX:Float = _checkWithEpsilon(box.x);
				var sizeY:Float = _checkWithEpsilon(box.y);
				var sizeZ:Float = _checkWithEpsilon(box.z);

				// The delta between the mesh position and the mesh boudning box center
				var deltaPosition:Vector3 = mesh.position.subtract(bbox.center);

				body = new OimoBody( {
					name:mesh.name,
					type: ['box'],
					size: [sizeX, sizeY, sizeZ],
					pos: [bbox.center.x, bbox.center.y, bbox.center.z],
					rot: [mesh.rotation.x * FastMath.DEGS_PER_RAD, 
						mesh.rotation.y  * FastMath.DEGS_PER_RAD, 
						mesh.rotation.z  * FastMath.DEGS_PER_RAD],
					move: options.mass != 0,
					config: options,
					world: _world
				});

				_registeredMeshes.push( { mesh:mesh, body:body, delta:  deltaPosition } );
		}
		return body;
	}
	
	public function registerMeshesAsCompound(parts:Array<PhysicsCompoundBodyPart>, options:PhysicsBodyCreationOptions):Dynamic 
	{
		var types = [];
		var sizes = [];
		var positions = [];
		var rotations = [];

		var initialMesh:Mesh = parts[0].mesh;

		for (index in 0...parts.length)
		{
			var part:PhysicsCompoundBodyPart = parts[index];
			var bodyParameters:Dynamic = _createBodyAsCompound(part, options, initialMesh);
			types = types.concat(bodyParameters.type);
			sizes = sizes.concat(bodyParameters.size);
			positions = positions.concat(bodyParameters.pos);
			rotations = rotations.concat(bodyParameters.rot);
		}

		var body = new OimoBody({
			type: types,
			size: sizes,
			pos: positions,
			rot: rotations,
			move: options.mass != 0,
			config: options,
			world: _world
		});

		_registeredMeshes.push({
			mesh: initialMesh,
			body: body
		});

		return body;
	}
	
	private function _createBodyAsCompound(part: PhysicsCompoundBodyPart, options: PhysicsBodyCreationOptions, initialMesh: AbstractMesh): Dynamic
	{
		var bodyParameters = null;
		var mesh:Mesh = part.mesh;
		var bbox:BoundingBox;
		switch (part.impostor)
		{
			case PhysicsEngine.SphereImpostor:
				bbox = mesh.getBoundingInfo().boundingBox;
				var radiusX = bbox.maximumWorld.x - bbox.minimumWorld.x;
				var radiusY = bbox.maximumWorld.y - bbox.minimumWorld.y;
				var radiusZ = bbox.maximumWorld.z - bbox.minimumWorld.z;

				var size = Math.max(_checkWithEpsilon(radiusX),Math.max(_checkWithEpsilon(radiusY),_checkWithEpsilon(radiusZ)))/2;
				bodyParameters = {
					type: ['sphere'],
					/* bug with oimo : sphere needs 3 sizes in this case */
					size: [size, size, size],
					pos: [mesh.position.x, mesh.position.y, mesh.position.z],
					rot: [mesh.rotation.x * FastMath.DEGS_PER_RAD, 
						mesh.rotation.y * FastMath.DEGS_PER_RAD, 
						mesh.rotation.z * FastMath.DEGS_PER_RAD]
				};

			case PhysicsEngine.PlaneImpostor,PhysicsEngine.BoxImpostor:
				bbox = mesh.getBoundingInfo().boundingBox;
				var min:Vector3 = bbox.minimumWorld;
				var max:Vector3 = bbox.maximumWorld;
				var box:Vector3 = max.subtract(min);
				var sizeX:Float = _checkWithEpsilon(box.x);
				var sizeY:Float = _checkWithEpsilon(box.y);
				var sizeZ:Float = _checkWithEpsilon(box.z);
				var relativePosition:Vector3 = mesh.position;
				bodyParameters = {
					type: ['box'],
					size: [sizeX, sizeY, sizeZ],
					pos: [relativePosition.x, relativePosition.y, relativePosition.z],
					rot: [mesh.rotation.x * FastMath.DEGS_PER_RAD, 
						mesh.rotation.y * FastMath.DEGS_PER_RAD, 
						mesh.rotation.z * FastMath.DEGS_PER_RAD]
				};
		}

		return bodyParameters;
	}
	
	public function unregisterMesh(mesh:AbstractMesh):Void 
	{
		for (index in 0..._registeredMeshes.length)
		{
			var registeredMesh:OimoMesh = _registeredMeshes[index];
			if (registeredMesh.mesh == mesh || registeredMesh.mesh == mesh.parent)
			{
				if (registeredMesh.body != null)
				{
					_world.removeRigidBody(registeredMesh.body.body);
					_unbindBody(registeredMesh.body);
				}
				_registeredMeshes.splice(index, 1);
				return;
			}
		}
	}
	
	private function _unbindBody(body: Dynamic): Void 
	{
		for (index in 0..._registeredMeshes.length)
		{
			var registeredMesh:OimoMesh = _registeredMeshes[index];
			if (registeredMesh.body == body) 
			{
				registeredMesh.body = null;
			}
		}
	}
		
	/**
	 * Update the body position according to the mesh position
	 * @param mesh
	 */
	public function updateBodyPosition(mesh: AbstractMesh): Void
	{
		var body:RigidBody;
		for (index in 0..._registeredMeshes.length)
		{
			var registeredMesh:OimoMesh = _registeredMeshes[index];
			if (registeredMesh.mesh == mesh || registeredMesh.mesh == mesh.parent) 
			{
				body = registeredMesh.body.body;

				var center:Vector3 = mesh.getBoundingInfo().boundingBox.center;
				body.setPosition(center.x, center.y, center.z);
				body.setOrientation(mesh.rotation.x, mesh.rotation.y, mesh.rotation.z);
				return;
			}
			// Case where the parent has been updated
			if (registeredMesh.mesh.parent == mesh)
			{
				mesh.computeWorldMatrix(true);
				registeredMesh.mesh.computeWorldMatrix(true);

				var absolutePosition = registeredMesh.mesh.getAbsolutePosition();
				var absoluteRotation = mesh.rotation;

				body = registeredMesh.body.body;
				body.setPosition(absolutePosition.x, absolutePosition.y, absolutePosition.z);
				body.setOrientation(absoluteRotation.x, absoluteRotation.y, absoluteRotation.z);
				return;
			}
		}
	}
		
	public function applyImpulse(mesh:AbstractMesh, force:Vector3, contactPoint:Vector3):Void 
	{
		for (index in 0..._registeredMeshes.length)
		{
			var registeredMesh:OimoMesh = _registeredMeshes[index];
			if (registeredMesh.mesh == mesh || registeredMesh.mesh == mesh.parent)
			{
				// Get object mass to have a behaviour similar to cannon.js
				var mass:Float = registeredMesh.body.body.massInfo.mass;
				
				// The force is scaled with the mass of object
				var newForce:Vec3 = new Vec3(force.x, force.y, force.z);
				newForce.scale(newForce, OimoPhysics.INV_SCALE * mass);
				var newContacePoint:Vec3 = new Vec3(contactPoint.x, contactPoint.y, contactPoint.z);
				newContacePoint.scale(newContacePoint, OimoPhysics.INV_SCALE);

				registeredMesh.body.body.applyImpulse(newContacePoint, newForce);
				return;
			}
		}
	}
	
	public function createLink(mesh1:AbstractMesh, mesh2:AbstractMesh, pivot1:Vector3, pivot2:Vector3, options:Dynamic = null):Bool 
	{
		var body1 = null;
		var body2 = null;
		
		for (index in 0..._registeredMeshes.length)
		{
			var registeredMesh:OimoMesh = _registeredMeshes[index];
			if (registeredMesh.mesh == mesh1)
			{
				body1 = registeredMesh.body.body;
			} 
			else if (registeredMesh.mesh == mesh2)
			{
				body2 = registeredMesh.body.body;
			}
		}
		if (body1 == null || body2 == null) 
		{
			return false;
		}
		
		if (options == null)
		{
			options = { collision:true, spring:false };
		}

		new OimoLink({
			type: options.type,
			body1: body1,
			body2: body2,
			min: options.min,
			max: options.max,
			axe1: options.axe1,
			axe2: options.axe2,
			pos1: [pivot1.x, pivot1.y, pivot1.z],
			pos2: [pivot2.x, pivot2.y, pivot2.z],
			collision: options.collision,
			spring: options.spring,
			world: _world
		});

		return true;
	}
	
	public function dispose():Void 
	{
		_world.clear();
		while (_registeredMeshes.length > 0)
		{
			unregisterMesh(_registeredMeshes[0].mesh);
		}
	}
	
	public function isSupported():Bool 
	{
		return true;
	}
	
	private function _getLastShape(body: RigidBody): Shape
	{
		var lastShape:Shape = body.shapes;
		while (lastShape.next != null)
		{
			lastShape = lastShape.next;
		}
		return lastShape;
	}
}