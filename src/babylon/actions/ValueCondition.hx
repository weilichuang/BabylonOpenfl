package babylon.actions;

class ValueCondition extends Condition
{
	public static inline var IsEqual:Int = 0;
	public static inline var IsDifferent:Int = 1;
	public static inline var IsGreater:Int = 2;
	public static inline var IsLesser:Int = 3;

	private var _target: Dynamic;
	private var _property: String;
	
	public var propertyPath:String;
	public var value:Dynamic;
	public var operator:Int;
		
	public function new(actionManager: ActionManager,target:Dynamic,propertyPath:String,value:Dynamic,operator:Int = ValueCondition.IsEqual) 
	{
		super(actionManager);
		
		this.propertyPath = propertyPath;
		this.value = value;
		this.operator = operator;
		
		this._target = this._getEffectiveTarget(target, this.propertyPath);
		this._property = this._getProperty(this.propertyPath);
	}
	
	override public function isValid(): Bool 
	{
		switch (this.operator) 
		{
			case ValueCondition.IsGreater:
				return Reflect.getProperty(this._target,this._property) > this.value;
			case ValueCondition.IsLesser:
				return Reflect.getProperty(this._target,this._property) < this.value;
			case ValueCondition.IsEqual,ValueCondition.IsDifferent:
				var check: Bool;

				if (Reflect.hasField(this.value,"equals"))
				{
					check = this.value.equals(Reflect.getProperty(this._target,this._property));
				} 
				else 
				{
					check = this.value == Reflect.getProperty(this._target,this._property);
				}
				return this.operator == ValueCondition.IsEqual ? check : !check;
		}

		return false;
	}
	
}