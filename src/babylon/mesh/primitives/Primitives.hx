package babylon.mesh.primitives;
import babylon.mesh.Geometry;

class Primitives extends Geometry
{
	// Private 
	private var _beingRegenerated: Bool;
	private var _canBeRegenerated: Bool;

	public function new(id: String, scene: Scene, 
						vertexData: VertexData = null,
						canBeRegenerated:Bool = false, 
						mesh: Mesh = null) 
	{
		this._beingRegenerated = true;
		this._canBeRegenerated = canBeRegenerated;
		
		super(id, scene, vertexData, false, mesh); // updatable = false to be sure not to update vertices
		
		this._beingRegenerated = false;
	}

	public function canBeRegenerated(): Bool 
	{
		return this._canBeRegenerated;
	}

	public function regenerate(): Void
	{
		if (!this._canBeRegenerated)
		{
			return;
		}
		this._beingRegenerated = true;
		this.setAllVerticesData(this._regenerateVertexData(), false);
		this._beingRegenerated = false;
	}

	public function asNewGeometry(id: String): Geometry
	{
		return super.copy(id);
	}

	override public function setAllVerticesData(vertexData: VertexData, updatable:Bool = false): Void
	{
		if (!this._beingRegenerated)
		{
			return;
		}
		super.setAllVerticesData(vertexData, false);
	}

	override public function setVerticesData(kind:String, data:Array<Float>, updatable:Bool = false, stride:Int = 0):Void 
	{
		if (!this._beingRegenerated) 
		{
			return;
		}
		super.setVerticesData(kind, data, false, stride);
	}

	public function _regenerateVertexData(): VertexData 
	{
		return null;
	}

	override public function copy(id: String): Geometry 
	{
		return null;
	}
	
}