package babylon.animations;

import babylon.animations.Animation.BabylonFrame;
import babylon.math.Color3;
import babylon.math.Quaternion;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.utils.Logger;

typedef BabylonFrame = {
	frame: Int,
	value: Dynamic			// Vector3 or Quaternion or Matrix or Float or Color3
}

class Animation 
{
	
	public static inline var ANIMATIONTYPE_FLOAT:Int = 0;
	public static inline var ANIMATIONTYPE_VECTOR3:Int = 1;
	public static inline var ANIMATIONTYPE_QUATERNION:Int = 2;
	public static inline var ANIMATIONTYPE_MATRIX:Int = 3;
	public static inline var ANIMATIONTYPE_COLOR3:Int = 4;
	public static inline var ANIMATIONTYPE_VECTOR2:Int = 5;

	public static inline var ANIMATIONLOOPMODE_RELATIVE:Int = 0;
	public static inline var ANIMATIONLOOPMODE_CYCLE:Int = 1;
	public static inline var ANIMATIONLOOPMODE_CONSTANT:Int = 2;
	
	
	public var name:String;
	public var targetProperty:String;
	public var targetPropertyPath:Array<String>;
	public var framePerSecond:Int;
	public var dataType:Int;
	public var loopMode:Int;
	public var currentFrame:Float;
	
	private var _keys:Array<BabylonFrame>;		
	private var _offsetsCache:Map<String,Dynamic>;
	private var _highLimitsCache:Map<String,Dynamic>;
	
	private var _stopped:Bool = false;
		
	public var _target:Dynamic;
	
	private var _easingFunction:IEasingFunction;

	public function new(name:String, targetProperty:String, framePerSecond:Int, dataType:Int, 
						loopMode:Int = Animation.ANIMATIONLOOPMODE_CYCLE)
	{
		this.name = name;
        this.targetProperty = targetProperty;
        this.targetPropertyPath = targetProperty.split(".");
        this.framePerSecond = framePerSecond;
        this.dataType = dataType;
        this.loopMode = loopMode;

        this._keys = [];
	}
	
	public static function CreateAndStartAnimation(name: String, mesh: AbstractMesh, tartgetProperty: String,
													framePerSecond: Int, totalFrame: Int,
													from: Dynamic, to: Dynamic, loopMode:Int = Animation.ANIMATIONLOOPMODE_CYCLE) 
	{

		var dataType:Int = -1;

		if (Std.is(from,Float) && Math.isFinite(cast from))
		{
			dataType = Animation.ANIMATIONTYPE_FLOAT;
		}
		else if (Std.is(from,Quaternion))
		{
			dataType = Animation.ANIMATIONTYPE_QUATERNION;
		}
		else if (Std.is(from,Vector3)) 
		{
			dataType = Animation.ANIMATIONTYPE_VECTOR3;
		} 
		else if (Std.is(from,Vector2)) 
		{
			dataType = Animation.ANIMATIONTYPE_VECTOR2;
		} 
		else if (Std.is(from,Color3))
		{
			dataType = Animation.ANIMATIONTYPE_COLOR3;
		}

		if (dataType == -1)
		{
			return;
		}

		var animation = new Animation(name, tartgetProperty, framePerSecond, dataType, loopMode);

		var keys:Array<BabylonFrame> = [];
		keys.push({ frame: 0, value: from });
		keys.push({ frame: totalFrame, value: to });
		animation.setKeys(keys);

		mesh.animations.push(animation);

		mesh.getScene().beginAnimation(mesh, 0, totalFrame, (animation.loopMode == 1));

	}
	
	public function isStopped(): Bool
	{
		return this._stopped;
	}

	public function getKeys(): Array<BabylonFrame>
	{
		return this._keys;
	}

	public function getEasingFunction():IEasingFunction
	{
		return this._easingFunction;
	}

	public function setEasingFunction(easingFunction: IEasingFunction):Void
	{
		this._easingFunction = easingFunction;
	}
	
