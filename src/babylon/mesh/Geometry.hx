package babylon.mesh;
import babylon.culling.BoundingInfo;
import babylon.math.Vector3;
import babylon.tools.Tools;
import haxe.Json;

using StringTools;

class Geometry implements IGetSetVerticesData
{
	public var id: String;
	public var delayLoadState:Int = 0;
	public var delayLoadingFile: String;
	public var _delayLoadingFunction:Dynamic->Geometry->Void;
	public var _delayInfo:Array<Dynamic>;
	
	private var _scene: Scene;
	private var _engine: Engine;
	private var _meshes: Array<Mesh>;
	private var _totalVertices:Int = 0;
	private var _indices:Array<Int> = [];
	private var _vertexBuffers:Map<String,VertexBuffer>;
	
	private var _indexBuffer:BabylonGLBuffer;
	public var _boundingInfo: BoundingInfo;

	public function new(id: String, scene: Scene, 
						vertexData: VertexData = null, 
						updatable: Bool = false, 
						mesh: Mesh = null) 
	{
		this.id = id;
		this._engine = scene.getEngine();
		this._meshes = [];
		this._scene = scene;
		
		// vertexData
		if (vertexData != null)
		{
			this.setAllVerticesData(vertexData, updatable);
		}
		else
		{
			this._totalVertices = 0;
			this._indices = [];
		}

		// applyToMesh
		if (mesh != null)
		{
			this.applyToMesh(mesh);
		}
	}
	
	public function getScene(): Scene
	{
		return this._scene;
	}

	public function getEngine(): Engine 
	{
		return this._engine;
	}

	public function isReady(): Bool 
	{
		return this.delayLoadState == Engine.DELAYLOADSTATE_LOADED || 
				this.delayLoadState == Engine.DELAYLOADSTATE_NONE;
	}
	
	public function setAllVerticesData(vertexData: VertexData, updatable: Bool = false): Void
	{
		vertexData.applyToGeometry(this, updatable);
	}
	
	public function  getTotalVertices(): Int
	{
		if (!this.isReady())
		{
			return 0;
		}

		return this._totalVertices;
	}
	
	public function getVertexBuffer(kind: String): VertexBuffer 
	{
		if (!this.isReady())
		{
			return null;
		}
		return this._vertexBuffers.get(kind);
	}

	public function getVertexBuffers(): Map<String,VertexBuffer>
	{
		if (!this.isReady())
		{
			return null;
		}
		return this._vertexBuffers;
	}
	
	public function getVerticesDataKinds(): Array<String>
	{
		var result = [];
		if (this._vertexBuffers == null && this._delayInfo != null) 
		{
			for (kind in this._delayInfo)
			{
				result.push(kind);
			}
		}
		else 
		{
			var keys = _vertexBuffers.keys();
			for (kind in keys) 
			{
				result.push(kind);
			}
		}

		return result;
	}
	
	public function isVerticesDataPresent(kind:String):Bool 
	{
		if (this._vertexBuffers == null)
		{
			if (this._delayInfo != null)
			{
				return this._delayInfo.indexOf(kind) != -1;
			}
			return false;
		}
		return this._vertexBuffers.exists(kind);
	}

	public function getVerticesData(kind:String):Array<Float> 
	{
		var vertexBuffer = this.getVertexBuffer(kind);
		if (vertexBuffer == null) 
		{
			return null;
		}
		return vertexBuffer.getData();
	}

	public function getTotalIndices(): Int
	{
		if (!this.isReady())
		{
			return 0;
		}
		return this._indices.length;
	}
	
	public function getIndexBuffer(): BabylonGLBuffer
	{
		if (!this.isReady()) 
		{
			return null;
		}
		return this._indexBuffer;
	}

	public function getIndices():Array<Int> 
	{
		if (!this.isReady())
		{
			return null;
		}
		return this._indices;
	}

	public function setVerticesData(kind:String, data:Array<Float>, updatable:Bool = false, stride:Int = 0):Void 
	{
		if (_vertexBuffers == null)
			_vertexBuffers = new Map<String,VertexBuffer>();

		if (this._vertexBuffers.exists(kind))
		{
			this._vertexBuffers.get(kind).dispose();
		}

		this._vertexBuffers.set(kind, new VertexBuffer(this._engine, data, kind, updatable, this._meshes.length == 0, stride));

		if (kind == VertexBuffer.PositionKind)
		{
			stride = this._vertexBuffers.get(kind).getStrideSize();

			this._totalVertices = Std.int(data.length / stride);

			var minMax:BabylonMinMax = Tools.ExtractMinAndMax(data, 0, this._totalVertices);

			var meshes:Array<Mesh> = this._meshes;
			var numOfMeshes:Int = meshes.length;
			for (index in 0...numOfMeshes) 
			{
				var mesh:Mesh = meshes[index];
				mesh._resetPointsArrayCache();
				mesh._boundingInfo = new BoundingInfo(minMax.minimum, minMax.maximum);
				mesh._createGlobalSubMesh();
				mesh.computeWorldMatrix(true);
			}
		}
	}
	
