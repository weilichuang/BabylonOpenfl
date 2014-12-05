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
package com.element.oimo.physics.collision.broadphase;
	
/**
 * An axis-aligned bounding box.
 * @author saharan
 */
class AABB
{
	public var minX:Float;
	public var maxX:Float;
	public var minY:Float;
	public var maxY:Float;
	public var minZ:Float;
	public var maxZ:Float;
	
	public function new(minX:Float = 0, maxX:Float = 0, minY:Float = 0, maxY:Float = 0, minZ:Float = 0, maxZ:Float = 0)
	{
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		this.minZ = minZ;
		this.maxZ = maxZ;
	}
	
	public function init(minX:Float = 0, maxX:Float = 0, minY:Float = 0, maxY:Float = 0, minZ:Float = 0, maxZ:Float = 0):Void
	{
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		this.minZ = minZ;
		this.maxZ = maxZ;
	}
	
	/**
	 * Set this AABB to the combined AABB of aabb1 and aabb2.
	 * @param	aabb1
	 * @param	aabb2
	 */
	public function combine(aabb1:AABB, aabb2:AABB):Void
	{
		if (aabb1.minX < aabb2.minX)
		{
			minX = aabb1.minX;
		}
		else
		{
			minX = aabb2.minX;
		}
		if (aabb1.maxX > aabb2.maxX)
		{
			maxX = aabb1.maxX;
		}
		else
		{
			maxX = aabb2.maxX;
		}
		if (aabb1.minY < aabb2.minY)
		{
			minY = aabb1.minY;
		}
		else
		{
			minY = aabb2.minY;
		}
		if (aabb1.maxY > aabb2.maxY)
		{
			maxY = aabb1.maxY;
		}
		else
		{
			maxY = aabb2.maxY;
		}
		if (aabb1.minZ < aabb2.minZ)
		{
			minZ = aabb1.minZ;
		}
		else
		{
			minZ = aabb2.minZ;
		}
		if (aabb1.maxZ > aabb2.maxZ)
		{
			maxZ = aabb1.maxZ;
		}
		else
		{
			maxZ = aabb2.maxZ;
		}
		var margin:Float = 0;
		minX -= margin;
		minY -= margin;
		minZ -= margin;
		maxX += margin;
		maxY += margin;
		maxZ += margin;
	}
	
	/**
	 * Get the surface area.
	 * @return
	 */
	public function surfaceArea():Float
	{
		var h:Float = maxY - minY;
		var d:Float = maxZ - minZ;
		return 2 * ((maxX - minX) * (h + d) + h * d);
	}
	
	/**
	 * Get whether the AABB intersects with the point or not.
	 * @param	x
	 * @param	y
	 * @param	z
	 * @return
	 */
	public function intersectsWithPoint(x:Float, y:Float, z:Float):Bool
	{
		return x >= minX && x <= maxX && y >= minY && y <= maxY && z >= minZ && z <= maxZ;
	}

}