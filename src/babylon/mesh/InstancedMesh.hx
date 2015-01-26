package babylon.mesh;
import babylon.bones.Skeleton;
import babylon.cameras.Camera;
import babylon.culling.BoundingInfo;
import babylon.culling.BoundingSphere;
import babylon.materials.Material;
import babylon.math.Vector3;
import babylon.tools.Tools;

class InstancedMesh extends AbstractMesh
{
	private var _sourceMesh:Mesh;
	private var _currentLOD: Mesh;

	public function new(name,source:Mesh) 
	{
		super(name, source.getScene());
		
		source.instances.push(this);
		
		this._sourceMesh = source;

		this.position.copyFrom(source.position);
		this.rotation.copyFrom(source.rotation);
		this.scaling.copyFrom(source.scaling);

		if (source.rotationQuaternion != null)
		{
			this.rotationQuaternion = source.rotationQuaternion.clone();
		}

		this.infiniteDistance = source.infiniteDistance;

		this.setPivotMatrix(source.getPivotMatrix());

		this.refreshBoundingInfo();
		this._syncSubMeshes();
	}
	
	override private function set_receiveShadows(value:Bool):Bool
	{
		return _sourceMesh.receiveShadows = value;
	}
	
	override private function get_receiveShadows():Bool
	{
		return _sourceMesh.receiveShadows;
	}
	
	override private function get_material():Material
	{
		return _sourceMesh.material;
	}
	
	override private function set_material(value:Material):Material
	{
		return _sourceMesh.material = value;
	}
	
	override private function set_visibility(value:Float):Float
	{
		return _sourceMesh.visibility = value;
	}
	
	override private function get_visibility():Float
	{
		return _sourceMesh.visibility;
	}
	
	override private function get_skeleton():Skeleton
	{
		return _sourceMesh.skeleton;
	}
	
	override private function set_skeleton(value:Skeleton):Skeleton
	{
		return _sourceMesh.skeleton = value;
	}
	
	public var sourceMesh(get, null):Mesh;
	private function get_sourceMesh():Mesh
	{
		return _sourceMesh;
	}
	
	override public function getTotalVertices(): Int 
	{
		return _sourceMesh.getTotalVertices();
	}
	
	override public function getVerticesData(kind: String): Array<Float>
	{
		return _sourceMesh.getVerticesData(kind);
	}

	override public function isVerticesDataPresent(kind: String): Bool
	{
		return _sourceMesh.isVerticesDataPresent(kind);
	}

	override public function getIndices(): Array<Int>
	{
		return _sourceMesh.getIndices();
	}
	
	override private function get_positions(): Array<Vector3>
	{
		return _sourceMesh.positions;
	}

	public function refreshBoundingInfo(): Void
	{
		var positions:Array<Float> = _sourceMesh.getVerticesData(VertexBuffer.PositionKind);

		if (positions != null) 
		{
			var minMax:BabylonMinMax = Tools.ExtractMinAndMax(positions, 0, _sourceMesh.getTotalVertices());
			_boundingInfo = new BoundingInfo(minMax.minimum, minMax.maximum);
		}

		_updateBoundingInfo();
	}
	
	override public function preActivate(): Void 
	{
		if (this._currentLOD != null)
		{
			this._currentLOD.preActivate();
		}
	}

	override public function activate(renderId: Int): Void 
	{
		if (this._currentLOD != null)
		{
			this._currentLOD._registerInstanceForRenderId(this, renderId);
		}
	}
	
	override public function getLOD(camera: Camera, boundingSphere:BoundingSphere = null): AbstractMesh 
	{
		this._currentLOD = cast this.sourceMesh.getLOD(this.getScene().activeCamera, this.getBoundingInfo().boundingSphere);
		
		if (this._currentLOD == this.sourceMesh) 
		{
			return this;
		}

		return this._currentLOD;
	}

	public function _syncSubMeshes(): Void
	{
		releaseSubMeshes();
		
		if (_sourceMesh.subMeshes != null)
		{
			for (index in 0..._sourceMesh.subMeshes.length)
			{
				_sourceMesh.subMeshes[index].clone(this, _sourceMesh);
			}
		}
	}

	override public function _generatePointsArray(): Bool
	{
		return _sourceMesh._generatePointsArray();
	}

	// Clone
	override public function clone(name: String, newParent: Node = null, doNotCloneChildren: Bool = false ): InstancedMesh
	{
		var result = _sourceMesh.createInstance(name);

		//TODO 这里对cpp无效，改
		// Deep copy
		//Tools.DeepCopy(this, result, ["name"], []);

		// Bounding info
		refreshBoundingInfo();

		// Parent
		if (newParent != null)
		{
			result.parent = newParent;
		}

		if (!doNotCloneChildren)
		{
			// Children
			for (index in 0...getScene().meshes.length)
			{
				var mesh = getScene().meshes[index];

				if (mesh.parent == this) 
				{
					mesh.clone(mesh.name, result);
				}
			}
		}

		result.computeWorldMatrix(true);

		return result;
	}

	// Dispoe
	override public function dispose(doNotRecurse: Bool = false): Void 
	{
		// Remove from mesh
		_sourceMesh.instances.remove(this);

		super.dispose(doNotRecurse);
	}
}