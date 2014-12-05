package babylon.actions;

/**
 * ...
 * @author 
 */
class ExecuteCodeAction extends Action
{
	public var func:ActionEvent->Void;

	public function new(trigger:Int, triggerParameter:Dynamic = null,
						func:ActionEvent->Void,
						condition:Condition=null) 
	{
		super(trigger, triggerParameter, condition);
		this.func = func;
	}
	
	override public function _prepare():Void 
	{
		
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		this.func(evt);
	}
	
}