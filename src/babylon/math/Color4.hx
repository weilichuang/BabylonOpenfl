package babylon.math;

class Color4 
{
	public static inline function Lerp(left:Color4, right:Color4, amount:Float):Color4 
	{
		var result = new Color4(0, 0, 0, 0);
        return LerpToRef(left, right, amount, result);
	}
	
	public static inline function LerpToRef(left:Color4, right:Color4, amount:Float, result:Color4):Color4 
	{
		result.r = left.r + (right.r - left.r) * amount;
        result.g = left.g + (right.g - left.g) * amount;
        result.b = left.b + (right.b - left.b) * amount;
        result.a = left.a + (right.a - left.a) * amount;
		
		return result;
	}
	
	public static inline function FromArray(array:Array<Float>, offset:Int = 0):Color4 
	{
		return new Color4(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
	}	
	
	public static inline function FromInts(r: Float, g: Float, b: Float, a: Float):Color4 
	{
		return new Color4(r / 255.0, g / 255.0, b / 255.0, a / 255.0);
	}

	public var r:Float;		
	public var g:Float;
	public var b:Float;
	public var a:Float;

	public function new(r:Float, g:Float, b:Float, a:Float = 1.0) 
	{
		this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
	}
	
	public inline function copyFrom(source:Color4):Void  
	{
		this.r = source.r;
        this.g = source.g;
        this.b = source.b;
        this.a = source.a;
	}

	public inline function addInPlace(right:Color4):Void
	{
		this.r += right.r;
        this.g += right.g;
        this.b += right.b;
        this.a += right.a;
	}
	
    public inline function toArray(array:Array<Float>, offset:Int = 0):Void
	{
        array[offset] = this.r;
        array[offset + 1] = this.g;
        array[offset + 2] = this.b;
        array[offset + 3] = this.a;
    }
	
	public inline function add(right:Color4):Color4 
	{
		return new Color4(this.r + right.r, this.g + right.g, this.b + right.b, this.a + right.a);
	}
	
	public inline function subtract(right:Color4):Color4 
	{
		return new Color4(this.r - right.r, this.g - right.g, this.b - right.b, this.a - right.a);
	}
	
	public inline function subtractToRef(right:Color4, result:Color4):Color4
	{
		result.r = this.r - right.r;
        result.g = this.g - right.g;
        result.b = this.b - right.b;
        result.a = this.a - right.a;
		
		return result;
	}
	
	public inline function scale(scale:Float):Color4 
	{
		return new Color4(this.r * scale, this.g * scale, this.b * scale, this.a * scale);
	}
	
	public inline function scaleToRef(scale:Float, result:Color4):Color4
	{
		result.r = this.r * scale;
        result.g = this.g * scale;
        result.b = this.b * scale;
        result.a = this.a * scale;
		
		return result;
	}

	public function toString():String
	{
		return "{R: " + this.r + " G:" + this.g + " B:" + this.b + " A:" + this.a + "}";
	}
	
	public function clone():Color4 
	{
		return new Color4(this.r, this.g, this.b, this.a);
	}
}
