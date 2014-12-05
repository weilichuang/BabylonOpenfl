package babylon.actions;

/**
 * ...
 * @author 
 */
class StopAnimationAction extends Action
{
	private var _target:Dynamic;


	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic,
						condition:Condition = null) 	
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
	}
	
	override public function _prepare():Void 
	{
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		var scene:Scene = this.actionManager.getScene();
		scene.stopAnimation(this._target);
	}
	
}