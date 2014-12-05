package babylon.actions;
import babylon.actions.ActionEvent;

class SwitchBooleanAction extends Action
{
	public var propertyPath:String;
	private var _target: Dynamic;
	private var _property: String;

	public function new(trigger:Int, triggerParameter:Dynamic = null, target:Dynamic,propertyPath:String,condition:Condition = null)
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
		this.propertyPath = propertyPath;
	}
	
	override public function _prepare():Void 
	{
		this._target = this._getEffectiveTarget(this._target, this.propertyPath);
		this._property = this._getProperty(this.propertyPath);
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		Reflect.setProperty(this._target, this._property, !Reflect.getProperty(this._target, this._property));
	}
	
}