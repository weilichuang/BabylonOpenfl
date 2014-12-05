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
package com.element.oimo.physics.constraint.joint;

import com.element.oimo.math.Mat33;
import com.element.oimo.math.Quaternion;
import com.element.oimo.math.Vec3;
import com.element.oimo.physics.constraint.joint.base.Rotational3Constraint;
import com.element.oimo.physics.constraint.joint.base.RotationalConstraint;
import com.element.oimo.physics.constraint.joint.base.Translational3Constraint;
import com.element.oimo.physics.constraint.joint.base.TranslationalConstraint;
import com.element.oimo.physics.dynamics.RigidBody;

/**
 * A slider joint allows for relative translation and relative rotation between two rigid bodies along the axis.
 * @author saharan
 */
class SliderJoint extends Joint
{
	/**
	 * The first axis in local coordinate system.
	 */
	public var localAxis1:Vec3;
	
	/**
	 * The second axis in local coordinate system.
	 */
	public var localAxis2:Vec3;
	
	/**
	 * The limit and motor for the rotation.
	 */
	public var rotationalLimitMotor:LimitMotor;
	
	/**
	 * The limit and motor for the translation.
	 */
	public var translationalLimitMotor:LimitMotor;
	
	private var localAxis1X:Float;
	private var localAxis1Y:Float;
	private var localAxis1Z:Float;
	
	private var localAxis2X:Float;
	private var localAxis2Y:Float;
	private var localAxis2Z:Float;
	
	private var localAngAxis1X:Float;
	private var localAngAxis1Y:Float;
	private var localAngAxis1Z:Float;
	
	private var localAngAxis2X:Float;
	private var localAngAxis2Y:Float;
	private var localAngAxis2Z:Float;
	
	private var t3:Translational3Constraint;
	private var r3:Rotational3Constraint;
	
	private var nor:Vec3;
	private var tan:Vec3;
	private var bin:Vec3;
	
	public function new(config:JointConfig, lowerTranslation:Float, upperTranslation:Float)
	{
		super(config);
		localAxis1 = new Vec3().normalize(config.localAxis1);
		localAxis2 = new Vec3().normalize(config.localAxis2);
		
		var len:Float;
		localAxis1X = localAxis1.x;
		localAxis1Y = localAxis1.y;
		localAxis1Z = localAxis1.z;
		localAngAxis1X = localAxis1Y * localAxis1X - localAxis1Z * localAxis1Z;
		localAngAxis1Y = -localAxis1Z * localAxis1Y - localAxis1X * localAxis1X;
		localAngAxis1Z = localAxis1X * localAxis1Z + localAxis1Y * localAxis1Y;
		len = 1 / Math.sqrt(localAngAxis1X * localAngAxis1X + localAngAxis1Y * localAngAxis1Y + localAngAxis1Z * localAngAxis1Z);
		localAngAxis1X *= len;
		localAngAxis1Y *= len;
		localAngAxis1Z *= len;
		localAxis2X = localAxis2.x;
		localAxis2Y = localAxis2.y;
		localAxis2Z = localAxis2.z;
		
		// make angle axis 2
		var arc:Mat33 = new Mat33().setQuat(new Quaternion().arc(localAxis1, localAxis2));
		localAngAxis2X = localAngAxis1X * arc.e00 + localAngAxis1Y * arc.e01 + localAngAxis1Z * arc.e02;
		localAngAxis2Y = localAngAxis1X * arc.e10 + localAngAxis1Y * arc.e11 + localAngAxis1Z * arc.e12;
		localAngAxis2Z = localAngAxis1X * arc.e20 + localAngAxis1Y * arc.e21 + localAngAxis1Z * arc.e22;
		
		type = Joint.JOINT_SLIDER;
		
		nor = new Vec3();
		tan = new Vec3();
		bin = new Vec3();
		rotationalLimitMotor = new LimitMotor(nor, false);
		r3 = new Rotational3Constraint(this, rotationalLimitMotor, new LimitMotor(tan, true), new LimitMotor(bin, true));
		
		translationalLimitMotor = new LimitMotor(nor, true);
		translationalLimitMotor.lowerLimit = lowerTranslation;
		translationalLimitMotor.upperLimit = upperTranslation;
		t3 = new Translational3Constraint(this, translationalLimitMotor, new LimitMotor(tan, true), new LimitMotor(bin, true));
	}
	
