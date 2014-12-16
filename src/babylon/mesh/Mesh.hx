package babylon.mesh;

import babylon.cameras.Camera;
import babylon.culling.BoundingInfo;
import babylon.culling.BoundingSphere;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.Material;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.math.Vector3;
import babylon.Node;
import babylon.particles.ParticleSystem;
import babylon.Scene;
import babylon.tools.Tools;
import babylon.utils.Logger;
import babylon.utils.MathUtils;
import haxe.Json;
import openfl.utils.ByteArray;
import openfl.utils.Float32Array;

typedef InstanceInfo = {
	var defaultRenderId:Int;
	var selfDefaultRenderId:Int;
	var instances:Map<Int,Array<InstancedMesh>>;
}

class Mesh extends AbstractMesh implements IGetSetVerticesData 
{
	
	public static inline var BILLBOARDMODE_NONE:Int = 0;
	public static inline var BILLBOARDMODE_X:Int = 1;
	public static inline var BILLBOARDMODE_Y:Int = 2;
	public static inline var BILLBOARDMODE_Z:Int = 4;
	public static inline var BILLBOARDMODE_ALL:Int = 7;

	public var _geometry: Geometry;
	
	private var _onBeforeRenderCallbacks:Array < Void->Void > = [];
	private var _onAfterRenderCallbacks:Array<Void->Void> = [];
	
	// delay load
	public var delayLoadState:Int = 0;
	public var delayLoadingFile:String;
	public var _delayInfo:Array<Dynamic>;
	public var _delayLoadingFunction:Dynamic->Mesh->Void;
	
	public var instances:Array<InstancedMesh> = [];
	public var _visibleInstances:InstanceInfo;
	
	private var _renderIdForInstances:Array<Int> = [];
	private var _batchCache:InstancesBatch;
	
	private var _worldMatricesInstancesBuffer: BabylonGLBuffer;
	private var _worldMatricesInstancesArray: Float32Array;
	private var _instancesBufferSize:Int = 32 * 16 * 4; // let's start with a maximum of 32 instances

	public var _shouldGenerateFlatShading:Bool = false;
	
	private var _preActivateId: Int = -1;
	
	public var _binaryInfo:Dynamic;
	
	private var _LODLevels:Array<MeshLODLevel> = [];
	
	public function new(name:String, scene:Scene)
	{
		super(name, scene);

        _batchCache = new InstancesBatch();
	}
	
	public function hasLODLevels():Bool
	{
		return _LODLevels.length > 0;
	}
	
	// Methods
	private function _sortLODLevels(): Void
	{
		this._LODLevels.sort(function(a:MeshLODLevel, b:MeshLODLevel):Int 
		{
			if (a.distance < b.distance)
			{
				return 1;
			}
			if (a.distance > b.distance) 
			{
				return -1;
			}
			return 0;
		});
	}

	public function addLODLevel(distance: Float, mesh: Mesh): Mesh 
	{
		if (mesh != null && mesh._masterMesh != null)
		{
			Logger.warn("You cannot use a mesh as LOD level twice");
			return this;
		}
			
		var level:MeshLODLevel = new MeshLODLevel(distance, mesh);
		this._LODLevels.push(level);

		if (mesh != null)
		{
			mesh._masterMesh = this;
		}

		this._sortLODLevels();

		return this;
	}

	public function removeLODLevel(mesh: Mesh): Mesh
	{
		if (mesh == null)
			return null;
		
		var i:Int = 0;
		while (i < _LODLevels.length) 
		{
			if (this._LODLevels[i].mesh == mesh) 
			{
				this._LODLevels.splice(i, 1);
				mesh._masterMesh = null;
				i--;
			}
			
			i++;
		}
		
		this._sortLODLevels();

		return this;
	}

