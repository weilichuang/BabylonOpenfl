package babylon.math;

import babylon.cameras.Camera;
import openfl.utils.Float32Array;

//TODO 很多方法需要优化
class Matrix 
{
	//不要修改此值
	public static var IDENTITY:Matrix = new Matrix();
	
	public var position(get, set):Vector3;
	
	#if html5
	public var m:Float32Array;
	#else
	public var m:Array<Float>;	
	#end

	public function new() 
	{
		#if html5
		m = new Float32Array(16);
		#else
		m = [];
		#end
		
		m[0] = 1.0;
		m[1] = 0; 
		m[2] = 0; 
		m[3] = 0;
		
		m[4] = 0;
		m[5] = 1.0; 
		m[6] = 0; 
		m[7] = 0;
		
		m[8] = 0; 
		m[9] = 0; 
		m[10] = 1.0; 
		m[11] = 0;
		
		m[12] = 0; 
		m[13] = 0; 
		m[14] = 0; 
		m[15] = 1.0;
	}
	
	private inline function get_position():Vector3
	{	
		return new Vector3 (m[12], m[13], m[14]);
	}
	
	
	private inline function set_position(val:Vector3):Vector3
	{
		m[12] = val.x;
		m[13] = val.y;
		m[14] = val.z;
		return val;
	}

	public function isIdentity():Bool 
	{
		var ret:Bool = true;
		if (m[0] != 1.0 || m[5] != 1.0 || m[10] != 1.0 || m[15] != 1.0)
            ret = false;

        if (m[1] != 0.0 || m[2] != 0.0 || m[3] != 0.0 ||
            m[4] != 0.0 || m[6] != 0.0 || m[7] != 0.0 ||
            m[8] != 0.0 || m[9] != 0.0 || m[11] != 0.0 ||
            m[12] != 0.0 || m[13] != 0.0 || m[14] != 0.0)
            ret = false;

        return ret;
	}
	
	public function determinant():Float 
	{
		var temp1:Float = (m[10] * m[15]) - (m[11] * m[14]);
        var temp2:Float = (m[9] * m[15]) - (m[11] * m[13]);
        var temp3:Float = (m[9] * m[14]) - (m[10] * m[13]);
        var temp4:Float = (m[8] * m[15]) - (m[11] * m[12]);
        var temp5:Float = (m[8] * m[14]) - (m[10] * m[12]);
        var temp6:Float = (m[8] * m[13]) - (m[9] * m[12]);

        return ((((m[0] * (((m[5] * temp1) - (m[6] * temp2)) + 
				(m[7] * temp3))) - (m[1] * (((m[4] * temp1) -
                (m[6] * temp4)) + (m[7] * temp5)))) + 
				(m[2] * (((m[4] * temp2) - (m[5] * temp4)) + 
				(m[7] * temp6)))) -
				(m[3] * (((m[4] * temp3) - 
				(m[5] * temp5)) + 
				(m[6] * temp6))));
	}
	
	public inline function toArray(): #if html5 Float32Array #else Array<Float> #end 
	{
		return m;
	}
	
	public function fromArray(array:Array<Float>):Void 
	{
        for (index in 0...16) 
		{
            m[index] = array[index];
        }
	}
	
	public function identity():Void
	{
		m[0] = 1.0;
		m[1] = 0; 
		m[2] = 0; 
		m[3] = 0;
		
		m[4] = 0;
		m[5] = 1.0; 
		m[6] = 0; 
		m[7] = 0;
		
		m[8] = 0; 
		m[9] = 0; 
		m[10] = 1.0; 
		m[11] = 0;
		
		m[12] = 0; 
		m[13] = 0; 
		m[14] = 0; 
		m[15] = 1.0;
	}
	
	public inline function invert():Void
	{
		this.invertToRef(this);
	}
	
