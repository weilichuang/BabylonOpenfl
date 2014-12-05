package babylon.math;

class Frustum 
{
	public static function GetPlanes(transform:Matrix):Array<Plane> 
	{
		var frustumPlanes:Array<Plane>  = [];

        for (index in 0...6)
		{
            frustumPlanes.push(new Plane(0, 0, 0, 0));
        }

        Frustum.GetPlanesToRef(transform, frustumPlanes);

        return frustumPlanes;
	}
	
	public static function GetPlanesToRef(transform:Matrix, frustumPlanes:Array<Plane>):Array<Plane> 
	{
		var m = transform.m;
		var m0:Float = m[0]; var m1:Float = m[1]; var m2:Float = m[2]; var m3:Float = m[3];
		var m4:Float = m[4]; var m5:Float = m[5]; var m6:Float = m[6]; var m7:Float = m[7];
		var m8:Float = m[8]; var m9:Float = m[9]; var m10:Float = m[10]; var m11:Float = m[11];
		var m12:Float = m[12]; var m13:Float = m[13]; var m14:Float = m[14]; var m15:Float = m[15];
		
		var plane:Plane;
		// Near
		plane = frustumPlanes[0];
        plane.normal.x = m3 + m2;
        plane.normal.y = m7 + m6;
        plane.normal.z = m10 + m10;
        plane.d = m15 + m14;
        plane.normalize();

        // Far
		plane = frustumPlanes[1];
        plane.normal.x = m3 - m2;
        plane.normal.y = m7 - m6;
        plane.normal.z = m11 - m10;
        plane.d = m15 - m14;
        plane.normalize();

        // Left
		plane = frustumPlanes[2];
        plane.normal.x = m3 + m0;
        plane.normal.y = m7 + m4;
        plane.normal.z = m11 + m8;
        plane.d = m15 + m12;
        plane.normalize();

        // Right
		plane = frustumPlanes[3];
        plane.normal.x = m3 - m0;
        plane.normal.y = m7 - m4;
        plane.normal.z = m11 - m8;
        plane.d = m15 - m12;
        plane.normalize();

        // Top
		plane = frustumPlanes[4];
        plane.normal.x = m3 - m1;
        plane.normal.y = m7 - m5;
        plane.normal.z = m11 - m9;
        plane.d = m15 - m13;
        plane.normalize();

        // Bottom
		plane = frustumPlanes[5];
        plane.normal.x = m3 + m1;
        plane.normal.y = m7 + m5;
        plane.normal.z = m11 + m9;
        plane.d = m15 + m13;
        plane.normalize();
		
		return frustumPlanes;
	}
}
