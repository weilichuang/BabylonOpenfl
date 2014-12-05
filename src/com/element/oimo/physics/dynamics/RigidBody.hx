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
package com.element.oimo.physics.dynamics;

import com.element.oimo.math.Mat33;
import com.element.oimo.math.MathUtil;
import com.element.oimo.math.Quaternion;
import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.shape.MassInfo;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.constraint.contact.ContactLink;
import com.element.oimo.physics.constraint.joint.JointLink;
import com.element.oimo.physics.OimoPhysics;

/**
 * 剛体のクラスです。
 * 剛体は衝突処理用に単数あるいは複数の形状を持ち、
 * それぞれ個別にパラメーターを設定できます。
 * @author saharan
 */
class RigidBody
{
	/**
	 * 動的な剛体を表す剛体の種類です。
	 */
	public static inline var BODY_DYNAMIC:Int = 0x1;
	
	/**
	 * 静的な剛体を表す剛体の種類です。
	 */
	public static inline var BODY_STATIC:Int = 0x2;
	
	/**
	 * 一つの剛体に追加できる形状の最大数です。
	 */
	public static inline var MAX_SHAPES:Int = 64;
	
	public var name:String;
	
	public var prev:RigidBody;
	public var next:RigidBody;
	
	/**
	 * 剛体の種類を表します。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 剛体の種類を変更する場合は、必ず
	 * setupMass メソッドの引数に設定したい種類を指定してください。
	 */
	public var type:Int = 1;
	
	/**
	 * この剛体が動的な剛体であるかどうかを示します。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var isDynamic:Bool;
	
	/**
	 * この剛体が静的な剛体であるかどうかを示します。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var isStatic:Bool;
	
	/**
	 * 重心のワールド座標です。
	 */
	public var position:Vec3 = new Vec3(1, 1, 1);
	
	/**
	 * 姿勢を表すクォータニオンです。
	 */
	public var orientation:Quaternion;
	
	/**
	 * スリープ直前での重心のワールド座標です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var sleepPosition:Vec3;
	
	/**
	 * スリープ直前での姿勢を表すクォータニオンです。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var sleepOrientation:Quaternion;
	
	/**
	 * 並進速度です。
	 */
	public var linearVelocity:Vec3;
	
	/**
	 * 角速度です。
	 */
	public var angularVelocity:Vec3;
	
	/**
	 * 姿勢を表す回転行列です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 回転行列は、ステップ毎にクォータニオンから再計算されます。
	 */
	public var rotation:Mat33;
	
	/**
	 * 質量です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 質量は setupMass メソッドを呼び出すと、
	 * 含まれている形状から自動で再計算されます。
	 */
	public var mass:Float;
	
	/**
	 * 質量の逆数です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 質量は setupMass メソッドを呼び出すと、
	 * 含まれている形状から自動で再計算されます。
	 */
	public var inverseMass:Float;
	
	/**
	 * ワールド系での慣性テンソルの逆行列です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * ワールド系での慣性テンソルの逆行列は、ステップ毎に
	 * 姿勢と初期状態の慣性テンソルの逆数から再計算されます。
	 */
	public var inverseInertia:Mat33;
	
	/**
	 * 初期状態での慣性テンソルです。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 慣性テンソルは setupMass メソッドを呼び出すと、
	 * 含まれている形状から自動で再計算されます。
	 */
	public var localInertia:Mat33;
	
	/**
	 * 初期状態での慣性テンソルの逆行列です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 *
	 * 慣性テンソルは setupMass メソッドを呼び出すと、
	 * 含まれている形状から自動で再計算されます。
	 */
	public var inverseLocalInertia:Mat33;
	
	/**
	 * 剛体に含まれている形状の配列です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var shapes:Shape = null;
	
	/**
	 * 剛体に含まれている形状の数です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var numShapes:Int = 0;
	
	/**
	 * 剛体が追加されているワールドです。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var parent:World;
	
	public var contactLink:ContactLink;
	public var numContacts:Int = 0;
	
	/**
	 * 剛体に接続されているジョイントのリンク配列です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var jointLink:JointLink;
	
	/**
	 * 剛体に接続されているジョイントの数です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var numJoints:Int = 0;
	
	/**
	 * 剛体がシミュレーションアイランドに追加されたかどうかを示します。
	 * この変数は内部でのみ使用されます。
	 */
	public var addedToIsland:Bool;
	
	/**
	 * 剛体が静止してからの時間です。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 */
	public var sleepTime:Float;
	
