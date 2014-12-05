package babylon.actions;

class StateCondition extends Condition
{
	private var _target: Dynamic;
	
	public var value:String;

	public function new(actionManager:ActionManager,target:Dynamic,value:String) 
	{
		super(actionManager);
		
		this._target = target;
		this.value = value;
	}
	
	
	override public function isValid():Bool
	{
		return _target.state == this.value;
	}
}