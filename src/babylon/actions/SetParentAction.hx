package babylon.actions;
import babylon.math.Vector3;

/**
 * ...
 * @author 
 */
class SetParentAction extends Action
{
	private var _target:Dynamic;
	private var _parent:Dynamic;
	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic,parent:Dynamic,
						condition:Condition=null) 
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
		this._prepare = parent;
	}
	
	override public function _prepare():Void 
	{
		
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		if (this._target.parent == this._parent)
		{
			return;
		}
		
		var invertParentWorldMatrix = this._parent.getWorldMatrix().clone();
		invertParentWorldMatrix.invert();

		this._target.position = Vector3.TransformCoordinates(this._target.position, invertParentWorldMatrix);

		this._target.parent = this._parent;
	}
	
}