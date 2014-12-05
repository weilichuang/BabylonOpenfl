package babylon.math;

/**
 * ...
 * @author weilichuang
 */
class EulerAngles
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

	public function toString(): String
	{
		return "{x: " + this.x + " y:" + this.y + " z:" + this.z + "}";
	}

	public function asArray(): Array<Float> 
	{
		return [this.x, this.y, this.z];
	}

	public function equals(otherEulerAngles: EulerAngles): Bool 
	{
		return otherEulerAngles && 
				this.x == otherEulerAngles.x && 
				this.y == otherEulerAngles.y && 
				this.z == otherEulerAngles.z;
	}

	public function clone(): EulerAngles
	{
		return new EulerAngles(this.x, this.y, this.z);
	}

	public function copyFrom(other: EulerAngles): Void 
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;
	}

	public function copyFromFloats(x: Float, y: Float, z: Float): Void 
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function add(other: EulerAngles): EulerAngles 
	{
		return new EulerAngles(this.x + other.x, this.y + other.y, this.z + other.z);
	}

	public function subtract(other: EulerAngles): EulerAngles
	{
		return new EulerAngles(this.x - other.x, this.y - other.y, this.z - other.z);
	}

	public function scale(value: Float): EulerAngles 
	{
		return new EulerAngles(this.x * value, this.y * value, this.z * value);
	}

	public function length(): Float 
	{
		return Math.sqrt((this.x * this.x) + (this.y * this.y) + (this.z * this.z));
	}

	public function normalize(): Void
	{
		var length = 1.0 / this.length();
		this.x *= length;
		this.y *= length;
		this.z *= length;
	}

	public function toQuaternion(): Vector4 
	{
		var result;

		//result is a Quaternion in the z-x-z rotation convention
		var cosxPlusz = Math.cos((this.x + this.z) * 0.5);
		var sinxPlusz = Math.sin((this.x + this.z) * 0.5);
		var coszMinusx = Math.cos((this.z - this.x) * 0.5);
		var sinzMinusx = Math.sin((this.z - this.x) * 0.5);
		var cosy = Math.cos(this.y * 0.5);
		var siny = Math.sin(this.y * 0.5);

		result.x = coszMinusx * siny;
		result.y = -sinzMinusx * siny; 
		result.z = sinxPlusz * cosy;
		result.w = cosxPlusz * cosy;

		return result;

	}

	public function toRotationMatrix(result: Matrix): Void
	{
		//returns matrix with result.m[0]=m11,result.m[1]=m21,result.m[2]=m31,result.m[4]=12, etc
		//done in the z-x-z rotation convention
		var cosx = Math.cos(this.x);
		var sinx = Math.sin(this.x);
		var cosy = Math.cos(this.y);
		var siny = Math.sin(this.y);
		var cosz = Math.cos(this.z);
		var sinz = Math.sin(this.z);

		result.m[0] = cosx * cosz - cosy * sinx * sinz;
		result.m[1] = cosy * sinx * cosz + cosx * sinz;
		result.m[2] = siny * sinx;
		result.m[4] = -sinx * cosz - cosy * cosx * sinz;
		result.m[5] = cosy * cosx * cosz - sinx * sinz;
		result.m[6] = siny * cosx;
		result.m[8] = siny * sinz;
		result.m[9] = -siny * cosz;
		result.m[10] = cosy;
	}

	public function fromRotationMatrix(matrix: Matrix): Void 
	{
		var data = matrix.m;
		var m11 = data[0], m12 = data[4], m13 = data[8];
		var m21 = data[1], m22 = data[5], m23 = data[9];
		var m31 = data[2], m32 = data[6], m33 = data[10];

		if (m33 == -1) 
		{
			this.x = 0; //any angle works here
			this.y = Math.PI;
			this.z = Math.atan2(m21, m11); //generally, atan2(m21,m11)-x
		}
		else if (m33 == 1)
		{
			this.x = 0; //any angle works here
			this.y = 0;
			this.z = Math.atan2(m21, m11); //generally, atan2(m21,m11)-x
		}
		else
		{
			this.x = Math.atan2(m31, m32);
			this.y = Math.acos(m33); //principal value (between 0 and PI)
			this.z = Math.atan2(m13, -m23);
		}
	}
	
}