	public function invertToRef(other:Matrix):Void
	{
		var t1 = m[0]; var t2 = m[1]; var t3 = m[2]; var t4 = m[3];
        var t5 = m[4]; var t6 = m[5]; var t7 = m[6]; var t8 = m[7];
		var t9 = m[8]; var t10 = m[9]; var t11 = m[10]; var t12 = m[11];
		var t13 = m[12]; var t14 = m[13]; var t15 = m[14]; var t16 = m[15];
		
        var t17 = (t11 * t16) - (t12 * t15);
        var t18 = (t10 * t16) - (t12 * t14);
        var t19 = (t10 * t15) - (t11 * t14);
        var t20 = (t9 * t16) - (t12 * t13);
        var t21 = (t9 * t15) - (t11 * t13);
        var t22 = (t9 * t14) - (t10 * t13);
        var t23 = ((t6 * t17) - (t7 * t18)) + (t8 * t19);
        var t24 = -(((t5 * t17) - (t7 * t20)) + (t8 * t21));
        var t25 = ((t5 * t18) - (t6 * t20)) + (t8 * t22);
        var t26 = -(((t5 * t19) - (t6 * t21)) + (t7 * t22));
        var t27 = 1.0 / ((((t1 * t23) + (t2 * t24)) + (t3 * t25)) + (t4 * t26));
        var t28 = (t7 * t16) - (t8 * t15);
        var t29 = (t6 * t16) - (t8 * t14);
        var t30 = (t6 * t15) - (t7 * t14);
        var t31 = (t5 * t16) - (t8 * t13);
        var t32 = (t5 * t15) - (t7 * t13);
        var t33 = (t5 * t14) - (t6 * t13);
        var t34 = (t7 * t12) - (t8 * t11);
        var t35 = (t6 * t12) - (t8 * t10);
        var t36 = (t6 * t11) - (t7 * t10);
        var t37 = (t5 * t12) - (t8 * t9);
        var t38 = (t5 * t11) - (t7 * t9);
        var t39 = (t5 * t10) - (t6 * t9);

        other.m[0] = t23 * t27;
        other.m[4] = t24 * t27;
        other.m[8] = t25 * t27;
        other.m[12] = t26 * t27;
        other.m[1] = -(((t2 * t17) - (t3 * t18)) + (t4 * t19)) * t27;
        other.m[5] = (((t1 * t17) - (t3 * t20)) + (t4 * t21)) * t27;
        other.m[9] = -(((t1 * t18) - (t2 * t20)) + (t4 * t22)) * t27;
        other.m[13] = (((t1 * t19) - (t2 * t21)) + (t3 * t22)) * t27;
        other.m[2] = (((t2 * t28) - (t3 * t29)) + (t4 * t30)) * t27;
        other.m[6] = -(((t1 * t28) - (t3 * t31)) + (t4 * t32)) * t27;
        other.m[10] = (((t1 * t29) - (t2 * t31)) + (t4 * t33)) * t27;
        other.m[14] = -(((t1 * t30) - (t2 * t32)) + (t3 * t33)) * t27;
        other.m[3] = -(((t2 * t34) - (t3 * t35)) + (t4 * t36)) * t27;
        other.m[7] = (((t1 * t34) - (t3 * t37)) + (t4 * t38)) * t27;
        other.m[11] = -(((t1 * t35) - (t2 * t37)) + (t4 * t39)) * t27;
        other.m[15] = (((t1 * t36) - (t2 * t38)) + (t3 * t39)) * t27;
	}
	
	public inline function setTranslation(vector3:Vector3):Void
	{
		m[12] = vector3.x;
        m[13] = vector3.y;
        m[14] = vector3.z;
	}
	
	public inline function multiply(other:Matrix):Matrix 
	{
		var result = new Matrix();
        multiplyToRef(other, result);
        return result;
	}
	
	public inline function copyFrom(other:Matrix):Void
	{
		var om = other.m;
		for (index in 0...16)
		{
            m[index] = om[index];
        }
	}
	
	public inline function multiplyToRef(other:Matrix, result:Matrix):Void
	{
		multiplyToArray(other, result.m, 0);
	}
	
