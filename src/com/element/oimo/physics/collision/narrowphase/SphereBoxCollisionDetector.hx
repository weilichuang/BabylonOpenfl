/* Copyright (c) 2012-2013 EL-EMENT saharan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation  * files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,  * modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package com.element.oimo.physics.collision.narrowphase;

import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.shape.BoxShape;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.collision.shape.SphereShape;
import com.element.oimo.physics.constraint.contact.ContactManifold;

/**
 * A collision detector which detects collisions between sphere and box.
 * @author saharan
 */
class SphereBoxCollisionDetector extends CollisionDetector
{
	public function new(flip:Bool)
	{
		super();
		this.flip = flip;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function detectCollision(shape1:Shape, shape2:Shape, manifold:ContactManifold):Void
	{
		var s:SphereShape;
		var b:BoxShape;
		if (flip)
		{
			s = Std.instance(shape2,SphereShape);
			b = Std.instance(shape1,BoxShape);
		}
		else
		{
			s = Std.instance(shape1,SphereShape);
			b = Std.instance(shape2,BoxShape);
		}
		var ps:Vec3 = s.position;
		var psx:Float = ps.x;
		var psy:Float = ps.y;
		var psz:Float = ps.z;
		var pb:Vec3 = b.position;
		var pbx:Float = pb.x;
		var pby:Float = pb.y;
		var pbz:Float = pb.z;
		var rad:Float = s.radius;
		// normal
		var nw:Vec3 = b.normalDirectionWidth;
		var nh:Vec3 = b.normalDirectionHeight;
		var nd:Vec3 = b.normalDirectionDepth;
		// half
		var hw:Float = b.halfWidth;
		var hh:Float = b.halfHeight;
		var hd:Float = b.halfDepth;
		// diff
		var dx:Float = psx - pbx;
		var dy:Float = psy - pby;
		var dz:Float = psz - pbz;
		// shadow
		var sx:Float = nw.x * dx + nw.y * dy + nw.z * dz;
		var sy:Float = nh.x * dx + nh.y * dy + nh.z * dz;
		var sz:Float = nd.x * dx + nd.y * dy + nd.z * dz;
		// closest
		var cx:Float;
		var cy:Float;
		var cz:Float;
		var len:Float;
		var invLen:Float;
		var overlap:Int = 0;
		if (sx > hw)
		{
			sx = hw;
		}
		else if (sx < -hw)
		{
			sx = -hw;
		}
		else
		{
			overlap = 1;
		}
		if (sy > hh)
		{
			sy = hh;
		}
		else if (sy < -hh)
		{
			sy = -hh;
		}
		else
		{
			overlap |= 2;
		}
		if (sz > hd)
		{
			sz = hd;
		}
		else if (sz < -hd)
		{
			sz = -hd;
		}
		else
		{
			overlap |= 4;
		}
		if (overlap == 7)
		{
			// center of sphere is in the box
			if (sx < 0)
			{
				dx = hw + sx;
			}
			else
			{
				dx = hw - sx;
			}
			if (sy < 0)
			{
				dy = hh + sy;
			}
			else
			{
				dy = hh - sy;
			}
			if (sz < 0)
			{
				dz = hd + sz;
			}
			else
			{
				dz = hd - sz;
			}
			if (dx < dy)
			{
				if (dx < dz)
				{
					// x
					len = dx - hw;
					if (sx < 0)
					{
						sx = -hw;
						dx = nw.x;
						dy = nw.y;
						dz = nw.z;
					}
					else
					{
						sx = hw;
						dx = -nw.x;
						dy = -nw.y;
						dz = -nw.z;
					}
				}
				else
				{
					// z
					len = dz - hd;
					if (sz < 0)
					{
						sz = -hd;
						dx = nd.x;
						dy = nd.y;
						dz = nd.z;
					}
					else
					{
						sz = hd;
						dx = -nd.x;
						dy = -nd.y;
						dz = -nd.z;
					}
				}
			}
			else
			{
				if (dy < dz)
				{
					// y
					len = dy - hh;
					if (sy < 0)
					{
						sy = -hh;
						dx = nh.x;
						dy = nh.y;
						dz = nh.z;
					}
					else
					{
						sy = hh;
						dx = -nh.x;
						dy = -nh.y;
						dz = -nh.z;
					}
				}
				else
				{
					// z
					len = dz - hd;
					if (sz < 0)
					{
						sz = -hd;
						dx = nd.x;
						dy = nd.y;
						dz = nd.z;
					}
					else
					{
						sz = hd;
						dx = -nd.x;
						dy = -nd.y;
						dz = -nd.z;
					}
				}
			}
			cx = pbx + sx * nw.x + sy * nh.x + sz * nd.x;
			cy = pby + sx * nw.y + sy * nh.y + sz * nd.y;
			cz = pbz + sx * nw.z + sy * nh.z + sz * nd.z;
			manifold.addPoint(psx + rad * dx, psy + rad * dy, psz + rad * dz, dx, dy, dz, len - rad, flip);
		}
		else
		{
			// closest
			cx = pbx + sx * nw.x + sy * nh.x + sz * nd.x;
			cy = pby + sx * nw.y + sy * nh.y + sz * nd.y;
			cz = pbz + sx * nw.z + sy * nh.z + sz * nd.z;
			dx = cx - ps.x;
			dy = cy - ps.y;
			dz = cz - ps.z;
			len = dx * dx + dy * dy + dz * dz;
			if (len > 0 && len < rad * rad)
			{
				len = Math.sqrt(len);
				invLen = 1 / len;
				dx *= invLen;
				dy *= invLen;
				dz *= invLen;
				manifold.addPoint(psx + rad * dx, psy + rad * dy, psz + rad * dz, dx, dy, dz, len - rad, flip);
			}
		}
	}

}