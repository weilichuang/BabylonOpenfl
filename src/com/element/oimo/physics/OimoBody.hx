package com.element.oimo.physics;
import babylon.math.Vector3;
import com.element.oimo.math.MathUtil;
import com.element.oimo.math.Vec3;
import com.element.oimo.physics.collision.shape.BoxShape;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.collision.shape.ShapeConfig;
import com.element.oimo.physics.collision.shape.SphereShape;
import com.element.oimo.physics.dynamics.RigidBody;
import com.element.oimo.physics.dynamics.World;

/**
 * ...
 * 
 */
class OimoBody
{
	public var name:String = "";
	public var body:RigidBody;

	public function new(data:Dynamic) 
	{
		if (data.name != null)
			this.name = data.name;
			
		var move:Bool = false;
		if (data.move != null)
			move = data.move;
		
		var noSleep:Bool = false;
		if (data.noSleep != null)
			noSleep = data.noSleep;
			
		var p:Array<Float>;
		if (data.pos != null)
			p = data.pos;
		else
			p = [0, 0, 0];
			
		p = p.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
			
		var s:Array<Float>;
		if (data.size != null)
			s = data.size;
		else
			s = [1, 1, 1];
		
		s = s.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
		
		var rot:Array<Float>;
		if (data.rot != null)
			rot = data.rot;
		else
			rot = [0, 0, 0];
			
		rot = rot.map(function(x:Float):Float { return x * OimoPhysics.RADS_PER_DEG; } );
		
		var rotations:Array<Float> = [];
		for (i in 0...Std.int(rot.length / 3))
		{
			var tmp = MathUtil.EulerToAxis(rot[i * 3 + 0], rot[i * 3 + 1], rot[i * 3 + 2]);
			rotations.push(tmp[0]);
			rotations.push(tmp[1]);
			rotations.push(tmp[2]);
			rotations.push(tmp[3]);
		}
		
		//physics setting
		var sc:ShapeConfig = new ShapeConfig();
		if (data.config != null)
		{
			sc.density = data.config.density != null ? data.config.density : 1;
			sc.friction = data.config.friction  != null ? data.config.friction  : 0.4;
			sc.restitution = data.config.restitution  != null ? data.config.restitution  : 0.2;
			sc.belongsTo = data.config.belongsTo  != null ? data.config.belongsTo  : 1;
			sc.collidesWith = data.config.collidesWith  != null ? data.config.collidesWith  : 0xffffffff;
		}
		
		if (data.massPos != null)
		{
			data.massPos = data.massPos.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
			sc.relativePosition.setTo(data.massPos[0], data.massPos[1], data.massPos[2]);
		}
		
		if (data.massRot != null)
		{
			data.massRot = data.massRot.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
			sc.relativeRotation = MathUtil.EulerToMatrix(data.massRot[0], data.massRot[1], data.massRot[2]);
		}
		
		// the rigidbody
		this.body = new RigidBody(p[0], p[1], p[2], rotations[0], rotations[1], rotations[2], rotations[3]);
		
		// the shapes
		var shapes:Array<Shape> = [];
		var types = ["box"];
		if (data.type != null)
			types = data.type;
			
		for (i in 0...types.length)
		{
			var n:Int = i * 3;
			switch(types[i])
			{
				case "sphere": 
					shapes[i] = new SphereShape(sc, s[n + 0]);
				case "cylinder": 
					shapes[i] = new BoxShape(sc, s[n + 0], s[n + 1], s[n + 2]); // fake cylinder
				case "box": 
					shapes[i] = new BoxShape(sc, s[n + 0], s[n + 1], s[n + 2]);
				default:
					continue;
			}
			this.body.addShape(shapes[i]);
			if (i > 0)
			{
				//shapes[i].position.init(p[0]+p[n+0], p[1]+p[n+1], p[2]+p[n+2] );
				shapes[i].relativePosition = new Vec3( p[n + 0], p[n + 1], p[n + 2] );

				if (rot.length > n) 
					shapes[i].relativeRotation = MathUtil.EulerToMatrix(rot[n], rot[n + 1], rot[n + 2]);
			}
		}
		
		// static or move
		if (move)
		{
			if (data.massPos != null || data.massRot != null)
				this.body.setupMass(RigidBody.BODY_DYNAMIC, false);
			else
				this.body.setupMass(RigidBody.BODY_DYNAMIC, true);

			this.body.allowSleep = noSleep;	
		}
		else
		{
			this.body.setupMass(RigidBody.BODY_STATIC);
		}
		
		this.body.name = this.name;
		var world:World = data.world;
		world.addRigidBody(this.body);
	}
	
}