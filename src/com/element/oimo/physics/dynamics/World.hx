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

import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.broadphase.AABB;
import com.element.oimo.physics.collision.broadphase.BroadPhase;
import com.element.oimo.physics.collision.broadphase.BruteForceBroadPhase;
import com.element.oimo.physics.collision.broadphase.dbvt.DBVTBroadPhase;
import com.element.oimo.physics.collision.broadphase.Pair;
import com.element.oimo.physics.collision.broadphase.sap.SAPBroadPhase;
import com.element.oimo.physics.collision.narrowphase.BoxBoxCollisionDetector;
import com.element.oimo.physics.collision.narrowphase.CollisionDetector;
import com.element.oimo.physics.collision.narrowphase.SphereBoxCollisionDetector;
import com.element.oimo.physics.collision.narrowphase.SphereSphereCollisionDetector;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.constraint.Constraint;
import com.element.oimo.physics.constraint.contact.Contact;
import com.element.oimo.physics.constraint.contact.ContactLink;
import com.element.oimo.physics.constraint.joint.Joint;
import com.element.oimo.physics.constraint.joint.JointLink;
import com.element.oimo.physics.OimoPhysics;
import com.element.oimo.physics.util.Performance;
import flash.Lib;
import haxe.ds.Vector;

/**
 * 物理演算ワールドのクラスです。
 * 全ての物理演算オブジェクトはワールドに追加する必要があります。
 * @author saharan
 */
class World
{
	/**
	 * The rigid body list.
	 */
	public var rigidBodies:RigidBody;
	
	/**
	 * The number of rigid bodies.
	 */
	public var numRigidBodies:Int;
	
	/**
	 * The contact list.
	 */
	public var contacts:Contact;
	private var unusedContacts:Contact;
	
	/**
	 * The number of contacts.
	 */
	public var numContacts:Int = 0;
	
	/**
	 * The number of contact points.
	 */
	public var numContactPoints:Int = 0;
	
	/**
	 * The joint list.
	 */
	public var joints:Joint;
	
	/**
	 * The number of joints.
	 */
	public var numJoints:Int = 0;
	
	/**
	 * The number of simulation islands.
	 */
	public var numIslands:Int = 0;
	
	/**
	 * 1回のステップで進む時間の長さです。
	 */
	public var timeStep:Float = 0;
	
	/**
	 * The gravity in the world.
	 */
	public var gravity:Vec3;
	
	/**
	 * The number of iterations for constraint solvers.
	 */
	public var numIterations:Int = 8;
	
	/**
	 * Whether the constraints randomizer is enabled or not.
	 */
	public var enableRandomizer:Bool;
	
	/**
	 * パフォーマンスの詳細情報です。
	 * 計算に要した時間などが記録されています。
	 */
	public var performance:Performance;
	
	/**
	 * 詳細な衝突判定をできるだけ削減するために使用される広域衝突判定です。
	 */
	public var broadPhase:BroadPhase;
	
	private var detectors:Vector<Vector<CollisionDetector>>;
	
	private var islandStack:Vector<RigidBody>;
	private var islandRigidBodies:Vector<RigidBody>;
	private var maxIslandRigidBodies:Int;
	private var islandConstraints:Vector<Constraint>;
	private var maxIslandConstraints:Int;
	
	private var randX:Int;
	private var randA:Int;
	private var randB:Int;
	