	override public function getLOD(camera: Camera, boundingSphere:BoundingSphere = null): AbstractMesh 
	{
		if (this._LODLevels == null || this._LODLevels.length == 0) 
		{
			return this;
		}

		var distanceToCamera:Float = boundingSphere != null ? 
									boundingSphere.centerWorld.subtract(camera.position).length() : 
									this.getBoundingInfo().boundingSphere.centerWorld.subtract(camera.position).length();

		if (this._LODLevels[this._LODLevels.length - 1].distance > distanceToCamera) 
		{
			return this;
		}

		for (index in 0...this._LODLevels.length)
		{
			var level:MeshLODLevel = this._LODLevels[index];

			if (level.distance < distanceToCamera)
			{
				if (level.mesh != null)
				{
					level.mesh.preActivate();
					level.mesh._updateSubMeshesBoundingInfo(this.worldMatrixFromCache);
				}
				return level.mesh;
			}
		}

		return this;
	}
	
	public var geometry(get, null):Geometry;
	private function get_geometry():Geometry
	{
		return _geometry;
	}
	
	override public function getTotalVertices(): Int 
	{
		if (_geometry == null)
		{
			return 0;
		}
		return _geometry.getTotalVertices();
	}
	
	override public function getVerticesData(kind:String):Array<Float>
	{
		if (_geometry == null)
		{
			return null;
		}
		return _geometry.getVerticesData(kind);
	}
	
	public function getVertexBuffer(kind:String):VertexBuffer 
	{
		if (_geometry == null)
		{
			return null;
		}
        return _geometry.getVertexBuffer(kind);
    }
	
	override public function isVerticesDataPresent(kind:String):Bool
	{
		if (_geometry == null)
		{
			if (_delayInfo != null)
			{
				return _delayInfo.indexOf(kind) != -1;
			}
			return false;
		}
		return _geometry.isVerticesDataPresent(kind);
	}
	
	public function getVerticesDataKinds():Array<String> 
	{
        if (_geometry == null)
		{
			var result = [];
			if (_delayInfo != null) 
			{
				for (kind in _delayInfo)
				{
					result.push(kind);
				}
			}
			return result;
		}
		return _geometry.getVerticesDataKinds();
    }
	
	public function getTotalIndices():Int
	{
		if (_geometry == null)
		{
			return 0;
		}
		return _geometry.getTotalIndices();
	}
	
	override public function getIndices():Array<Int> 
	{
		if (_geometry == null)
		{
			return [];
		}
		return _geometry.getIndices();
	}
	
	override private function get_isBlocked():Bool
	{
		return _masterMesh != null;
	}
	
	override public function isReady(): Bool 
	{
		if (this.delayLoadState == Engine.DELAYLOADSTATE_LOADING)
		{
			return false;
		}

		return super.isReady();
	}
	
	override public function preActivate(): Void
	{
		var sceneRenderId:Int = this.getScene().getRenderId();
		if (this._preActivateId == sceneRenderId)
		{
			return;
		}

		this._preActivateId = sceneRenderId;
		this._visibleInstances = null;
	}
	
	public function _registerInstanceForRenderId(instance: InstancedMesh, renderId: Int):Void
	{
		if (this._visibleInstances == null)
		{
			this._visibleInstances = { defaultRenderId:renderId,
										selfDefaultRenderId:this._renderId,
										instances:new Map<Int,Array<InstancedMesh>>() };
		}
		
		var instancedMeshs:Array<InstancedMesh> = this._visibleInstances.instances.get(renderId);
		if (instancedMeshs == null) 
		{
			instancedMeshs = new Array<InstancedMesh>();
			this._visibleInstances.instances.set(renderId, instancedMeshs);
		}

		instancedMeshs.push(instance);
	}
	
	public function refreshBoundingInfo():Void
	{
		var data:Array<Float> = this.getVerticesData(VertexBuffer.PositionKind);

        if (data != null) 
		{
			var extend:BabylonMinMax = Tools.ExtractMinAndMax(data, 0, this.getTotalVertices());
			this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
		}

		if (this.subMeshes != null)
		{
			for (index in 0...this.subMeshes.length) 
			{
				this.subMeshes[index].refreshBoundingInfo();
			}
		}
        
        this._updateBoundingInfo();
	}
	