	public function updateVerticesDataDirectly(kind:String, data:Array<Float>, offset:Int):Void 
	{
		var vertexBuffer:VertexBuffer = this.getVertexBuffer(kind);

		if (vertexBuffer == null)
		{
			return;
		}

		vertexBuffer.updateDirectly(data, offset);
	}

	public function updateVerticesData(kind:String,
										data:Array<Float>, 
										updateExtends:Bool = true, 
										makeItUnique:Bool = true):Void 
	{
		var vertexBuffer:VertexBuffer = this.getVertexBuffer(kind);

		if (vertexBuffer == null)
		{
			return;
		}

		vertexBuffer.update(data);

		if (kind == VertexBuffer.PositionKind)
		{
			var stride:Int = vertexBuffer.getStrideSize();
			
			_totalVertices = Std.int(data.length / stride);
				
			var extend = {minimum:new Vector3(),maximum:new Vector3()};
			if (updateExtends) 
			{
				extend = Tools.ExtractMinAndMax(data, 0, this._totalVertices);
			}

			var meshes:Array<Mesh> = this._meshes;
			var numOfMeshes:Int = meshes.length;

			for (index in 0...numOfMeshes) 
			{
				var mesh:Mesh = meshes[index];
				mesh._resetPointsArrayCache();
				if (updateExtends)
				{
					mesh._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
				}
			}
		}
	}

	public function setIndices(indices:Array<Int>, totalVertices:Int = 0):Void 
	{
		if (this._indexBuffer != null)
		{
				this._engine.releaseBuffer(this._indexBuffer);
			}

			this._indices = indices;
			if (this._meshes.length != 0 && this._indices != null)
			{
				this._indexBuffer = this._engine.createIndexBuffer(this._indices);
			}
			
			if (totalVertices > 0)
				this._totalVertices = totalVertices;

			var meshes = this._meshes;
			var numOfMeshes = meshes.length;
			for (index in 0...numOfMeshes)
			{
				meshes[index]._createGlobalSubMesh();
			}
	}

	public function releaseForMesh(mesh: Mesh, shouldDispose:Bool = false): Void
	{
		var meshes = this._meshes;
		var index = meshes.indexOf(mesh);
		if (index == -1)
		{
			return;
		}

		for (vertexBuffer in this._vertexBuffers)
		{
			vertexBuffer.dispose();
		}

		if (this._indexBuffer != null && this._engine.releaseBuffer(this._indexBuffer))
		{
			this._indexBuffer = null;
		}

		meshes.splice(index, 1);

		mesh._geometry = null;

		if (meshes.length == 0 && shouldDispose)
		{
			this.dispose();
		}
	}

	public function applyToMesh(mesh: Mesh): Void 
	{
		if (mesh._geometry == this)
		{
			return;
		}

		var previousGeometry = mesh._geometry;
		if (previousGeometry != null)
		{
			previousGeometry.releaseForMesh(mesh);
		}

		var meshes = this._meshes;

		// must be done before setting vertexBuffers because of mesh._createGlobalSubMesh()
		mesh._geometry = this;

		this._scene.pushGeometry(this);

		meshes.push(mesh);

		if (this.isReady()) 
		{
			this._applyToMesh(mesh);
		}
		else 
		{
			mesh._boundingInfo = this._boundingInfo;
		}
	}

	private function _applyToMesh(mesh: Mesh): Void 
	{
		var numOfMeshes = this._meshes.length;

		// vertexBuffers
		var keys = this._vertexBuffers.keys();
		for (kind in keys)
		{
			if (numOfMeshes == 1)
			{
				_vertexBuffers.get(kind).create();
			}
			_vertexBuffers.get(kind).getBuffer().references = numOfMeshes;

			if (kind == VertexBuffer.PositionKind)
			{
				mesh._resetPointsArrayCache();

				var extend = Tools.ExtractMinAndMax(this._vertexBuffers.get(kind).getData(), 0, this._totalVertices);
				mesh._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);

				mesh._createGlobalSubMesh();
			}
		}

