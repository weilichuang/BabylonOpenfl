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
package com.element.oimo.physics.collision.broadphase.sap;

import com.element.oimo.physics.collision.broadphase.Proxy;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.dynamics.RigidBody;
import haxe.ds.Vector;

/**
 * A proxy for sweep and prune broad-phase.
 * @author saharan
 */
class SAPProxy extends Proxy
{
	/**
	 * The minimum elements on each axis.
	 */
	public var min:Vector<SAPElement>;
	
	/**
	 * The maximum elements on each axis.
	 */
	public var max:Vector<SAPElement>;
	
	/**
	 * Type of the axis to which the proxy belongs to. [0:none, 1:dynamic, 2:static]
	 */
	public var belongsTo:Int = 0;
	
	private var sap:SAPBroadPhase;
	
	public function new(sap:SAPBroadPhase, shape:Shape)
	{
		super(shape);
		this.sap = sap;
		
		min = new Vector<SAPElement>(3);
		max = new Vector<SAPElement>(3);
		
		min[0] = new SAPElement(this, false);
		max[0] = new SAPElement(this, true);
		
		min[1] = new SAPElement(this, false);
		max[1] = new SAPElement(this, true);
		
		min[2] = new SAPElement(this, false);
		max[2] = new SAPElement(this, true);
		
		max[0].pair = min[0];
		max[1].pair = min[1];
		max[2].pair = min[2];
		
		min[0].min1 = min[1];
		min[0].max1 = max[1];
		min[0].min2 = min[2];
		min[0].max2 = max[2];
		
		min[1].min1 = min[0];
		min[1].max1 = max[0];
		min[1].min2 = min[2];
		min[1].max2 = max[2];
		
		min[2].min1 = min[0];
		min[2].max1 = max[0];
		min[2].min2 = min[1];
		min[2].max2 = max[1];
	}
	
	/**
	 * Returns whether the proxy is dynamic or not.
	 * @return
	 */
	public inline function isDynamic():Bool
	{
		var body:RigidBody = shape.parent;
		return body.isDynamic && !body.sleeping;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function update():Void
	{
		min[0].value = aabb.minX;
		max[0].value = aabb.maxX;
		min[1].value = aabb.minY;
		max[1].value = aabb.maxY;
		min[2].value = aabb.minZ;
		max[2].value = aabb.maxZ;
		if (belongsTo == 1 && !isDynamic() || belongsTo == 2 && isDynamic())
		{
			sap.removeProxy(this);
			sap.addProxy(this);
		}
	}

}