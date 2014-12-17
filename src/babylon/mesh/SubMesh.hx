package babylon.mesh;

import babylon.collisions.Collider;
import babylon.collisions.IntersectionInfo;
import babylon.culling.BoundingInfo;
import babylon.Engine;
import babylon.materials.Material;
import babylon.materials.MultiMaterial;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.math.Ray;
import babylon.math.Vector3;
import babylon.mesh.BabylonGLBuffer;
import babylon.tools.Tools;

class SubMesh 
{
	public var materialIndex:Int;
	public var verticesStart:Int;
	public var verticesCount:Int;
	public var indexStart:Int;
	public var indexCount:Int;
	
	public var linesIndexCount:Int = 0;
	private var _linesIndexBuffer:BabylonGLBuffer;
	
	private var _mesh:AbstractMesh;
	private var _renderingMesh:Mesh;
	private var _boundingInfo:BoundingInfo;
	
	//collision
	public var _lastColliderWorldVertices:Array<Vector3>;
	public var _trianglePlanes:Array<Plane>;
	public var _lastColliderTransformMatrix:Matrix = new Matrix();
		
	public var _distanceToCamera:Float = 0;
	public var _alphaIndex:Int = 0;
	public var _renderId:Int = -1;
	
	public var _id:Int = -1;
	
	public function new(materialIndex:Int, 
						verticesStart:Int, verticesCount:Int, 
						indexStart:Int, indexCount:Int, 
						mesh:AbstractMesh,
						renderingMesh:Mesh = null,
						createBoundingBox:Bool = true ) 
	{
		this._mesh = mesh;
		this._renderingMesh = renderingMesh != null ? renderingMesh : Std.instance(mesh, Mesh);
        mesh.subMeshes.push(this);
		
		this._id = mesh.subMeshes.length - 1;
		
        this.materialIndex = materialIndex;
        this.verticesStart = verticesStart;
        this.verticesCount = verticesCount;
        this.indexStart = indexStart;
        this.indexCount = indexCount;

		if(createBoundingBox)
			this.refreshBoundingInfo();
	}
	
	public inline function getBoundingInfo():BoundingInfo 
	{
        return _boundingInfo;
    }
	
	public inline function getMesh():AbstractMesh
	{
        return _mesh;
    }
	
	public inline function getRenderingMesh():Mesh
	{
        return _renderingMesh;
    }
	
	public function getMaterial():Material
	{
        var rootMaterial:Material = this._mesh.material;

        if (rootMaterial != null && Std.is(rootMaterial, MultiMaterial)) 
		{
            return Std.instance(rootMaterial, MultiMaterial).getSubMaterial(this.materialIndex);
        }

        if (rootMaterial == null)
		{
            return this._mesh.getScene().defaultMaterial;
        }

        return rootMaterial;
    }
	
	public function refreshBoundingInfo():Void 
	{
        var data:Array<Float> = this._mesh.getVerticesData(VertexBuffer.PositionKind);

        if (data == null) 
		{
            this._boundingInfo = this._mesh._boundingInfo;
			return;
        }
		
		var indices:Array<Int> = this._renderingMesh.getIndices();
		
		var extend:BabylonMinMax;
		
		if (this.indexStart == 0 && this.indexCount == indices.length)
		{
			extend = Tools.ExtractMinAndMax(data, this.verticesStart, this.verticesCount);
		}
		else
		{
			extend = Tools.ExtractMinAndMaxIndexed(data, indices, this.indexStart, this.indexCount);
		}
		
		_boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
    }
	
	public inline function _checkCollision(collider:Collider):Bool 
	{
        return _boundingInfo._checkCollision(collider);
    }
	
	public inline function updateBoundingInfo(world:Matrix):Void
	{
		if (_boundingInfo == null)
			this.refreshBoundingInfo();
			
        _boundingInfo.update(world);
    }
	
	public inline function isInFrustrum(frustumPlanes:Array<Plane>):Bool
	{
        return _boundingInfo.isInFrustrum(frustumPlanes);
    }
	
