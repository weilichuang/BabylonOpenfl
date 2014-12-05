package babylon.mesh.primitives;

import babylon.mesh.Mesh;
import babylon.mesh.VertexData;
import babylon.Scene;
/**
 * ...
 * @author 
 */
class TiledGround extends Primitives
{
	public var xmin: Float;
	public var zmin: Float;
	public var xmax: Float;
	public var zmax: Float;
	public var subdivisions: {w: Int, h: Int};
	public var precision:    {w: Int, h: Int};

	public function new(id:String, scene:Scene, 
						xmin: Float, zmin: Float, xmax: Float, zmax: Float, 
						subdivisions: {w: Int, h: Int}, 
						precision: {w: Int, h: Int}, 
						canBeRegenerated: Bool = false, mesh: Mesh = null) 
	{
		this.xmin = xmin;
		this.zmin = zmin;
		this.xmax = xmax;
		this.zmax = zmax;
		this.subdivisions  = subdivisions;
		this.precision     = precision;
				
		super(id, scene, this._regenerateVertexData(), canBeRegenerated, mesh);
	}
	
	override public function _regenerateVertexData(): VertexData
	{
		return VertexData.CreateTiledGround(this.xmin, this.zmin, this.xmax, this.zmax, this.subdivisions, this.precision);
	}

	override public function copy(id: String): Geometry 
	{
		return new TiledGround(id, this.getScene(), this.xmin, this.zmin, this.xmax, this.zmax, this.subdivisions, this.precision, this.canBeRegenerated(), null);
	}
	
}