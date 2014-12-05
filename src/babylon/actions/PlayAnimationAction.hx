package babylon.actions;
import babylon.Scene;

/**
 * ...
 * @author 
 */
class PlayAnimationAction extends Action
{
	public var from:Float;
	public var to:Float;
	public var loop:Bool;
	private var _target:Dynamic;

	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic, from:Float, to:Float, loop:Bool = false,
						condition:Condition = null) 	
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
		this.from = from;
		this.to = to;
		this.loop = loop;
	}
	
	override public function _prepare():Void 
	{
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		var scene:Scene = this.actionManager.getScene();
		scene.beginAnimation(this._target, this.from, this.to, this.loop);
	}
}