	/**
	 * @inheritDoc
	 */
	override public function preSolve(timeStep:Float, invTimeStep:Float):Void
	{
		var tmpM:Mat33;
		var tmp1X:Float;
		var tmp1Y:Float;
		var tmp1Z:Float;
		
		updateAnchorPoints();
		
		tmpM = body1.rotation;
		var axis1X:Float = localAxis1X * tmpM.e00 + localAxis1Y * tmpM.e01 + localAxis1Z * tmpM.e02;
		var axis1Y:Float = localAxis1X * tmpM.e10 + localAxis1Y * tmpM.e11 + localAxis1Z * tmpM.e12;
		var axis1Z:Float = localAxis1X * tmpM.e20 + localAxis1Y * tmpM.e21 + localAxis1Z * tmpM.e22;
		var angAxis1X:Float = localAngAxis1X * tmpM.e00 + localAngAxis1Y * tmpM.e01 + localAngAxis1Z * tmpM.e02;
		var angAxis1Y:Float = localAngAxis1X * tmpM.e10 + localAngAxis1Y * tmpM.e11 + localAngAxis1Z * tmpM.e12;
		var angAxis1Z:Float = localAngAxis1X * tmpM.e20 + localAngAxis1Y * tmpM.e21 + localAngAxis1Z * tmpM.e22;
		tmpM = body2.rotation;
		var axis2X:Float = localAxis2X * tmpM.e00 + localAxis2Y * tmpM.e01 + localAxis2Z * tmpM.e02;
		var axis2Y:Float = localAxis2X * tmpM.e10 + localAxis2Y * tmpM.e11 + localAxis2Z * tmpM.e12;
		var axis2Z:Float = localAxis2X * tmpM.e20 + localAxis2Y * tmpM.e21 + localAxis2Z * tmpM.e22;
		var angAxis2X:Float = localAngAxis2X * tmpM.e00 + localAngAxis2Y * tmpM.e01 + localAngAxis2Z * tmpM.e02;
		var angAxis2Y:Float = localAngAxis2X * tmpM.e10 + localAngAxis2Y * tmpM.e11 + localAngAxis2Z * tmpM.e12;
		var angAxis2Z:Float = localAngAxis2X * tmpM.e20 + localAngAxis2Y * tmpM.e21 + localAngAxis2Z * tmpM.e22;
		var nx:Float = axis1X * body2.inverseMass + axis2X * body1.inverseMass;
		var ny:Float = axis1Y * body2.inverseMass + axis2Y * body1.inverseMass;
		var nz:Float = axis1Z * body2.inverseMass + axis2Z * body1.inverseMass;
		tmp1X = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (tmp1X > 0)
			tmp1X = 1 / tmp1X;
		nx *= tmp1X;
		ny *= tmp1X;
		nz *= tmp1X;
		var tx:Float = ny * nx - nz * nz;
		var ty:Float = -nz * ny - nx * nx;
		var tz:Float = nx * nz + ny * ny;
		tmp1X = 1 / Math.sqrt(tx * tx + ty * ty + tz * tz);
		tx *= tmp1X;
		ty *= tmp1X;
		tz *= tmp1X;
		var bx:Float = ny * tz - nz * ty;
		var by:Float = nz * tx - nx * tz;
		var bz:Float = nx * ty - ny * tx;
		
		nor.setTo(nx, ny, nz);
		tan.setTo(tx, ty, tz);
		bin.setTo(bx, by, bz);
		
		// ----------------------------------------------
		//            calculate hinge angle
		// ----------------------------------------------
		
		if (nx * (angAxis1Y * angAxis2Z - angAxis1Z * angAxis2Y) + ny * (angAxis1Z * angAxis2X - angAxis1X * angAxis2Z) + nz * (angAxis1X * angAxis2Y - angAxis1Y * angAxis2X) < 0 // cross product
			)
		{
			rotationalLimitMotor.angle = -acosClamp(angAxis1X * angAxis2X + angAxis1Y * angAxis2Y + angAxis1Z * angAxis2Z);
		}
		else
		{
			rotationalLimitMotor.angle = acosClamp(angAxis1X * angAxis2X + angAxis1Y * angAxis2Y + angAxis1Z * angAxis2Z);
		}
		
		// angular error
		tmp1X = axis1Y * axis2Z - axis1Z * axis2Y;
		tmp1Y = axis1Z * axis2X - axis1X * axis2Z;
		tmp1Z = axis1X * axis2Y - axis1Y * axis2X;
		
		r3.limitMotor2.angle = tx * tmp1X + ty * tmp1Y + tz * tmp1Z;
		r3.limitMotor3.angle = bx * tmp1X + by * tmp1Y + bz * tmp1Z;
		
		r3.preSolve(timeStep, invTimeStep);
		t3.preSolve(timeStep, invTimeStep);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function solve():Void
	{
		r3.solve();
		t3.solve();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function postSolve():Void
	{
	}
	
	private function acosClamp(cos:Float):Float
	{
		if (cos > 1)
			return 0;
		else if (cos < -1)
			return Math.PI;
		else
			return Math.acos(cos);
	}

}