	public inline function render():Void 
	{
        _renderingMesh.render(this);
    }
	
	public function getLinesIndexBuffer(indices:Array<Int>, engine:Engine):BabylonGLBuffer
	{
        if (_linesIndexBuffer == null)
		{
            var linesIndices:Array<Int> = [];

			var index:Int = this.indexStart;
			var total:Int = this.indexStart + this.indexCount;
			while (index < total) 
			{
                linesIndices.push(indices[index]);
				linesIndices.push(indices[index + 1]);
				
				linesIndices.push(indices[index + 1]);
				linesIndices.push(indices[index + 2]);
				
				linesIndices.push(indices[index + 2]);
				linesIndices.push(indices[index]);
				
				index += 3;
            }
			
            _linesIndexBuffer = engine.createIndexBuffer(linesIndices);
            linesIndexCount = linesIndices.length;
        }
        return _linesIndexBuffer;
    }
	
	public inline function canIntersects(ray:Ray):Bool 
	{
        return ray.intersectsBox(_boundingInfo.boundingBox);
    }
	
	public function intersects(ray:Ray, 
									positions:Array<Vector3>, 
									indices:Array<Int>, 
									fastCheck:Bool = false):IntersectionInfo
	{
        var intersectInfo: IntersectionInfo = null;

        // Triangles test
		var index:Int = this.indexStart;
		while (index < this.indexStart + this.indexCount)
		{
            var p0:Vector3 = positions[indices[index]];
            var p1:Vector3 = positions[indices[index + 1]];
            var p2:Vector3 = positions[indices[index + 2]];

            var currentIntersectInfo:IntersectionInfo = ray.intersectsTriangle(p0, p1, p2);

            if (currentIntersectInfo != null) 
			{
                if (fastCheck || intersectInfo == null || currentIntersectInfo.distance < intersectInfo.distance) 
				{
                    intersectInfo = currentIntersectInfo;
					intersectInfo.faceId = Std.int(index / 3);

                    if (fastCheck)
					{
                        break;
                    }
                }
            }
			
			index += 3;
        }

        return intersectInfo;
    }
	
	public function clone(newMesh:AbstractMesh, newRenderingMesh:Mesh = null):SubMesh 
	{
        var result:SubMesh = new SubMesh(this.materialIndex, 
										this.verticesStart, this.verticesCount, 
										this.indexStart, this.indexCount, 
										newMesh,newRenderingMesh,
										false);
							
		result._boundingInfo = new BoundingInfo(this._boundingInfo.minimum, this._boundingInfo.maximum);
		
		return result;
    }
	
	public function dispose():Void
	{
		if (_linesIndexBuffer != null)
		{
			_mesh.getScene().getEngine().releaseBuffer(this._linesIndexBuffer);
			_linesIndexBuffer = null;
		}
		
		// Remove from mesh
		var index = this._mesh.subMeshes.indexOf(this);
		this._mesh.subMeshes.splice(index, 1);
	}
	
	public static function CreateFromIndices(materialIndex:Int, 
											startIndex:Int,
											indexCount:Int,
											mesh: AbstractMesh,
											renderingMesh:Mesh = null):SubMesh 
	{
		if (renderingMesh == null)
			renderingMesh = Std.instance(mesh,Mesh);

        var indices:Array<Int> = renderingMesh.getIndices();
		
		var minVertexIndex:Int = indices[startIndex];
        var maxVertexIndex:Int = indices[startIndex];

        for (index in (startIndex + 1)...(startIndex + indexCount))
		{
            var vertexIndex = indices[index];

            if (vertexIndex < minVertexIndex)
                minVertexIndex = vertexIndex;
				
            if (vertexIndex > maxVertexIndex)
                maxVertexIndex = vertexIndex;
        }

        return new SubMesh(materialIndex, 
							minVertexIndex, 
							(maxVertexIndex - minVertexIndex) + 1, 
							startIndex, 
							indexCount, 
							mesh,
							renderingMesh);
    }
	
}