	public function _createGlobalSubMesh():SubMesh
	{
		var totalVertices = this.getTotalVertices();
		if (totalVertices == 0 || this.getIndices() == null)
		{
            return null;
        }

        this.releaseSubMeshes();
        return new SubMesh(0, 0, totalVertices, 0, this.getTotalIndices(), this);
	}
	
	public function subdivide(count:Int):Void
	{
		if (count < 1) 
		{
            return;
        }

        var totalIndices:Int = this.getTotalIndices();
		
		var subdivisionSize:Int = Std.int(totalIndices / count);
		
		// Ensure that subdivisionSize is a multiple of 3
		while (subdivisionSize % 3 != 0)
		{
			subdivisionSize++;
		}

        this.releaseSubMeshes();
		
		var offset:Int = 0;
        for (index in 0...count)
		{
			if (offset >= totalIndices)
			{
				break;
			}
			
            SubMesh.CreateFromIndices(0, offset, MathUtils.min(subdivisionSize, totalIndices - offset), this);

            offset += subdivisionSize;
        }
		
		this.synchronizeInstances();
	}
	
	public function setVerticesData(kind:String, data:Array<Float>, updatable:Bool = false, stride:Int = 0):Void
	{
		if (this._geometry == null)
		{
			var vertexData:VertexData = new VertexData();
			vertexData.set(data, kind);

			var scene:Scene = this.getScene();

			new Geometry(Geometry.RandomId(), scene, vertexData, updatable, this);
		}
		else
		{
			this._geometry.setVerticesData(kind, data, updatable, stride);
		}
	}
	
	public function updateVerticesData(kind:String, data:Array<Float>, updateExtends: Bool = false, makeItUnique: Bool = false):Void 
	{
		if (this._geometry == null)
		{
			return;
		}
		
		if (!makeItUnique)
		{
			this._geometry.updateVerticesData(kind, data, updateExtends);
		}
		else
		{
			this.makeGeometryUnique();
			this.updateVerticesData(kind, data, updateExtends, false);
		}
	}
	
	public function makeGeometryUnique():Void
	{
		if (this._geometry == null) 
		{
			return;
		}
		
		var geometry:Geometry = this._geometry.copy(Geometry.RandomId());
		geometry.applyToMesh(this);
	}
	
	public function setIndices(indices:Array<Int>):Void
	{
		if (this._geometry == null)
		{
			var vertexData = new VertexData();
			vertexData.indices = indices;

			var scene = this.getScene();

			new Geometry(Geometry.RandomId(), scene, vertexData, false, this);
		}
		else
		{
			this._geometry.setIndices(indices);
		}
	}
	
	public function _bind(subMesh: SubMesh, effect: Effect, fillMode: Int = 0): Void
	{
		var engine = this.getScene().getEngine();

		
		var indexBuffer:BabylonGLBuffer = null;
		switch(fillMode)
		{
			case Material.PointFillMode:
				indexBuffer = null;
			case Material.WireFrameFillMode:
				indexBuffer = subMesh.getLinesIndexBuffer(this.getIndices(), engine);
			case Material.TriangleFillMode:
				indexBuffer = _geometry.getIndexBuffer();
		}

		// VBOs
		engine.bindMultiBuffers(_geometry.getVertexBuffers(), indexBuffer, effect);
	}
	
	public function _draw(subMesh: SubMesh, fillMode: Int, instancesCount: Int = 0): Void 
	{
		if (_geometry == null || 
			_geometry.getVertexBuffers() == null || 
			_geometry.getIndexBuffer() == null)
		{
			return;
		}
		
		var engine:Engine = this.getScene().getEngine();
		// Draw order
		switch (fillMode)
		{
			case Material.PointFillMode:
				engine.drawPointClouds(subMesh.verticesStart, subMesh.verticesCount, instancesCount);
			case Material.WireFrameFillMode:
				engine.draw(false, 0, subMesh.linesIndexCount, instancesCount);
			case Material.TriangleFillMode:
				engine.draw(true, subMesh.indexStart, subMesh.indexCount, instancesCount);
		}
	}
	
