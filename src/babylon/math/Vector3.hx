package babylon.math;
import babylon.tools.Tools;
import openfl.utils.Float32Array;

class Vector3
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	public function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public inline function setTo(x:Float, y:Float, z:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public inline function dot(other:Vector3):Float
	{
		return this.x * other.x + this.y * other.y + this.z * other.z;
	}

	public function toString():String
	{
		return "{X:" + this.x + " Y:" + this.y + " Z:" + this.z + "}";
	}
	
	public inline function asArray():Array<Float> 
	{
        var result = [];
        this.toArray(result, 0);
        return result;
    }
	
	public inline function toArray(array:Array<Float>, index:Int = 0):Array<Float> 
	{
		array[index] = this.x;
        array[index + 1] = this.y;
        array[index + 2] = this.z;
		return array;
	}

	public inline function addInPlace(otherVector:Vector3):Void 
	{
		this.x += otherVector.x;
		this.y += otherVector.y;
		this.z += otherVector.z;
	}
	
	public inline function add(otherVector:Vector3):Vector3 
	{
		return new Vector3(this.x + otherVector.x, this.y + otherVector.y, this.z + otherVector.z);
	}
	
	public inline function addToRef(otherVector:Vector3, result:Vector3):Vector3
	{
		result.x = this.x + otherVector.x;
        result.y = this.y + otherVector.y;
        result.z = this.z + otherVector.z;
		return result;
	}
	
	public inline function subtractInPlace(otherVector:Vector3):Void 
	{
		this.x -= otherVector.x;
		this.y -= otherVector.y;
		this.z -= otherVector.z;
	}
	
	public inline function subtract(otherVector:Vector3, result:Vector3 = null):Vector3 
	{
		if (result == null)
			result = new Vector3();
		result.x = this.x - otherVector.x;
		result.y = this.y - otherVector.y;
		result.z = this.z - otherVector.z;
		return result;
	}
	
	public inline function subtractToRef(otherVector:Vector3, result:Vector3):Void 
	{
		result.x = this.x - otherVector.x;
        result.y = this.y - otherVector.y;
        result.z = this.z - otherVector.z;
	}
	
	public inline function subtractFromFloats(x:Float, y:Float, z:Float):Vector3
	{
		return new Vector3(this.x - x, this.y - y, this.z - z);
	}
	
	public inline function subtractFromFloatsToRef(x:Float, y:Float, z:Float, result:Vector3) 
	{
		result.x = this.x - x;
        result.y = this.y - y;
        result.z = this.z - z;
	}
	
	public inline function negate():Vector3
	{
		return new Vector3( -this.x, -this.y, -this.z);
	}
	
	public inline function scaleInPlace(scale:Float):Void 
	{
		this.x *= scale;
        this.y *= scale;
        this.z *= scale;
	}
	
	public inline function scale(scale:Float):Vector3 
	{
		return new Vector3(this.x * scale, this.y * scale, this.z * scale);
	}
	
	public inline function scaleToRef(scale:Float, result:Vector3):Void  
	{
		result.x = this.x * scale;
        result.y = this.y * scale;
        result.z = this.z * scale;
	}
	
	public inline function equals(otherVector:Vector3):Bool 
	{
		return this.x == otherVector.x && this.y == otherVector.y && this.z == otherVector.z;
	}
	
	public function equalsWithEpsilon(otherVector: Vector3): Bool
	{
		return  FastMath.fabs(this.x - otherVector.x) < Engine.Epsilon &&
				FastMath.fabs(this.y - otherVector.y) < Engine.Epsilon &&
				FastMath.fabs(this.z - otherVector.z) < Engine.Epsilon;
	}
	
	public inline function equalsToFloats(x:Float, y:Float, z:Float):Bool 
	{
		return this.x == x && this.y == y && this.z == z;
	}
	
	public inline function multiplyInPlace(otherVector:Vector3):Void 
	{
		this.x *= otherVector.x;
        this.y *= otherVector.y;
        this.z *= otherVector.z;
	}
	
	public inline function multiply(otherVector:Vector3):Vector3 
	{
		return new Vector3(this.x * otherVector.x, this.y * otherVector.y, this.z * otherVector.z);
	}
	
	public inline function multiplyToRef(otherVector:Vector3, result:Vector3)
	{
		result.x = this.x * otherVector.x;
        result.y = this.y * otherVector.y;
        result.z = this.z * otherVector.z;
	}
	
	public inline function multiplyByFloats(x:Float, y:Float, z:Float):Vector3
	{
		return new Vector3(this.x * x, this.y * y, this.z * z);
	}
	
	public inline function divide(otherVector:Vector3):Vector3 
	{
		return new Vector3(this.x / otherVector.x, this.y / otherVector.y, this.z / otherVector.z);
	}
	
	public inline function divideToRef(otherVector:Vector3, result:Vector3):Void 
	{
		result.x = this.x / otherVector.x;
        result.y = this.y / otherVector.y;
        result.z = this.z / otherVector.z;
	}
	
	public inline function length():Float 
	{
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}
	
	public inline function lengthSquared():Float 
	{
		return (this.x * this.x + this.y * this.y + this.z * this.z);
	}
	
	public inline function normalize():Void  
	{
		var len = this.length();

        if (len != 0) 
		{
			var num = 1.0 / len;

			this.x *= num;
			this.y *= num;
			this.z *= num;
		}
	}
	
	public inline function clone():Vector3 
	{
		return new Vector3(this.x, this.y, this.z);
	}
	
	public inline function copyFrom(source:Vector3):Void  
	{
		this.x = source.x;
        this.y = source.y;
        this.z = source.z;
	}
	
	public function minimizeInPlace(other: Vector3): Void
	{
		if (other.x < this.x) this.x = other.x;
		if (other.y < this.y) this.y = other.y;
		if (other.z < this.z) this.z = other.z;
	}

	public function maximizeInPlace(other: Vector3): Void 
	{
		if (other.x > this.x) this.x = other.x;
		if (other.y > this.y) this.y = other.y;
		if (other.z > this.z) this.z = other.z;
	}
	
	public inline function distanceTo(value:Vector3):Float
	{
		var vx:Float = this.x - value.x;
        var vy:Float = this.y - value.y;
        var vz:Float = this.z - value.z;

		return Math.sqrt(vx * vx + vy * vy + vz * vz);
	}
	
	public inline function distanceSquaredTo(value:Vector3):Float
	{
		var vx:Float = this.x - value.x;
        var vy:Float = this.y - value.y;
        var vz:Float = this.z - value.z;

        return (vx * vx) + (vy * vy) + (vz * vz);
	}

	public static inline function FromArray(array:Array<Float>, offset:Int = 0):Vector3 
	{
        return new Vector3(array[offset], array[offset + 1], array[offset + 2]);
	}
	
	public static inline function FromArrayToRef(array: Dynamic , offset:Int = 0, result:Vector3):Void 
	{
		result.x = array[offset];
        result.y = array[offset + 1];
        result.z = array[offset + 2];
	}
	
	//public static inline function FromFloatsToRef(x:Float, y:Float, z:Float, result:Vector3):Void 
	//{
		//result.x = x;
        //result.y = y;
        //result.z = z;
	//}
	
	public static inline function Zero():Vector3 
	{
		return new Vector3(0.0, 0.0, 0.0);
	}
	
	public static inline function Up():Vector3 
	{
		return new Vector3(0, 1.0, 0);
	}
	
	public static inline function TransformCoordinates(vector:Vector3, transformation:Matrix):Vector3 
	{
		var result = new Vector3();

        Vector3.TransformCoordinatesToRef(vector, transformation, result);

        return result;
	}
	
	public static inline function TransformCoordinatesToRef(vector:Vector3, transformation:Matrix, result:Vector3):Void 
	{
		var vx = vector.x, vy = vector.y, vz = vector.z;
		var tm = transformation.m;
		
		var x = (vx * tm[0]) + (vy * tm[4]) + (vz * tm[8]) + tm[12];
        var y = (vx * tm[1]) + (vy * tm[5]) + (vz * tm[9]) + tm[13];
        var z = (vx * tm[2]) + (vy * tm[6]) + (vz * tm[10]) + tm[14];
        var w = (vx * tm[3]) + (vy * tm[7]) + (vz * tm[11]) + tm[15];
		
		var invW:Float = 1 / w;

        result.x = x * invW;
        result.y = y * invW;
        result.z = z * invW;
	}
	
	public static inline function TransformCoordinatesFromFloatsToRef(x:Float, y:Float, z:Float, transformation:Matrix, result:Vector3):Vector3
	{
		var tm = transformation.m;
		var rx = (x * tm[0]) + (y * tm[4]) + (z * tm[8]) + tm[12];
        var ry = (x * tm[1]) + (y * tm[5]) + (z * tm[9]) + tm[13];
        var rz = (x * tm[2]) + (y * tm[6]) + (z * tm[10]) + tm[14];
        var rw = (x * tm[3]) + (y * tm[7]) + (z * tm[11]) + tm[15];

        result.x = rx / rw;
        result.y = ry / rw;
        result.z = rz / rw;
		
		return result;
	}
	
	public static inline function TransformNormal(vector:Vector3, transformation:Matrix):Vector3
	{
		var result = Vector3.Zero();

        Vector3.TransformNormalToRef(vector, transformation, result);

        return result;
	}
	
	public static inline function TransformNormalToRef(vector:Vector3, transformation:Matrix, result:Vector3):Void
	{
		var tm = transformation.m;
		var vx:Float = vector.x; var vy:Float = vector.y; var vz:Float = vector.z;
		result.x = (vx * tm[0]) + (vy * tm[4]) + (vz * tm[8]);
        result.y = (vx * tm[1]) + (vy * tm[5]) + (vz * tm[9]);
        result.z = (vx * tm[2]) + (vy * tm[6]) + (vz * tm[10]);
	}
	
	public static inline function TransformNormalFromFloatsToRef(x:Float, y:Float, z:Float, transformation:Matrix, result:Vector3):Void 
	{
		var tm = transformation.m;
		result.x = (x * tm[0]) + (y * tm[4]) + (z * tm[8]);
        result.y = (x * tm[1]) + (y * tm[5]) + (z * tm[9]);
        result.z = (x * tm[2]) + (y * tm[6]) + (z * tm[10]);
	}
	

	public static inline function CatmullRom(value1:Vector3, value2:Vector3, value3:Vector3, value4:Vector3, amount:Float):Vector3 
	{
		var squared = amount * amount;
        var cubed = amount * squared;

        var x = 0.5 * ((((2.0 * value2.x) + ((-value1.x + value3.x) * amount)) +
                (((((2.0 * value1.x) - (5.0 * value2.x)) + (4.0 * value3.x)) - value4.x) * squared)) +
            ((((-value1.x + (3.0 * value2.x)) - (3.0 * value3.x)) + value4.x) * cubed));

        var y = 0.5 * ((((2.0 * value2.y) + ((-value1.y + value3.y) * amount)) +
                (((((2.0 * value1.y) - (5.0 * value2.y)) + (4.0 * value3.y)) - value4.y) * squared)) +
            ((((-value1.y + (3.0 * value2.y)) - (3.0 * value3.y)) + value4.y) * cubed));

        var z = 0.5 * ((((2.0 * value2.z) + ((-value1.z + value3.z) * amount)) +
                (((((2.0 * value1.z) - (5.0 * value2.z)) + (4.0 * value3.z)) - value4.z) * squared)) +
            ((((-value1.z + (3.0 * value2.z)) - (3.0 * value3.z)) + value4.z) * cubed));

        return new Vector3(x, y, z);
	}
	
	public static inline function Clamp(value:Vector3, min:Vector3, max:Vector3):Vector3 
	{
		var x = value.x;
        x = (x > max.x) ? max.x : x;
        x = (x < min.x) ? min.x : x;

        var y = value.y;
        y = (y > max.y) ? max.y : y;
        y = (y < min.y) ? min.y : y;

        var z = value.z;
        z = (z > max.z) ? max.z : z;
        z = (z < min.z) ? min.z : z;

        return new Vector3(x, y, z);
	}
	
	public static inline function Hermite(value1:Vector3, tangent1:Vector3, value2:Vector3, tangent2:Vector3, amount:Float):Vector3 
	{
		var squared = amount * amount;
        var cubed = amount * squared;
        var part1 = ((2.0 * cubed) - (3.0 * squared)) + 1.0;
        var part2 = (-2.0 * cubed) + (3.0 * squared);
        var part3 = (cubed - (2.0 * squared)) + amount;
        var part4 = cubed - squared;

        var x = (((value1.x * part1) + (value2.x * part2)) + (tangent1.x * part3)) + (tangent2.x * part4);
        var y = (((value1.y * part1) + (value2.y * part2)) + (tangent1.y * part3)) + (tangent2.y * part4);
        var z = (((value1.z * part1) + (value2.z * part2)) + (tangent1.z * part3)) + (tangent2.z * part4);

        return new Vector3(x, y, z);
	}
	
	public static inline function Lerp(start:Vector3, end:Vector3, amount:Float):Vector3 
	{
		var x = start.x + ((end.x - start.x) * amount);
        var y = start.y + ((end.y - start.y) * amount);
        var z = start.z + ((end.z - start.z) * amount);

        return new Vector3(x, y, z);
	}
	
	//public static inline function Dot(left:Vector3, right:Vector3):Float
	//{
		//return left.x * right.x + left.y * right.y + left.z * right.z;
	//}
	
	public static inline function Cross(left:Vector3, right:Vector3):Vector3
	{
		var result:Vector3 = new Vector3();
        Vector3.CrossToRef(left, right, result);
        return result;
	}
	
	public static inline function CrossToRef(left:Vector3, right:Vector3, result:Vector3):Vector3 
	{
		var lx:Float = left.x; var ly:Float = left.y; var lz:Float = left.z;
		var rx:Float = right.x; var ry:Float = right.y; var rz:Float = right.z;
		result.x = ly * rz - lz * ry;
        result.y = lz * rx - lx * rz;
        result.z = lx * ry - ly * rx;
		return result;
	}
	
	//public static inline function Normalize(vector:Vector3):Vector3 
	//{
		//var result = Vector3.Zero();
        //Vector3.NormalizeToRef(vector, result);
        //return result;
	//}
	
	//public static inline function NormalizeToRef(vector:Vector3, result:Vector3) 
	//{
		//result.copyFrom(vector);
        //result.normalize();
	//}
	
	public static inline function Project(vector:Vector3, world:Matrix, transform:Matrix, viewport:Viewport):Vector3
	{
		var cw = viewport.width;
        var ch = viewport.height;
        var cx = viewport.x;
        var cy = viewport.y;

        var viewportMatrix = Matrix.FromValues(
										cw / 2.0, 0, 0, 0,
									    0, -ch / 2.0, 0, 0,
										0, 0, 1, 0,
										cx + cw / 2.0, ch / 2.0 + cy, 0, 1);
        
        var finalMatrix = world.multiply(transform).multiply(viewportMatrix);

        return Vector3.TransformCoordinates(vector, finalMatrix);
	}
	
	public static function Unproject(source:Vector3, 
									viewportWidth:Float, viewportHeight:Float, 
									world:Matrix, view:Matrix, projection:Matrix):Vector3 
	{
		var matrix = world.multiply(view).multiply(projection);
        matrix.invert();
        source.x = source.x / viewportWidth * 2 - 1;
        source.y = -(source.y / viewportHeight * 2 - 1);
        var vector = Vector3.TransformCoordinates(source, matrix);
        var num = source.x * matrix.m[3] + source.y * matrix.m[7] + source.z * matrix.m[11] + matrix.m[15];

        if (Tools.WithinEpsilon(num, 1.0)) {
            vector = vector.scale(1.0 / num);
        }

        return vector;
	}	

	public static inline function Minimize(left:Vector3, right:Vector3):Vector3 
	{
		var x = (left.x < right.x) ? left.x : right.x;
        var y = (left.y < right.y) ? left.y : right.y;
        var z = (left.z < right.z) ? left.z : right.z;
        return new Vector3(x, y, z);
	}
	
	public static inline function Maximize(left:Vector3, right:Vector3):Vector3
	{
		var x = (left.x > right.x) ? left.x : right.x;
        var y = (left.y > right.y) ? left.y : right.y;
        var z = (left.z > right.z) ? left.z : right.z;
        return new Vector3(x, y, z);
	}
	
	//public static inline function Distance(value1:Vector3, value2:Vector3):Float
	//{
		//return Math.sqrt(Vector3.DistanceSquared(value1, value2));
	//}
	
	//public static inline function DistanceSquared(value1:Vector3, value2:Vector3):Float
	//{
		//var x = value1.x - value2.x;
        //var y = value1.y - value2.y;
        //var z = value1.z - value2.z;
//
        //return (x * x) + (y * y) + (z * z);
	//}
	
	public static function Center(value1: Vector3, value2: Vector3): Vector3
	{
		var center = value1.add(value2);
		center.scaleInPlace(0.5);
		return center;
	}
	
	public static function UnprojectFromTransform(source: Vector3, 
												viewportWidth: Float, 
												viewportHeight: Float, 
												world: Matrix, transform: Matrix): Vector3
	{
		var matrix = world.multiply(transform);
		matrix.invert();
		source.x = source.x / viewportWidth * 2 - 1;
		source.y = -(source.y / viewportHeight * 2 - 1);
		var vector = Vector3.TransformCoordinates(source, matrix);
		var num = source.x * matrix.m[3] + source.y * matrix.m[7] + source.z * matrix.m[11] + matrix.m[15];

		if (Tools.WithinEpsilon(num, 1.0))
		{
			vector = vector.scale(1.0 / num);
		}

		return vector;
	}
		
}
