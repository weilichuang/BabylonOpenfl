package babylon.mesh;

import babylon.actions.ActionManager;
import babylon.bones.Skeleton;
import babylon.cameras.Camera;
import babylon.collisions.Collider;
import babylon.collisions.IntersectionInfo;
import babylon.collisions.PickingInfo;
import babylon.culling.BoundingBox;
import babylon.culling.BoundingInfo;
import babylon.culling.BoundingSphere;
import babylon.culling.octrees.Octree;
import babylon.IDispose;
import babylon.materials.Material;
import babylon.math.Color3;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.math.Quaternion;
import babylon.math.Ray;
import babylon.math.Space;
import babylon.math.Vector3;
import babylon.Node;
import babylon.physics.PhysicsBodyCreationOptions;
import babylon.physics.PhysicsEngine;
import babylon.Scene;

class AbstractMesh extends Node implements IDispose
{
	public static inline var BILLBOARDMODE_NONE:Int = 0;
	public static inline var BILLBOARDMODE_X:Int = 1;
	public static inline var BILLBOARDMODE_Y:Int = 2;
	public static inline var BILLBOARDMODE_Z:Int = 4;
	public static inline var BILLBOARDMODE_ALL:Int = 7;
	
	public var isPickable(get, set):Bool;
	public var checkCollisions(get, set):Bool;
	public var receiveShadows(get, set):Bool;
	public var skeleton(get, set):Skeleton;
	public var material(get, set):Material;
	public var visibility(get, set):Float;
	public var worldMatrixFromCache(get, never):Matrix;
	public var absolutePosition(get, never):Vector3;
	public var positions(get, never):Array<Vector3>;
	public var isBlocked(get, never):Bool;
	
	public var alwaysSelectAsActiveMesh:Bool = false;
	
	public var rotation:Vector3 = new Vector3(0, 0, 0);
	public var rotationQuaternion:Quaternion = null;
	public var scaling:Vector3 = new Vector3(1, 1, 1);
	public var billboardMode:Int = BILLBOARDMODE_NONE;
	
	public var infiniteDistance:Bool = false;
	public var isVisible:Bool = true;
	public var applyFog:Bool = true;
	
	public var alphaIndex:Int = FastMath.INT32_MAX;
	
	public var subMeshes: Array<SubMesh>;
	
	public var hasVertexAlpha:Bool = false;
	public var useVertexColors:Bool = true;
	
	public var isBlocker:Bool = false;
	
	public var showBoundingBox:Bool = false;
	public var showSubMeshesBoundingBox:Bool = false;
	public var onDispose:Void->Void = null;
	
	public var renderingGroupId:Int = 0;
	
	public var actionManager:ActionManager;
	
	public var renderOutline:Bool = false;
	public var outlineColor:Color3 = Color3.Red();
	public var outlineWidth:Float = 0.02;
	
	public var renderOverlay:Bool = false;
	public var overlayColor:Color3 = Color3.Red();
	public var overlayAlpha:Float = 0.5;
	
	public var useOctreeForRenderingSelection:Bool = true;
	public var useOctreeForPicking:Bool = true;
	public var useOctreeForCollisions:Bool = true;
	
	public var layerMask: Int = 0xFFFFFFFF;
	
	// Collisions
	public var ellipsoid:Vector3 = new Vector3(0.5, 1, 0.5);
	public var ellipsoidOffset:Vector3 = new Vector3(0, 0, 0);
	
	public var definedFacingForward:Bool = true; // orientation for POV movement & rotation
	
	// Physics
	@:dox(hide)
	public var _physicImpostor:Int = 0;
	@:dox(hide)
	public var _physicsMass: Float = 0;
	@:dox(hide)
	public var _physicsFriction: Float = 0;
	@:dox(hide)
	public var _physicRestitution: Float = 0;
	
	@:dox(hide)
	public var _masterMesh: AbstractMesh;
	@:dox(hide)
	public var _boundingInfo: BoundingInfo;
	
	@:dox(hide)
	public var _submeshesOctree: Octree<SubMesh>;
	
	@:dox(hide)
	public var _renderId:Int = 0;
	
	@:dox(hide)
	public var _intersectionsInProgress:Array<AbstractMesh>;
	
	private var _collider:Collider;
	private var _oldPositionForCollisions:Vector3 = new Vector3(0, 0, 0);
	private var _diffPositionForCollisions:Vector3 = new Vector3(0, 0, 0);
	private var _newPositionForCollisions:Vector3 = new Vector3(0, 0, 0);
	
