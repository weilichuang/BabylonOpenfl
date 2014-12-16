package babylon.utils;

/**
 * ...
 * @author 
 */
class MathUtils
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

	public function new() 
	{
		
	}
	
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
	
	public static inline function min(a:Int, b:Int):Int
	{
		return a <= b ? a : b;
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
	
	public static function fclamp(value:Float, min:Float, max:Float):Float
	{
		if (value <= min)
			return min;
		else if (value >= max)
			return max;
		else
			return value;
	}
	
	public static function clamp(value:Int, min:Int, max:Int):Int
	{
		if (value <= min)
			return min;
		else if (value >= max)
			return max;
		else
			return value;
	}
	
}