	public function registerBeforeRender(func:Void->Void):Void
	{
		this._onBeforeRenderCallbacks.push(func);
	}
	
	public function unregisterBeforeRender(func:Void->Void):Void
	{
		this._onBeforeRenderCallbacks.remove(func);
	}
	
	public function registerAfterRender(func:Void->Void):Void
	{
		this._onAfterRenderCallbacks.push(func);
	}
	
	public function unregisterAfterRender(func:Void->Void):Void
	{
		this._onAfterRenderCallbacks.remove(func);
	}
	
	public function _getInstancesRenderList(subMeshId:Int): InstancesBatch
	{
		var scene:Scene = this.getScene();
		
		_batchCache.mustReturn = false;
		_batchCache.renderSelf[subMeshId] = isEnabled() && isVisible;
		_batchCache.visibleInstances[subMeshId] = null;

		if (_visibleInstances != null)
		{
			var currentRenderId:Int = scene.getRenderId();
			
			_batchCache.visibleInstances[subMeshId] = _visibleInstances.instances.get(currentRenderId);
			
			var selfRenderId:Int = _renderId;

			if (_batchCache.visibleInstances[subMeshId] == null && _visibleInstances.defaultRenderId != 0)
			{
				var renderId = _visibleInstances.defaultRenderId;
				
				_batchCache.visibleInstances[subMeshId] = _visibleInstances.instances.get(renderId);

				currentRenderId = _visibleInstances.defaultRenderId;
				selfRenderId = _visibleInstances.selfDefaultRenderId;
			}

			if (_batchCache.visibleInstances[subMeshId] != null && _batchCache.visibleInstances[subMeshId].length > 0)
			{
				if (_renderIdForInstances[subMeshId] == currentRenderId) 
				{
					_batchCache.mustReturn = true;
					return _batchCache;
				}

				if (currentRenderId != selfRenderId)
				{
					_batchCache.renderSelf[subMeshId] = false;
				}

			}
			_renderIdForInstances[subMeshId] = currentRenderId;
		}

		return _batchCache;
	}
	
	#if html5
	public function _renderWithInstances(subMesh: SubMesh, fillMode: Int, batch: InstancesBatch, effect: Effect, engine: Engine): Void
	{
		var visibleInstances:Array<InstancedMesh> = batch.visibleInstances[subMesh._id];
		if (visibleInstances == null)
			return;
			
		var matricesCount = visibleInstances.length + 1;
		var bufferSize = matricesCount * 16 * 4;

		while (this._instancesBufferSize < bufferSize)
		{
			this._instancesBufferSize *= 2;
		}

		if (this._worldMatricesInstancesBuffer == null || 
			this._worldMatricesInstancesBuffer.capacity < this._instancesBufferSize) 
		{
			if (this._worldMatricesInstancesBuffer != null) 
			{
				engine.deleteInstancesBuffer(this._worldMatricesInstancesBuffer);
			}

			this._worldMatricesInstancesBuffer = engine.createInstancesBuffer(this._instancesBufferSize);
			this._worldMatricesInstancesArray = new Float32Array(Std.int(this._instancesBufferSize / 4));
		}

		var offset = 0;
		var instancesCount = 0;

		var world:Matrix = this.getWorldMatrix();
		if (batch.renderSelf[subMesh._id]) 
		{
			world.copyToFloat32Array(this._worldMatricesInstancesArray, offset);
			offset += 16;
			instancesCount++;
		}

		if (visibleInstances != null)
		{
			for (instanceIndex in 0...visibleInstances.length)
			{
				var instance:InstancedMesh = visibleInstances[instanceIndex];
				instance.getWorldMatrix().copyToFloat32Array(this._worldMatricesInstancesArray, offset);
				offset += 16;
				instancesCount++;
			}
		}
		

		var offsetLocation0 = effect.getAttributeLocationByName("world0");
		var offsetLocation1 = effect.getAttributeLocationByName("world1");
		var offsetLocation2 = effect.getAttributeLocationByName("world2");
		var offsetLocation3 = effect.getAttributeLocationByName("world3");

		var offsetLocations = [offsetLocation0, offsetLocation1, offsetLocation2, offsetLocation3];

		engine.updateAndBindInstancesBuffer(this._worldMatricesInstancesBuffer, this._worldMatricesInstancesArray, offsetLocations);

		this._draw(subMesh, fillMode, instancesCount);

		engine.unBindInstancesBuffer(this._worldMatricesInstancesBuffer, offsetLocations);
	}
	#end
	