	private var _collisionsTransformMatrix:Matrix = new Matrix();
	private var _collisionsScalingMatrix:Matrix = new Matrix();
	
	// Cache
	//TODO 没有必要这么多的矩阵，优化
	private var _localScaling:Matrix;
	private var _localRotation:Matrix;
	private var _localTranslation:Matrix;
	private var _localBillboard:Matrix;
	private var _localPivotScaling:Matrix;
	private var _localPivotScalingRotation:Matrix;
	private var _localWorld:Matrix;
	private var _rotateYByPI:Matrix;
	
	private var _absolutePosition:Vector3;
	private var _pivotMatrix:Matrix;
	
	private var _isDirty:Bool = false;
	
	private var _isPickable:Bool = true;
	private var _needCheckCollisions:Bool = false;
	private var _receiveShadows:Bool = false;
	private var _skeleton:Skeleton;
	private var _visibility:Float = 1.0;
	private var _material:Material;
	private var _positions: Array<Vector3> = null;
	
	private var _isDisposed:Bool = false;
	
	private var _onAfterWorldMatrixUpdate:Array<AbstractMesh->Void> = new Array<AbstractMesh->Void>();
	
	@:dox(hide)
	public var _waitingActions: Dynamic;

	public function new(name:String, scene:Scene) 
	{
		super(name, scene);
		
		scene.addMesh(this);
		
		this.billboardMode = AbstractMesh.BILLBOARDMODE_NONE;
		
		_physicImpostor = PhysicsEngine.NoImpostor;
		
		_localScaling = new Matrix();
		_localRotation = new Matrix();
		_localTranslation = new Matrix();
		_localBillboard = new Matrix();
		_localPivotScaling = new Matrix();
		_localPivotScalingRotation = new Matrix();
		_localWorld = new Matrix();
		_worldMatrix = new Matrix();
		
		_absolutePosition = new Vector3();
		_pivotMatrix = new Matrix();
		
		subMeshes = [];
		_intersectionsInProgress = new Array<AbstractMesh>();
		
		_collider = new Collider();
	}
	
	public function isSkeletonsEnabled():Bool
	{
		return skeleton != null &&
				isVerticesDataPresent(VertexBuffer.MatricesIndicesKind) && 
				isVerticesDataPresent(VertexBuffer.MatricesWeightsKind);
	}
	
	public function getLOD(camera:Camera, boundingSphere:BoundingSphere = null):AbstractMesh
	{
		return this;
	}
	
	public function isDisposed():Bool
	{
		return this._isDisposed;
	}

    public function getTotalVertices(): Int
	{
		return 0;
	}

	public function getIndices(): Array<Int>
	{
		return null;
	}

	public function getVerticesData(kind: String): Array<Float>
	{
		return null;
	}

	public function isVerticesDataPresent(kind: String): Bool
	{
		return false;
	}

	public function getBoundingInfo(): BoundingInfo
	{
		if (this._masterMesh != null)
		{
			return this._masterMesh.getBoundingInfo();
		}
			
		if (this._boundingInfo == null)
		{
			this._updateBoundingInfo();
		}
		return this._boundingInfo;
	}

	public function preActivate(): Void
	{
	}

	public function activate(renderId: Int): Void 
	{
		this._renderId = renderId;
	}

	override public function getWorldMatrix(): Matrix
	{
		if (this._masterMesh != null)
		{
			return this._masterMesh.getWorldMatrix();
		}
			
		if (this._currentRenderId != this.getScene().getRenderId())
		{
			this.computeWorldMatrix();
		}
		return this._worldMatrix;
	}

	public function rotate(axis: Vector3, amount: Float, space: Space): Void
	{
		if (this.rotationQuaternion == null)
		{
			this.rotationQuaternion = Quaternion.RotationYawPitchRoll(this.rotation.y, this.rotation.x, this.rotation.z);
			this.rotation.setTo(0, 0, 0);
		}

		if (space == null || space == Space.LOCAL) 
		{
			var q = Quaternion.RotationAxis(axis, amount);
			this.rotationQuaternion = this.rotationQuaternion.multiply(q);
		}
		else 
		{
			if (this.parent != null) 
			{
				var invertParentWorldMatrix = this.parent.getWorldMatrix().clone();
				invertParentWorldMatrix.invert();

				axis = Vector3.TransformNormal(axis, invertParentWorldMatrix);
			}
			var q:Quaternion = Quaternion.RotationAxis(axis, amount);
			this.rotationQuaternion = q.multiply(this.rotationQuaternion);
		}
	}

