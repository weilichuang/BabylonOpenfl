package babylon.mesh.primitives;

class Cylinder extends Primitives
{
	public var height: Float;
	public var diameterTop: Float;
	public var diameterBottom: Float;
	public var tessellation: Int;
	public var subdivisions: Int;

	public function new(id: String, scene: Scene,
						height: Float, 
						diameterTop: Float = 0.5, diameterBottom: Float = 1,
						tessellation: Int = 16,subdivisions: Int=1,
						canBeRegenerated:Bool = false, mesh: Mesh = null)
	{
		this.height = height;
		this.diameterTop = diameterTop;
		this.diameterBottom = diameterBottom;
		this.tessellation = tessellation;
		this.subdivisions = subdivisions;

		super(id, scene, this._regenerateVertexData(), canBeRegenerated, mesh);
	}

	override public function _regenerateVertexData(): VertexData
	{
		return VertexData.CreateCylinder(this.height, this.diameterTop, this.diameterBottom, this.tessellation,this.subdivisions);
	}

	override public function copy(id: String): Geometry
	{
		return new Cylinder(id, this.getScene(), 
							this.height, 
							this.diameterTop, this.diameterBottom, 
							this.tessellation, this.subdivisions,
							this.canBeRegenerated(), null);
	}
	
}