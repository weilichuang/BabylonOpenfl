package babylon.math;
import babylon.utils.MathUtils;

class Vector2 
{
	
	public var x:Float;
	public var y:Float;
		

	public function new(x:Float = 0, y:Float = 0) 
	{
		this.x = x;
		this.y = y;
	}
	
	public inline function setTo(x:Float, y:Float):Void
	{
		this.x = x;
		this.y = y;
	}
	
	public function multiplyInPlace(otherVector: Vector2): Void 
	{
		this.x *= otherVector.x;
		this.y *= otherVector.y;
	}

	public function multiply(otherVector: Vector2): Vector2 
	{
		return new Vector2(this.x * otherVector.x, this.y * otherVector.y);
	}

	public function multiplyToRef(otherVector: Vector2, result: Vector2): Void 
	{
		result.x = this.x * otherVector.x;
		result.y = this.y * otherVector.y;
	}

	public function multiplyByFloats(x: Float, y: Float): Vector2 
	{
		return new Vector2(this.x * x, this.y * y);
	}

	public function divide(otherVector: Vector2): Vector2
	{
		return new Vector2(this.x / otherVector.x, this.y / otherVector.y);
	}

	public function divideToRef(otherVector: Vector2, result: Vector2): Void
	{
		result.x = this.x / otherVector.x;
		result.y = this.y / otherVector.y;
	}
	
	public function toString():String 
	{
		return "{X: " + this.x + " Y:" + this.y + "}";
	}

	// Operators
    public inline function add(otherVector:Vector2):Vector2 
	{
		return new Vector2(this.x + otherVector.x, this.y + otherVector.y);
	}	
	
	public inline function asArray():Array<Float> 
	{
        var result = [];
        this.toArray(result, 0);
        return result;
    }
	
	public static function FromArray(array: Array<Float>, offset: Int = 0): Vector2 
	{
		return new Vector2(array[offset], array[offset + 1]);
	}

    public inline function toArray(array:Array<Float>, index:Int = 0)
	{
        array[index] = this.x;
        array[index + 1] = this.y;
    }
    
	public inline function subtract(otherVector:Vector2):Vector2 
	{
		return new Vector2(this.x - otherVector.x, this.y - otherVector.y);
	}
	
    public inline function negate():Vector2
	{
		return new Vector2( -this.x, -this.y);
	}
	
    public inline function scaleInPlace(scale:Float)
	{
		this.x *= scale;
		this.y *= scale;
	}
	
    public inline function scale(scale:Float):Vector2 
	{
		return new Vector2(this.x * scale, this.y * scale);
	}
	
    public inline function equals(otherVector:Vector2):Bool 
	{
		return this.x == otherVector.x && this.y == otherVector.y;
	}
	
    public inline function length():Float 
	{
		return Math.sqrt(this.x * this.x + this.y * this.y);
	}
	
    public inline function lengthSquared():Float 
	{
		return (this.x * this.x + this.y * this.y);
	}
	
    public inline function normalize() 
	{
		var len = length();

        if (len != 0) 
		{
			var num = 1.0 / len;

			this.x *= num;
			this.y *= num;
		}
	}
	
    public inline function clone():Vector2 
	{
		return new Vector2(this.x, this.y);
	}
	
	
	// Statics
    public static inline function Zero():Vector2
	{
		return new Vector2(0, 0);
	}
	
    public static inline function CatmullRom(value1:Vector2, value2:Vector2, value3:Vector2, value4:Vector2, amount:Float):Vector2 
	{
		var squared = amount * amount;
        var cubed = amount * squared;

        var x = 0.5 * ((((2.0 * value2.x) + ((-value1.x + value3.x) * amount)) +
                (((((2.0 * value1.x) - (5.0 * value2.x)) + (4.0 * value3.x)) - value4.x) * squared)) +
            ((((-value1.x + (3.0 * value2.x)) - (3.0 * value3.x)) + value4.x) * cubed));

        var y = 0.5 * ((((2.0 * value2.y) + ((-value1.y + value3.y) * amount)) +
                (((((2.0 * value1.y) - (5.0 * value2.y)) + (4.0 * value3.y)) - value4.y) * squared)) +
            ((((-value1.y + (3.0 * value2.y)) - (3.0 * value3.y)) + value4.y) * cubed));

        return new Vector2(x, y);
	}
	
    public static inline function Clamp(value:Vector2, min:Vector2, max:Vector2):Vector2
	{
		var vx = MathUtils.fclamp(value.x, min.x, max.x);
		var vy = MathUtils.fclamp(value.y, min.y, max.y);

        return new Vector2(vx, vy);
	}
	
    public static inline function Hermite(value1:Vector2, tangent1:Vector2, value2:Vector2, tangent2:Vector2, amount:Float):Vector2
	{
		var squared = amount * amount;
        var cubed = amount * squared;
        var part1 = ((2.0 * cubed) - (3.0 * squared)) + 1.0;
        var part2 = (-2.0 * cubed) + (3.0 * squared);
        var part3 = (cubed - (2.0 * squared)) + amount;
        var part4 = cubed - squared;

        var vx = (((value1.x * part1) + (value2.x * part2)) + (tangent1.x * part3)) + (tangent2.x * part4);
        var vy = (((value1.y * part1) + (value2.y * part2)) + (tangent1.y * part3)) + (tangent2.y * part4);

        return new Vector2(vx, vy);
	}
	
    public static inline function Lerp(start:Vector2, end:Vector2, amount:Float):Vector2 
	{
		var vx = start.x + ((end.x - start.x) * amount);
        var vy = start.y + ((end.y - start.y) * amount);

        return new Vector2(vx, vy);
	}
	
    public static inline function Dot(left:Vector2, right:Vector2):Float 
	{
		return left.x * right.x + left.y * right.y;
	}
	
    public static inline function Normalize(vector:Vector2):Vector2 
	{
		var newVector = vector.clone();
        newVector.normalize();
        return newVector;
	}
	
    public static inline function Minimize(left:Vector2, right:Vector2):Vector2 
	{
		var vx = (left.x < right.x) ? left.x : right.x;
        var vy = (left.y < right.y) ? left.y : right.y;

        return new Vector2(vx, vy);
	}
	
    public static inline function Maximize(left:Vector2, right:Vector2):Vector2
	{
		var vx = (left.x > right.x) ? left.x : right.x;
        var vy = (left.y > right.y) ? left.y : right.y;

        return new Vector2(vx, vy);
	}
	
    public static inline function Transform(vector:Vector2, transformation:Matrix):Vector2 
	{
		var vx = (vector.x * transformation.m[0]) + (vector.y * transformation.m[4]);
        var vy = (vector.x * transformation.m[1]) + (vector.y * transformation.m[5]);

        return new Vector2(vx, vy);
	}
	
    public static inline function Distance(value1:Vector2, value2:Vector2):Float 
	{
		var vx = value1.x - value2.x;
        var vy = value1.y - value2.y;
		return Math.sqrt(vx * vx + vy * vy);
	}
	
    public static inline function DistanceSquared(value1:Vector2, value2:Vector2):Float
	{
		var vx = value1.x - value2.x;
        var vy = value1.y - value2.y;

        return vx * vx + vy * vy;
	}
		
}