	public function translate(axis: Vector3, distance: Float, space: Space): Void 
	{
		var displacementVector = axis.scale(distance);

		if (space == null || space == Space.LOCAL)
		{
			var tempV3 = this.getPositionExpressedInLocalSpace().add(displacementVector);
			this.setPositionWithLocalVector(tempV3);
		}
		else 
		{
			this.setAbsolutePosition(this.getAbsolutePosition().add(displacementVector));
		}
	}

	public function getAbsolutePosition(): Vector3
	{
		this.computeWorldMatrix();
		return this._absolutePosition;
	}

	public function setAbsolutePosition(absolutePosition: Vector3): Void
	{
		if (absolutePosition == null)
		{
			return;
		}

		if (this.parent != null)
		{
			var invertParentWorldMatrix = this.parent.getWorldMatrix().clone();
			invertParentWorldMatrix.invert();

			this.position = Vector3.TransformCoordinates(absolutePosition, invertParentWorldMatrix);
		}
		else
		{
			this.position.copyFrom(absolutePosition);
		}
	}
	
	// ================================== Point of View Movement =================================
	/**
	 * Perform relative position change from the point of view of behind the front of the mesh.
	 * This is performed taking into account the meshes current rotation, so you do not have to care.
	 * Supports definition of mesh facing forward or backward.
	 * @param {number} amountRight
	 * @param {number} amountUp
	 * @param {number} amountForward
	 */
	public function movePOV(amountRight : Float, amountUp : Float, amountForward : Float) : Void
	{
		this.position.addInPlace(this.calcMovePOV(amountRight, amountUp, amountForward));
	}
	
	/**
	 * Calculate relative position change from the point of view of behind the front of the mesh.
	 * This is performed taking into account the meshes current rotation, so you do not have to care.
	 * Supports definition of mesh facing forward or backward.
	 * @param {number} amountRight
	 * @param {number} amountUp
	 * @param {number} amountForward
	 */
	public function calcMovePOV(amountRight : Float, amountUp : Float, amountForward : Float) : Vector3
	{
		var rotMatrix = new Matrix();
		var rotQuaternion:Quaternion = (this.rotationQuaternion != null) ? this.rotationQuaternion : Quaternion.RotationYawPitchRoll(this.rotation.y, this.rotation.x, this.rotation.z);
		rotQuaternion.toRotationMatrix(rotMatrix);
		
		var translationDelta:Vector3 = Vector3.Zero();
		var defForwardMult:Int = this.definedFacingForward ? -1 : 1;
		Vector3.TransformCoordinatesFromFloatsToRef(amountRight * defForwardMult, amountUp, amountForward * defForwardMult, rotMatrix, translationDelta);
		return translationDelta;
	}
	// ================================== Point of View Rotation =================================
	/**
	 * Perform relative rotation change from the point of view of behind the front of the mesh.
	 * Supports definition of mesh facing forward or backward.
	 * @param {number} flipBack
	 * @param {number} twirlClockwise
	 * @param {number} tiltRight
	 */
	public function rotatePOV(flipBack : Float, twirlClockwise : Float, tiltRight : Float) : Void
	{
		this.rotation.addInPlace(this.calcRotatePOV(flipBack, twirlClockwise, tiltRight));
	}
	
	/**
	 * Calculate relative rotation change from the point of view of behind the front of the mesh.
	 * Supports definition of mesh facing forward or backward.
	 * @param {number} flipBack
	 * @param {number} twirlClockwise
	 * @param {number} tiltRight
	 */
	public function calcRotatePOV(flipBack : Float, twirlClockwise : Float, tiltRight : Float) : Vector3 
	{
		var defForwardMult:Int = this.definedFacingForward ? 1 : -1;
		return new Vector3(flipBack * defForwardMult, twirlClockwise, tiltRight * defForwardMult);
	}

	public function setPivotMatrix(matrix: Matrix): Void 
	{
		this._pivotMatrix.copyFrom(matrix);
		this._cache.pivotMatrixUpdated = true;
	}

	public function getPivotMatrix(): Matrix
	{
		return this._pivotMatrix;
	}

