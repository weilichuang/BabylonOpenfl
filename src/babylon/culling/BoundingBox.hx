package babylon.culling;

import babylon.math.Vector3;
import babylon.math.Matrix;
import babylon.math.Plane;

//TODO 使用的数据过多，优化，其实可简化到只有6个数字
class BoundingBox 
{
	
	public var minimum:Vector3;
	public var maximum:Vector3;
	
	public var vectors:Array<Vector3>;
	public var vectorsWorld:Array<Vector3>;
	
	public var center:Vector3;
	public var extendSize:Vector3;
	public var directions:Array<Vector3>;
	
	public var minimumWorld:Vector3;
	public var maximumWorld:Vector3;
	
	private var _worldMatrix: Matrix;

	public function new(minimum:Vector3, maximum:Vector3) 
	{
		this.minimum = minimum.clone();
        this.maximum = maximum.clone();
        
        // Bounding vectors
        this.vectors = [];

        this.vectors.push(this.minimum.clone());
        this.vectors.push(this.maximum.clone());

        this.vectors.push(this.minimum.clone());
        this.vectors[2].x = this.maximum.x;

        this.vectors.push(this.minimum.clone());
        this.vectors[3].y = this.maximum.y;

        this.vectors.push(this.minimum.clone());
        this.vectors[4].z = this.maximum.z;

        this.vectors.push(this.maximum.clone());
        this.vectors[5].z = this.minimum.z;

        this.vectors.push(this.maximum.clone());
        this.vectors[6].x = this.minimum.x;

        this.vectors.push(this.maximum.clone());
        this.vectors[7].y = this.minimum.y;

        // OBB
        this.center = new Vector3();
		this.center.x = (this.maximum.x + this.minimum.x) * 0.5;
		this.center.y = (this.maximum.y + this.minimum.y) * 0.5;
		this.center.z = (this.maximum.z + this.minimum.z) * 0.5;
		
        this.extendSize = new Vector3();
		this.extendSize.x = (this.maximum.x - this.minimum.x) * 0.5;
		this.extendSize.y = (this.maximum.y - this.minimum.y) * 0.5;
		this.extendSize.z = (this.maximum.z - this.minimum.z) * 0.5;

        this.directions = [new Vector3(), new Vector3(), new Vector3()];

        // World
        this.vectorsWorld = [];
        for (index in 0...this.vectors.length) 
		{
            this.vectorsWorld[index] = new Vector3();
        }
		
        this.minimumWorld = new Vector3();
        this.maximumWorld = new Vector3();
		
		this._worldMatrix = new Matrix();

        this.update(new Matrix());
	}
	
	public function getWorldMatrix():Matrix
	{
		return _worldMatrix;
	}
	
	public function update(world:Matrix):Void
	{
        this.minimumWorld.setTo(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        this.maximumWorld.setTo(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

        for (index in 0...this.vectors.length)
		{
            var vecWorld:Vector3 = this.vectorsWorld[index];
            Vector3.TransformCoordinatesToRef(this.vectors[index], world, vecWorld);

            if (vecWorld.x < this.minimumWorld.x)
                this.minimumWorld.x = vecWorld.x;
				
            if (vecWorld.y < this.minimumWorld.y)
                this.minimumWorld.y = vecWorld.y;
				
            if (vecWorld.z < this.minimumWorld.z)
                this.minimumWorld.z = vecWorld.z;

            if (vecWorld.x > this.maximumWorld.x)
                this.maximumWorld.x = vecWorld.x;
				
            if (vecWorld.y > this.maximumWorld.y)
                this.maximumWorld.y = vecWorld.y;
				
            if (vecWorld.z > this.maximumWorld.z)
                this.maximumWorld.z = vecWorld.z;
        }

        // OBB
        this.maximumWorld.addToRef(this.minimumWorld, this.center);
        this.center.scaleInPlace(0.5);

        Vector3.FromArrayToRef(world.m, 0, this.directions[0]);
        Vector3.FromArrayToRef(world.m, 4, this.directions[1]);
        Vector3.FromArrayToRef(world.m, 8, this.directions[2]);
		
		_worldMatrix.copyFrom(world);
    }
	
	public function isInFrustrum(frustumPlanes:Array<Plane>):Bool 
	{ 
		for (p in 0...6) 
		{
			var plane:Plane = frustumPlanes[p];
            var inCount:Int = 8;
            for (i in 0...8) 
			{
                if (plane.dotCoordinate(vectorsWorld[i]) < 0) 
				{
                    --inCount;
                }
				else 
				{
                    break;
                }
            }
            if (inCount == 0)
                return false;
        }
        return true;
    }
	
	public function intersectsPoint(point:Vector3):Bool
	{
        var delta:Float = Engine.Epsilon;

		if (this.maximumWorld.x - point.x < delta || delta > point.x - this.minimumWorld.x)
			return false;

		if (this.maximumWorld.y - point.y < delta || delta > point.y - this.minimumWorld.y)
			return false;

		if (this.maximumWorld.z - point.z < delta || delta > point.z - this.minimumWorld.z)
			return false;

		return true;
    }
	
	public function intersectsSphere(sphere:BoundingSphere):Bool
	{
        return IntersectsSphere(this.minimumWorld, this.maximumWorld, sphere.centerWorld, sphere.radiusWorld);
    }
	
	public function intersectsMinMax(min:Vector3, max:Vector3):Bool 
	{
        if (this.maximumWorld.x < min.x || this.minimumWorld.x > max.x)
            return false;

        if (this.maximumWorld.y < min.y || this.minimumWorld.y > max.y)
            return false;

        if (this.maximumWorld.z < min.z || this.minimumWorld.z > max.z)
            return false;

        return true;
    }
	
	public static function intersects(box0:BoundingBox, box1:BoundingBox):Bool
	{
        if (box0.maximumWorld.x < box1.minimumWorld.x || box0.minimumWorld.x > box1.maximumWorld.x)
            return false;

        if (box0.maximumWorld.y < box1.minimumWorld.y || box0.minimumWorld.y > box1.maximumWorld.y)
            return false;

        if (box0.maximumWorld.z < box1.minimumWorld.z || box0.minimumWorld.z > box1.maximumWorld.z)
            return false;

        return true;
    }
	
	public static function IntersectsSphere(minPoint: Vector3, maxPoint: Vector3, sphereCenter: Vector3, sphereRadius: Float):Bool
	{
        var vector = Vector3.Clamp(sphereCenter, minPoint, maxPoint);
		var num = sphereCenter.distanceSquaredTo(vector);
		return (num <= (sphereRadius * sphereRadius));
    }
	
	public static function IsInFrustum(boundingVectors:Array<Vector3>, frustumPlanes:Array<Plane>):Bool 
	{
        for (p in 0...6) 
		{
			var plane:Plane = frustumPlanes[p];
            var inCount:Int = 8;
            for (i in 0...8) 
			{
                if (plane.dotCoordinate(boundingVectors[i]) < 0) 
				{
                    --inCount;
                }
				else 
				{
                    break;
                }
            }
            if (inCount == 0)
                return false;
        }
        return true;
    }
	
}
