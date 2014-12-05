package babylon.mesh.primitives;

class TorusKnot extends Primitives
{
	public var radius: Float;
	public var tube: Float;
	public var radialSegments: Int;
	public var tubularSegments: Int;
	public var p: Float;
	public var q: Float;

	public function new(id: String, scene: Scene, 
						radius: Float = 2, tube: Float = 0.5, 
						radialSegments: Int = 32, tubularSegments: Int = 32, 
						p: Float = 2, q: Float = 3, 
						canBeRegenerated:Bool = false, 
						mesh: Mesh = null) 
	{
		this.radius = radius;
		this.tube = tube;
		this.radialSegments = radialSegments;
		this.tubularSegments = tubularSegments;
		this.p = p;
		this.q = q;

		super(id, scene, this._regenerateVertexData(), canBeRegenerated, mesh);
	}

	override public function _regenerateVertexData(): VertexData
	{
		return VertexData.CreateTorusKnot(this.radius, this.tube, this.radialSegments, this.tubularSegments, this.p, this.q);
	}

	override public function copy(id: String): Geometry {
		return new TorusKnot(id, this.getScene(), this.radius, this.tube, this.radialSegments, this.tubularSegments, this.p, this.q, this.canBeRegenerated(), null);
	}
	
}