	public function new(stepPerSecond:Float = 60, broadPhaseType:Int = BroadPhase.BROAD_PHASE_SWEEP_AND_PRUNE)
	{
		Lib.trace("OimoPhysics " + OimoPhysics.VERSION + " Copyright (c) 2012-2013 EL-EMENT saharan");
		timeStep = 1 / stepPerSecond;
		switch (broadPhaseType)
		{
			case BroadPhase.BROAD_PHASE_BRUTE_FORCE: 
				broadPhase = new BruteForceBroadPhase();
			case BroadPhase.BROAD_PHASE_SWEEP_AND_PRUNE: 
				broadPhase = new SAPBroadPhase();
			case BroadPhase.BROAD_PHASE_DYNAMIC_BOUNDING_VOLUME_TREE: 
				broadPhase = new DBVTBroadPhase();
			default: 
				throw ("Invalid BroadPhase type.");
		}
		
		gravity = new Vec3(0, -9.80665, 0);
		performance = new Performance();
		
		var numShapeTypes:Int = 3;
		detectors = new Vector<Vector<CollisionDetector>>(numShapeTypes);
		for (i in 0...numShapeTypes)
		{
			detectors[i] = new Vector<CollisionDetector>(numShapeTypes);
		}
		detectors[Shape.SHAPE_SPHERE][Shape.SHAPE_SPHERE] = new SphereSphereCollisionDetector();
		detectors[Shape.SHAPE_SPHERE][Shape.SHAPE_BOX] = new SphereBoxCollisionDetector(false);
		detectors[Shape.SHAPE_BOX][Shape.SHAPE_SPHERE] = new SphereBoxCollisionDetector(true);
		detectors[Shape.SHAPE_BOX][Shape.SHAPE_BOX] = new BoxBoxCollisionDetector();
		
		randX = 65535;
		randA = 98765;
		randB = 123456789;
		maxIslandRigidBodies = 64;
		islandRigidBodies = new Vector<RigidBody>(maxIslandRigidBodies);
		islandStack = new Vector<RigidBody>(maxIslandRigidBodies);
		maxIslandConstraints = 128;
		islandConstraints = new Vector<Constraint>(maxIslandConstraints);
		enableRandomizer = true;
	}
	
	/**
	 * Reset the randomizer and remove all rigid bodies, shapes, joints and any object from the world.
	 */
	public function clear():Void
	{
		randX = 65535;
		while (joints != null)
		{
			removeJoint(joints);
		}
		while (contacts != null)
		{
			removeContact(contacts);
		}
		while (rigidBodies != null)
		{
			removeRigidBody(rigidBodies);
		}
	}
	
	/**
	 * ワールドに剛体を追加します。
	 * 追加された剛体はステップ毎の演算対象になります。
	 * @param	rigidBody 追加する剛体
	 */
	public function addRigidBody(rigidBody:RigidBody):Void
	{
		if (rigidBody.parent != null)
		{
			throw ("一つの剛体を複数ワールドに追加することはできません");
		}
		rigidBody.parent = this;
		rigidBody.awake();
		
		var shape:Shape = rigidBody.shapes;
		while ( shape != null)
		{
			addShape(shape);
			shape = shape.next;
		}
		if (rigidBodies != null)
			(rigidBodies.prev = rigidBody).next = rigidBodies;
		rigidBodies = rigidBody;
		numRigidBodies++;
	}
	
	/**
	 * ワールドから剛体を削除します。
	 * 削除された剛体はステップ毎の演算対象から外されます。
	 * @param	rigidBody 削除する剛体
	 */
	public function removeRigidBody(rigidBody:RigidBody):Void
	{
		var remove:RigidBody = rigidBody;
		if (remove.parent != this)
			return;
		remove.awake();
		var js:JointLink = remove.jointLink;
		while (js != null)
		{
			var joint:Joint = js.joint;
			js = js.next;
			removeJoint(joint);
		}
		
		var shape:Shape = rigidBody.shapes;
		while ( shape != null)
		{
			removeShape(shape);
			shape = shape.next;
		}
		
		var prev:RigidBody = remove.prev;
		var next:RigidBody = remove.next;
		if (prev != null)
			prev.next = next;
		if (next != null)
			next.prev = prev;
		if (rigidBodies == remove)
			rigidBodies = next;
		remove.prev = null;
		remove.next = null;
		remove.parent = null;
		numRigidBodies--;
	}
	
	/**
	 * ワールドに形状を追加します。
	 * <strong>剛体をワールドに追加、およびワールドに追加されている剛体に形状を追加すると、
	 * 自動で形状もワールドに追加されるので、このメソッドは外部から呼ばないでください。</strong>
	 * @param	shape 追加する形状
	 */
	public function addShape(shape:Shape):Void
	{
		if (shape.parent == null || shape.parent.parent == null)
		{
			throw ("ワールドに形状を単体で追加することはできません");
		}
		shape.proxy = broadPhase.createProxy(shape);
		shape.updateProxy();
		broadPhase.addProxy(shape.proxy);
	}
	
