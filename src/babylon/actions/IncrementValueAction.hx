package babylon.actions;
import babylon.utils.Logger;

class IncrementValueAction extends Action
{
	public var propertyPath:String;
	public var value:Dynamic;
	private var _target:Dynamic;
	private var _property:String;

	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic, propertyPath:String, value:Float, 
						condition:Condition = null) 
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
		this.propertyPath = propertyPath;
		this.value = value;
	}
	
	override public function _prepare():Void 
	{
		this._target = this._getEffectiveTarget(this._target, this.propertyPath);
		this._property = this._getProperty(this.propertyPath);
		
		var curValue = Reflect.getProperty(this._target, this._property);
		if (!Std.is(curValue, Float))
		{
			Logger.log("Warning: IncrementValueAction can only be used with number values");
		}
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		var curValue = Reflect.getProperty(this._target, this._property);
		Reflect.setProperty(this._target, this._property, curValue + this.value);
	}
	
}