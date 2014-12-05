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
package com.element.oimo.physics.demo;

import com.element.oimo.math.Quaternion;
import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.shape.BoxShape;
import com.element.oimo.physics.collision.shape.ShapeConfig;
import com.element.oimo.physics.collision.shape.SphereShape;
import com.element.oimo.physics.constraint.joint.JointConfig;
import com.element.oimo.physics.constraint.joint.WheelJoint;
import com.element.oimo.physics.dynamics.RigidBody;
import com.element.oimo.physics.dynamics.World;

/**
 * ...
 * @author saharan
 */
class VehicleDemo extends DemoBase
{
	private var car:Car;
	private var cameraPos:Vec3;
	
	public function new()
	{
		super();
		title = "Vehicle demo";
	}
	
	override public function reset():Void
	{
		var sc:ShapeConfig = new ShapeConfig();
		var body:RigidBody;
		body = new RigidBody(0, 1, 0);
		body.setupMass(RigidBody.BODY_STATIC);
		world.addRigidBody(body);
		sc.relativePosition.setTo();
		var width:UInt = 9;
		var height:UInt = 5;
		var depth:UInt = 9;
		var bWidth:Float = 0.5;
		var bHeight:Float = 0.5;
		var bDepth:Float = 0.5;
		for (i in 0...width)
		{
			for (j in 0...height)
			{
				for (k in 0...depth)
				{
					body = new RigidBody((i - (width - 1) * 0.5) * 8, // 剛体を作成
						j * (bHeight * 1.01) + bHeight * 0.5, (k - (depth - 1) * 0.5) * 8);
					body.addShape(new BoxShape(sc, bWidth, bHeight, bDepth)); // 形状を追加
					body.setupMass(); // 質量情報を計算
					world.addRigidBody(body); // ワールドに追加
				}
			}
		}
		
		car = new Car(0, 1, 6, world);
		control = car.body;
		cameraPos = new Vec3(0, 4, 12);
	}
	
	override public function cameraControl(pi:Float, theta:Float):Void
	{
		var eye:Vec3 = new Vec3(0, 3, 6); // 視点の相対位置
		eye.mulMat(car.body.rotation, eye);
		eye.add(eye, car.body.position);
		var diff:Vec3 = new Vec3().sub(eye, cameraPos);
		var len:Float = diff.length();
		if (len > 1)
		{
			diff.scaleEqual((len - 1) / len);
			cameraPos.addEqual(diff);
		}
		draw.camera(cameraPos.x, cameraPos.y, cameraPos.z, car.body.position.x, car.body.position.y, car.body.position.z);
	}
	
	override public function userControl(up:Bool, down:Bool, left:Bool, right:Bool, pi:Float, theta:Float):Void
	{
		car.update((up ? 1 : 0) + (down ? -1 : 0), (left ? -1 : 0) + (right ? 1 : 0));
	}

}

class Car
{
	public var body:RigidBody;
	public var wheel1:RigidBody;
	public var wheel2:RigidBody;
	public var wheel3:RigidBody;
	public var wheel4:RigidBody;
	public var joint1:WheelJoint;
	public var joint2:WheelJoint;
	public var joint3:WheelJoint;
	public var joint4:WheelJoint;
	private var speed:Float;
	private var motor:Bool;
	private var angle:Float;