	@:dox(hide)
	override public function _isSynchronized(): Bool
	{
		if (this._isDirty)
		{
			return false;
		}

		if (this.billboardMode != AbstractMesh.BILLBOARDMODE_NONE)
			return false;

		if (this._cache.pivotMatrixUpdated) 
		{
			return false;
		}

		if (this.infiniteDistance)
		{
			return false;
		}

		if (!this._cache.position.equals(this.position))
			return false;

		if (this.rotationQuaternion != null) 
		{
			if (!this._cache.rotationQuaternion.equals(this.rotationQuaternion))
				return false;
		}
		else
		{
			if (!this._cache.rotation.equals(this.rotation))
				return false;
		}

		if (!this._cache.scaling.equals(this.scaling))
			return false;

		return true;
	}

	public function markAsDirty(property: String): Void
	{
		if (property == "rotation")
		{
			this.rotationQuaternion = null;
		}
		this._currentRenderId = Std.int(Math.POSITIVE_INFINITY);
		this._isDirty = true;
	}

	@:dox(hide)
	public function _updateBoundingInfo(): Void 
	{
		if(this._boundingInfo == null)
			this._boundingInfo = new BoundingInfo(this.absolutePosition, this.absolutePosition);

		this._boundingInfo.update(this.worldMatrixFromCache);
		
		this._updateSubMeshesBoundingInfo(this.worldMatrixFromCache);
	}
	
	@:dox(hide)
	public function _updateSubMeshesBoundingInfo(matrix: Matrix):Void
	{
		for (subIndex in 0...this.subMeshes.length)
		{
			var subMesh:SubMesh = this.subMeshes[subIndex];

			subMesh.updateBoundingInfo(matrix);
		}
	}

	public function computeWorldMatrix(force: Bool = false): Matrix
	{
		var scene:Scene = this.getScene();
		var sceneRenderId = scene.getRenderId();
		
		if (!force && (this._currentRenderId == sceneRenderId || this.isSynchronized(true))) 
		{
			return this._worldMatrix;
		}

		this._cache.position.copyFrom(this.position);
		this._cache.scaling.copyFrom(this.scaling);
		this._cache.pivotMatrixUpdated = false;
		this._currentRenderId = sceneRenderId;
		this._isDirty = false;

		// Scaling
		//Matrix.ScalingToRef(this.scaling.x, this.scaling.y, this.scaling.z, this._localScaling);
		_localScaling.m[0] = scaling.x;
		_localScaling.m[5] = scaling.y;
		_localScaling.m[10] = scaling.z;

		// Rotation
		if (this.rotationQuaternion != null)
		{
			this.rotationQuaternion.toRotationMatrix(this._localRotation);
			this._cache.rotationQuaternion.copyFrom(this.rotationQuaternion);
		} 
		else 
		{
			Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this._localRotation);
			this._cache.rotation.copyFrom(this.rotation);
		}

		// Translation
		if (this.infiniteDistance && this.parent == null)
		{
			var camera:Camera = scene.activeCamera;
			var cameraWorldMatrix:Matrix = camera.getWorldMatrix();

			//var cameraGlobalPosition:Vector3 = new Vector3(cameraWorldMatrix.m[12], cameraWorldMatrix.m[13], cameraWorldMatrix.m[14]);
//
			//Matrix.TranslationToRef(this.position.x + cameraGlobalPosition.x, this.position.y + cameraGlobalPosition.y, this.position.z + cameraGlobalPosition.z, this._localTranslation);
			
			//this._localTranslation.identity();
			this._localTranslation.m[12] = cameraWorldMatrix.m[12] + this.position.x;
			this._localTranslation.m[13] = cameraWorldMatrix.m[13] + this.position.y;
			this._localTranslation.m[14] = cameraWorldMatrix.m[14] + this.position.z;
		}
		else 
		{
			this._localTranslation.setTranslation(this.position);
			//Matrix.TranslationToRef(this.position.x, this.position.y, this.position.z, this._localTranslation);
		}

		// Composing transformations
		this._pivotMatrix.multiplyToRef(this._localScaling, this._localPivotScaling);
		this._localPivotScaling.multiplyToRef(this._localRotation, this._localPivotScalingRotation);

