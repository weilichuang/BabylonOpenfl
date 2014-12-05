package babylon;
import babylon.math.Color3;

class FogInfo
{
	public static inline var FOGMODE_NONE:Int = 0;
	public static inline var FOGMODE_EXP:Int = 1;
	public static inline var FOGMODE_EXP2:Int = 2;
	public static inline var FOGMODE_LINEAR:Int = 3;
	
	public var fogMode:Int;
	public var fogColor:Color3;
	public var fogDensity:Float;
	public var fogStart:Float;
	public var fogEnd:Float;
	
	public function new() 
	{
		this.fogMode = FOGMODE_NONE;
        this.fogColor = new Color3(0.2, 0.2, 0.3);
        this.fogDensity = 0.1;
        this.fogStart = 0;
        this.fogEnd = 1000.0;
	}
}