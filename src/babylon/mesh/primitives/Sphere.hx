package babylon.mesh.primitives;

class Sphere extends Primitives
{
	public var segments: Int;
	public var diameter: Float;

	public function new(id: String, scene: Scene, 
						segments: Int = 32, diameter: Float = 1, 
						canBeRegenerated:Bool = false, mesh: Mesh = null)
	{
		this.segments = segments;
		this.diameter = diameter;

		super(id, scene, this._regenerateVertexData(), canBeRegenerated, mesh);
	}

	override public function _regenerateVertexData(): VertexData
	{
		return VertexData.CreateSphere(this.segments, this.diameter);
	}

	override public function copy(id: String): Geometry 
	{
		return new Sphere(id, this.getScene(), this.segments, this.diameter, this.canBeRegenerated(), null);
	}
	
}