		// Billboarding
		if (this.billboardMode != AbstractMesh.BILLBOARDMODE_NONE && scene.activeCamera != null)
		{
			var localPosition = this.position.clone();
			var zero = scene.activeCamera.position.clone();

			if (this.parent != null && this.parent.position != null)
			{
				localPosition.addInPlace(this.parent.position);
				//Matrix.TranslationToRef(localPosition.x, localPosition.y, localPosition.z, this._localTranslation);
				this._localTranslation.setTranslation(localPosition);
			}

			if ((this.billboardMode & BILLBOARDMODE_ALL) == BILLBOARDMODE_ALL)
			{
				zero.copyFrom(scene.activeCamera.position);
			} 
			else
			{
				if ((this.billboardMode & BILLBOARDMODE_X) != 0)
					zero.x = localPosition.x + Engine.Epsilon;
				if ((this.billboardMode & BILLBOARDMODE_Y) != 0)
					zero.y = localPosition.y + 0.001;
				if ((this.billboardMode & BILLBOARDMODE_Z) != 0)
					zero.z = localPosition.z + 0.001;
			}

			Matrix.LookAtLHToRef(localPosition, zero, Vector3.Up(), this._localBillboard);
			this._localBillboard.m[12] = this._localBillboard.m[13] = this._localBillboard.m[14] = 0;

			this._localBillboard.invert();

			this._localPivotScalingRotation.multiplyToRef(this._localBillboard, this._localWorld);
			
			if (this._rotateYByPI == null)
				this._rotateYByPI = Matrix.RotationY(Math.PI);
			this._rotateYByPI.multiplyToRef(this._localWorld, this._localPivotScalingRotation);
		}

		// Local world
		this._localPivotScalingRotation.multiplyToRef(this._localTranslation, this._localWorld);

		// Parent
		if (this.parent != null && this.billboardMode == BILLBOARDMODE_NONE)
		{
			this._localWorld.multiplyToRef(this.parent.getWorldMatrix(), this._worldMatrix);
		} 
		else 
		{
			this._worldMatrix.copyFrom(this._localWorld);
		}

		// Bounding info
		this._updateBoundingInfo();

		// Absolute position
		this._absolutePosition.setTo(this._worldMatrix.m[12], this._worldMatrix.m[13], this._worldMatrix.m[14]);
		
		// Callbacks
		for (callbackIndex in 0..._onAfterWorldMatrixUpdate.length)
		{
			this._onAfterWorldMatrixUpdate[callbackIndex](this);
		}

