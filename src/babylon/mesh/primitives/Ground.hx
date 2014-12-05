package babylon.mesh.primitives;

class Ground extends Primitives
{
	public var width: Float;
	public var height: Float;
	public var subdivisions: Int;

	public function new(id: String, scene: Scene, 
						width: Float, height: Float, 
						subdivisions: Int, 
						canBeRegenerated:Bool = false, 
						mesh: Mesh = null)
	{
		this.width = width;
		this.height = height;
		this.subdivisions = subdivisions;

		super(id, scene, this._regenerateVertexData(), canBeRegenerated, mesh);
	}

	override public function _regenerateVertexData(): VertexData
	{
		return VertexData.CreateGround(this.width, this.height, this.subdivisions);
	}

	override public function copy(id: String): Geometry 
	{
		return new Ground(id, this.getScene(), this.width, this.height, this.subdivisions, this.canBeRegenerated(), null);
	}
	
}