	/**
	 * ワールドから形状を削除します。
	 * <strong>剛体をワールドから削除、およびワールドに追加されている剛体から形状を削除すると、
	 * 自動で形状もワールドから削除されるので、このメソッドは外部から呼ばないでください。</strong>
	 * @param	shape 削除する形状
	 */
	public function removeShape(shape:Shape):Void
	{
		broadPhase.removeProxy(shape.proxy);
		shape.proxy = null;
	}
	
	/**
	 * ワールドにジョイントを追加します。
	 * 追加されたジョイントはステップ毎の演算対象になります。
	 * @param	joint 追加するジョイント
	 */
	public function addJoint(joint:Joint):Void
	{
		if (joint.parent != null)
		{
			throw ("一つのジョイントを複数ワールドに追加することはできません");
		}
		if (joints != null)
			(joints.prev = joint).next = joints;
		joints = joint;
		joint.parent = this;
		numJoints++;
		joint.awake();
		joint.attach();
	}
	
	/**
	 * ワールドからジョイントを削除します。
	 * 削除されたジョイントはステップ毎の演算対象から外されます。
	 * @param	joint 削除するジョイント
	 */
	public function removeJoint(joint:Joint):Void
	{
		var remove:Joint = joint;
		var prev:Joint = remove.prev;
		var next:Joint = remove.next;
		if (prev != null)
			prev.next = next;
		if (next != null)
			next.prev = prev;
		if (joints == remove)
			joints = next;
		remove.prev = null;
		remove.next = null;
		numJoints--;
		remove.awake();
		remove.detach();
		remove.parent = null;
	}
	
	/**
	 * ワールドの時間をタイムステップ秒だけ進めます。
	 */
	public function step():Void
	{
		var time1:Int = Lib.getTimer();
		
		var body:RigidBody = rigidBodies;
		while (body != null)
		{
			body.addedToIsland = false;
			if (body.sleeping)
			{
				if (!body.linearVelocity.isZero() || 
					!body.angularVelocity.isZero() ||
					!body.position.equals(body.sleepPosition) ||
					!body.orientation.equals(body.sleepOrientation))
				{ 
					// awake the body
					body.awake();
				}
			}
			body = body.next;
		}
		
		updateContacts();
		
		
		solveIslands();
		
		performance.totalTime = Lib.getTimer() - time1;
		performance.updatingTime = performance.totalTime - (performance.broadPhaseTime + performance.narrowPhaseTime + performance.solvingTime);
	}
	
	private function updateContacts():Void
	{
		var time1:Int = Lib.getTimer();
		
		var contact:Contact;
		// broad phase
		broadPhase.detectPairs();
		var pairs:Vector<Pair> = broadPhase.pairs;
		var numPairs:Int = broadPhase.numPairs;
		for (i in 0...numPairs)
		{
			var pair:Pair = pairs[i];
			var s1:Shape;
			var s2:Shape;
			if (pair.shape1.id < pair.shape2.id)
			{
				s1 = pair.shape1;
				s2 = pair.shape2;
			}
			else
			{
				s1 = pair.shape2;
				s2 = pair.shape1;
			}
			var link:ContactLink;
			if (s1.numContacts < s2.numContacts)
			{
				link = s1.contactLink;
			}
			else
			{
				link = s2.contactLink;
			}
			var exists:Bool = false;
			while (link != null)
			{
				contact = link.contact;
				if (contact.shape1 == s1 && contact.shape2 == s2)
				{
					contact.persisting = true;
					exists = true; // contact already exists
					break;
				}
				link = link.next;
			}
			if (!exists)
			{
				addContact(s1, s2);
			}
		}
		
		var time2:Int = Lib.getTimer();
		performance.broadPhaseTime = time2 - time1;
		
		// update & narrow phase
		numContactPoints = 0;
		contact = contacts;
		while (contact != null)
		{
			if (!contact.persisting)
			{
				var aabb1:AABB = contact.shape1.aabb;
				var aabb2:AABB = contact.shape2.aabb;
				//无交集
				if (aabb1.minX > aabb2.maxX || aabb1.maxX < aabb2.minX || 
					aabb1.minY > aabb2.maxY || aabb1.maxY < aabb2.minY || 
					aabb1.minZ > aabb2.maxZ || aabb1.maxZ < aabb2.minZ)
				{
					var next:Contact = contact.next;
					removeContact(contact);
					contact = next;
					continue;
				}
			}
			var b1:RigidBody = contact.body1;
			var b2:RigidBody = contact.body2;
			if (b1.isDynamic && !b1.sleeping || b2.isDynamic && !b2.sleeping)
			{
				contact.updateManifold();
			}
			numContactPoints += contact.manifold.numPoints;
			contact.persisting = false;
			contact.constraint.addedToIsland = false;
			contact = contact.next;
		}
		
		performance.narrowPhaseTime = Lib.getTimer() - time2;
	}
	
