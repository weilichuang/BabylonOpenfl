package babylon.math;

/**
 * ...
 * @author weilichuang
 */
class FastMath
{

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
}