	public function render(subMesh: SubMesh): Void 
	{
		var scene:Scene = getScene();

		// Managing instances
		var batch:InstancesBatch = _getInstancesRenderList(subMesh._id);
		if (batch.mustReturn)
		{
			return;
		}

		// Checking geometry state
		if (_geometry == null || 
			_geometry.getVertexBuffers() == null  || 
			_geometry.getIndexBuffer() == null )
		{
			//trace(subMesh.getMesh().name+" _geometry:" + _geometry);
			return;
		}

		for (callbackIndex in 0..._onBeforeRenderCallbacks.length) 
		{
			_onBeforeRenderCallbacks[callbackIndex]();
		}

		var engine:Engine = scene.getEngine();
		var hardwareInstancedRendering:Bool = engine.getCaps().instancedArrays != null && 
											(batch.visibleInstances[subMesh._id] != null); 

		// Material
		var effectiveMaterial:Material = subMesh.getMaterial();

		if (effectiveMaterial == null || !effectiveMaterial.isReady(this, hardwareInstancedRendering))
		{
			//trace(effectiveMaterial.name + " isReady:" + effectiveMaterial.isReady(this, hardwareInstancedRendering));
			return;
		}
		
		// Outline - step 1
		var savedDepthWrite:Bool = engine.getDepthWrite();
		if (this.renderOutline)
		{
			engine.setDepthWrite(false);
			scene.getOutlineRenderer().render(subMesh, batch);
			engine.setDepthWrite(savedDepthWrite);
		}

		effectiveMaterial._preBind();
		
		var effect:Effect = effectiveMaterial.getEffect();

		// Bind
	var fillMode:Int = scene.forcePointsCloud ? Material.PointFillMode : 
												(scene.forceWireframe ? Material.WireFrameFillMode : effectiveMaterial.fillMode);
		_bind(subMesh, effect, fillMode);

		var world:Matrix = getWorldMatrix();
		effectiveMaterial.bind(world, this);

		// Instances rendering
		if (hardwareInstancedRendering) 
		{
			#if html5
			_renderWithInstances(subMesh, fillMode, batch, effect, engine);
			#end
		} 
		else 
		{
			if (batch.renderSelf[subMesh._id])
			{
				// Draw
				_draw(subMesh, fillMode);
			}


			if (batch.visibleInstances[subMesh._id] != null)
			{
				var instances:Array<InstancedMesh> = batch.visibleInstances[subMesh._id];
				for (instanceIndex in 0...instances.length)
				{
					var instance:InstancedMesh = instances[instanceIndex];

					// World
					world = instance.getWorldMatrix();
					effectiveMaterial.bindOnlyWorldMatrix(world);

					// Draw
					_draw(subMesh, fillMode);
				}
			}
		}
		
		// Unbind
		effectiveMaterial.unbind();
		
		// Outline - step 2
		if (this.renderOutline && savedDepthWrite)
		{
			engine.setDepthWrite(true);
			engine.setColorWrite(false);
			scene.getOutlineRenderer().render(subMesh, batch);
			engine.setColorWrite(true);
		}
		
		// Overlay
		if (this.renderOverlay) 
		{
			var currentMode:Int = engine.getAlphaMode();
			engine.setAlphaMode(Engine.ALPHA_COMBINE);
			scene.getOutlineRenderer().render(subMesh, batch, true);
			engine.setAlphaMode(currentMode);
		}

		for (callbackIndex in 0..._onAfterRenderCallbacks.length)
		{
			_onAfterRenderCallbacks[callbackIndex]();
		}
	}
	