	private function _getKeyValue(value: Dynamic): Dynamic
	{
		if (Reflect.isFunction(value))
		{
			return value();
		}
		return value;
	}
	
	/**
	 * 如果Map存储类型使用Dynamic在cpp中会导致程序异常退出
	 * 为什么放到一个函数中就不异常退出了？
	 */
	private function initCacheMap():Void
	{
		this._offsetsCache = new Map<String,Dynamic>();
		this._highLimitsCache = new Map<String,Dynamic>();
		//switch (this.dataType) 
		//{
			//// Float
			//case Animation.ANIMATIONTYPE_FLOAT:
				//this._offsetsCache = new Map<String,Dynamic>();
				//this._highLimitsCache = new Map<String,Dynamic>();
			//// Quaternion
			//case Animation.ANIMATIONTYPE_QUATERNION:
				//this._offsetsCache = new Map<String,Dynamic>();
				//this._highLimitsCache = new Map<String,Dynamic>();
			//// Vector3
			//case Animation.ANIMATIONTYPE_VECTOR3:
				//this._offsetsCache = new Map<String,Dynamic>();
				//this._highLimitsCache = new Map<String,Dynamic>();
			//// Color3
			//case Animation.ANIMATIONTYPE_COLOR3:
				//this._offsetsCache = new Map<String,Dynamic>();
				//this._highLimitsCache = new Map<String,Dynamic>();
		//}
	}
	
	public inline function floatInterpolate(startValue:Float, endValue:Float, gradient:Float):Float 
	{
        return startValue + (endValue - startValue) * gradient;
    }
	
	public inline function quaternionInterpolate(startValue:Quaternion, endValue:Quaternion, gradient:Float):Quaternion
	{
        return Quaternion.Slerp(startValue, endValue, gradient);
    }
	
	public inline function vector3Interpolate(startValue:Vector3, endValue:Vector3, gradient:Float):Vector3 
	{
        return Vector3.Lerp(startValue, endValue, gradient);
    }
	
	public inline function vector2Interpolate(startValue:Vector2, endValue:Vector2, gradient:Float):Vector2 
	{
        return Vector2.Lerp(startValue, endValue, gradient);
    }
	
	public inline function color3Interpolate(startValue:Color3, endValue:Color3, gradient:Float):Color3 
	{
		return Color3.Lerp(startValue, endValue, gradient);
    }
	
	public function clone():Animation 
	{
        var clone = new Animation(this.name, this.targetPropertyPath.join("."), this.framePerSecond, this.dataType, this.loopMode);

        clone.setKeys(this._keys);

        return clone;
    }
	
	public function setKeys(values:Array<BabylonFrame>):Void
	{
        this._keys = values.slice(0);
        this.initCacheMap();
    }
	
