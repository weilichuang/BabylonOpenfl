package babylon.math;
import openfl.utils.Float32Array;

class Vector4
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) 
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public function toString(): String 
	{
		return "{X: " + this.x + " Y:" + this.y + " Z:" + this.z + "W:" + this.w + "}";
	}

	// Operators
	public function asArray(): Array<Float>
	{
		var result = [];

		this.toArray(result, 0);

		return result;
	}

	public function toArray(array: Array<Float>, index: Int = 0): Void
	{
		array[index] = this.x;
		array[index + 1] = this.y;
		array[index + 2] = this.z;
		array[index + 3] = this.w;
	}

	public function addInPlace(otherVector: Vector4): Void
	{
		this.x += otherVector.x;
		this.y += otherVector.y;
		this.z += otherVector.z;
		this.w += otherVector.w;
	}

	public function add(otherVector: Vector4): Vector4 
	{
		return new Vector4(this.x + otherVector.x, 
						this.y + otherVector.y, 
						this.z + otherVector.z, 
						this.w + otherVector.w);
	}

	public function addToRef(otherVector: Vector4, result: Vector4): Void
	{
		result.x = this.x + otherVector.x;
		result.y = this.y + otherVector.y;
		result.z = this.z + otherVector.z;
		result.w = this.w + otherVector.w;
	}

	public function subtractInPlace(otherVector: Vector4): Void
	{
		this.x -= otherVector.x;
		this.y -= otherVector.y;
		this.z -= otherVector.z;
		this.w -= otherVector.w;
	}

	public function subtract(otherVector: Vector4): Vector4
	{
		return new Vector4(this.x - otherVector.x, this.y - otherVector.y, this.z - otherVector.z, this.w - otherVector.w);
	}

	public function subtractToRef(otherVector: Vector4, result: Vector4): Void 
	{
		result.x = this.x - otherVector.x;
		result.y = this.y - otherVector.y;
		result.z = this.z - otherVector.z;
		result.w = this.w - otherVector.w;
	}

	public function subtractFromFloats(x: Float, y: Float, z: Float, w: Float): Vector4
	{
		return new Vector4(this.x - x, this.y - y, this.z - z, this.w - w);
	}

	public function subtractFromFloatsToRef(x: Float, y: Float, z: Float, w: Float, result: Vector4): Void
	{
		result.x = this.x - x;
		result.y = this.y - y;
		result.z = this.z - z;
		result.w = this.w - w;
	}

	public function negate(): Vector4
	{
		return new Vector4(-this.x, -this.y, -this.z, -this.w);
	}

	public function scaleInPlace(scale: Float): Vector4
	{
		this.x *= scale;
		this.y *= scale;
		this.z *= scale;
		this.w *= scale;
		return this;
	}

	public function scale(scale: Float): Vector4 
	{
		return new Vector4(this.x * scale, this.y * scale, this.z * scale, this.w * scale);
	}

	public function scaleToRef(scale: Float, result: Vector4) 
	{
		result.x = this.x * scale;
		result.y = this.y * scale;
		result.z = this.z * scale;
		result.w = this.w * scale;
	}

	public function equals(otherVector: Vector4): Bool 
	{
		return otherVector != null && this.x == otherVector.x && this.y == otherVector.y && this.z == otherVector.z && this.w == otherVector.w;
	}

	public function equalsWithEpsilon(otherVector: Vector4): Bool
	{
		return FastMath.fabs(this.x - otherVector.x) < Engine.Epsilon &&
			FastMath.fabs(this.y - otherVector.y) < Engine.Epsilon &&
			FastMath.fabs(this.z - otherVector.z) < Engine.Epsilon &&
			FastMath.fabs(this.w - otherVector.w) < Engine.Epsilon;
	}

	public function equalsToFloats(x: Float, y: Float, z: Float, w: Float): Bool 
	{
		return this.x == x && this.y == y && this.z == z && this.w == w;
	}

	public function multiplyInPlace(otherVector: Vector4): Void
	{
		this.x *= otherVector.x;
		this.y *= otherVector.y;
		this.z *= otherVector.z;
		this.w *= otherVector.w;
	}

	public function multiply(otherVector: Vector4): Vector4 
	{
		return new Vector4(this.x * otherVector.x, this.y * otherVector.y, this.z * otherVector.z, this.w * otherVector.w);
	}

	public function multiplyToRef(otherVector: Vector4, result: Vector4): Void
	{
		result.x = this.x * otherVector.x;
		result.y = this.y * otherVector.y;
		result.z = this.z * otherVector.z;
		result.w = this.w * otherVector.w;
	}

	public function multiplyByFloats(x: Float, y: Float, z: Float, w: Float): Vector4 
	{
		return new Vector4(this.x * x, this.y * y, this.z * z, this.w * w);
	}

	public function divide(otherVector: Vector4): Vector4
	{
		return new Vector4(this.x / otherVector.x, this.y / otherVector.y, this.z / otherVector.z, this.w / otherVector.w);
	}

	public function divideToRef(otherVector: Vector4, result: Vector4): Void 
	{
		result.x = this.x / otherVector.x;
		result.y = this.y / otherVector.y;
		result.z = this.z / otherVector.z;
		result.w = this.w / otherVector.w;
	}

	public function MinimizeInPlace(other: Vector4): Void 
	{
		if (other.x < this.x) this.x = other.x;
		if (other.y < this.y) this.y = other.y;
		if (other.z < this.z) this.z = other.z;
		if (other.w < this.w) this.w = other.w;
	}

	public function MaximizeInPlace(other: Vector4): Void 
	{
		if (other.x > this.x) this.x = other.x;
		if (other.y > this.y) this.y = other.y;
		if (other.z > this.z) this.z = other.z;
		if (other.w > this.w) this.w = other.w;
	}

	// Properties
	public function length(): Float
	{
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
	}

	public function lengthSquared(): Float
	{
		return (this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
	}

	// Methods
	public function normalize(): Vector4 
	{
		var len = this.length();

		if (len == 0)
			return this;

		var num = 1.0 / len;

		this.x *= num;
		this.y *= num;
		this.z *= num;
		this.w *= num;

		return this;
	}

	public function clone(): Vector4 
	{
		return new Vector4(this.x, this.y, this.z, this.w);
	}

	public function copyFrom(source: Vector4): Void
	{
		this.x = source.x;
		this.y = source.y;
		this.z = source.z;
		this.w = source.w;
	}

	public function copyFromFloats(x: Float, y: Float, z: Float, w: Float): Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	// Statics
	public static function FromArray(array: Array<Float>, offset: Int = 0): Vector4 
	{
		return new Vector4(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
	}

	public static function FromArrayToRef(array: Array<Float>, offset: Int, result: Vector4): Void
	{
		result.x = array[offset];
		result.y = array[offset + 1];
		result.z = array[offset + 2];
		result.w = array[offset + 3];
	}

	public static function FromFloatArrayToRef(array: Float32Array, offset: Int, result: Vector4): Void 
	{
		result.x = array[offset];
		result.y = array[offset + 1];
		result.z = array[offset + 2];
		result.w = array[offset + 3];
	}

	public static function FromFloatsToRef(x: Float, y: Float, z: Float, w: Float, result: Vector4): Void
	{
		result.x = x;
		result.y = y;
		result.z = z;
		result.w = w;
	}

	public static function Zero(): Vector4 
	{
		return new Vector4(0, 0, 0, 0);
	}

	public static function Normalize(vector: Vector4): Vector4 
	{
		var result = Vector4.Zero();
		Vector4.NormalizeToRef(vector, result);
		return result;
	}

	public static function NormalizeToRef(vector: Vector4, result: Vector4): Void
	{
		result.copyFrom(vector);
		result.normalize();
	}

	public static function Minimize(left: Vector4, right: Vector4): Vector4
	{
		var min = left.clone();
		min.MinimizeInPlace(right);
		return min;
	}

	public static function Maximize(left: Vector4, right: Vector4): Vector4
	{
		var max = left.clone();
		max.MaximizeInPlace(right);
		return max;
	}

	public static function Distance(value1: Vector4, value2: Vector4): Float 
	{
		return Math.sqrt(Vector4.DistanceSquared(value1, value2));
	}

	public static function DistanceSquared(value1: Vector4, value2: Vector4): Float
	{
		var x = value1.x - value2.x;
		var y = value1.y - value2.y;
		var z = value1.z - value2.z;
		var w = value1.w - value2.w;

		return (x * x) + (y * y) + (z * z) + (w * w);
	}

	public static function Center(value1: Vector4, value2: Vector4): Vector4 
	{
		var center = value1.add(value2);
		center.scaleInPlace(0.5);
		return center;
	}
}