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
package com.element.oimo.math;

	
/**
 * A quaternion. This is used to represent three-dimansional orientations of rigid bodies.
 * @author saharan
 */
class Quaternion
{
	public var w:Float;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	/**
	 * Constructor.
	 * If the parameters are empty, the quaternion will be set to the identity quaternion.
	 * @param	s
	 * @param	x
	 * @param	y
	 * @param	z
	 */
	public function new(s:Float = 1, x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.w = s;
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	/**
	 * Initialize the quaternion.
	 * If the parameters are empty, the quaternion will be set to the identity quaternion.
	 */
	public function setTo(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public inline function equals(other:Quaternion):Bool 
	{
		return this.x == other.x && this.y == other.y && this.z == other.z && this.w == other.w;
	}
	
	/**
	 * this = q1 + q2
	 * @param	q1
	 * @param	q2
	 * @return
	 */
	public function add(q1:Quaternion, q2:Quaternion):Quaternion
	{
		w = q1.w + q2.w;
		x = q1.x + q2.x;
		y = q1.y + q2.y;
		z = q1.z + q2.z;
		return this;
	}
	
	/**
	 * this = q1 - q2
	 * @param	q1
	 * @param	q2
	 * @return
	 */
	public function sub(q1:Quaternion, q2:Quaternion):Quaternion
	{
		w = q1.w - q2.w;
		x = q1.x - q2.x;
		y = q1.y - q2.y;
		z = q1.z - q2.z;
		return this;
	}
	
	/**
	 * this = q * s
	 * @param	q
	 * @param	s
	 * @return
	 */
	public function scale(q:Quaternion, s:Float):Quaternion
	{
		this.w = q.w * s;
		x = q.x * s;
		y = q.y * s;
		z = q.z * s;
		return this;
	}
	
	/**
	 * this = q1 * q2
	 * @param	q1
	 * @param	q2
	 * @return
	 */
	public function mul(q1:Quaternion, q2:Quaternion):Quaternion
	{
		var s:Float = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
		var x:Float = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
		var y:Float = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
		var z:Float = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
		this.w = s;
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}
	
	/**
	 * Set this quaternion to the shortest arc rotation quaternion.
	 * Note that v1 and v2 must be normalized.
	 * @param	v1 from
	 * @param	v2 to
	 * @return
	 */
	public function arc(v1:Vec3, v2:Vec3):Quaternion
	{
		var x1:Float = v1.x;
		var y1:Float = v1.y;
		var z1:Float = v1.z;
		var x2:Float = v2.x;
		var y2:Float = v2.y;
		var z2:Float = v2.z;
		var d:Float = x1 * x2 + y1 * y2 + z1 * z2; // cos(theta)
		if (d == -1)
		{ // 180 rotation, set a vector perpendicular to v1
			x2 = y1 * x1 - z1 * z1;
			y2 = -z1 * y1 - x1 * x1;
			z2 = x1 * z1 + y1 * y1;
			d = 1 / Math.sqrt(x2 * x2 + y2 * y2 + z2 * z2);
			w = 0;
			x = x2 * d;
			y = y2 * d;
			z = z2 * d;
			return this;
		}
		var cx:Float = y1 * z2 - z1 * y2;
		var cy:Float = z1 * x2 - x1 * z2;
		var cz:Float = x1 * y2 - y1 * x2;
		w = Math.sqrt((1 + d) * 0.5); // cos(theta / 2)
		d = 0.5 / w; // sin(theta / 2) / sin(theta)
		x = cx * d;
		y = cy * d;
		z = cz * d;
		return this;
	}
	
	/**
	 * Set this quaternion to the normalized quaternion of q.
	 * @param	q
	 * @return
	 */
	public function normalize(q:Quaternion):Quaternion
	{
		var len:Float = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
		if (len > 0)
			len = 1 / len;
		w = q.w * len;
		x = q.x * len;
		y = q.y * len;
		z = q.z * len;
		return this;
	}
	
	/**
	 * this = -q
	 * @param	q
	 * @return
	 */
	public function invert(q:Quaternion):Quaternion
	{
		w = q.w;
		x = -q.x;
		y = -q.y;
		z = -q.z;
		return this;
	}
	
	/**
	 * Get the length of the quaternion.
	 * @return
	 */
	public inline function length():Float
	{
		return Math.sqrt(w * w + x * x + y * y + z * z);
	}
	
	/**
	 * this = q
	 * @param	q
	 * @return
	 */
	public inline function copyFrom(q:Quaternion):Void
	{
		w = q.w;
		x = q.x;
		y = q.y;
		z = q.z;
	}
	
	/**
	 * Get the clone of the quaternion.
	 * @return
	 */
	public function clone(q:Quaternion):Quaternion
	{
		return new Quaternion(w, x, y, z);
	}
	
	/**
	 * Get the string of the quaternion.
	 * @return
	 */
	public function toString():String
	{
		return "Quat[" + w + ", (" + x + ", " + y + ", " + z + ")]";
	}

}