	public function _interpolate(currentFrame:Float, repeatCount:Int, 
								loopMode:Int, 
								offsetValue:Dynamic = null,
								highLimitValue:Dynamic = null):Dynamic
	{
        if (loopMode == Animation.ANIMATIONLOOPMODE_CONSTANT && repeatCount > 0)
		{
			if (Std.is(highLimitValue, Float))
			{
				return highLimitValue;
			}
			else
			{
				return highLimitValue.clone();
			}
        }

        this.currentFrame = currentFrame;
		
        for (key in 0...(_keys.length - 1)) 
		{
			var frameInfo:BabylonFrame = _keys[key];
			var nextFrameInfo:BabylonFrame = _keys[key + 1];
			// for each frame, we need the key just before the frame superior
            if (nextFrameInfo.frame >= currentFrame)
			{
                var startValue:Dynamic = _getKeyValue(frameInfo.value);
                var endValue:Dynamic = _getKeyValue(nextFrameInfo.value);

				// gradient : percent of currentFrame between the frame inf and the frame sup
                var gradient:Float;
				if (nextFrameInfo.frame == frameInfo.frame)
				{
					gradient = 1;
				}
				else
				{
					gradient = (currentFrame - frameInfo.frame) / (nextFrameInfo.frame - frameInfo.frame);
				}
				
				// check for easingFunction and correction of gradient
				if (this._easingFunction != null) 
				{
					gradient = this._easingFunction.ease(gradient);
				}
				
                switch (dataType)
				{
                    // Float
                    case Animation.ANIMATIONTYPE_FLOAT:
                        switch (loopMode) 
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, Animation.ANIMATIONLOOPMODE_CONSTANT:
                                return floatInterpolate(cast startValue, cast endValue, gradient);                                
                            case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                return offsetValue * repeatCount + floatInterpolate(cast startValue, cast endValue, gradient);
                        }
                    // Quaternion
                    case Animation.ANIMATIONTYPE_QUATERNION:
                        var quaternion:Quaternion = null;
                        switch (loopMode) 
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, Animation.ANIMATIONLOOPMODE_CONSTANT:
                                quaternion = quaternionInterpolate(cast startValue, cast endValue, gradient);
                            case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                quaternion = quaternionInterpolate(cast startValue, cast endValue, gradient).add(offsetValue.scale(repeatCount));
                        }
                        return quaternion;
                    // Vector3
                    case Animation.ANIMATIONTYPE_VECTOR3:
                        switch (loopMode) 
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, Animation.ANIMATIONLOOPMODE_CONSTANT:
                                return vector3Interpolate(cast startValue, cast endValue, gradient);
                            case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                return vector3Interpolate(cast startValue, cast endValue, gradient).add(offsetValue.scale(repeatCount));
                        }
					//Vector2
					case Animation.ANIMATIONTYPE_VECTOR2:
                        switch (loopMode) 
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, Animation.ANIMATIONLOOPMODE_CONSTANT:
                                return vector2Interpolate(cast startValue, cast endValue, gradient);
                            case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                return vector2Interpolate(cast startValue, cast endValue, gradient).add(offsetValue.scale(repeatCount));
                        }
					//COLOR3
					case Animation.ANIMATIONTYPE_COLOR3:
                        switch (loopMode) 
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, Animation.ANIMATIONLOOPMODE_CONSTANT:
                                return color3Interpolate(cast startValue, cast endValue, gradient);
                            case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                return color3Interpolate(cast startValue, cast endValue, gradient).add(offsetValue.scale(repeatCount));
                        }
                    // Matrix
                    case Animation.ANIMATIONTYPE_MATRIX:
                        switch (loopMode)
						{
                            case Animation.ANIMATIONLOOPMODE_CYCLE, 
								Animation.ANIMATIONLOOPMODE_CONSTANT, 
								Animation.ANIMATIONLOOPMODE_RELATIVE:
                                return startValue.clone();
                        }
                }
            }
        }
		
        return _getKeyValue(_keys[_keys.length - 1].value);
    }
	
	private function getZeroValue(dataType:Int):Dynamic
	{
		switch (dataType) 
		{
			// Float
			case Animation.ANIMATIONTYPE_FLOAT:
				return 0;
			// Quaternion
			case Animation.ANIMATIONTYPE_QUATERNION:
				return new Quaternion(0, 0, 0, 1);
			// Vector3
			case Animation.ANIMATIONTYPE_VECTOR3:
				return new Vector3();
			// Vector2
			case Animation.ANIMATIONTYPE_VECTOR2:
				return new Vector2();
			// Color3
			case Animation.ANIMATIONTYPE_COLOR3:
				return new Color3();
			default:
				return null;
		}
	}
	
	public function animate(delay:Float, from:Float, to:Float, loop:Bool, speedRatio:Float):Bool
	{
        if (this.targetPropertyPath == null || this.targetPropertyPath.length < 1)
		{
            _stopped = true;
			return false;
        }
		
		if (_keys.length == 0)
		{
			_stopped = true;
			return false;
		}
		
		if (delay < 0)
			delay = 0;
   
		var returnValue:Bool = true;
		
		var firstFrame:BabylonFrame = _keys[0];
		var lastFrame:BabylonFrame = _keys[_keys.length - 1];
		
		// Adding a start key at frame 0 if missing
		if (firstFrame.frame != 0)
		{
			var newKey = {
				frame: 0,
				value: firstFrame.value
			};

			//this._keys.splice(0, 0, newKey);
			_keys.unshift(newKey);
		}

		// Check limits
		if (from < firstFrame.frame || from > lastFrame.frame) 
		{
			from = firstFrame.frame;
		}
		
		if (to < firstFrame.frame || to > lastFrame.frame)
		{
			to = lastFrame.frame;
		}
		
		// Compute ratio
		var range:Float = to - from;
		// ratio represents the frame delta between from and to
		var ratio:Float = delay * (this.framePerSecond * speedRatio) / 1000.0;
		
		var offsetValue = getZeroValue(this.dataType);
		var highLimitValue:Dynamic = null;

		// If we are out of range and not looping get back to caller
		if (ratio > range && !loop)
		{ 
			returnValue = false;
			highLimitValue = _getKeyValue(lastFrame.value);
		} 
		else 
		{
			// Get max value if required         
			if (this.loopMode != Animation.ANIMATIONLOOPMODE_CYCLE) 
			{
				var keyOffset:String = Std.string(to) + "_" + Std.string(from);
				if (!_offsetsCache.exists(keyOffset)) 
				{
					var fromValue:Dynamic = this._interpolate(from, 0, Animation.ANIMATIONLOOPMODE_CYCLE);
					var toValue:Dynamic = this._interpolate(to, 0, Animation.ANIMATIONLOOPMODE_CYCLE);
					switch (this.dataType) 
					{
						// Float
						case Animation.ANIMATIONTYPE_FLOAT:
							this._offsetsCache.set(keyOffset, toValue - fromValue);
						// Quaternion
						case Animation.ANIMATIONTYPE_QUATERNION:
							this._offsetsCache.set(keyOffset, cast(toValue, Quaternion).subtract(cast fromValue));
						// Vector3
						case Animation.ANIMATIONTYPE_VECTOR3:
							this._offsetsCache.set(keyOffset, cast(toValue, Vector3).subtract(cast fromValue));
						// Vector2
						case Animation.ANIMATIONTYPE_VECTOR2:
							this._offsetsCache.set(keyOffset,cast(toValue,Vector2).subtract(cast fromValue));
						// Color3
						case Animation.ANIMATIONTYPE_COLOR3:
							this._offsetsCache.set(keyOffset, cast(toValue, Color3).subtract(cast fromValue));
					}

					this._highLimitsCache.set(keyOffset, toValue);
				}

				highLimitValue = this._highLimitsCache.get(keyOffset);
				offsetValue = this._offsetsCache.get(keyOffset);
			}
		}

		// Compute value
		var repeatCount:Int = Std.int(ratio / range);  		
		var currentFrame = returnValue ? (from + ratio) % range : to;
		var currentValue = this._interpolate(currentFrame, repeatCount, this.loopMode, offsetValue, highLimitValue);
		
		// Set value
		if (this.targetPropertyPath.length > 1)
		{
			var property = Reflect.getProperty(_target, this.targetPropertyPath[0]);

			for (index in 1...(this.targetPropertyPath.length - 1))
			{
				property = Reflect.getProperty(property, this.targetPropertyPath[index]);
			}

			Reflect.setProperty(property, this.targetPropertyPath[this.targetPropertyPath.length - 1], currentValue);
		} 
		else 
		{
			Reflect.setProperty(_target, this.targetPropertyPath[0], currentValue);
		}
		
		//此处使用hasField判断时无效
		if (Reflect.field(_target, "markAsDirty") != null) 
		{
			_target.markAsDirty(this.targetProperty);
		}
		
		if (!returnValue)
		{
			_stopped = true;
		}

        return returnValue;
    }
	
}
