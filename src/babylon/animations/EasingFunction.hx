package babylon.animations;
import babylon.math.BezierCurve;
import babylon.math.FastMath;

/**
 * ...
 * 
 */
class EasingFunction implements IEasingFunction
{
	public static inline var EASINGMODE_EASEIN:Int = 0;
	public static inline var EASINGMODE_EASEOUT:Int = 1;
	public static inline var EASINGMODE_EASEINOUT:Int = 2;
	
	private var _easingMode:Int = EASINGMODE_EASEIN;

	public function new() 
	{
		
	}
	
	public function setEasingMode(easingMode:Int):Void
	{
		var n:Int = Std.int(Math.min(Math.max(easingMode, 0), 2));
		this._easingMode = n;
	}
	
	public function getEasingMode():Int
	{
		return _easingMode;
	}
	
	public function easeInCore(gradient:Float):Float
	{
		return 0;
	}
	
	/* INTERFACE babylon.animations.IEasingFunction */
	
	public function ease(gradient:Float):Float 
	{
		switch (this._easingMode) 
		{
			case EASINGMODE_EASEIN:
				return this.easeInCore(gradient);
			case EASINGMODE_EASEOUT:
				return (1 - this.easeInCore(1 - gradient));
		}

		if (gradient >= 0.5)
		{
			return (((1 - this.easeInCore((1 - gradient) * 2)) * 0.5) + 0.5);
		}

		return (this.easeInCore(gradient * 2) * 0.5);
	}
	
}

class CircleEase extends EasingFunction implements IEasingFunction
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		gradient = Math.max(0, Math.min(1, gradient));
		return (1.0 - Math.sqrt(1.0 - (gradient * gradient)));
	}
}

class BackEase extends EasingFunction implements IEasingFunction
{
	public var amplitude:Float;
	public function new(amplitude:Float = 1)
	{
		super();
		this.amplitude = amplitude;
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		var num = Math.max(0, this.amplitude);
		return (Math.pow(gradient, 3.0) - ((gradient * num) * Math.sin(3.1415926535897931 * gradient)));
	}
}

class BounceEase extends EasingFunction implements IEasingFunction
{
	public var bounces:Float;
	public var bounciness:Float;
	public function new(bounces:Float = 3, bounciness:Float = 2)
	{
		super();
		this.bounces = bounces;
		this.bounciness = bounciness;
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		var y = Math.max(0.0, this.bounces);
		var bounciness = this.bounciness;
		if (bounciness <= 1.0) {
			bounciness = 1.001;
		}
		var num9 = Math.pow(bounciness, y);
		var num5 = 1.0 - bounciness;
		var num4 = ((1.0 - num9) / num5) + (num9 * 0.5);
		var num15 = gradient * num4;
		var num65 = Math.log((-num15 * (1.0 - bounciness)) + 1.0) / Math.log(bounciness);
		var num3 = Math.floor(num65);
		var num13 = num3 + 1.0;
		var num8 = (1.0 - Math.pow(bounciness, num3)) / (num5 * num4);
		var num12 = (1.0 - Math.pow(bounciness, num13)) / (num5 * num4);
		var num7 = (num8 + num12) * 0.5;
		var num6 = gradient - num7;
		var num2 = num7 - num8;
		return (((-Math.pow(1.0 / bounciness, y - num3) / (num2 * num2)) * (num6 - num2)) * (num6 + num2));
	}
}

class CubicEase extends EasingFunction implements IEasingFunction
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		return (gradient * gradient * gradient);
	}
}

class ElasticEase extends EasingFunction implements IEasingFunction
{
	public var oscillations:Float;
	public var springiness:Float;
	public function new(oscillations: Float = 3, springiness: Float = 3)
	{
		super();
		
		this.oscillations = oscillations;
		this.springiness = springiness;
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		var num2;
		var num3 = Math.max(0.0, this.oscillations);
		var num = Math.max(0.0, this.springiness);

		if (num == 0)
		{
			num2 = gradient;
		}
		else
		{
			num2 = (Math.exp(num * gradient) - 1.0) / (Math.exp(num) - 1.0);
		}
		return (num2 * Math.sin(((6.2831853071795862 * num3) + 1.5707963267948966) * gradient));
	}
}

class ExponentialEase extends EasingFunction implements IEasingFunction
{
	public var exponent:Float;
	public function new(exponent:Float = 2)
	{
		super();
		this.exponent = exponent;
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		if (this.exponent <= 0) {
			return gradient;
		}

		return ((Math.exp(this.exponent * gradient) - 1.0) / (Math.exp(this.exponent) - 1.0));
	}
}

class PowerEase extends EasingFunction implements IEasingFunction
{
	public var power:Float;
	
	public function new(power:Float = 2)
	{
		super();
		
		this.power = power;
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		var y = Math.max(0.0, this.power);
		return Math.pow(gradient, y);
	}
}

class QuadraticEase extends EasingFunction implements IEasingFunction
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		return (gradient * gradient);
	}
}

class QuarticEase extends EasingFunction implements IEasingFunction 
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		return (gradient * gradient * gradient * gradient);
	}
}

class QuinticEase extends EasingFunction implements IEasingFunction 
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		return (gradient * gradient * gradient * gradient * gradient);
	}
}

class SineEase extends EasingFunction implements IEasingFunction 
{
	public function new()
	{
		super();
	}
	
	override public function easeInCore(gradient:Float):Float
	{
		return (1.0 - Math.sin(1.5707963267948966 * (1.0 - gradient)));
	}
}

class BezierCurveEase extends EasingFunction implements IEasingFunction
{
	public var x1:Float;
	public var y1:Float;
	public var x2:Float;
	public var y2:Float;
	
	public function new(x1: Float = 0, y1: Float = 0, x2: Float = 1, y2: Float = 1)
	{
		super();
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
	}

	override public function easeInCore(gradient:Float):Float
	{
		return BezierCurve.interpolate(gradient, this.x1, this.y1, this.x2, this.y2);
	}
}