	public function new(x:Float, y:Float, z:Float, world:World)
	{
		body = new RigidBody(x, y, z);
		var sc:ShapeConfig = new ShapeConfig();
		sc.density = 10;
		body.allowSleep = false;
		// create a body
		var off:Float = 0.4;
		var rad:Float = 0.3;
		var w:Float = 0.5;
		var d:Float = 1;
		sc.relativePosition.setTo(0, off, 0);
		body.addShape(new BoxShape(sc, w * 2, 0.6, d * 2));
		// create wheels
		sc.friction = 4;
		sc.relativePosition.setTo(0, 0, 0);
		wheel1 = new RigidBody(x - w, y, z - d);
		wheel1.addShape(new SphereShape(sc, rad));
		wheel1.addShape(new BoxShape(sc, rad * 2, 0.2, 0.2));
		wheel2 = new RigidBody(x + w, y, z - d);
		wheel2.addShape(new SphereShape(sc, rad));
		wheel2.addShape(new BoxShape(sc, rad * 2, 0.2, 0.2));
		wheel3 = new RigidBody(x - w, y, z + d);
		wheel3.addShape(new SphereShape(sc, rad));
		wheel3.addShape(new BoxShape(sc, rad * 2, 0.2, 0.2));
		wheel4 = new RigidBody(x + w, y, z + d);
		wheel4.addShape(new SphereShape(sc, rad));
		wheel4.addShape(new BoxShape(sc, rad * 2, 0.2, 0.2));
		
		body.setupMass(RigidBody.BODY_DYNAMIC, false);
		wheel1.setupMass();
		wheel2.setupMass();
		wheel3.setupMass();
		wheel4.setupMass();
		world.addRigidBody(body);
		world.addRigidBody(wheel1);
		world.addRigidBody(wheel2);
		world.addRigidBody(wheel3);
		world.addRigidBody(wheel4);
		
		// create joints
		var jc:JointConfig = new JointConfig();
		jc.localAxis1.setTo(0, -1, 0);
		jc.localAxis2.setTo(-1, 0, 0);
		jc.localAnchorPoint1.setTo(-w, 0, -d);
		jc.body1 = body;
		jc.body2 = wheel1;
		joint1 = new WheelJoint(jc);
		jc.localAnchorPoint1.setTo(w, 0, -d);
		jc.body2 = wheel2;
		joint2 = new WheelJoint(jc);
		jc.localAnchorPoint1.setTo(-w, 0, d);
		jc.body2 = wheel3;
		joint3 = new WheelJoint(jc);
		jc.localAnchorPoint1.setTo(w, 0, d);
		jc.body2 = wheel4;
		joint4 = new WheelJoint(jc);
		
		// handled
		joint1.rotationalLimitMotor1.setLimit(0, 0);
		joint2.rotationalLimitMotor1.setLimit(0, 0);
		joint3.rotationalLimitMotor1.setLimit(0, 0);
		joint4.rotationalLimitMotor1.setLimit(0, 0);
		joint1.rotationalLimitMotor1.setSpring(8, 1);
		joint2.rotationalLimitMotor1.setSpring(8, 1);
		angle = 0;
		world.addJoint(joint1);
		world.addJoint(joint2);
		world.addJoint(joint3);
		world.addJoint(joint4);
	}

	public function update(accelSign:Int, handleSign:Int):Void
	{
		var breaking:Bool = body.linearVelocity.dot(new Vec3(body.rotation.e02, body.rotation.e12, body.rotation.e22)) * accelSign > 0;
		var ratio:Float = 0;
		var v:Float = body.linearVelocity.length() * 3.6;
		var maxSpeed:Float = Math.PI * 2 / 60 * 1200; // 1200rpm
		var minTorque:Float = 4;
		
		if (breaking)
			minTorque *= 2;
		
		if (v < 10)
		{
			ratio = 3;
		}
		else if (v < 30)
		{
			ratio = 2;
		}
		else if (v < 70)
		{
			ratio = 1.4;
		}
		else if (v < 100)
		{
			ratio = 1.2;
		}
		else
		{
			ratio = 1;
		}
		
		var speed:Float = maxSpeed / ratio * accelSign;
		var torque:Float = minTorque * ratio * (accelSign * accelSign);
		
		var deg45:Float = Math.PI / 4;
		angle += handleSign * 0.02;
		angle *= 0.94;
		angle = angle > deg45 ? deg45 : angle < -deg45 ? -deg45 : angle;
		
		joint1.rotationalLimitMotor2.setMotor(speed, torque);
		joint2.rotationalLimitMotor2.setMotor(speed, torque);
		joint3.rotationalLimitMotor2.setMotor(speed, torque);
		joint4.rotationalLimitMotor2.setMotor(speed, torque);
		joint1.rotationalLimitMotor1.setLimit(angle, angle);
		joint2.rotationalLimitMotor1.setLimit(angle, angle);
		
		var axis:Vec3 = new Vec3(body.rotation.e01, body.rotation.e11, body.rotation.e21); // up axis
		
		correctRotation(wheel1);
		correctRotation(wheel2);
		correctRotation(wheel3);
		correctRotation(wheel4);
	}

	private function correctRotation(w:RigidBody):Void
	{
		var axis1:Vec3 = new Vec3(body.rotation.e01, body.rotation.e11, body.rotation.e21);
		var axis2:Vec3 = new Vec3(w.rotation.e00, w.rotation.e10, w.rotation.e20);
		var axis3:Vec3 = new Vec3().sub(axis2, axis1.scaleEqual(axis1.dot(axis2)));
		w.orientation.mul(new Quaternion().arc(axis2, axis3.normalize(axis3)), w.orientation);
		w.orientation.normalize(w.orientation);
	}
}