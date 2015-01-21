package babylon.math;

class Quaternion 
{

	public var x:Float;		
	public var y:Float;
	public var z:Float;
	public var w:Float;
	
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1)
	{
		this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
	}
	
	public inline function setTo(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1)
	{
		this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
	}
	
	public inline function copyFrom(other:Quaternion):Void
	{
		this.x = other.x;
        this.y = other.y;
        this.z = other.z;
        this.w = other.w;
	}

	public function toString():String
	{
		return "{X: " + this.x + " Y:" + this.y + " Z:" + this.z + " W:" + this.w + "}";
	}

	public inline function equals(other:Quaternion):Bool 
	{
		return this.x == other.x && this.y == other.y && this.z == other.z && this.w == other.w;
	}
	
	public inline function clone():Quaternion 
	{
		return new Quaternion(this.x, this.y, this.z, this.w);
	}
	
	public inline function add(other:Quaternion):Quaternion 
	{
		return new Quaternion(this.x + other.x, this.y + other.y, this.z + other.z, this.w + other.w);
	}
	
	public inline function subtract(otherVector:Quaternion, result:Quaternion = null):Quaternion 
	{
		if (result == null)
			result = new Quaternion();
		result.x = this.x - otherVector.x;
		result.y = this.y - otherVector.y;
		result.z = this.z - otherVector.z;
		result.w = this.w - otherVector.w;
		return result;
	}
	
	public inline function scale(value:Float):Quaternion
	{
		return new Quaternion(this.x * value, this.y * value, this.z * value, this.w * value);
	}
	
	public inline function multiply(q1:Quaternion):Quaternion 
	{
		var result:Quaternion = new Quaternion(0, 0, 0, 1.0);
        this.multiplyToRef(q1, result);

        return result;
	}
	
	public inline function multiplyToRef(q1:Quaternion, result:Quaternion):Quaternion
	{
		var tx = this.x; var ty = this.y; var tz = this.z; var tw = this.w;
		result.x = tx * q1.w + ty * q1.z - tz * q1.y + tw * q1.x;
        result.y = -tx * q1.z + ty * q1.w + tz * q1.x + tw * q1.y;
        result.z = tx * q1.y - ty * q1.x + tz * q1.w + tw * q1.z;
        result.w = -tx * q1.x - ty * q1.y - tz * q1.z + tw * q1.w;
		
		return result;
	}
	
	public inline function length():Float 
	{
		return Math.sqrt(x * x + y * y + z * z + w * w);
	}
	
	public inline function normalize():Void
	{
		var length = this.length();
		if (length != 0)
			length = 1.0 / length;

        this.x *= length;
        this.y *= length;
        this.z *= length;
        this.w *= length;
	}
	
	public function toEulerAnglesToRef(result:Vector3):Void
	{
		//result is an EulerAngles in the in the z-x-z convention
		var qx:Float = this.x;
		var qy:Float = this.y;
		var qz:Float = this.z;
		var qw:Float = this.w;
		var qxy:Float = qx * qy;
		var qxz:Float = qx * qz;
		var qwy:Float = qw * qy;
		var qwz:Float = qw * qz;
		var qwx:Float = qw * qx;
		var qyz:Float = qy * qz;
		var sqx:Float = qx * qx;
		var sqy:Float = qy * qy;

		var determinant:Float = sqx + sqy;

		if (determinant != 0 && determinant != 1)
		{
			result.x = Math.atan2(qxz + qwy, qwx - qyz);
			result.y = Math.acos(1 - 2 * determinant);
			result.z = Math.atan2(qxz - qwy, qwx + qyz);
		}
		else if (determinant == 0)
		{
			result.x = 0.0;
			result.y = 0.0;
			result.z = Math.atan2(qxy - qwz, 0.5 - sqy - qz * qz); //actually, degeneracy gives us choice with x+z=Math.atan2(qxy-qwz,0.5-sqy-qz*qz)
		}
		else //determinant == 1.000
		{
			result.x = Math.atan2(qxy - qwz, 0.5 - sqy - qz * qz); //actually, degeneracy gives us choice with x-z=Math.atan2(qxy-qwz,0.5-sqy-qz*qz)
			result.y = Math.PI;
			result.z = 0.0;
		}
	}
	
	public function toEulerAngles():Vector3
	{
		var result:Vector3 = new Vector3();

		this.toEulerAnglesToRef(result);

		return result;
	}
	
	public function toRotationMatrix(result:Matrix):Matrix
	{
		var xx = this.x * this.x;
        var yy = this.y * this.y;
        var zz = this.z * this.z;
        var xy = this.x * this.y;
        var zw = this.z * this.w;
        var zx = this.z * this.x;
        var yw = this.y * this.w;
        var yz = this.y * this.z;
        var xw = this.x * this.w;
		
		var rm = result.m;

        rm[0] = 1.0 - (2.0 * (yy + zz));
        rm[1] = 2.0 * (xy + zw);
        rm[2] = 2.0 * (zx - yw);
        rm[3] = 0;
        rm[4] = 2.0 * (xy - zw);
        rm[5] = 1.0 - (2.0 * (zz + xx));
        rm[6] = 2.0 * (yz + xw);
        rm[7] = 0;
        rm[8] = 2.0 * (zx + yw);
        rm[9] = 2.0 * (yz - xw);
        rm[10] = 1.0 - (2.0 * (yy + xx));
        rm[11] = 0;
        rm[12] = 0;
        rm[13] = 0;
        rm[14] = 0;
        rm[15] = 1.0;
		
		return result;
	}
	
	public function fromRotationMatrix(matrix: Matrix): Void
	{
		var data = matrix.m;
		var m11 = data[0], m12 = data[4], m13 = data[8];
		var m21 = data[1], m22 = data[5], m23 = data[9];
		var m31 = data[2], m32 = data[6], m33 = data[10];
		var t:Float = m11 + m22 + m33;
		var s:Float;

		if (t > 0) 
		{
			s = 0.5 / Math.sqrt(t + 1.0);

			this.w = 0.25 / s;
			this.x = (m32 - m23) * s;
			this.y = (m13 - m31) * s;
			this.z = (m21 - m12) * s;

			return;
		}

		if (m11 > m22 && m11 > m33)
		{
			s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

			this.w = (m32 - m23) / s;
			this.x = 0.25 * s;
			this.y = (m12 + m21) / s;
			this.z = (m13 + m31) / s;

			return;
		}

		if (m22 > m33) 
		{
			s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

			this.w = (m13 - m31) / s;
			this.x = (m12 + m21) / s;
			this.y = 0.25 * s;
			this.z = (m23 + m32) / s;

			return;
		}

		s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

		this.w = (m21 - m12) / s;
		this.x = (m13 + m31) / s;
		this.y = (m23 + m32) / s;
		this.z = 0.25 * s;
	}
	
	public static function RotationAxis(axis: Vector3, angle: Float): Quaternion 
	{
		var result = new Quaternion();
		var sin = Math.sin(angle / 2);

		result.w = Math.cos(angle / 2);
		result.x = axis.x * sin;
		result.y = axis.y * sin;
		result.z = axis.z * sin;

		return result;
	}
	
	public static function Identity(): Quaternion 
	{
		return new Quaternion(0, 0, 0, 1);
	}
	
	public static function Inverse(q: Quaternion): Quaternion
	{
		return new Quaternion(-q.x, -q.y, -q.z, q.w);
	}
		
	public static inline function FromArray(array:Array<Float>, offset:Int = 0):Quaternion 
	{
		return new Quaternion(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
	}
	
	public static inline function RotationYawPitchRoll(yaw:Float, pitch:Float, roll:Float):Quaternion 
	{
		var result = new Quaternion();
        Quaternion.RotationYawPitchRollToRef(yaw, pitch, roll, result);

        return result;
	}
	
	public static function RotationYawPitchRollToRef(yaw:Float, pitch:Float, roll:Float, result:Quaternion):Quaternion
	{
		var halfRoll = roll * 0.5;
        var halfPitch = pitch * 0.5;
        var halfYaw = yaw * 0.5;

        var sinRoll = Math.sin(halfRoll);
        var cosRoll = Math.cos(halfRoll);
        var sinPitch = Math.sin(halfPitch);
        var cosPitch = Math.cos(halfPitch);
        var sinYaw = Math.sin(halfYaw);
        var cosYaw = Math.cos(halfYaw);

        result.x = (cosYaw * sinPitch * cosRoll) + (sinYaw * cosPitch * sinRoll);
        result.y = (sinYaw * cosPitch * cosRoll) - (cosYaw * sinPitch * sinRoll);
        result.z = (cosYaw * cosPitch * sinRoll) - (sinYaw * sinPitch * cosRoll);
        result.w = (cosYaw * cosPitch * cosRoll) + (sinYaw * sinPitch * sinRoll);
		
		return result;
	}
	
	public static inline function Slerp(left:Quaternion, right:Quaternion, amount:Float):Quaternion
	{
		var num2:Float;
        var num3:Float;
        var num:Float = amount;
        var num4:Float = (((left.x * right.x) + (left.y * right.y)) + (left.z * right.z)) + (left.w * right.w);
        var flag:Bool = false;

        if (num4 < 0) 
		{
            flag = true;
            num4 = -num4;
        }

        if (num4 > 0.999999)
		{
            num3 = 1 - num;
            num2 = flag ? -num : num;
        }
        else 
		{
            var num5 = Math.acos(num4);
            var num6 = (1.0 / Math.sin(num5));
            num3 = (Math.sin((1.0 - num) * num5)) * num6;
            num2 = flag ? ((-Math.sin(num * num5)) * num6) : ((Math.sin(num * num5)) * num6);
        }

        return new Quaternion((num3 * left.x) + (num2 * right.x), 
							(num3 * left.y) + (num2 * right.y), 
							(num3 * left.z) + (num2 * right.z), 
							(num3 * left.w) + (num2 * right.w));
	}
		
}
