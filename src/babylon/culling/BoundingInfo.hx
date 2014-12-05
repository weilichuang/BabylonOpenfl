package babylon.culling;

import babylon.collisions.Collider;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.math.Plane;

typedef BoundingInfoMinMax = {
	min: Float,
	max: Float
}

class BoundingInfo
{
	public var boundingBox:BoundingBox;
	public var boundingSphere:BoundingSphere;
	
	public var minimum:Vector3;
	public var maximum:Vector3;

	public function new(minimum:Vector3, maximum:Vector3)
	{
		this.minimum = minimum.clone();
		this.maximum = maximum.clone();
		
		this.boundingBox = new BoundingBox(this.minimum, this.maximum);
        this.boundingSphere = new BoundingSphere(this.minimum, this.maximum);
	}
	
	public function update(world:Matrix):Void
	{
        this.boundingBox.update(world);
        this.boundingSphere.update(world);
    }
	
	public function extentsOverlap(min0:Float, max0:Float, min1:Float, max1:Float):Bool
	{
        return !(min0 > max1 || min1 > max0);
    }
	
	public function computeBoxExtents(axis:Vector3, box:BoundingBox):BoundingInfoMinMax 
	{
        var p = box.center.dot(axis);

        var r0 = FastMath.fabs(box.directions[0].dot(axis)) * box.extendSize.x;
        var r1 = FastMath.fabs(box.directions[1].dot(axis)) * box.extendSize.y;
        var r2 = FastMath.fabs(box.directions[2].dot(axis)) * box.extendSize.z;

        var r = r0 + r1 + r2;
        return {
            min: p - r,
            max: p + r
        };
    }
	
	public function axisOverlap(axis:Vector3, box0:BoundingBox, box1:BoundingBox):Bool 
	{
        var result0 = computeBoxExtents(axis, box0);
        var result1 = computeBoxExtents(axis, box1);

        return extentsOverlap(result0.min, result0.max, result1.min, result1.max);
    }
	
	public inline function isInFrustrum(frustumPlanes:Array<Plane>):Bool
	{
        return boundingSphere.isInFrustrum(frustumPlanes) && boundingBox.isInFrustrum(frustumPlanes);
    }
	
	public function _checkCollision(collider:Collider):Bool 
	{
        return collider._canDoCollision(this.boundingSphere.centerWorld, this.boundingSphere.radiusWorld, this.boundingBox.minimumWorld, this.boundingBox.maximumWorld);
    }
	
	public function intersectsPoint(point:Vector3):Bool 
	{
        if (this.boundingSphere.centerWorld == null)
		{
            return false;
        }

        if (!this.boundingSphere.intersectsPoint(point))
		{
            return false;
        }

        if (!this.boundingBox.intersectsPoint(point))
		{
            return false;
        }

        return true;
    }
	
	public function intersects(boundingInfo:BoundingInfo, precise:Bool):Bool
	{
        if (this.boundingSphere.centerWorld == null || 
			boundingInfo.boundingSphere.centerWorld == null)
		{
            return false;
        }

        if (!BoundingSphere.intersects(this.boundingSphere, boundingInfo.boundingSphere)) 
		{
            return false;
        }

        if (!BoundingBox.intersects(this.boundingBox, boundingInfo.boundingBox)) 
		{
            return false;
        }

        if (!precise) 
		{
            return true;
        }

        var box0 = this.boundingBox;
        var box1 = boundingInfo.boundingBox;
		var directions0 = box0.directions;
		var directions1 = box1.directions;

        if (!axisOverlap(directions0[0], box0, box1)) return false;
        if (!axisOverlap(directions0[1], box0, box1)) return false;
        if (!axisOverlap(directions0[2], box0, box1)) return false;
        if (!axisOverlap(directions1[0], box0, box1)) return false;
        if (!axisOverlap(directions1[1], box0, box1)) return false;
        if (!axisOverlap(directions1[2], box0, box1)) return false;
		
		
		var tmpVec3:Vector3 = new Vector3();
        if (!axisOverlap(Vector3.CrossToRef(directions0[0], directions1[0], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[0], directions1[1], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[0], directions1[2], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[1], directions1[0], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[1], directions1[1], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[1], directions1[2], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[2], directions1[0], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[2], directions1[1], tmpVec3), box0, box1)) return false;
        if (!axisOverlap(Vector3.CrossToRef(directions0[2], directions1[2], tmpVec3), box0, box1)) return false;

        return true;
    }
}
