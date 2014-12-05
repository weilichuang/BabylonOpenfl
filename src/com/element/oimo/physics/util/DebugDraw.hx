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
package com.element.oimo.physics.util;

import com.element.oimo.glmini.OimoGLMini;
import com.element.oimo.math.Mat44;
import com.element.oimo.physics.collision.shape.BoxShape;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.collision.shape.SphereShape;
import com.element.oimo.physics.constraint.contact.Contact;
import com.element.oimo.physics.constraint.contact.ContactManifold;
import com.element.oimo.physics.constraint.contact.ManifoldPoint;
import com.element.oimo.physics.constraint.joint.Joint;
import com.element.oimo.physics.dynamics.RigidBody;
import com.element.oimo.physics.dynamics.World;
import flash.display3D.*;
import flash.Vector;

/**
 * Simple world renderer
 */
class DebugDraw
{
	private var w:Int;
	private var h:Int;
	private var wld:World;
	private var c3d:Context3D;
	private var gl:OimoGLMini;
	private var m44:Mat44;
	private var ignores:Vector<Shape>;
	private var numIgnores:Int;
	
	public var drawContacts:Bool;
	public var drawForces:Bool;
	public var drawJoints:Bool;
	
	public function new(width:Int, height:Int)
	{
		w = width;
		h = height;
		m44 = new Mat44();
		ignores = new Vector<Shape>(1024, true);
		numIgnores = 0;
		drawContacts = false;
		drawJoints = false;
		drawForces = true;
	}
	
	public function setContext3D(context3D:Context3D):Void
	{
		c3d = context3D;
		gl = new OimoGLMini(c3d, w, h);
		gl.registerSphere(0, 1, 8, 4);
		gl.registerBox(1, 1, 1, 1);
		gl.camera(0, 5, 10, 0, 0, 0, 0, 1, 0);
	}
	
	public function setWorld(world:World):Void
	{
		clearIgnoredShapes();
		wld = world;
	}
	
	public function camera(camX:Float, camY:Float, camZ:Float, targetX:Float = 0, targetY:Float = 0, targetZ:Float = 0, upX:Float = 0, upY:Float = 1, upZ:Float = 0):Void
	{
		gl.camera(camX, camY, camZ, targetX, targetY, targetZ, upX, upY, upZ);
		var dx:Float = targetX - camX;
		var dy:Float = targetY - camY;
		var dz:Float = targetZ - camZ;
		var len:Float = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (len > 0)
			len = 1 / len;
		gl.directionalLightDirection(dx * len, dy * len, dz * len);
	}
	
	public function ignore(shape:Shape):Void
	{
		ignores[numIgnores++] = shape;
	}
	
	public function clearIgnoredShapes():Void
	{
		while (numIgnores > 0)
		{
			ignores[--numIgnores] = null;
		}
	}
	