		// indexBuffer
		if (numOfMeshes == 1 && this._indices != null)
		{
			this._indexBuffer = this._engine.createIndexBuffer(this._indices);
		}
		if (this._indexBuffer != null)
		{
			this._indexBuffer.references = numOfMeshes;
		}
	}

	public function load(scene: Scene, onLoaded: Void->Void = null): Void
	{
		if (this.delayLoadState == Engine.DELAYLOADSTATE_LOADING)
		{
			return;
		}

		if (this.isReady())
		{
			if (onLoaded != null)
			{
				onLoaded();
			}
			return;
		}

		this.delayLoadState = Engine.DELAYLOADSTATE_LOADING;

		scene._addPendingData(this);
		
		Tools.LoadFile(this.delayLoadingFile, function(data:String):Void 
		{
			this._delayLoadingFunction(Json.parse(data), this);

			this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
			this._delayInfo = [];

			scene._removePendingData(this);

			var meshes = this._meshes;
			var numOfMeshes = meshes.length;
			for (index in 0...numOfMeshes)
			{
				this._applyToMesh(meshes[index]);
			}

			if (onLoaded != null)
			{
				onLoaded();
			}
		});
	}

	public function dispose(): Void 
	{
		var numOfMeshes:Int = _meshes.length;
		for (index in 0...numOfMeshes)
		{
			releaseForMesh(_meshes[index]);
		}
		_meshes = [];

		var keys:Iterator<String> = _vertexBuffers.keys();
		for (kind in keys) 
		{
			_vertexBuffers.get(kind).dispose();
		}
		_vertexBuffers = new Map<String,VertexBuffer>();
		_totalVertices = 0;

		if (_indexBuffer != null)
		{
			_engine.releaseBuffer(_indexBuffer);
		}
		_indexBuffer = null;
		_indices = [];

		delayLoadState = Engine.DELAYLOADSTATE_NONE;
		delayLoadingFile = null;
		_delayLoadingFunction = null;
		_delayInfo = [];

		_boundingInfo = null;
		
		var geometries = getScene().getGeometries();
		var index:Int = geometries.indexOf(this);
		if (index > -1)
		{
			geometries.splice(index, 1);
		}
	}

	public function copy(id: String): Geometry
	{
		var vertexData = new VertexData();

		vertexData.indices = [];

		var indices = this.getIndices();
		for (index in 0...indices.length) 
		{
			vertexData.indices.push(indices[index]);
		}

		var updatable = false;
		var stopChecking = false;

		var keys = this._vertexBuffers.keys();
		for (kind in keys)
		{
			vertexData.set(this.getVerticesData(kind), kind);

			if (!stopChecking) 
			{
				updatable = this.getVertexBuffer(kind).isUpdatable();
				stopChecking = !updatable;
			}
		}

		var geometry = new Geometry(id, this._scene, vertexData, updatable, null);

		geometry.delayLoadState = this.delayLoadState;
		geometry.delayLoadingFile = this.delayLoadingFile;
		geometry._delayLoadingFunction = this._delayLoadingFunction;

		if (_delayInfo != null)
		{
			for (kind in this._delayInfo)
			{
				geometry._delayInfo = geometry._delayInfo != null ? geometry._delayInfo : [];
				geometry._delayInfo.push(kind);
			}
		}
		
		// Bounding info
		var extend = Tools.ExtractMinAndMax(this.getVerticesData(VertexBuffer.PositionKind), 0, this.getTotalVertices());
		geometry._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);

		return geometry;
	}

	// Statics
	public static function  ExtractFromMesh(mesh: Mesh, id: String): Geometry 
	{
		var geometry = mesh._geometry;

		if (geometry == null) 
		{
			return null;
		}

		return geometry.copy(id);
	}

	// from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/2117523#answer-2117523
	// be aware Math.random() could cause collisions
	private static var RANDOM_ID:Int = 0;
	public static function RandomId(): String 
	{
		//var s = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
		//var regExp = ~/[xy]/g;
		//return regExp.map(s, function(regExp:EReg):String {
			//var c = regExp.matched(1);
			//var r = Std.int(Math.random() * 16) | 0;
			//var v = c == 'x' ? r : (r & 0x3 | 0x8);
			//return v.hex();
		//});
		//return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(~/[xy]/g, function(c):String {
			//var r = Std.int(Math.random() * 16) | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
			//return v.toString(16);
		//});
		return "random_geometry_id" + (RANDOM_ID++);
	}
}