	private function addContact(s1:Shape, s2:Shape):Void
	{
		var newContact:Contact;
		if (unusedContacts != null)
		{
			newContact = unusedContacts;
			unusedContacts = unusedContacts.next;
		}
		else
		{
			newContact = new Contact();
		}
		newContact.attach(s1, s2);
		newContact.detector = detectors[s1.type][s2.type];
		if (contacts != null)
			(contacts.prev = newContact).next = contacts;
		contacts = newContact;
		numContacts++;
	}
	
	private function removeContact(contact:Contact):Void
	{
		var prev:Contact = contact.prev;
		var next:Contact = contact.next;
		if (next != null)
			next.prev = prev;
		if (prev != null)
			prev.next = next;
		if (contacts == contact)
			contacts = next;
		contact.prev = null;
		contact.next = null;
		contact.detach();
		contact.next = unusedContacts;
		unusedContacts = contact;
		numContacts--;
	}
	
	/**
	 * 是否可休眠
	 * @param	body
	 * @return
	 */
	private function calSleep(body:RigidBody):Bool
	{
		if (!body.allowSleep)
			return false;
			
		var v:Vec3 = body.linearVelocity;
		if (v.x * v.x + v.y * v.y + v.z * v.z > 0.04)
			return false;
			
		v = body.angularVelocity;
		if (v.x * v.x + v.y * v.y + v.z * v.z > 0.25)
			return false;
			
		return true;
	}
	
