package babylon.actions;

class SetValueAction extends Action
{
	public var propertyPath:String;
	public var value:Dynamic;
	private var _target:Dynamic;
	private var _property:String;
	
	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic, propertyPath:String, value:Dynamic, 
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
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		Reflect.setProperty(this._target, this._property, this.value);
	}
	
}