	/**
	 * 剛体がスリープ状態であるかどうかを示します。
	 * <strong>この変数は外部から変更しないでください。</strong>
	 * 剛体をスリープさせる場合は sleep メソッドを、
	 * 剛体のスリープ状態を解除する場合は awake メソッドを呼び出してください。
	 */
	public var sleeping:Bool = false;
	
	/**
	 * 剛体をスリープさせるかを示します。
	 * シミュレーションアイランド内の全ての剛体が静止している状態が一定時間続くと、
	 * そのシミュレーションアイランドはスリープ状態に入ります。
	 * スリープしている剛体は awake メソッドが呼び出されるか、
	 * 外部からの干渉を受けるまで、スリープ状態が解除されることはありません。
	 */
	public var allowSleep:Bool = false;
	
	public var massInfo:MassInfo = new MassInfo();
	
	/**
	 * 新しく RigidBody オブジェクトを作成します。
	 * 回転成分を指定することもできます。
	 * @param	x
	 * @param	y
	 * @param	z
	 * @param	rad ラジアンでの回転角度
	 * @param	ax 回転軸の x 成分
	 * @param	ay 回転軸の y 成分
	 * @param	az 回転軸の z 成分
	 */
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, rad:Float = 0, ax:Float = 0, ay:Float = 0, az:Float = 0)
	{
		position = new Vec3(x, y, z);
		var len:Float = ax * ax + ay * ay + az * az;
		if (len > 0)
		{
			len = 1 / Math.sqrt(len);
			ax *= len;
			ay *= len;
			az *= len;
		}
		var sin:Float = Math.sin(rad * 0.5);
		var cos:Float = Math.cos(rad * 0.5);
		orientation = new Quaternion(cos, sin * ax, sin * ay, sin * az);
		linearVelocity = new Vec3();
		angularVelocity = new Vec3();
		sleepPosition = new Vec3();
		sleepOrientation = new Quaternion();
		rotation = new Mat33();
		inverseInertia = new Mat33();
		localInertia = new Mat33();
		inverseLocalInertia = new Mat33();
		allowSleep = true;
		sleepTime = 0;
	}
	
	/**
	 * 剛体に形状を追加します。
	 * 形状を追加した場合、次のステップ開始までに setupMass メソッドを呼び出してください。
	 * @param	shape 追加する形状
	 */
	public function addShape(newShape:Shape):Void
	{
		if (newShape.parent != null)
		{
			throw ("一つの形状を複数剛体に追加することはできません");
		}
		
		if (shapes != null)
		{
			(shapes.prev = newShape).next = shapes;
		}
			
		shapes = newShape;
		shapes.parent = this;
		if (parent != null)
			parent.addShape(shapes);
		numShapes++;
	}
	
	/**
	 * 剛体から形状を削除します。
	 * 形状を削除した場合、次のステップ開始までに setupMass メソッドを呼び出してください。
	 * @param	shape 削除する形状
	 */
	public function removeShape(shape:Shape):Void
	{
		var remove:Shape = shape;
		if (remove.parent != this)
			return;
			
		var prev:Shape = remove.prev;
		var next:Shape = remove.next;
		if (prev != null)
			prev.next = next;
			
		if (next != null)
			next.prev = prev;
			
		if (shapes == remove)
			shapes = next;
			
		remove.prev = null;
		remove.next = null;
		remove.parent = null;
		if (parent != null)
			parent.removeShape(remove);
		numShapes--;
	}
	
	/**
	 * Calulates mass datas(center of gravity, mass, moment inertia, etc...).
	 * If the parameter type is set to BODY_STATIC, the rigid body will be fixed to the space.
	 * If the parameter adjustPosition is set to true, the shapes' relative positions and
	 * the rigid body's position will be adjusted to the center of gravity.
	 * @param	type
	 * @param	adjustPosition
	 */
	public function setupMass(type:Int = BODY_DYNAMIC, adjustPosition:Bool = true):Void
	{
		this.type = type;
		isDynamic = type == BODY_DYNAMIC;
		isStatic = type == BODY_STATIC;
		mass = 0;
		localInertia.init(0, 0, 0, 0, 0, 0, 0, 0, 0);
		var tmpM:Mat33 = new Mat33();
		var tmpV:Vec3 = new Vec3();
		
		var relX:Float;
		var relY:Float;
		var relZ:Float;
		var xy:Float;
		var yz:Float;
		var zx:Float;
		var shape:Shape = shapes;
		while (shape != null)
		{
			shape.calculateMassInfo(massInfo);
			var shapeMass:Float = massInfo.mass;
			relX = shape.relativePosition.x;
			relY = shape.relativePosition.y;
			relZ = shape.relativePosition.z;
			
			tmpV.x += relX * shapeMass;
			tmpV.y += relY * shapeMass;
			tmpV.z += relZ * shapeMass;
			mass += shapeMass;
			
			rotateInertia(shape.relativeRotation, massInfo.inertia, tmpM);
			localInertia.addEqual(tmpM);
			
			// add offset inertia
			localInertia.e00 += shapeMass * (relY * relY + relZ * relZ);
			localInertia.e11 += shapeMass * (relX * relX + relZ * relZ);
			localInertia.e22 += shapeMass * (relX * relX + relY * relY);
			xy = shapeMass * relX * relY;
			yz = shapeMass * relY * relZ;
			zx = shapeMass * relZ * relX;
			localInertia.e01 -= xy;
			localInertia.e10 -= xy;
			localInertia.e02 -= yz;
			localInertia.e20 -= yz;
			localInertia.e12 -= zx;
			localInertia.e21 -= zx;
			
			shape = shape.next;
		}
		
		if (mass == 0)
		{
			inverseMass = 0;
		}
		else
		{
			inverseMass = 1 / mass;
		}
		
		tmpV.scaleEqual(inverseMass);
		
		if (adjustPosition)
		{
			position.addEqual(tmpV);
			
			shape = shapes; 
			while (shape != null )
			{
				shape.relativePosition.subEqual(tmpV);
				shape = shape.next;
			}
			// subtract offset inertia
			relX = tmpV.x;
			relY = tmpV.y;
			relZ = tmpV.z;
			localInertia.e00 -= mass * (relY * relY + relZ * relZ);
			localInertia.e11 -= mass * (relX * relX + relZ * relZ);
			localInertia.e22 -= mass * (relX * relX + relY * relY);
			xy = mass * relX * relY;
			yz = mass * relY * relZ;
			zx = mass * relZ * relX;
			localInertia.e01 += xy;
			localInertia.e10 += xy;
			localInertia.e02 += yz;
			localInertia.e20 += yz;
			localInertia.e12 += zx;
			localInertia.e21 += zx;
		}
		
		inverseLocalInertia.invert(localInertia);
		
		if (type == BODY_STATIC)
		{
			inverseMass = 0;
			inverseLocalInertia.init(0, 0, 0, 0, 0, 0, 0, 0, 0);
		}
		
		syncShapes();
		awake();
	}
	
	/**
	 * Awake the rigid body.
	 */
	public function awake():Void
	{
		if (!allowSleep || !sleeping)
			return;
		sleeping = false;
		sleepTime = 0;
		// awake connected constraints
		var cs:ContactLink = contactLink;
		while (cs != null)
		{
			cs.body.sleepTime = 0;
			cs.body.sleeping = false;
			cs = cs.next;
		}
		var js:JointLink = jointLink;
		while (js != null)
		{
			js.body.sleepTime = 0;
			js.body.sleeping = false;
			js = js.next;
		}
		
		var shape:Shape = shapes;
		while ( shape != null )
		{
			shape.updateProxy();
			shape = shape.next;
		}
	}
	
	/**
	 * Sleep the rigid body.
	 */
	public function sleep():Void
	{
		if (!allowSleep || sleeping)
			return;
			
		linearVelocity.setTo(0, 0, 0);
		angularVelocity.setTo(0, 0, 0);
		sleepPosition.copyFrom(position);
		sleepOrientation.copyFrom(orientation);
		sleepTime = 0;
		sleeping = true;
		
		var shape:Shape = shapes; 
		while (shape != null)
		{
			shape.updateProxy();
			shape = shape.next;
		}
	}
	
	/**
	 * Get whether the rigid body has not any connection with others.
	 * @return
	 */
	public inline function isLonely():Bool
	{
		return numJoints == 0 && numContacts == 0;
	}
	
	/**
	 * 剛体の運動を時間積分し、形状などの情報を更新します。
	 * このメソッドはワールドのステップを呼ぶと自動で呼び出されるので、
	 * 通常は外部から呼ぶ必要はありません。
	 * @param	timeStep 時間刻み幅
	 */
	public function updatePosition(timeStep:Float):Void
	{
		switch (type)
		{
			case BODY_STATIC: 
				linearVelocity.setTo(0, 0, 0);
				angularVelocity.setTo(0, 0, 0);

			case BODY_DYNAMIC: 
				//position
				position.x += linearVelocity.x * timeStep;
				position.y += linearVelocity.y * timeStep;
				position.z += linearVelocity.z * timeStep;
				
				//rotation
				var vx:Float = angularVelocity.x;
				var vy:Float = angularVelocity.y;
				var vz:Float = angularVelocity.z;
				var os:Float = orientation.w;
				var ox:Float = orientation.x;
				var oy:Float = orientation.y;
				var oz:Float = orientation.z;
				timeStep *= 0.5;
				var s:Float = (-vx * ox - vy * oy - vz * oz) * timeStep;
				var x:Float = (vx * os + vy * oz - vz * oy) * timeStep;
				var y:Float = (-vx * oz + vy * os + vz * ox) * timeStep;
				var z:Float = (vx * oy - vy * ox + vz * os) * timeStep;
				os += s;
				ox += x;
				oy += y;
				oz += z;
				s = 1 / Math.sqrt(os * os + ox * ox + oy * oy + oz * oz);
				orientation.w = os * s;
				orientation.x = ox * s;
				orientation.y = oy * s;
				orientation.z = oz * s;
				//var len:Float = Math.sqrt(vx * vx + vy * vy + vz * vz);
				//var theta:Float = len * timeStep;
				//if (len > 0) len = 1 / len;
				//vx *= len;
				//vy *= len;
				//vz *= len;
				//var sin:Float = Math.sin(theta * 0.5);
				//var cos:Float = Math.cos(theta * 0.5);
				//var q:Quat = new Quat(cos, vx * sin, vy * sin, vz * sin);
				//orientation.mul(q, orientation);
				//orientation.normalize(orientation);

			default: 
				throw ("Invalid type.");
		}
		syncShapes();
	}
	
	private function rotateInertia(rot:Mat33, inertia:Mat33, out:Mat33):Void
	{
		var r00:Float = rot.e00;
		var r01:Float = rot.e01;
		var r02:Float = rot.e02;
		var r10:Float = rot.e10;
		var r11:Float = rot.e11;
		var r12:Float = rot.e12;
		var r20:Float = rot.e20;
		var r21:Float = rot.e21;
		var r22:Float = rot.e22;
		var i00:Float = inertia.e00;
		var i01:Float = inertia.e01;
		var i02:Float = inertia.e02;
		var i10:Float = inertia.e10;
		var i11:Float = inertia.e11;
		var i12:Float = inertia.e12;
		var i20:Float = inertia.e20;
		var i21:Float = inertia.e21;
		var i22:Float = inertia.e22;
		var e00:Float = r00 * i00 + r01 * i10 + r02 * i20;
		var e01:Float = r00 * i01 + r01 * i11 + r02 * i21;
		var e02:Float = r00 * i02 + r01 * i12 + r02 * i22;
		var e10:Float = r10 * i00 + r11 * i10 + r12 * i20;
		var e11:Float = r10 * i01 + r11 * i11 + r12 * i21;
		var e12:Float = r10 * i02 + r11 * i12 + r12 * i22;
		var e20:Float = r20 * i00 + r21 * i10 + r22 * i20;
		var e21:Float = r20 * i01 + r21 * i11 + r22 * i21;
		var e22:Float = r20 * i02 + r21 * i12 + r22 * i22;
		out.e00 = e00 * r00 + e01 * r01 + e02 * r02;
		out.e01 = e00 * r10 + e01 * r11 + e02 * r12;
		out.e02 = e00 * r20 + e01 * r21 + e02 * r22;
		out.e10 = e10 * r00 + e11 * r01 + e12 * r02;
		out.e11 = e10 * r10 + e11 * r11 + e12 * r12;
		out.e12 = e10 * r20 + e11 * r21 + e12 * r22;
		out.e20 = e20 * r00 + e21 * r01 + e22 * r02;
		out.e21 = e20 * r10 + e21 * r11 + e22 * r12;
		out.e22 = e20 * r20 + e21 * r21 + e22 * r22;
	}
	
	private function syncShapes():Void
	{
		var s:Float = orientation.w;
		var x:Float = orientation.x;
		var y:Float = orientation.y;
		var z:Float = orientation.z;
		
		var x2:Float = 2 * x;
		var y2:Float = 2 * y;
		var z2:Float = 2 * z;
		var xx:Float = x * x2;
		var yy:Float = y * y2;
		var zz:Float = z * z2;
		var xy:Float = x * y2;
		var yz:Float = y * z2;
		var xz:Float = x * z2;
		var sx:Float = s * x2;
		var sy:Float = s * y2;
		var sz:Float = s * z2;
		
		rotation.e00 = 1 - yy - zz;
		rotation.e01 = xy - sz;
		rotation.e02 = xz + sy;
		rotation.e10 = xy + sz;
		rotation.e11 = 1 - xx - zz;
		rotation.e12 = yz - sx;
		rotation.e20 = xz - sy;
		rotation.e21 = yz + sx;
		rotation.e22 = 1 - xx - yy;
		
		var r00:Float = rotation.e00;
		var r01:Float = rotation.e01;
		var r02:Float = rotation.e02;
		var r10:Float = rotation.e10;
		var r11:Float = rotation.e11;
		var r12:Float = rotation.e12;
		var r20:Float = rotation.e20;
		var r21:Float = rotation.e21;
		var r22:Float = rotation.e22;
		
		rotateInertia(rotation, inverseLocalInertia, inverseInertia);
		
		var shape:Shape = shapes; 
		while (shape != null)
		{
			var relPos:Vec3 = shape.relativePosition;
			var relRot:Mat33 = shape.relativeRotation;
			var rot:Mat33 = shape.rotation;
			
			var lx:Float = relPos.x;
			var ly:Float = relPos.y;
			var lz:Float = relPos.z;
			
			shape.position.x = position.x + lx * r00 + ly * r01 + lz * r02;
			shape.position.y = position.y + lx * r10 + ly * r11 + lz * r12;
			shape.position.z = position.z + lx * r20 + ly * r21 + lz * r22;
			rot.mul(relRot, rotation);
			
			shape.updateProxy();
			
			shape = shape.next;
		}
	}
	
	public function applyImpulse(position:Vec3, force:Vec3):Void
	{
		linearVelocity.x += force.x * inverseMass;
		linearVelocity.y += force.y * inverseMass;
		linearVelocity.z += force.z * inverseMass;
		var rel:Vec3 = new Vec3();
		rel.sub(position, this.position).cross(rel, force).mulMat(inverseInertia, rel);
		angularVelocity.x += rel.x;
		angularVelocity.y += rel.y;
		angularVelocity.z += rel.z;
	}

	// for three js
    public function setPosition(x:Float, y:Float, z:Float):Void
	{
		this.position.setTo(x * OimoPhysics.INV_SCALE, y * OimoPhysics.INV_SCALE, z * OimoPhysics.INV_SCALE);
        this.linearVelocity.setTo(0,0,0);
        this.angularVelocity.setTo(0,0,0);
    }
	
    public function setOrientation(x:Float, y:Float, z:Float):Void
	{
        // angle in radian
		var r:Array<Float> = MathUtil.EulerToAxis(x, y, z);
        var rad = r[0], ax = r[1], ay = r[2], az = r[3];
        var len = ax * ax + ay * ay + az * az; 
        if (len > 0)
		{
            len = 1 / Math.sqrt(len);
            ax *= len;
            ay *= len;
            az *= len;
        }
        var sin = Math.sin(rad * 0.5);
        var cos = Math.cos(rad * 0.5);
        this.orientation = new Quaternion(cos, sin * ax, sin * ay, sin * az);
        this.angularVelocity.setTo(0,0,0);
    }
	
	private var matrix:Array<Float>;
    public function getMatrix():Array<Float>
	{
        if (matrix == null)
		{
			matrix = [1, 0, 0, 0,
					  0, 1, 0, 0,
					  0, 0, 1, 0,
					  0, 0, 0, 1];
		}
							
        if (!this.sleeping)
		{
            // rotation matrix
            //r = this.rotation.elements;
            matrix[0] = this.rotation.e00;// r[0];
			matrix[1] = this.rotation.e10;// r[3];
			matrix[2] = this.rotation.e20;// r[6];
            matrix[3] = 0;

            matrix[4] = this.rotation.e01;//r[1];
            matrix[5] = this.rotation.e11;//r[4];
            matrix[6] = this.rotation.e21;//r[7];
            matrix[7] = 0;

            matrix[8] = this.rotation.e02;//r[2];
            matrix[9] = this.rotation.e12;//r[5];
            matrix[10] = this.rotation.e22;//r[8];
            matrix[11] = 0;

            // position matrix
            //p = this.position;
			matrix[12] = this.position.x * OimoPhysics.WORLD_SCALE;
            matrix[13] = this.position.y * OimoPhysics.WORLD_SCALE;
            matrix[14] = this.position.z * OimoPhysics.WORLD_SCALE;
            matrix[15] = 0;
        }
		else
		{
            matrix[15] = 1;
        }

        return matrix;
    }
}