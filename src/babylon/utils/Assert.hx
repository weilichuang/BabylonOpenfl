package babylon.utils;

class Assert
{
	/**
	 * 
	 * @param	condition 为false时报错
	 * @param	info
	 */
	public static inline function assert(condition:Bool, info:String):Void
	{
		#if debug
			if (!condition)
				throw info;
		#end
	}
}


