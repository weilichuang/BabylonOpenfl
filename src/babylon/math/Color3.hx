package babylon.math;

class Color3
{
	public static inline function FromArray(array:Array<Float>):Color3
	{
		return new Color3(array[0], array[1], array[2]);
	}
	
	public static inline function FromInts(r:Float, g:Float, b:Float):Color3
	{
		return new Color3(r / 255.0, g / 255.0, b / 255.0);
	}
	
	public static function Lerp(start:Color3, end:Color3, amount:Float):Color3
	{
		var tr:Float = start.r + ((end.r - start.r) * amount);
		var tg:Float = start.g + ((end.g - start.g) * amount);
		var tb:Float = start.b + ((end.b - start.b) * amount);

		return new Color3(tr, tg, tb);
	}
	
	public static inline function Red(): Color3 { return new Color3(1, 0, 0); }
	public static inline function Green(): Color3 { return new Color3(0, 1, 0); }
	public static inline function Blue(): Color3 { return new Color3(0, 0, 1); }
	public static inline function Black(): Color3 { return new Color3(0, 0, 0); }
	public static inline function White(): Color3 { return new Color3(1, 1, 1); }
	public static inline function Purple(): Color3 { return new Color3(0.5, 0, 0.5); }
	public static inline function Magenta(): Color3 { return new Color3(1, 0, 1); }
	public static inline function Yellow(): Color3 { return new Color3(1, 1, 0); }
	public static inline function Gray(): Color3 { return new Color3(0.5, 0.5, 0.5); }
	
	public var r:Float;		
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 0, g:Float = 0, b:Float = 0) 
	{
		this.r = r;
        this.g = g;
        this.b = b;
	}

	public inline function equals(otherColor:Color3):Bool 
	{
		return this.r == otherColor.r && this.g == otherColor.g && this.b == otherColor.b;
	}
	
	public function toString():String 
	{
		return "{R: " + this.r + " G:" + this.g + " B:" + this.b + "}";
	}
	
	public inline function clone():Color3
	{
		return new Color3(this.r, this.g, this.b);
	}
	
    public inline function toArray(array:Array<Float>, offset:Int = 0):Void 
	{ 
        array[offset] = this.r;
        array[offset + 1] = this.g;
        array[offset + 2] = this.b;
    }
	
	public function toLuminance(): Float
	{
		return this.r * 0.3 + this.g * 0.59 + this.b * 0.11;
	}
	
	public inline function multiply(otherColor:Color3):Color3
	{
		return new Color3(this.r * otherColor.r, this.g * otherColor.g, this.b * otherColor.b);
	}
	
	public inline function multiplyToRef(otherColor:Color3, result:Color3):Void 
	{
		result.r = this.r * otherColor.r;
        result.g = this.g * otherColor.g;
        result.b = this.b * otherColor.b;
	}
	
	public inline function scale(scale:Float):Color3 
	{
		return new Color3(this.r * scale, this.g * scale, this.b * scale);
	}
	
	public inline function scaleToRef(scale:Float, result:Color3):Void  
	{
		result.r = this.r * scale;
        result.g = this.g * scale;
        result.b = this.b * scale;
	}
	
	public inline function add(otherColor:Color3):Color3 
	{
		return new Color3(this.r + otherColor.r, this.g + otherColor.g, this.b + otherColor.b);
	}
	
	public inline function addToRef(otherColor:Color3, result:Color3):Void  
	{
		result.r = this.r + otherColor.r;
        result.g = this.g + otherColor.g;
        result.b = this.b + otherColor.b;
	}
	
	public inline function subtract(otherColor:Color3):Color3 
	{
		return new Color3(this.r - otherColor.r, this.g - otherColor.g, this.b - otherColor.b);
	}
	
	public inline function subtractToRef(otherColor:Color3, result:Color3):Void  
	{
		result.r = this.r - otherColor.r;
        result.g = this.g - otherColor.g;
        result.b = this.b - otherColor.b;
	}
	
	public inline function copyFrom(source:Color3):Void  
	{
		this.r = source.r;
        this.g = source.g;
        this.b = source.b;
	}
	
	public inline function setTo(r:Float, g:Float, b:Float):Void 
	{
		this.r = r;
        this.g = g;
        this.b = b;
	}
}
