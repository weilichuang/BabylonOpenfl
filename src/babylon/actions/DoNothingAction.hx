package babylon.actions;
import babylon.actions.ActionEvent;

/**
 * ...
 * @author 
 */
class DoNothingAction extends Action
{

	public function new(trigger:Int = ActionManager.NothingTrigger, 
						triggerParameter:Dynamic = null, 
						condition:Condition = null)
	{
		super(trigger, triggerParameter, condition);
		
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		super.execute(evt);
	}
	
}