	public function getEmittedParticleSystems():Array<ParticleSystem> 
	{
		var results:Array<ParticleSystem> = [];
		var particleSystems:Array<ParticleSystem> = this.getScene().particleSystems;
        for (index in 0...particleSystems.length) 
		{
            var particleSystem = particleSystems[index];
            if (particleSystem.emitter == this) 
			{
                results.push(particleSystem);
            }
        }

        return results;
	}
	
	public function getHierarchyEmittedParticleSystems():Array<ParticleSystem>
	{
		var results:Array<ParticleSystem> = [];
        var descendants:Array<Dynamic> = this.getDescendants();
        descendants.push(this);

        var particleSystems:Array<ParticleSystem> = this.getScene().particleSystems;
        for (index in 0...particleSystems.length) 
		{
            var particleSystem = particleSystems[index];
            if (descendants.indexOf(particleSystem.emitter) != -1)
			{
                results.push(particleSystem);
            }
        }

        return results;
	}
	
	
	public function getChildren():Array<AbstractMesh> 
	{
		var results:Array<AbstractMesh> = [];
        for (index in 0...this.getScene().meshes.length) 
		{
            var mesh:AbstractMesh = this.getScene().meshes[index];
            if (mesh.parent == this)
			{
                results.push(mesh);
            }
        }

        return results;
	}
	
	public function _checkDelayState(): Void
	{
		var scene:Scene = this.getScene();

		if (this._geometry != null)
		{
			this._geometry.load(scene);
		}
		else if (this.delayLoadState == Engine.DELAYLOADSTATE_NOTLOADED)
		{
			this.delayLoadState = Engine.DELAYLOADSTATE_LOADING;

			scene._addPendingData(this);
			
			var isByteArray:Bool = (this.delayLoadingFile.indexOf(".babylonbinarymeshdata") != -1) ? true : false;
			
			if (isByteArray)
			{
				Tools.LoadBinary(this.delayLoadingFile, function(data:ByteArray):Void
				{
					this._delayLoadingFunction(data, this);
					this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
					scene._removePendingData(this);
				},function():Void {
					Logger.warn("load mesh " + this.delayLoadingFile + " failed,remove from scene");
					scene._removePendingData(this);
					this.dispose();
				});
			}
			else
			{
				Tools.LoadFile(this.delayLoadingFile, function(data:String):Void
				{
					this._delayLoadingFunction(Json.parse(data), this);
					this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
					scene._removePendingData(this);
				},function(url:String):Void {
					Logger.warn("load mesh " + url + " failed,remove from scene");
					scene._removePendingData(this);
					this.dispose();
				});
			}
		}
	}
	
	override public function isInFrustrum(frustumPlanes: Array<Plane>): Bool
	{
		if (this.delayLoadState == Engine.DELAYLOADSTATE_LOADING) 
		{
			return false;
		}

		if (!super.isInFrustrum(frustumPlanes)) 
		{
			return false;
		}

		this._checkDelayState();

		return true;
	}
	
	public function setMaterialByID(id:String):Void
	{
		var materials = this.getScene().materials;
        for (index in 0...materials.length)
		{
            if (materials[index].id == id) 
			{
                this.material = materials[index];
                return;
            }
        }

        // Multi
        var multiMaterials = this.getScene().multiMaterials;
        for (index in 0...multiMaterials.length)
		{
            if (multiMaterials[index].id == id) 
			{
                this.material = multiMaterials[index];
                return;
            }
        }
	}
	
	public function getAnimatables():Array<Dynamic> 
	{		
		var results:Array<Dynamic> = [];

        if (this.material != null)
		{
            results.push(this.material);
        }

        return results;
	}
	