	/**
	 * Render the world.
	 */
	public function render():Void
	{
		if (c3d == null)
		{
			return;
		}
		gl.beginScene(0.1, 0.1, 0.1);
		gl.material(1, 1, 0, 0.6, 32);
		var alpha:Float = 1;
		var contacts:Contact = wld.contacts;
		var num:Int;
		if (drawContacts)
		{
			while (contacts != null)
			{
				var m:ContactManifold = contacts.manifold;
				num = m.numPoints;
				for (j in 0...num)
				{
					var c:ManifoldPoint = m.points[j];
					gl.push();
					gl.translate(c.position.x, c.position.y, c.position.z);
					gl.push();
					if (c.warmStarted)
					{
						gl.scale(0.1, 0.1, 0.1);
						gl.color(0.5, 0.5, 0.5);
					}
					else
					{
						gl.scale(0.15, 0.15, 0.15);
						gl.color(1, 1, 0);
					}
					gl.drawTriangles(0);
					gl.pop();
					gl.push();
					if (drawForces)
						gl.translate(c.normal.x * -c.normalImpulse * 0.3, c.normal.y * -c.normalImpulse * 0.3, c.normal.z * -c.normalImpulse * 0.3);
					else
						gl.translate(c.normal.x * 0.5, c.normal.y * 0.5, c.normal.z * 0.5);
					var size:Float = 0.075 + Math.sqrt(-c.normalImpulse / c.normalDenominator) * 0.1;
					gl.scale(size, size, size);
					gl.color(1, 0.2, 0.2);
					gl.drawTriangles(0);
					gl.pop();
					if (!drawForces)
					{
						gl.push();
						gl.translate(c.tangent.x * 0.2, c.tangent.y * 0.2, c.tangent.z * 0.2);
						gl.scale(0.075, 0.075, 0.075);
						gl.color(0.2, 0.6, 0.2);
						gl.drawTriangles(0);
						gl.pop();
						gl.push();
						gl.translate(c.binormal.x * 0.2, c.binormal.y * 0.2, c.binormal.z * 0.2);
						gl.scale(0.075, 0.075, 0.075);
						gl.color(0.2, 0.2, 1);
						gl.drawTriangles(0);
						gl.pop();
					}
					else
					{
						gl.push();
						gl.translate((c.tangent.x * c.tangentImpulse + c.binormal.x * c.binormalImpulse) * 0.3, (c.tangent.y * c.tangentImpulse + c.binormal.y * c.binormalImpulse) * 0.3, (c.tangent.z * c.tangentImpulse + c.binormal.z * c.binormalImpulse) * 0.3);
						size = 0.075 + Math.sqrt((c.tangentImpulse > 0 ? c.tangentImpulse : -c.tangentImpulse) / c.tangentDenominator + (c.binormalImpulse > 0 ? c.binormalImpulse : -c.binormalImpulse) / c.binormalDenominator) * 0.1
						;
						gl.scale(size, size, size);
						gl.color(0.2, 1, 1);
						gl.drawTriangles(0);
						gl.pop();
					}
					gl.pop();
				}
				contacts = contacts.next;
			}
		}
		gl.material(0, 0, 1, 0, 0);
		if (drawJoints)
		{
			var joint:Joint = wld.joints;
			while ( joint != null)
			{
				gl.color(1, 0, 0);
				joint.updateAnchorPoints();
				drawLine(joint.anchorPoint1.x, joint.anchorPoint1.y, joint.anchorPoint1.z, joint.anchorPoint2.x, joint.anchorPoint2.y, joint.anchorPoint2.z);
				joint = joint.next;
			}
		}
		
		gl.material(1, 1, 0, 0.6, 32);
		
		var body:RigidBody = wld.rigidBodies;
		while ( body != null)
		{
			var shapeLoopLabel:Bool;
			var shape:Shape = body.shapes;
			while (shape != null)
			{
				shapeLoopLabel = false;
				
				var s:Shape = shape;
				for (l in 0...numIgnores)
				{
					if (s == ignores[l])
					{
						shapeLoopLabel = true;
						break;
					}
				}
				
				//
				if (shapeLoopLabel)
				{
					shapeLoopLabel = false;
					shape = shape.next;
					continue;
				}
				
				gl.push();
				m44.copyMat33(s.rotation);
				m44.e03 = s.position.x;
				m44.e13 = s.position.y;
				m44.e23 = s.position.z;
				gl.transform(m44);
				
				switch (s.parent.type)
				{
					case RigidBody.BODY_DYNAMIC: 
						if ((s.id & 1) != 0)
						{
							if (s.parent.sleeping)
								gl.color(0.2, 0.8, 0.4, alpha);
							else if (s.parent.sleepTime > 0.5)
								gl.color(0.6, 0.7, 0.1, alpha);
							else
								gl.color(1, 0.6, 0.2, alpha);
						}
						else
						{
							if (s.parent.sleeping)
								gl.color(0.2, 0.4, 0.8, alpha);
							else if (s.parent.sleepTime > 0.5)
								gl.color(0.4, 0.3, 0.9, alpha);
							else
								gl.color(0.6, 0.2, 1, alpha);
						}
					case RigidBody.BODY_STATIC: 
						gl.color(0.5, 0.5, 0.5, alpha);
				}
				
				switch (s.type)
				{
					case Shape.SHAPE_SPHERE: 
						var sph:SphereShape = Std.instance(s,SphereShape);
						gl.scale(sph.radius, sph.radius, sph.radius);
						gl.drawTriangles(0);
					case Shape.SHAPE_BOX: 
						var box:BoxShape = Std.instance(s,BoxShape);
						gl.scale(box.width, box.height, box.depth);
						gl.drawTriangles(1);
				}
				gl.pop();
				
				shape = shape.next;
			}
			
			body = body.next;
		}
		gl.endScene();
	}
	
	private var lineM:Mat44 = new Mat44();
	
	private function drawLine(x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float):Void
	{
		var x:Float = (x1 + x2) * 0.5;
		var y:Float = (y1 + y2) * 0.5;
		var z:Float = (z1 + z2) * 0.5;
		var nx:Float = x2 - x1;
		var ny:Float = y2 - y1;
		var nz:Float = z2 - z1;
		var len:Float = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (len < 1e-5)
			return;
		var inv:Float = 1 / len;
		nx *= inv;
		ny *= inv;
		nz *= inv;
		// get tangent and binormal
		var tx:Float = ny * nx - nz * nz;
		var ty:Float = -nz * ny - nx * nx;
		var tz:Float = nx * nz + ny * ny;
		inv = 1 / Math.sqrt(tx * tx + ty * ty + tz * tz);
		tx *= inv;
		ty *= inv;
		tz *= inv;
		var bx:Float = ny * tz - nz * ty;
		var by:Float = nz * tx - nx * tz;
		var bz:Float = nx * ty - ny * tx;
		lineM.init(nx * len, tx * 0.05, bx * 0.05, x, ny * len, ty * 0.05, by * 0.05, y, nz * len, tz * 0.05, bz * 0.05, z, 0, 0, 0, 1);
		gl.push();
		gl.transform(lineM);
		gl.drawTriangles(1);
		gl.pop();
	}
}