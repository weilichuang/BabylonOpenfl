package babylon.actions;
import babylon.actions.ActionEvent;

class SetStateAction extends Action
{
	public var value:String;
	
	private var _target:Dynamic;
	
	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic, value:String, condition:Condition = null)
	{
		super(trigger, triggerParameter, condition);
		this.value = value;
		this._target = target;
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		super.execute(evt);
		this._target.state = this.value;
	}
	
}