	// Geometry
	public function bakeTransformIntoVertices(transform: Matrix): Void 
	{
		// Position
		if (!this.isVerticesDataPresent(VertexBuffer.PositionKind))
		{
			return;
		}

		this._resetPointsArrayCache();

		var data = this.getVerticesData(VertexBuffer.PositionKind);
		var temp = [];
		var index:Int = 0;
		while (index < data.length ) 
		{
			Vector3.TransformCoordinates(Vector3.FromArray(data, index), transform).toArray(temp, index);
			
			index += 3;
		}

		this.setVerticesData(VertexBuffer.PositionKind, temp, this.getVertexBuffer(VertexBuffer.PositionKind).isUpdatable());

		// Normals
		if (!this.isVerticesDataPresent(VertexBuffer.NormalKind))
		{
			return;
		}

		data = this.getVerticesData(VertexBuffer.NormalKind);
		var index:Int = 0;
		while (index < data.length ) 
		{
			Vector3.TransformNormal(Vector3.FromArray(data, index), transform).toArray(temp, index);
			
			index += 3;
		}

		this.setVerticesData(VertexBuffer.NormalKind, temp, this.getVertexBuffer(VertexBuffer.NormalKind).isUpdatable());
	}
	
	public function _resetPointsArrayCache():Void
	{
		this._positions = null;
	}
	
	override public function _generatePointsArray():Bool
	{
		if (this._positions != null)
            return true;

        this._positions = [];

        var data:Array<Float> = this.getVerticesData(VertexBuffer.PositionKind);
		if (data == null)
			return false;
			
		
		var index:Int = 0;
        while (index < data.length)
		{
            this._positions.push(Vector3.FromArray(data, index));
			index += 3;
        }
		
		return true;
	}
	
	//TODO 修改
	override public function clone(name:String, newParent:Node = null, doNotCloneChildren:Bool = false):AbstractMesh
	{
		var result:Mesh = new Mesh(name, this.getScene());
		result.rotation.copyFrom(this.rotation);
		if (this.rotationQuaternion != null)
			result.rotationQuaternion = this.rotationQuaternion.clone();
		result.scaling.copyFrom(this.scaling);
		result.billboardMode = this.billboardMode;
		result.infiniteDistance = this.infiniteDistance;
		result.isVisible = this.isVisible;
		result.isPickable = this.isPickable;
		result.checkCollisions = this.checkCollisions;
		result.receiveShadows = this.receiveShadows;
		result.visibility = this.visibility;
		result.material = this.material;
		result.showBoundingBox = this.showBoundingBox;
		result.showSubMeshesBoundingBox = this.showSubMeshesBoundingBox;
		result.layerMask = this.layerMask;
		
		result.onDispose = this.onDispose;
		result.useOctreeForRenderingSelection = this.useOctreeForRenderingSelection;
		result.useOctreeForCollisions = this.useOctreeForCollisions;
		result.useOctreeForPicking = this.useOctreeForPicking;
		
		var newSubMeshes:Array<SubMesh> = [];
		for (i in 0...this.subMeshes.length) 
		{
			newSubMeshes[i] = this.subMeshes[i].clone(result);
		}
		
		result.subMeshes = newSubMeshes;
		
		// Geometry
		this._geometry.applyToMesh(result);
		
		// Parent
		if (newParent != null)
		{
			result.parent = newParent;
		}
		else
		{
			result.parent = this.parent;
		}
		
		
		
		//Tools.DeepCopy(this, result, ["name", "material", "skeleton"], []);
		
        if (!doNotCloneChildren)
		{
            // Children
            for (index in 0...this.getScene().meshes.length)
			{
                var mesh = this.getScene().meshes[index];

                if (mesh.parent == this) 
				{
                    mesh.clone(mesh.name, result);
                }
            }
        }

        // Particles
        for (index in 0...this.getScene().particleSystems.length) 
		{
            var system = this.getScene().particleSystems[index];

            if (system.emitter == this) 
			{
                system.clone(system.name, result);
            }
        }
		
		result.computeWorldMatrix(true);

        return result;
	}
	
