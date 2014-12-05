package babylon.mesh;

class InstancesBatch
{
	public var mustReturn:Bool = false;
	public var renderSelf:Array<Bool>;
	public var visibleInstances:Array<Array<InstancedMesh>>;

	public function new() 
	{
		this.renderSelf = new Array<Bool>();
		this.visibleInstances = new Array<Array<InstancedMesh>>();
	}
	
}