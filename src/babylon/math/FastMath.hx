package babylon.math;

/**
 * ...
 * 
 */
class FastMath
{
	
	public static inline var RADS_PER_DEG:Float = 0.01745329251994329508888888888889;
    public static inline var DEGS_PER_RAD:Float = 57.295779513082323110248951135514;
	
	/**
	 * Max value, signed integer.
	 */
	inline public static var INT32_MAX = 0x7fffffff;
	
	/**
	 * The largest representable number (single-precision IEEE-754).
	 */
	inline public static var FLOAT_MAX = 3.4028234663852886e+38;

	public static function max(values:Array<Float>):Float
	{
		var result:Float = values[0];
		for (i in 1...values.length)
		{
			if (values[i] > result)
			{
				result = values[i];
			}
		}
		
		return result;
	}
	
	public static function randomNumber(min:Float, max:Float):Float
	{
		return Math.random() * (max - min) + min;	
	}
	
	public static function getExponantOfTwo(value:Int, max:Int):Int
	{
        var count:Int = 1;

        do 
		{
            count *= 2;
        } while (count < value);

        if (count > max)
            count = max;

        return count;
    }

	public static inline function ToDegrees(angle: Float): Float
	{
		return angle * 180 / Math.PI;
	}

	public static inline function ToRadians(angle: Float): Float
	{
		return angle * Math.PI / 180;
	}
	
	public static inline function iabs(value:Int):Int
	{
		return value > 0 ? value : -value;
	}
	
	public static inline function fabs(value:Float):Float
	{
		return value > 0 ? value : -value;
	}
	
	public static inline function imax(v1:Int,v2:Int):Int
	{
		return v1 > v2 ? v1 : v2;
	}
	
	public static inline function imin(v1:Int,v2:Int):Int
	{
		return v1 < v2 ? v1 : v2;
	}
	
	public static inline function clamp(value:Float, min:Float = 0, max:Float = 1):Float
	{
		if (value < min)
		{
			return min;
		}
		else if (value > max)
		{
			return max;
		}
		else
		{
			return value;
		}
	}
	
	// Returns -1 when value is a negative number and
	// +1 when value is a positive number. 
	public static function Sign(value: Float): Float
	{
		if (value == 0 || Math.isNaN(value))
			return value;

		return value > 0 ? 1 : -1;
	}
}