	private function solveIslands():Void
	{
		var invTimeStep:Float = 1 / timeStep;

		var joint:Joint = joints; 
		while (joint != null)
		{
			joint.addedToIsland = false;
			joint = joint.next;
		}
		
		// expand island buffers
		if (maxIslandRigidBodies < numRigidBodies)
		{
			maxIslandRigidBodies = numRigidBodies << 1;
			islandRigidBodies = new Vector<RigidBody>(maxIslandRigidBodies);
			islandStack = new Vector<RigidBody>(maxIslandRigidBodies);
		}
		
		var numConstraints:Int = numJoints + numContacts;
		if (maxIslandConstraints < numConstraints)
		{
			maxIslandConstraints = numConstraints << 1;
			islandConstraints = new Vector<Constraint>(maxIslandConstraints);
		}
		
		var time1:Int = Lib.getTimer();
		
		var gx:Float = gravity.x * timeStep;
		var gy:Float = gravity.y * timeStep;
		var gz:Float = gravity.z * timeStep;
		
		numIslands = 0;
		// build and solve simulation islands
		var body:RigidBody;
		var constraint:Constraint;
		var base:RigidBody = rigidBodies; 
		while (base != null)
		{
			if (base.addedToIsland || base.isStatic || base.sleeping)
			{
				base = base.next;
				continue; // ignore
			}
			
			// update single body
			if (base.isLonely())
			{
				if (base.isDynamic)
				{
					base.linearVelocity.x += gx;
					base.linearVelocity.y += gy;
					base.linearVelocity.z += gz;
				}
				
				//计算休眠时间，超过一定时间，使其休眠
				if (calSleep(base))
				{
					base.sleepTime += timeStep;
					if (base.sleepTime > 0.5)
					{
						base.sleep();
					}
					else
					{
						base.updatePosition(timeStep);
					}
				}
				else
				{
					base.sleepTime = 0;
					base.updatePosition(timeStep);
				}
				
				numIslands++;
				
				base = base.next;
				continue;
			}
			
			
			var islandNumRigidBodies:Int = 0;
			var islandNumConstraints:Int = 0;
			var stackCount:Int = 1;
			// add rigid body to stack
			islandStack[0] = base;
			base.addedToIsland = true;
			// build an island
			do
			{
				if (stackCount == 0)
					break;
					
				// get rigid body from stack
				body = islandStack[--stackCount];
				islandStack[stackCount] = null; // gc

				body.sleeping = false;
				// add rigid body to the island
				islandRigidBodies[islandNumRigidBodies++] = body;
				if (body.isStatic)
				{
					//这里返回后stackCount变为0，导致islandStack[--stackCount]取值出错,所以上面需要判断stackCount
					continue;
				}
				
				// search connections
				var next:RigidBody;
				var cs:ContactLink = body.contactLink; 
				while (cs != null)
				{
					var contact:Contact = cs.contact;
					constraint = contact.constraint;
					if (constraint.addedToIsland || !contact.touching)
					{
						cs = cs.next;
						continue; // ignore
					}
					
					// add constraint to the island
					islandConstraints[islandNumConstraints++] = constraint;
					constraint.addedToIsland = true;
					next = cs.body;
					if (next.addedToIsland)
					{
						cs = cs.next;
						continue;
					}

					// add rigid body to stack
					//这种情况下next可能是isStatic
					islandStack[stackCount++] = next;
					next.addedToIsland = true;
					
					cs = cs.next;
				}
				
				var js:JointLink = body.jointLink;
				while ( js != null)
				{
					constraint = js.joint;
					if (constraint.addedToIsland)
					{
						js = js.next;
						continue; // ignore
					}
					// add constraint to the island
					islandConstraints[islandNumConstraints++] = constraint;
					constraint.addedToIsland = true;
					next = js.body;
					if (next.addedToIsland || !next.isDynamic)
					{
						js = js.next;
						continue;
					}
					// add rigid body to stack
					islandStack[stackCount++] = next;
					next.addedToIsland = true;
					
					js = js.next;
				}
				
			} while (stackCount != 0);
			
			// update velocities
			for (j in 0...islandNumRigidBodies)
			{
				body = islandRigidBodies[j];
				if (body.isDynamic)
				{
					body.linearVelocity.x += gx;
					body.linearVelocity.y += gy;
					body.linearVelocity.z += gz;
				}
			}
			
			// randomizing order
			if (enableRandomizer)
			{
				for (j in 1...islandNumConstraints)
				{
					var swap:Int = Std.int((randX = (randX * randA + randB & 0x7fffffff)) / 2147483648.0 * j);
					constraint = islandConstraints[j];
					islandConstraints[j] = islandConstraints[swap];
					islandConstraints[swap] = constraint;
				}
			}
			
			// solve contraints
			for (j in 0...islandNumConstraints)
			{
				islandConstraints[j].preSolve(timeStep, invTimeStep); // pre-solve
			}
			for (k in 0...numIterations)
			{
				for (j in 0...islandNumConstraints)
				{
					islandConstraints[j].solve(); // main-solve
				}
			}
			for (j in 0...islandNumConstraints)
			{
				islandConstraints[j].postSolve(); // post-solve
				islandConstraints[j] = null; // gc
			}
			
			// sleeping check
			var sleepTime:Float = 10;
			for (j in 0...islandNumRigidBodies)
			{
				body = islandRigidBodies[j];
				if (calSleep(body))
				{
					body.sleepTime += timeStep;
					if (body.sleepTime < sleepTime)
						sleepTime = body.sleepTime;
				}
				else
				{
					body.sleepTime = 0;
					sleepTime = 0;
					continue;
				}
			}
			if (sleepTime > 0.5)
			{
				// sleep the island
				for (j in 0...islandNumRigidBodies)
				{
					islandRigidBodies[j].sleep();
					islandRigidBodies[j] = null; // gc
				}
			}
			else
			{
				// update positions
				for (j in 0...islandNumRigidBodies)
				{
					islandRigidBodies[j].updatePosition(timeStep);
					islandRigidBodies[j] = null; // gc
				}
			}
			numIslands++;
			base = base.next;
		}
		
		performance.solvingTime = Lib.getTimer() - time1;
	}
	
	public function getRigidBodyByName(name):RigidBody
	{
        var body:RigidBody = this.rigidBodies;
        while (body != null)
		{
            if (body.name != "" && body.name == name)
			{
				return body;
			}
            body = body.next;
        }
        return null;
    }
	
	public function getJointByName(name):Joint
	{
        var joint:Joint = this.joints;
        while (joint != null)
		{
            if (joint.name != "" && joint.name == name) 
				return joint;
            joint = joint.next;
        }
        return null;
    }

}