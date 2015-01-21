package com.element.oimo.math;

class MathUtil
{
	public static inline function dotProduct(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float):Float
	{
		return ax * bx + ay * by + az * bz;
	}
	
	// angles in radians
	public static function EulerToAxis( ox:Float, oy:Float, oz:Float ):Array<Float>
	{
		var c1:Float = Math.cos(oy * 0.5);//heading
		var s1:Float = Math.sin(oy * 0.5);
		var c2:Float = Math.cos(oz * 0.5);//altitude
		var s2:Float = Math.sin(oz * 0.5);
		var c3:Float = Math.cos(ox * 0.5);//bank
		var s3:Float = Math.sin(ox * 0.5);
		var c1c2:Float = c1 * c2;
		var s1s2:Float = s1 * s2;
		var w:Float = c1c2 * c3 - s1s2 * s3;
		var x:Float = c1c2 * s3 + s1s2 * c3;
		var y:Float = s1 * c2 * c3 + c1 * s2 * s3;
		var z:Float = c1 * s2 * c3 - s1 * c2 * s3;
		var angle:Float = 2 * Math.acos(w);
		var norm = x * x + y * y + z * z;
		if (norm < 0.001)
		{
			x = 1;
			y = z = 0;
		} 
		else
		{
			norm = Math.sqrt(norm);
			x /= norm;
			y /= norm;
			z /= norm;
		}
		return [angle, x, y, z];
	}
	
	// angles in radians
	public static function EulerToMatrix( ox:Float, oy:Float, oz:Float ):Mat33
	{
		var ch = Math.cos(oy);//heading
		var sh = Math.sin(oy);
		var ca = Math.cos(oz);//altitude
		var sa = Math.sin(oz);
		var cb = Math.cos(ox);//bank
		var sb = Math.sin(ox);
		
		var mtx:Mat33 = new Mat33();
		mtx.e00 = ch * ca;
		mtx.e01 = sh*sb - ch*sa*cb;
		mtx.e02 = ch*sa*sb + sh*cb;
		mtx.e10 = sa;
		mtx.e11 = ca*cb;
		mtx.e12 = -ca*sb;
		mtx.e20 = -sh*ca;
		mtx.e21 = sh*sa*cb + ch*sb;
		mtx.e22 = -sh*sa*sb + ch*cb;
		return mtx;
	}
	
}