		return this._worldMatrix;
	}
	
	/**
	* If you'd like to be callbacked after the mesh position, rotation or scaling has been updated
	* @param func: callback function to add
	*/
	public function registerAfterWorldMatrixUpdate(func: AbstractMesh->Void): Void
	{
		this._onAfterWorldMatrixUpdate.push(func);
	}

	public function unregisterAfterWorldMatrixUpdate(func: AbstractMesh->Void): Void
	{
		var index = this._onAfterWorldMatrixUpdate.indexOf(func);

		if (index > -1)
		{
			this._onAfterWorldMatrixUpdate.splice(index, 1);
		}
	}

	public function setPositionWithLocalVector(vector3: Vector3): Void 
	{
		this.computeWorldMatrix();

		this.position = Vector3.TransformNormal(vector3, this._localWorld);
	}

	public function getPositionExpressedInLocalSpace(): Vector3
	{
		this.computeWorldMatrix();
		var invLocalWorldMatrix = this._localWorld.clone();
		invLocalWorldMatrix.invert();

		return Vector3.TransformNormal(this.position, invLocalWorldMatrix);
	}

	public function locallyTranslate(vector3: Vector3): Void
	{
		this.computeWorldMatrix();

		this.position = Vector3.TransformCoordinates(vector3, this._localWorld);
	}

	public function lookAt(targetPoint: Vector3, yawCor: Float = 0, pitchCor: Float = 0, rollCor: Float = 0): Void 
	{
		/// <summary>Orients a mesh towards a target point. Mesh must be drawn facing user.</summary>
		/// <param name="targetPoint" type="Vector3">The position (must be in same space as current mesh) to look at</param>
		/// <param name="yawCor" type="Float">optional yaw (y-axis) correction in radians</param>
		/// <param name="pitchCor" type="Float">optional pitch (x-axis) correction in radians</param>
		/// <param name="rollCor" type="Float">optional roll (z-axis) correction in radians</param>
		/// <returns>Mesh oriented towards targetMesh</returns>

		var dv = targetPoint.subtract(this.position);
		var yaw = -Math.atan2(dv.z, dv.x) - Math.PI / 2;
		var len = Math.sqrt(dv.x * dv.x + dv.z * dv.z);
		var pitch = Math.atan2(dv.y, len);
		this.rotationQuaternion = Quaternion.RotationYawPitchRoll(yaw + yawCor, pitch + pitchCor, rollCor);
	}

	public function isInFrustrum(frustumPlanes: Array<Plane>): Bool
	{
		return _boundingInfo.isInFrustrum(frustumPlanes);
	}

	public function intersectsMesh(mesh: AbstractMesh, precise: Bool = false): Bool
	{
		if (this._boundingInfo == null || mesh._boundingInfo == null)
		{
			return false;
		}

		return this._boundingInfo.intersects(mesh._boundingInfo, precise);
	}

	public function intersectsPoint(point: Vector3): Bool
	{
		if (this._boundingInfo == null)
		{
			return false;
		}

		return this._boundingInfo.intersectsPoint(point);
	}
	
	public function getPositionInCameraSpace(camera: Camera = null): Vector3 
	{
		if (camera == null)
		{
			camera = this.getScene().activeCamera;
		}

		return Vector3.TransformCoordinates(this.absolutePosition, camera.getViewMatrix());
	}

	public function getDistanceToCamera(camera: Camera = null): Float 
	{
		if (camera == null)
		{
			camera = this.getScene().activeCamera;
		}

		return this.absolutePosition.subtract(camera.position).length();
	}

	// Physics
	public function setPhysicsState(impostor: Int = 0, options: PhysicsBodyCreationOptions = null): Void 
	{
		var physicsEngine = this.getScene().getPhysicsEngine();

		if (physicsEngine == null)
		{
			return;
		}

		if (impostor == PhysicsEngine.NoImpostor)
		{
			physicsEngine.unregisterMesh(this);
			return;
		}

		this._physicImpostor = impostor;
		this._physicsMass = options.mass;
		if(options.friction != null)
			this._physicsFriction = options.friction;
		if(options.restitution != null)
			this._physicRestitution = options.restitution;


		physicsEngine.registerMesh(this, impostor, options);
	}

	public function getPhysicsImpostor(): Float 
	{
		return this._physicImpostor;
	}

	public function getPhysicsMass(): Float 
	{
		return this._physicsMass;
	}

	public function getPhysicsFriction(): Float
	{
		return this._physicsFriction;
	}

	public function getPhysicsRestitution(): Float 
	{
		return this._physicRestitution;
	}

	public function applyImpulse(force: Vector3, contactPoint: Vector3): Void 
	{
		this.getScene().getPhysicsEngine().applyImpulse(this, force, contactPoint);
	}

	public function setPhysicsLinkWith(otherMesh: Mesh, pivot1: Vector3, pivot2: Vector3): Void
	{
		this.getScene().getPhysicsEngine().createLink(this, otherMesh, pivot1, pivot2);
	}
	
	// Collisions
	public function moveWithCollisions(velocity: Vector3): Void
	{
		var globalPosition:Vector3 = this.getAbsolutePosition();

		globalPosition.subtractFromFloatsToRef(0, this.ellipsoid.y, 0, this._oldPositionForCollisions);
		this._oldPositionForCollisions.addInPlace(this.ellipsoidOffset);
		this._collider.radius.copyFrom(this.ellipsoid);

		this.getScene()._getNewPosition(this._oldPositionForCollisions, velocity, this._collider, 3, this._newPositionForCollisions, this);
		this._newPositionForCollisions.subtractToRef(this._oldPositionForCollisions, this._diffPositionForCollisions);

		if (this._diffPositionForCollisions.length() > Engine.CollisionsEpsilon)
		{
			this.position.addInPlace(this._diffPositionForCollisions);
		}
	}

	// Submeshes octree

	/**
	* This function will create an octree to help select the right submeshes for rendering, picking and collisions
	* Please note that you must have a decent Float of submeshes to get performance improvements when using octree
	*/
	public function createOrUpdateSubmeshesOctree(maxCapacity:Int = 64, maxDepth:Int = 2): Octree<SubMesh> 
	{
		if (_submeshesOctree == null)
		{
			_submeshesOctree = new Octree<SubMesh>(Octree.CreationFuncForSubMeshes, maxCapacity, maxDepth);
		}

		this.computeWorldMatrix(true);            

		// Update octree
		var bbox:BoundingBox = this.getBoundingInfo().boundingBox;
		_submeshesOctree.update(bbox.minimumWorld, bbox.maximumWorld, this.subMeshes);

		return _submeshesOctree;
	}

	// Collisions
	@:dox(hide)
	public function _collideForSubMesh(subMesh: SubMesh, transformMatrix: Matrix, collider: Collider): Void 
	{
		this._generatePointsArray();
		
		// Transformation
		//TODO 优化
		if (subMesh._lastColliderWorldVertices == null || !subMesh._lastColliderTransformMatrix.equals(transformMatrix))
		{
			subMesh._lastColliderTransformMatrix.copyFrom(transformMatrix);
			subMesh._lastColliderWorldVertices = [];
			subMesh._trianglePlanes = [];
			
			var start:Int = subMesh.verticesStart;
			var end:Int = (subMesh.verticesStart + subMesh.verticesCount);
			for (i in start...end)
			{
				subMesh._lastColliderWorldVertices.push(Vector3.TransformCoordinates(this._positions[i], transformMatrix));
			}
		}
		// Collide
		collider._collide(subMesh, subMesh._lastColliderWorldVertices, this.getIndices(), subMesh.indexStart, subMesh.indexStart + subMesh.indexCount, subMesh.verticesStart);
	}

	public function _processCollisionsForSubMeshes(collider: Collider, transformMatrix: Matrix): Void
	{
		var subMeshes: Array<SubMesh>;
		var len: Int;            

		// Octrees
		if (this._submeshesOctree != null && this.useOctreeForCollisions)
		{
			var radius = collider.velocityWorldLength + FastMath.max([collider.radius.x, collider.radius.y, collider.radius.z]);
			var intersections = this._submeshesOctree.intersects(collider.basePointWorld, radius);

			len = intersections.length;
			subMeshes = intersections.data;
		} 
		else
		{
			subMeshes = this.subMeshes;
			len = subMeshes.length;
		}

		for (index in 0...len) 
		{
			var subMesh = subMeshes[index];

			// Bounding test
			if (len > 1 && !subMesh._checkCollision(collider))
				continue;

			this._collideForSubMesh(subMesh, transformMatrix, collider);
		}
	}

	@:dox(hide)
	public function _checkCollision(collider: Collider): Void 
	{
		// Bounding box test
		if (!this._boundingInfo._checkCollision(collider))
			return;

		// Transformation matrix
		Matrix.ScalingToRef(1.0 / collider.radius.x, 1.0 / collider.radius.y, 1.0 / collider.radius.z, this._collisionsScalingMatrix);
		
		this.worldMatrixFromCache.multiplyToRef(this._collisionsScalingMatrix, this._collisionsTransformMatrix);

		this._processCollisionsForSubMeshes(collider, this._collisionsTransformMatrix);
	}

	// Picking
	@:dox(hide)
	public function _generatePointsArray(): Bool
	{
		return false;
	}

	public function intersects(ray: Ray, fastCheck: Bool = false): PickingInfo
	{
		var pickingInfo:PickingInfo = new PickingInfo();

		if (this._boundingInfo == null || 
			!ray.intersectsSphere(this._boundingInfo.boundingSphere) || 
			!ray.intersectsBox(this._boundingInfo.boundingBox)) 
		{
			return pickingInfo;
		}

		if (!this._generatePointsArray())
		{
			return pickingInfo;
		}

		var intersectInfo: IntersectionInfo = null;

		// Octrees
		var subMeshes: Array<SubMesh>;
		var len: Int;

		if (this._submeshesOctree != null && this.useOctreeForPicking)
		{
			var worldRay:Ray = Ray.Transform(ray, this.getWorldMatrix());
			var intersections = this._submeshesOctree.intersectsRay(worldRay);

			len = intersections.length;
			subMeshes = intersections.data;
		} 
		else
		{
			subMeshes = this.subMeshes;
			len = subMeshes.length;
		}

		for (index in 0...len) 
		{
			var subMesh:SubMesh = subMeshes[index];

			// Bounding test
			if (len > 1 && !subMesh.canIntersects(ray))
				continue;

			var currentIntersectInfo:IntersectionInfo = subMesh.intersects(ray, this._positions, this.getIndices(), fastCheck);

			if (currentIntersectInfo != null)
			{
				if (fastCheck || intersectInfo == null || currentIntersectInfo.distance < intersectInfo.distance)
				{
					intersectInfo = currentIntersectInfo;

					if (fastCheck) 
					{
						break;
					}
				}
			}
		}

		if (intersectInfo != null)
		{
			// Get picked point
			var world:Matrix = this.getWorldMatrix();
			var worldOrigin:Vector3 = Vector3.TransformCoordinates(ray.origin, world);
			var direction:Vector3 = ray.direction.clone();
			direction.normalize();
			direction = direction.scale(intersectInfo.distance);
			
			var worldDirection = Vector3.TransformNormal(direction, world);

			var pickedPoint = worldOrigin.add(worldDirection);

			// Return result
			pickingInfo.hit = true;
			pickingInfo.distance = worldOrigin.distanceTo(pickedPoint);
			pickingInfo.pickedPoint = pickedPoint;
			pickingInfo.pickedMesh = this;
			pickingInfo.bu = intersectInfo.bu;
			pickingInfo.bv = intersectInfo.bv;
			pickingInfo.faceId = intersectInfo.faceId;
			return pickingInfo;
		}

		return pickingInfo;
	}

	public function clone(name: String, newParent: Node = null, doNotCloneChildren: Bool = false): AbstractMesh
	{
		return null;
	}

	public function releaseSubMeshes(): Void
	{
		while (this.subMeshes.length > 0)
		{
			this.subMeshes[0].dispose();
		}
		this.subMeshes = new Array<SubMesh>();
	}

	public function dispose(doNotRecurse: Bool = false): Void
	{
		// Physics
		if (this.getPhysicsImpostor() != PhysicsEngine.NoImpostor)
		{
			this.setPhysicsState(PhysicsEngine.NoImpostor);
		}
		
		// Intersections in progress
		for (index in 0...this._intersectionsInProgress.length)
		{
			var other = this._intersectionsInProgress[index];

			var pos = other._intersectionsInProgress.indexOf(this);
			if(pos > -1)
				other._intersectionsInProgress.splice(pos, 1);
		}
		this._intersectionsInProgress = [];

		// SubMeshes
		this.releaseSubMeshes();

		// Remove from scene
		getScene().removeMesh(this);

		if (!doNotRecurse)
		{
			// Particles
			var index:Int = 0;
			while (index < this.getScene().particleSystems.length) 
			{
				if (this.getScene().particleSystems[index].emitter == this) 
				{
					this.getScene().particleSystems[index].dispose();
					index--;
				}
				index++;
			}

			// Children
			var objects = this.getScene().meshes.slice(0);
			for (index in 0...objects.length) 
			{
				if (objects[index].parent == this)
				{
					objects[index].dispose();
				}
			}
		}
		else 
		{
			for (index in 0...this.getScene().meshes.length) 
			{
				var obj = this.getScene().meshes[index];
				if (obj.parent == this)
				{
					obj.parent = null;
					obj.computeWorldMatrix(true);
				}
			}
		}
		
		this._onAfterWorldMatrixUpdate = [];

		this._isDisposed = true;

		// Callback
		if (this.onDispose != null)
		{
			this.onDispose();
		}
	}
	
	private function get_positions():Array<Vector3>
	{
		return _positions;
	}
	
	private function get_isBlocked():Bool
	{
		return false;
	}
	
	private function get_material():Material
	{
		return _material;
	}
	
	private function set_material(value:Material):Material
	{
		return _material = value;
	}
	
	private function get_isPickable():Bool
	{
		return _isPickable;
	}
	
	private function set_isPickable(value:Bool):Bool
	{
		return _isPickable = value;
	}
	
	private function get_checkCollisions():Bool
	{
		return _needCheckCollisions;
	}
	
	private function set_checkCollisions(value:Bool):Bool
	{
		return _needCheckCollisions = value;
	}
	
	private function get_receiveShadows():Bool
	{
		return _receiveShadows;
	}
	
	private function set_receiveShadows(value:Bool):Bool
	{
		return _receiveShadows = value;
	}
	
	private function get_visibility():Float
	{
		return _visibility;
	}
	
	private function set_visibility(value:Float):Float
	{
		return _visibility = value;
	}
	
	private function get_skeleton():Skeleton
	{
		return _skeleton;
	}
	
	private function set_skeleton(value:Skeleton):Skeleton
	{
		return _skeleton = value;
	}

	private function get_worldMatrixFromCache(): Matrix
	{
		return this._worldMatrix;
	}

	
	private function get_absolutePosition(): Vector3 
	{
		return this._absolutePosition;
	}

	override private function _initCache():Void
	{
		super._initCache();

		this._cache.localMatrixUpdated = false;
		this._cache.position = Vector3.Zero();
		this._cache.scaling = Vector3.Zero();
		this._cache.rotation = Vector3.Zero();
		this._cache.rotationQuaternion = new Quaternion(0, 0, 0, 0);
	}

}