	override public function dispose(doNotRecurse:Bool = false):Void 
	{
		if (this._geometry != null)
		{
			this._geometry.releaseForMesh(this, true);
		}

        // Instances
		if (this._worldMatricesInstancesBuffer != null)
		{
			#if html5
			this.getEngine().deleteInstancesBuffer(this._worldMatricesInstancesBuffer);
			#end
			this._worldMatricesInstancesBuffer = null;
		}

		while (this.instances.length > 0)
		{
			this.instances[0].dispose();
		}

		super.dispose(doNotRecurse);
	}
	
	// Geometric tools
	public function convertToFlatShadedMesh():Void
	{
        /// <summary>Update normals and vertices to get a flat shading rendering.</summary>
        /// <summary>Warning: This may imply adding vertices to the mesh in order to get exactly 3 vertices per face</summary>

        var kinds:Array<String> = this.getVerticesDataKinds();
        var vbs:Map<String, VertexBuffer> = new Map();
        var data:Map<String, Array<Float>> = new Map();
        var newdata:Map<String, Array<Float>> = new Map();
        var updatableNormals:Bool = false;
		for (kindIndex in 0...kinds.length) 
		{
            var kind = kinds[kindIndex];
			var vertexBuffer = this.getVertexBuffer(kind);
            if (kind == VertexBuffer.NormalKind)
			{
                updatableNormals = vertexBuffer.isUpdatable();
                kinds.remove(kind);
                continue;
            }
			
			vbs.set(kind, vertexBuffer);
            data.set(kind, vbs.get(kind).getData());
            newdata.set(kind, []);
		}
		
        // Save previous submeshes
        var previousSubmeshes:Array<SubMesh> = this.subMeshes.slice(0);

        var indices:Array<Int> = this.getIndices();
		var totalIndices = this.getTotalIndices();
        // Generating unique vertices per face
        for (index in 0...totalIndices)
		{
            var vertexIndex:Int = indices[index];

            for (kindIndex in 0...kinds.length)
			{
                var kind = kinds[kindIndex];
                var stride = vbs.get(kind).getStrideSize();

                for (offset in 0...stride)
				{
                    newdata[kind].push(data[kind][vertexIndex * stride + offset]);
                }
            }
        }

        // Updating faces & normal
        var normals:Array<Float> = [];
        var positions = newdata[VertexBuffer.PositionKind];
		
		var normal:Vector3 = new Vector3();
		var index:Int = 0;
		while (index < indices.length)
		{
            indices[index] = index;
            indices[index + 1] = index + 1;
            indices[index + 2] = index + 2;

            var p1 = Vector3.FromArray(positions, index * 3);
            var p2 = Vector3.FromArray(positions, (index + 1) * 3);
            var p3 = Vector3.FromArray(positions, (index + 2) * 3);

            var p1p2 = p1.subtract(p2);
            var p3p2 = p3.subtract(p2);

			Vector3.CrossToRef(p1p2, p3p2, normal);
			normal.normalize();

            // Store same normals for every vertex
            for (localIndex in 0...3) 
			{
                normals.push(normal.x);
                normals.push(normal.y);
                normals.push(normal.z);
            }
			
			index += 3;
        }

        this.setIndices(indices);
        this.setVerticesData(VertexBuffer.NormalKind, normals, updatableNormals);

        // Updating vertex buffers
        for (kindIndex in 0...kinds.length)
		{
            var kind:String = kinds[kindIndex];
            this.setVerticesData(kind, newdata.get(kind), vbs.get(kind).isUpdatable());
        }

        // Updating submeshes
		this.releaseSubMeshes();
        for (submeshIndex in 0...previousSubmeshes.length)
		{
            var previousOne:SubMesh = previousSubmeshes[submeshIndex];
            var subMesh = new SubMesh(previousOne.materialIndex, previousOne.indexStart, previousOne.indexCount, previousOne.indexStart, previousOne.indexCount, this);
        }
		
		this.synchronizeInstances();
    }
	
	public function createInstance(name: String): InstancedMesh
	{
		return new InstancedMesh(name, this);
	}
	
	public function synchronizeInstances(): Void 
	{
		for (instanceIndex in 0...this.instances.length)
		{
			var instance = this.instances[instanceIndex];
			instance._syncSubMeshes();
		}
	}
}