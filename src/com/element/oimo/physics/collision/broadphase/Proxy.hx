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

import com.element.oimo.physics.collision.shape.Shape;

/**
 * A proxy is used for broad-phase collecting pairs that can be colliding.
 */
class Proxy
{
	/**
	 * The parent shape.
	 */
	public var shape:Shape = null;
	
	/**
	 * The axis-aligned bounding box.
	 */
	public var aabb:AABB;
	
	public function new(shape:Shape)
	{
		this.shape = shape;
		aabb = shape.aabb;
	}
	
	/**
	 * Update the proxy.
	 */
	public function update():Void
	{
		throw ("Inheritance error.");
	}

}