package com.element.oimo.physics ;
import com.element.oimo.physics.constraint.joint.BallAndSocketJoint;
import com.element.oimo.physics.constraint.joint.DistanceJoint;
import com.element.oimo.physics.constraint.joint.HingeJoint;
import com.element.oimo.physics.constraint.joint.Joint;
import com.element.oimo.physics.constraint.joint.JointConfig;
import com.element.oimo.physics.constraint.joint.PrismaticJoint;
import com.element.oimo.physics.constraint.joint.SliderJoint;
import com.element.oimo.physics.constraint.joint.WheelJoint;
import com.element.oimo.physics.dynamics.World;

/**
 * ...
 * @author weilichuang
 */
class OimoLink
{
	public var name:String = "";
	public var joint:Joint;

	public function new(data:Dynamic) 
	{
		if (data.name != null)
			this.name = data.name;
			
		var pos1:Array<Float> ;
		if (data.pos1 != null)
			pos1 = data.pos1;
		else
			pos1 = [0, 0, 0];
		pos1 = pos1.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
		
		var pos2:Array<Float> ;
		if (data.pos2 != null)
			pos2 = data.pos2;
		else
			pos2 = [0, 0, 0];
		pos2 = pos2.map(function(x:Float):Float { return x * OimoPhysics.INV_SCALE; } );
		
		var axe1:Array<Float> ;
		if (data.axe1 != null)
			axe1 = data.axe1;
		else
			axe1 = [1, 0, 0];

		var axe2:Array<Float> ;
		if (data.axe2 != null)
			axe2 = data.axe2;
		else
			axe2 = [1, 0, 0];
			
		var type = "jointHinge";
		if (data.type != null)
			type = data.type;
			
		var min:Float;
		var max:Float;
		if (type == "jointDistance")
		{
			min = data.min != null ? data.min : 0;
			max = data.max != null ? data.max : 10;
			min *= OimoPhysics.INV_SCALE;
			max *= OimoPhysics.INV_SCALE;
		}
		else
		{
			min = data.min != null ? data.min : 57.2978;
			max = data.max != null ? data.max : 0;
			min *= OimoPhysics.RADS_PER_DEG;
			max *= OimoPhysics.RADS_PER_DEG;
		}
		
		var limit:Dynamic = data.limit;
		var spring:Dynamic = data.spring;
		
		var world:World = data.world;
		
		//joint setting
		var jc:JointConfig = new JointConfig();
		jc.allowCollision = data.collision != null ? data.collision : false;
		jc.localAxis1.setTo(axe1[0], axe1[1], axe1[2]);
		jc.localAxis2.setTo(axe2[0], axe2[1], axe2[2]);
		jc.localAnchorPoint1.setTo(pos1[0], pos1[1], pos1[2]);
		jc.localAnchorPoint2.setTo(pos2[0], pos2[1], pos2[2]);
		
		if (Std.is(data.body1, String))
		{
			jc.body1 = world.getRigidBodyByName(cast data.body1);
		}
		else
		{
			jc.body1 = data.body1;
		}
		
		if (Std.is(data.body2, String))
		{
			jc.body2 = world.getRigidBodyByName(cast data.body2);
		}
		else
		{
			jc.body2 = data.body2;
		}

		switch(type)
		{
			case "jointDistance": 
				this.joint = new DistanceJoint(jc, min, max); 
				if (spring != null)
					cast(this.joint,DistanceJoint).limitMotor.setSpring(spring[0], spring[1]);

			case "jointHinge": 
				this.joint = new HingeJoint(jc, min, max);
				if (spring != null)
					cast(this.joint,HingeJoint).limitMotor.setSpring(spring[0], spring[1]);// soften the joint ex: 100, 0.2
			case "jointPrisme": 
				this.joint = new PrismaticJoint(jc, min, max);
			case "jointSlide": 
				this.joint = new SliderJoint(jc, min, max);
			case "jointBall": 
				this.joint = new BallAndSocketJoint(jc);
			case "jointWheel": 
				this.joint = new WheelJoint(jc);  
				if (limit != null) 
					cast(this.joint,WheelJoint).rotationalLimitMotor1.setLimit(limit[0], limit[1]);
				if (spring != null) 
					cast(this.joint,WheelJoint).rotationalLimitMotor1.setSpring(spring[0], spring[1]);
		}

		// finaly add to physics world
		this.joint.name = this.name;
		world.addJoint(this.joint);
	}
	
}