	public function multiplyToArray(other:Matrix, result: #if html5 Float32Array #else Array<Float> #end , offset:Int): #if html5 Float32Array #else Array<Float> #end
	{
		var tm0 = m[0];  var tm1 = m[1];  var tm2 = m[2];  var tm3 = m[3];
        var tm4 = m[4];  var tm5 = m[5];  var tm6 = m[6];  var tm7 = m[7];
        var tm8 = m[8];  var tm9 = m[9];  var tm10 = m[10];var tm11 = m[11];
        var tm12 = m[12];var tm13 = m[13];var tm14 = m[14];var tm15 = m[15];

        var om0 = other.m[0];  var om1 = other.m[1];  var om2 = other.m[2];  var om3 = other.m[3];
        var om4 = other.m[4];  var om5 = other.m[5];  var om6 = other.m[6];  var om7 = other.m[7];
        var om8 = other.m[8];  var om9 = other.m[9];  var om10 = other.m[10];var om11 = other.m[11];
        var om12 = other.m[12];var om13 = other.m[13];var om14 = other.m[14];var om15 = other.m[15];

        result[offset] 	    = tm0 * om0 + tm1 * om4 + tm2 * om8 + tm3 * om12;
        result[offset + 1]  = tm0 * om1 + tm1 * om5 + tm2 * om9 + tm3 * om13;
        result[offset + 2]  = tm0 * om2 + tm1 * om6 + tm2 * om10 + tm3 * om14;
        result[offset + 3]  = tm0 * om3 + tm1 * om7 + tm2 * om11 + tm3 * om15;

        result[offset + 4]  = tm4 * om0 + tm5 * om4 + tm6 * om8 + tm7 * om12;
        result[offset + 5]  = tm4 * om1 + tm5 * om5 + tm6 * om9 + tm7 * om13;
        result[offset + 6]  = tm4 * om2 + tm5 * om6 + tm6 * om10 + tm7 * om14;
        result[offset + 7]  = tm4 * om3 + tm5 * om7 + tm6 * om11 + tm7 * om15;

        result[offset + 8]  = tm8 * om0 + tm9 * om4 + tm10 * om8 + tm11 * om12;
        result[offset + 9]  = tm8 * om1 + tm9 * om5 + tm10 * om9 + tm11 * om13;
        result[offset + 10] = tm8 * om2 + tm9 * om6 + tm10 * om10 + tm11 * om14;
        result[offset + 11] = tm8 * om3 + tm9 * om7 + tm10 * om11 + tm11 * om15;

        result[offset + 12] = tm12 * om0 + tm13 * om4 + tm14 * om8 + tm15 * om12;
        result[offset + 13] = tm12 * om1 + tm13 * om5 + tm14 * om9 + tm15 * om13;
        result[offset + 14] = tm12 * om2 + tm13 * om6 + tm14 * om10 + tm15 * om14;
        result[offset + 15] = tm12 * om3 + tm13 * om7 + tm14 * om11 + tm15 * om15;
		
		return result;
	}
	
	public function equals(value:Matrix):Bool 
	{
		if (value == null)
			return false;
		
		var vm = value.m;
			
		return (m[0] == vm[0] && m[1] == vm[1] && m[2] == vm[2] && m[3] == vm[3] &&
                m[4] == vm[4] && m[5] == vm[5] && m[6] == vm[6] && m[7] == vm[7] &&
                m[8] == vm[8] && m[9] == vm[9] && m[10] == vm[10] && m[11] == vm[11] &&
                m[12] == vm[12] && m[13] == vm[13] && m[14] == vm[14] && m[15] == vm[15]);
	}
	
	public inline function clone():Matrix
	{
		return Matrix.FromValues(m[0], m[1], m[2], m[3],
								m[4], m[5], m[6], m[7],
								m[8], m[9], m[10], m[11],
								m[12], m[13], m[14], m[15]);
	}
	
	public function copyToArray(array: Array<Float>, offset: Int = 0): Void 
	{
		for (index in 0...16) 
		{
			array[offset + index] = m[index];
		}
	}
	
	public function copyToFloat32Array(array: Float32Array, offset: Int = 0): Void 
	{
		for (index in 0...16) 
		{
			array[offset + index] = m[index];
		}
	}
	
	public function decompose(scale: Vector3, rotation: Quaternion, translation: Vector3):Bool
	{
		translation.x = this.m[12];
		translation.y = this.m[13];
		translation.z = this.m[14];

		var xs = FastMath.Sign(this.m[0] * this.m[1] * this.m[2] * this.m[3]) < 0 ? -1 : 1;
		var ys = FastMath.Sign(this.m[4] * this.m[5] * this.m[6] * this.m[7]) < 0 ? -1 : 1;
		var zs = FastMath.Sign(this.m[8] * this.m[9] * this.m[10] * this.m[11]) < 0 ? -1 : 1;

		scale.x = xs * Math.sqrt(this.m[0] * this.m[0] + this.m[1] * this.m[1] + this.m[2] * this.m[2]);
		scale.y = ys * Math.sqrt(this.m[4] * this.m[4] + this.m[5] * this.m[5] + this.m[6] * this.m[6]);
		scale.z = zs * Math.sqrt(this.m[8] * this.m[8] + this.m[9] * this.m[9] + this.m[10] * this.m[10]);

		if (scale.x == 0 || scale.y == 0 || scale.z == 0)
		{
			rotation.x = 0;
			rotation.y = 0;
			rotation.z = 0;
			rotation.w = 1;
			return false;
		}
		
		var sx:Float = 1 / scale.x;
		var sy:Float = 1 / scale.y;
		var sz:Float = 1 / scale.z;

		var rotationMatrix = Matrix.FromValues(this.m[0] * sx, this.m[1] * sx, this.m[2] * sx, 0,
			this.m[4] * sy, this.m[5] * sy, this.m[6] * sy, 0,
			this.m[8] * sz, this.m[9] * sz, this.m[10] * sz, 0,
			0, 0, 0, 1);

		rotation.fromRotationMatrix(rotationMatrix);

		return true;
	}
	
	public static function Compose(scale: Vector3, rotation: Quaternion, translation: Vector3): Matrix 
	{
		var result:Matrix = Matrix.FromValues(scale.x, 0, 0, 0,
			0, scale.y, 0, 0,
			0, 0, scale.z, 0,
			0, 0, 0, 1);

		var rotationMatrix:Matrix = new Matrix();
		rotation.toRotationMatrix(rotationMatrix);
		result = result.multiply(rotationMatrix);

		result.setTranslation(translation);

		return result;
	}

	public static function FromArray(array:Array<Float>, offset:Int = 0):Matrix 
	{
		var result = new Matrix();
		var rm = result.m;
        for (index in 0...16) 
		{
            rm[index] = array[index + offset];
        }
        return result;
	}
	
	public static function FromArrayToRef(array:Array<Float>, offset:Int, result:Matrix):Matrix 
	{
		var rm = result.m;
		for (index in 0...16) 
		{
            rm[index] = array[index + offset];
        }
		return result;
	}
	
	public static function FromValues(m11:Float, m12:Float, m13:Float, m14:Float,
										m21:Float, m22:Float, m23:Float, m24:Float,
										m31:Float, m32:Float, m33:Float, m34:Float,
										m41:Float, m42:Float, m43:Float, m44:Float,result:Matrix = null):Matrix 
	{
		if (result == null)
			result = new Matrix();
			
		var rm = result.m;

        rm[0] = m11;
        rm[1] = m12;
        rm[2] = m13;
        rm[3] = m14;
        rm[4] = m21;
        rm[5] = m22;
        rm[6] = m23;
        rm[7] = m24;
        rm[8] = m31;
        rm[9] = m32;
        rm[10] = m33;
        rm[11] = m34;
        rm[12] = m41;
        rm[13] = m42;
        rm[14] = m43;
        rm[15] = m44;

        return result;		
	}
	
	public static function FromValuesToRef(m11:Float, m12:Float, m13:Float, m14:Float,
												m21:Float, m22:Float, m23:Float, m24:Float,
												m31:Float, m32:Float, m33:Float, m34:Float,
												m41:Float, m42:Float, m43:Float, m44:Float, result:Matrix):Matrix
	{
		result.m[0] = m11;
        result.m[1] = m12;
        result.m[2] = m13;
        result.m[3] = m14;
        result.m[4] = m21;
        result.m[5] = m22;
        result.m[6] = m23;
        result.m[7] = m24;
        result.m[8] = m31;
        result.m[9] = m32;
        result.m[10] = m33;
        result.m[11] = m34;
        result.m[12] = m41;
        result.m[13] = m42;
        result.m[14] = m43;
        result.m[15] = m44;
		
		return result;
	}
	
	//public static inline function Identity():Matrix 
	//{
		//return Matrix.FromValues(
			//1.0, 0, 0, 0,
            //0, 1.0, 0, 0,
            //0, 0, 1.0, 0,
            //0, 0, 0, 1.0
		//);
	//}
	
	//public static inline function IdentityToRef(result:Matrix):Matrix 
	//{
		//Matrix.FromValuesToRef(
			//1.0, 0, 0, 0,
            //0, 1.0, 0, 0,
            //0, 0, 1.0, 0,
            //0, 0, 0, 1.0, result
		//);
		//
		//return result;
	//}
	
	public static inline function Zero():Matrix 
	{
		return Matrix.FromValues(
			0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0
		);
	}
	
	public static function Invert(source: Matrix): Matrix 
	{
		var result:Matrix = new Matrix();

		source.invertToRef(result);

		return result;
	}
	
	public static inline function RotationX(angle:Float):Matrix 
	{
		var result = new Matrix();
        Matrix.RotationXToRef(angle, result);

        return result;
	}
	
	public static inline function RotationXToRef(angle:Float, result:Matrix):Matrix 
	{
		var s = Math.sin(angle);
        var c = Math.cos(angle);

        result.m[0] = 1.0;
        result.m[15] = 1.0;

        result.m[5] = c;
        result.m[10] = c;
        result.m[9] = -s;
        result.m[6] = s;

        result.m[1] = 0;
        result.m[2] = 0;
        result.m[3] = 0;
        result.m[4] = 0;
        result.m[7] = 0;
        result.m[8] = 0;
        result.m[11] = 0;
        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = 0;
		
		return result;
	}
	
	public static inline function RotationY(angle:Float):Matrix 
	{
		var result = new Matrix();
        Matrix.RotationYToRef(angle, result);

        return result;
	}
	
	public static inline function RotationYToRef(angle:Float, result:Matrix):Matrix 
	{
		var s = Math.sin(angle);
        var c = Math.cos(angle);

        result.m[5] = 1.0;
        result.m[15] = 1.0;

        result.m[0] = c;
        result.m[2] = -s;
        result.m[8] = s;
        result.m[10] = c;

        result.m[1] = 0;
        result.m[3] = 0;
        result.m[4] = 0;
        result.m[6] = 0;
        result.m[7] = 0;
        result.m[9] = 0;
        result.m[11] = 0;
        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = 0;
		
		return result;
	}
	
	public static inline function RotationZ(angle:Float):Matrix
	{
		var result = new Matrix();
        Matrix.RotationZToRef(angle, result);

        return result;
	}
	
	public static inline function RotationZToRef(angle:Float, result:Matrix):Matrix
	{
		var s = Math.sin(angle);
        var c = Math.cos(angle);

        result.m[10] = 1.0;
        result.m[15] = 1.0;

        result.m[0] = c;
        result.m[1] = s;
        result.m[4] = -s;
        result.m[5] = c;

        result.m[2] = 0;
        result.m[3] = 0;
        result.m[6] = 0;
        result.m[7] = 0;
        result.m[8] = 0;
        result.m[9] = 0;
        result.m[11] = 0;
        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = 0;
		
		return result;
	}
	
	public static function RotationAxis(axis:Vector3, angle:Float, result:Matrix):Matrix
	{
		var s = Math.sin(-angle);
        var c = Math.cos(-angle);
        var c1 = 1 - c;

        axis.normalize();
		
		var ax:Float = axis.x;
		var ay:Float = axis.y;
		var az:Float = axis.z;
		
        if (result == null)
			result = new Matrix();
		else
			result.identity();
			
		var rm = result.m;

        rm[0] = (ax * ax) * c1 + c;
        rm[1] = (ax * ay) * c1 - (az * s);
        rm[2] = (ax * az) * c1 + (ay * s);
        rm[3] = 0.0;

        rm[4] = (ay * ax) * c1 + (az * s);
        rm[5] = (ay * ay) * c1 + c;
        rm[6] = (ay * az) * c1 - (ax * s);
        rm[7] = 0.0;

        rm[8] = (az * ax) * c1 - (ay * s);
        rm[9] = (az * ay) * c1 + (ax * s);
        rm[10] = (az * az) * c1 + c;
        rm[11] = 0.0;

        rm[15] = 1.0;

        return result;
	}
	
	public static inline function RotationYawPitchRoll(yaw:Float, pitch:Float, roll:Float):Matrix
	{
		var result = new Matrix();
		
        Matrix.RotationYawPitchRollToRef(yaw, pitch, roll, result);

        return result;
	}
	
	public static inline function RotationYawPitchRollToRef(yaw:Float, pitch:Float, roll:Float, result:Matrix):Matrix 
	{
		var tempQuaternion = new Quaternion(); // For RotationYawPitchRoll
		tempQuaternion = Quaternion.RotationYawPitchRollToRef(yaw, pitch, roll, tempQuaternion);

        return tempQuaternion.toRotationMatrix(result);
	}
	
	public static inline function Scaling(x:Float, y:Float, z:Float):Matrix 
	{
		var result:Matrix = new Matrix();
		
		result.m[0] = x;
		result.m[5] = y;
		result.m[10] = z;
		
        return result;
	}
	
	public static inline function ScalingToRef(x:Float, y:Float, z:Float, result:Matrix):Matrix 
	{
		result.m[0] = x;
        result.m[1] = 0;
        result.m[2] = 0;
        result.m[3] = 0;
        result.m[4] = 0;
        result.m[5] = y;
        result.m[6] = 0;
        result.m[7] = 0;
        result.m[8] = 0;
        result.m[9] = 0;
        result.m[10] = z;
        result.m[11] = 0;
        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = 0;
        result.m[15] = 1.0;
		
		return result;
	}
	
	public static inline function Translation(x:Float, y:Float, z:Float):Matrix 
	{
		var result:Matrix = new Matrix();
		
		result.m[12] = x;
		result.m[13] = y;
		result.m[14] = z;

        return result;
	}
	
	public static inline function TranslationToRef(x:Float, y:Float, z:Float, result:Matrix):Void
	{
		Matrix.FromValuesToRef(
			1.0, 0, 0, 0,
            0, 1.0, 0, 0,
            0, 0, 1.0, 0,
            x, y, z, 1.0, result
		);
	}
	
	public static inline function LookAtLH(eye:Vector3, target:Vector3, up:Vector3):Matrix
	{
		var result = Matrix.Zero();
        Matrix.LookAtLHToRef(eye, target, up, result);

        return result;
	}
	
	private static var xAxis:Vector3;
	private static var yAxis:Vector3;
	private static var zAxis:Vector3;
	public static inline function LookAtLHToRef(eye:Vector3, target:Vector3, up:Vector3, result:Matrix):Matrix 
	{
		if (xAxis == null)
		{
			xAxis = Vector3.Zero();
			yAxis = Vector3.Zero();
			zAxis = Vector3.Zero();
		}
		else
		{
			xAxis.setTo(0, 0, 0);
			yAxis.setTo(0, 0, 0);
			zAxis.setTo(0, 0, 0);
		}
		
		// Z axis
        target.subtractToRef(eye, zAxis);
        zAxis.normalize();

        // X axis
        Vector3.CrossToRef(up, zAxis, xAxis);
        xAxis.normalize();

        // Y axis
        Vector3.CrossToRef(zAxis, xAxis, yAxis);
        yAxis.normalize();

        // Eye angles
        var ex = -xAxis.dot(eye);
        var ey = -yAxis.dot(eye);
        var ez = -zAxis.dot(eye);

        return Matrix.FromValuesToRef(xAxis.x, yAxis.x, zAxis.x, 0,
									xAxis.y, yAxis.y, zAxis.y, 0,
									xAxis.z, yAxis.z, zAxis.z, 0,
									ex, ey, ez, 1, result);
	}
	
	public static inline function OrthoLH(width:Float, height:Float, znear:Float, zfar:Float):Matrix 
	{
		var hw = 2.0 / width;
        var hh = 2.0 / height;
        var id = 1.0 / (zfar - znear);
        var nid = znear / (znear - zfar);

        return Matrix.FromValues(
			hw, 0, 0, 0,
            0, hh, 0, 0,
            0, 0, id, 0,
            0, 0, nid, 1
		);
	}
	
	public static inline function OrthoOffCenterLH(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Matrix 
	{
		var matrix = Matrix.Zero();
        Matrix.OrthoOffCenterLHToRef(left, right, bottom, top, znear, zfar, matrix);

        return matrix;
	}
		
	public static inline function OrthoOffCenterLHToRef(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float, result:Matrix):Matrix
	{
		result.m[0] = 2.0 / (right - left);
        result.m[1] = result.m[2] = result.m[3] = result.m[4] = 0;
        result.m[5] = 2.0 / (top - bottom);
        result.m[6] = result.m[7] = 0;        
        result.m[8] = result.m[9] = 0;
		result.m[10] = -1 / (znear - zfar);
		result.m[11] = 0;
        result.m[12] = (left + right) / (left - right);
        result.m[13] = (top + bottom) / (bottom - top);
        result.m[14] = znear / (znear - zfar);
        result.m[15] = 1.0;
		
		
		return result;
	}
	
	public static inline function PerspectiveLH(width:Float, height:Float, znear:Float, zfar:Float):Matrix
	{
		var matrix = Matrix.Zero();

        matrix.m[0] = (2.0 * znear) / width;
        matrix.m[1] = matrix.m[2] = matrix.m[3] = 0.0;
        matrix.m[5] = (2.0 * znear) / height;
        matrix.m[4] = matrix.m[6] = matrix.m[7] = 0.0;
        matrix.m[10] = -zfar / (znear - zfar);
        matrix.m[8] = matrix.m[9] = 0.0;
        matrix.m[11] = 1.0;
        matrix.m[12] = matrix.m[13] = matrix.m[15] = 0.0;
        matrix.m[14] = (znear * zfar) / (znear - zfar);

        return matrix;
	}
	
	public static inline function PerspectiveFovLH(fov:Float, aspect:Float, znear:Float, zfar:Float):Matrix 
	{
		var matrix = Matrix.Zero();
        Matrix.PerspectiveFovLHToRef(fov, aspect, znear, zfar, matrix);

        return matrix;
	}
	
	public static inline function PerspectiveFovLHToRef(fov:Float, aspect:Float, 
														znear:Float, zfar:Float, 
														result:Matrix, fovMode:Int = 0):Matrix 
	{
		var tan:Float = 1.0 / (Math.tan(fov * 0.5));

        var v_fixed:Bool = (fovMode == Camera.FOVMODE_VERTICAL_FIXED);

		if (v_fixed)
		{
			result.m[0] = tan / aspect;
		}
		else 
		{
			result.m[0] = tan;
		}

		result.m[1] = result.m[2] = result.m[3] = 0.0;

		if (v_fixed)
		{
			result.m[5] = tan;
		}
		else 
		{
			result.m[5] = tan * aspect;
		}

		result.m[4] = result.m[6] = result.m[7] = 0.0;
		result.m[8] = result.m[9] = 0.0;
		result.m[10] = -zfar / (znear - zfar);
		result.m[11] = 1.0;
		result.m[12] = result.m[13] = result.m[15] = 0.0;
		result.m[14] = (znear * zfar) / (znear - zfar);
		
		return result;
	}
	
	/*public static function AffineTransformation(scaling:Float, rotationCenter:Vector3, rotation:Quaternion, translation:Vector3):Matrix {
		return Matrix.Scaling(scaling, scaling, scaling) * Matrix.Translation(-rotationCenter) *
            Matrix.RotationQuaternion(rotation) * Matrix.Translation(rotationCenter) * Matrix.Translation(translation);
	}*/
	
	//public static inline function GetFinalMatrix(viewport:Viewport, world:Matrix, view:Matrix, projection:Matrix, zmin:Float, zmax:Float):Matrix 
	//{
		//var cw = viewport.width;
        //var ch = viewport.height;
        //var cx = viewport.x;
        //var cy = viewport.y;
//
        //var viewportMatrix = Matrix.FromValues(
			//cw / 2.0, 0, 0, 0,
            //0, -ch / 2.0, 0, 0,
            //0, 0, zmax - zmin, 0,
            //cx + cw / 2.0, ch / 2.0 + cy, zmin, 1
		//);
//
        //return world.multiply(view).multiply(projection).multiply(viewportMatrix);
	//}
	
	public static function Transpose(matrix:Matrix, result:Matrix = null):Matrix 
	{
		if(result == null)
		   result = new Matrix();
		   
		var rm = result.m;
		var mm = matrix.m;

        rm[0] = mm[0];
        rm[1] = mm[4];
        rm[2] = mm[8];
        rm[3] = mm[12];

        rm[4] = mm[1];
        rm[5] = mm[5];
        rm[6] = mm[9];
        rm[7] = mm[13];

        rm[8] = mm[2];
        rm[9] = mm[6];
        rm[10] = mm[10];
        rm[11] = mm[14];

        rm[12] = mm[3];
        rm[13] = mm[7];
        rm[14] = mm[11];
        rm[15] = mm[15];

        return result;
	}
	
	public static inline function Reflection(plane:Plane):Matrix
	{
		var matrix = new Matrix();
        Matrix.ReflectionToRef(plane, matrix);

        return matrix;
	}
	
	public static function ReflectionToRef(plane:Plane, result:Matrix):Matrix 
	{
		plane.normalize();
        var x = plane.normal.x;
        var y = plane.normal.y;
        var z = plane.normal.z;
        var temp = -2 * x;
        var temp2 = -2 * y;
        var temp3 = -2 * z;
        result.m[0] = (temp * x) + 1;
        result.m[1] = temp2 * x;
        result.m[2] = temp3 * x;
        result.m[3] = 0.0;
        result.m[4] = temp * y;
        result.m[5] = (temp2 * y) + 1;
        result.m[6] = temp3 * y;
        result.m[7] = 0.0;
        result.m[8] = temp * z;
        result.m[9] = temp2 * z;
        result.m[10] = (temp3 * z) + 1;
        result.m[11] = 0.0;
        result.m[12] = temp * plane.d;
        result.m[13] = temp2 * plane.d;
        result.m[14] = temp3 * plane.d;
        result.m[15] = 1.0;
		
		return result;
	}
	
	public function toString():String
	{
		return m[0] + " " +m[1] + " " +m[2] + " " +m[3] + " " +
				m[4] + " " +m[5] + " " +m[6] + " " +m[7] + " " +
				m[8] + " " +m[9] + " " +m[10] + " " +m[11] + " " +
				m[12] + " " +m[13] + " " +m[14] + " " + m[15];
	}
	
}
