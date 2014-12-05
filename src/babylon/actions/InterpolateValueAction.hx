package babylon.actions;
import babylon.animations.Animation;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.math.Quaternion;
import babylon.math.Vector3;
import babylon.Scene;
import babylon.utils.Logger;

class InterpolateValueAction extends Action
{
	public var propertyPath:String;
	public var value:Dynamic;
	public var duration:Float;
	public var stopOtherAnimations:Bool;
	private var _target:Dynamic;
	private var _property:String;

	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						target:Dynamic, propertyPath:String, 
						value:Dynamic, duration:Float = 1000,
						condition:Condition = null,
						stopOtherAnimations:Bool = false)
	{
		super(trigger, triggerParameter, condition);
		this._target = target;
		this.propertyPath = propertyPath;
		this.value = value;
		this.duration = duration;
		this.stopOtherAnimations = stopOtherAnimations;
	}
	
	override public function _prepare():Void 
	{
		this._target = this._getEffectiveTarget(this._target, this.propertyPath);
		this._property = this._getProperty(this.propertyPath);
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		var scene:Scene = this.actionManager.getScene();
		var keys = [
			{
				frame: 0,
				value: Reflect.getProperty(this._target, this._property)
			}, 
			{
				frame: 100,
				value: this.value
			}
		];

		var dataType: Int;

		if (Std.is(this.value, Float))
		{
			dataType = Animation.ANIMATIONTYPE_FLOAT;
		} 
		else if (Std.is(this.value, Color3)) 
		{
			dataType = Animation.ANIMATIONTYPE_COLOR3;
		} 
		else if (Std.is(this.value, Vector3))
		{
			dataType = Animation.ANIMATIONTYPE_VECTOR3;
		} 
		else if (Std.is(this.value, Matrix))
		{
			dataType = Animation.ANIMATIONTYPE_MATRIX;
		} 
		else if (Std.is(this.value, Quaternion))
		{
			dataType = Animation.ANIMATIONTYPE_QUATERNION;
		} 
		else 
		{
			Logger.log("InterpolateValueAction: Unsupported type (" + this.value + ")");
			return;
		}
		
		var animation = new Animation("InterpolateValueAction", this._property, Std.int(100 * (1000.0 / this.duration)), dataType, Animation.ANIMATIONLOOPMODE_CONSTANT);

		animation.setKeys(keys);

		if (this.stopOtherAnimations)
		{
			scene.stopAnimation(this._target);
		}

		scene.beginDirectAnimation(this._target, [animation], 0, 100);
	}
}