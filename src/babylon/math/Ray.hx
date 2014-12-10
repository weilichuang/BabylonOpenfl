package babylon.math;

import babylon.collisions.IntersectionInfo;
import babylon.culling.BoundingBox;
import babylon.culling.BoundingSphere;

class Ray 
{
	public var origin:Vector3;
	public var direction:Vector3;
	public var length:Float;
	
	private var _edge1:Vector3;
	private var _edge2:Vector3;
	private var _pvec:Vector3;
	private var _tvec:Vector3;
	private var _qvec:Vector3;
	

	public function new(origin: Vector3, direction: Vector3, length:Float = 3.4028234663852886e+38) 
	{
		this.origin = origin.clone();
		this.direction = direction.clone();
		this.length = length;
	}
	
	public function intersectsBoxMinMax(minimum: Vector3, maximum: Vector3): Bool
	{
		var d:Float = 0.0;
        var maxValue:Float = Math.POSITIVE_INFINITY;

        if (FastMath.fabs(this.direction.x) < 0.0000001)
		{
            if (this.origin.x < minimum.x || this.origin.x > maximum.x) 
			{
                return false;
            }
        }
        else 
		{
            var inv:Float = 1.0 / this.direction.x;
            var min:Float = (minimum.x - this.origin.x) * inv;
            var max:Float = (maximum.x - this.origin.x) * inv;
			
			if (max == Math.NEGATIVE_INFINITY)
				max = Math.POSITIVE_INFINITY;

            if (min > max) 
			{
                var temp:Float = min;
                min = max;
                max = temp;
            }

            d = Math.max(min, d);
            maxValue = Math.min(max, maxValue);

            if (d > maxValue)
			{
                return false;
            }
        }

        if (FastMath.fabs(this.direction.y) < 0.0000001)
		{
            if (this.origin.y < minimum.y || this.origin.y > maximum.y)
			{
                return false;
            }
        }
        else 
		{
            var inv:Float = 1.0 / this.direction.y;
            var min:Float = (minimum.y - this.origin.y) * inv;
            var max:Float = (maximum.y - this.origin.y) * inv;
			
			if (max == Math.NEGATIVE_INFINITY)
				max = Math.POSITIVE_INFINITY;

            if (min > max) 
			{
                var temp = min;
                min = max;
                max = temp;
            }

            d = Math.max(min, d);
            maxValue = Math.min(max, maxValue);

            if (d > maxValue)
			{
                return false;
            }
        }

        if (FastMath.fabs(this.direction.z) < 0.0000001) 
		{
            if (this.origin.z < minimum.z || this.origin.z > maximum.z) 
			{
                return false;
            }
        }
        else 
		{
            var inv:Float = 1.0 / this.direction.z;
            var min:Float = (minimum.z - this.origin.z) * inv;
            var max:Float = (maximum.z - this.origin.z) * inv;
			
			if (max == Math.NEGATIVE_INFINITY)
				max = Math.POSITIVE_INFINITY;

            if (min > max) 
			{
                var temp:Float = min;
                min = max;
                max = temp;
            }

            d = Math.max(min, d);
            maxValue = Math.min(max, maxValue);

            if (d > maxValue) 
			{
                return false;
            }
        }
        return true;
	}

	public function intersectsBox(box:BoundingBox):Bool
	{
		return intersectsBoxMinMax(box.minimum, box.maximum);
	}
	
	public function intersectsSphere(sphere:BoundingSphere):Bool 
	{
		var x:Float = sphere.center.x - this.origin.x;
        var y:Float = sphere.center.y - this.origin.y;
        var z:Float = sphere.center.z - this.origin.z;
        var pyth:Float = (x * x) + (y * y) + (z * z);
        var rr:Float = sphere.radius * sphere.radius;

        if (pyth <= rr) 
		{
            return true;
        }

        var dot:Float = (x * this.direction.x) + (y * this.direction.y) + (z * this.direction.z);
        if (dot < 0.0) 
		{
            return false;
        }

        var temp:Float = pyth - (dot * dot);

        return temp <= rr;
	}
	
	public function intersectsTriangle(vertex0: Vector3, vertex1: Vector3, vertex2: Vector3):IntersectionInfo
	{
		if (this._edge1 == null) 
		{
            this._edge1 = Vector3.Zero();
            this._edge2 = Vector3.Zero();
            this._pvec = Vector3.Zero();
            this._tvec = Vector3.Zero();
            this._qvec = Vector3.Zero();
        }

        vertex1.subtractToRef(vertex0, this._edge1);
        vertex2.subtractToRef(vertex0, this._edge2);
        Vector3.CrossToRef(this.direction, this._edge2, this._pvec);
		
        var det:Float = this._edge1.dot(this._pvec);
        if (det == 0)
		{
            return null;
        }

        var invdet:Float = 1 / det;

        this.origin.subtractToRef(vertex0, this._tvec);

        var bu:Float = this._tvec.dot(this._pvec) * invdet;
        if (bu < 0 || bu > 1.0)
		{
            return null;
        }

        Vector3.CrossToRef(this._tvec, this._edge1, this._qvec);

        var bv:Float = this.direction.dot(this._qvec) * invdet;

        if (bv < 0 || bu + bv > 1.0)
		{
            return null;
        }
		
		//check if the distance is longer than the predefined length.
		var distance = this._edge2.dot(this._qvec) * invdet;
		if (distance > this.length) 
		{
			return null;
		}

		return new IntersectionInfo(bu, bv, distance);
	}
	

	public static function CreateNew(x: Float, y: Float, 
									viewportWidth: Float, viewportHeight: Float, 
									world: Matrix, view: Matrix, projection: Matrix):Ray 
	{
		var start = Vector3.Unproject(new Vector3(x, y, 0), viewportWidth, viewportHeight, world, view, projection);
        var end = Vector3.Unproject(new Vector3(x, y, 1), viewportWidth, viewportHeight, world, view, projection);

        var direction = end.subtract(start);
        direction.normalize();

        return new Ray(start, direction);
	}
	
	/**
    * Function will create a new transformed ray starting from origin and ending at the end point. Ray's length will be set, and ray will be 
	* transformed to the given world matrix.
	* @param origin The origin point
	* @param end The end point
	* @param world a matrix to transform the ray to. Default is the identity matrix.
	*/
	public static function CreateNewFromTo(origin: Vector3, end: Vector3, world: Matrix = null): Ray 
	{
		var direction = end.subtract(origin);
		var length = Math.sqrt((direction.x * direction.x) + (direction.y * direction.y) + (direction.z * direction.z));
		direction.normalize();

		if (world == null)
			world = new Matrix();
		return Ray.Transform(new Ray(origin, direction, length), world);
	}
	
	public static inline function Transform(ray:Ray, matrix:Matrix):Ray 
	{
		var newOrigin = Vector3.TransformCoordinates(ray.origin, matrix);
        var newDirection = Vector3.TransformNormal(ray.direction, matrix);
        
        return new Ray(newOrigin, newDirection, ray.length);
	}
	
}
