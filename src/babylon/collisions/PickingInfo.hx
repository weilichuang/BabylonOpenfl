package babylon.collisions;

import babylon.math.Vector2;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.math.Vector3;
import babylon.mesh.VertexBuffer;

class PickingInfo 
{
	public var hit:Bool = false;
    public var distance:Float;
    public var pickedPoint:Vector3;
    public var pickedMesh:AbstractMesh;
	
	public var bu:Float;
	public var bv:Float;
	public var faceId:Int;

	public function new()
	{
		this.hit = false;
		this.distance = 0;
		this.bu = 0;
		this.bv = 0;
		this.faceId = -1;
		this.pickedPoint = null;
		this.pickedMesh = null;
	}
	
	//TODO 优化
	public function getNormal(): Vector3 
	{
		if (this.pickedMesh == null || !this.pickedMesh.isVerticesDataPresent(VertexBuffer.NormalKind)) 
		{
			return null;
		}

		var indices:Array<Int> = this.pickedMesh.getIndices();
		var normals:Array<Float> = this.pickedMesh.getVerticesData(VertexBuffer.NormalKind);

		var normal0:Vector3 = Vector3.FromArray(normals, indices[this.faceId * 3] * 3);
		var normal1:Vector3 = Vector3.FromArray(normals, indices[this.faceId * 3 + 1] * 3);
		var normal2:Vector3 = Vector3.FromArray(normals, indices[this.faceId * 3 + 2] * 3);

		normal0 = normal0.scale(this.bu);
		normal1 = normal1.scale(this.bv);
		normal2 = normal2.scale(1.0 - this.bu - this.bv);

		return new Vector3(normal0.x + normal1.x + normal2.x, normal0.y + normal1.y + normal2.y, normal0.z + normal1.z + normal2.z);
	}

	public function getTextureCoordinates(): Vector2 
	{
		if (this.pickedMesh == null || !this.pickedMesh.isVerticesDataPresent(VertexBuffer.UVKind))
		{
			return null;
		}

		var indices = this.pickedMesh.getIndices();
		var uvs = this.pickedMesh.getVerticesData(VertexBuffer.UVKind);

		var uv0:Vector2 = Vector2.FromArray(uvs, indices[this.faceId * 3] * 2);
		var uv1:Vector2 = Vector2.FromArray(uvs, indices[this.faceId * 3 + 1] * 2);
		var uv2:Vector2 = Vector2.FromArray(uvs, indices[this.faceId * 3 + 2] * 2);

		uv0 = uv0.scale(this.bu);
		uv1 = uv1.scale(this.bv);
		uv2 = uv2.scale(1.0 - this.bu - this.bv);

		return new Vector2(uv0.x + uv1.x + uv2.x, uv0.y + uv1.y + uv2.y);
	}
}
