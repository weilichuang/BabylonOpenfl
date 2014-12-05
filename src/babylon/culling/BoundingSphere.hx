package babylon.culling;

import babylon.math.FastMath;
import babylon.math.Vector3;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.utils.TempVars;

class BoundingSphere
{
	public var minimum:Vector3;
	public var maximum:Vector3;
	
	public var center:Vector3;
	public var radius:Float;
	
	public var centerWorld:Vector3;
	public var radiusWorld:Float;
	
	public function new(minimum:Vector3, maximum:Vector3) 
	{
		this.minimum = minimum.clone();
        this.maximum = maximum.clone();
        
        var distance:Float = minimum.distanceTo(maximum);
        
        this.center = Vector3.Lerp(minimum, maximum, 0.5);
        this.radius = distance * 0.5;

        this.centerWorld = new Vector3();
        this.update(Matrix.IDENTITY);
	}
	
	public function update(world:Matrix):Void
	{
		var tempVar:TempVars = TempVars.getTempVars();
		var tmpVec:Vector3 = tempVar.vect1;
		
        Vector3.TransformCoordinatesToRef(this.center, world, this.centerWorld);
		Vector3.TransformNormalFromFloatsToRef(1.0, 1.0, 1.0, world, tmpVec);
		
		var tr:Vector3 = tmpVec;
        this.radiusWorld = Math.max(FastMath.fabs(tr.x), Math.max(FastMath.fabs(tr.y), FastMath.fabs(tr.z))) * this.radius;
		
		tempVar.release();
    }
	
	/**
	 判断某球体是否在平截头体内
	int Frustrum::ContainsSphere(const Sphere& refSphere) const
	{
		//球体中心到某裁面的距离
		float fDistance;
		//遍历所有裁面并计算
		for(int i = 0; i < 6; ++i)
		{
			//计算距离
			fDistance = m_plane[i].Normal().dotProduct(refSphere.Center())+m_plane[i].Distance();
			//如果距离小于负的球体半径,那么就是外离
			if(fDistance < -refSphere.Radius())
				return(OUT);
			//如果距离的绝对值小于球体半径,那么就是相交
			if((float)fabs(fDistance) < refSphere.Radius())
				return(INTERSECT);
		}
		//否则,就是内含
		return(IN);
	}
	 */
	public function isInFrustrum(frustumPlanes:Array<Plane>):Bool 
	{
        for (i in 0...6)
		{
			//外离，不在视锥体内
            if (frustumPlanes[i].dotCoordinate(this.centerWorld) <= -this.radiusWorld)
                return false;
        }

        return true;
    }
	
	public function intersectsPoint(point:Vector3):Bool 
	{
        var x = this.centerWorld.x - point.x;
        var y = this.centerWorld.y - point.y;
        var z = this.centerWorld.z - point.z;
        var distance = Math.sqrt((x * x) + (y * y) + (z * z));
		
		//html5中不会inline
		//var distance:Float = this.centerWorld.distanceTo(point);

		if (FastMath.fabs(this.radiusWorld - distance) < Engine.Epsilon)
            return false;

        return true;
    }
	
	public static function intersects(sphere0:BoundingSphere, sphere1:BoundingSphere):Bool
	{
        var x = sphere0.centerWorld.x - sphere1.centerWorld.x;
        var y = sphere0.centerWorld.y - sphere1.centerWorld.y;
        var z = sphere0.centerWorld.z - sphere1.centerWorld.z;
        var distance = Math.sqrt(x * x + y * y + z * z);
		
		//html5中不会inline
		//var distance:Float = sphere0.centerWorld.distanceTo(sphere1.centerWorld);

        if (sphere0.radiusWorld + sphere1.radiusWorld < distance)
            return false;

        return true;
    }
	
}
