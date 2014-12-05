package babylon.math;
import babylon.utils.TempVars;

class Plane 
{
	public var normal:Vector3;
	public var d:Float;

	public function new(a:Float, b:Float, c:Float, d:Float) 
	{
		this.normal = new Vector3(a, b, c);
        this.d = d;
	}
	
	public inline function clone():Plane 
	{
		return new Plane(this.normal.x, this.normal.y, this.normal.z, this.d);
	}

	public inline function normalize():Void
	{
		var norm:Float = Math.sqrt((normal.x * normal.x) + (normal.y * normal.y) + (normal.z * normal.z));
        if (norm != 0)
		{
            norm = 1.0 / norm;
        }

        this.normal.x *= norm;
        this.normal.y *= norm;
        this.normal.z *= norm;

        this.d *= norm;
	}
	
	private static var tmpMatrix:Matrix = new Matrix();
	
	public function transform(transformation:Matrix):Plane 
	{
		var transposedMatrix:Matrix = Matrix.Transpose(transformation, tmpMatrix);
		var m = transposedMatrix.m;
		
        var x:Float = this.normal.x;
        var y:Float = this.normal.y;
        var z:Float = this.normal.z;
        var d:Float = this.d;

        var normalX:Float = (((x * m[0])  + (y * m[1]))  + (z * m[2]))  + (d * m[3]);
        var normalY:Float = (((x * m[4])  + (y * m[5]))  + (z * m[6]))  + (d * m[7]);
        var normalZ:Float = (((x * m[8])  + (y * m[9]))  + (z * m[10])) + (d * m[11]);
        var finalD:Float  = (((x * m[12]) + (y * m[13])) + (z * m[14])) + (d * m[15]);
		
        return new Plane(normalX, normalY, normalZ, finalD);
	}
	
	public inline function dotCoordinate(point:Vector3):Float
	{
		return (normal.x * point.x) + (normal.y * point.y) + (normal.z * point.z) + d;
	}
	
	public inline function copyFromPoints(point1:Vector3, point2:Vector3, point3:Vector3):Void
	{
		var x1:Float = point2.x - point1.x;
        var y1:Float = point2.y - point1.y;
        var z1:Float = point2.z - point1.z;
		
        var x2:Float = point3.x - point1.x;
        var y2:Float = point3.y - point1.y;
        var z2:Float = point3.z - point1.z;
		
        var yz:Float = (y1 * z2) - (z1 * y2);
        var xz:Float = (z1 * x2) - (x1 * z2);
        var xy:Float = (x1 * y2) - (y1 * x2);
		
        var pyth:Float = Math.sqrt((yz * yz) + (xz * xz) + (xy * xy));
        if (pyth != 0)
		{
            pyth = 1.0 / pyth;
        }
		
        this.normal.x = yz * pyth;
        this.normal.y = xz * pyth;
        this.normal.z = xy * pyth;
        this.d = -((this.normal.x * point1.x) + (this.normal.y * point1.y) + (this.normal.z * point1.z));
	}
	
	public inline function isFrontFacingTo(direction:Vector3, epsilon:Float):Bool
	{
		var dot:Float = this.normal.dot(direction);

        return (dot <= epsilon);
	}
	
	public inline function signedDistanceTo(point:Vector3):Float 
	{
		return point.dot(this.normal) + this.d;
	}
	
	public static inline function FromArray(array:Array<Float>):Plane 
	{
		return new Plane(array[0], array[1], array[2], array[3]);
	}
	
	public static inline function FromPoints(point1:Vector3, point2:Vector3, point3:Vector3):Plane
	{
		var result:Plane = new Plane(0, 0, 0, 0);
        result.copyFromPoints(point1, point2, point3);

        return result;
	}
	
	public static inline function FromPositionAndNormal(origin:Vector3, normal:Vector3):Plane
	{
		var result:Plane = new Plane(0, 0, 0, 0);
        normal.normalize();

        result.normal = normal;
        result.d = -(normal.x * origin.x + normal.y * origin.y + normal.z * origin.z);

        return result;
	}
	
	public static inline function SignedDistanceToPlaneFromPositionAndNormal(origin:Vector3, normal:Vector3, point:Vector3):Float 
	{
		var d:Float = -(normal.x * origin.x + normal.y * origin.y + normal.z * origin.z);

        return point.dot(normal) + d;
	}	
	
}
