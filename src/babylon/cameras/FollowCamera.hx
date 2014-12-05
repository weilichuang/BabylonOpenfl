package babylon.cameras;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class FollowCamera extends TargetCamera
{
	public var radius:Float = 12;
	public var rotationOffset:Float = 0;
	public var heightOffset:Float = 4;
	public var cameraAcceleration:Float = 0.05;
	public var maxCameraSpeed:Float = 20;
	public var target:AbstractMesh;

	public function new(name:String,position:Vector3,scene:Scene) 
	{
		super(name, position, scene);
	}
	
	private function getRadians(degrees:Float):Float
	{
		return degrees * Math.PI / 180;
	}
	
	private function follow(cameraTarget:AbstractMesh):Void
	{
		if (cameraTarget == null)
			return;

		var radians:Float = this.getRadians(this.rotationOffset) + cameraTarget.rotation.y;
		var targetX:Float = cameraTarget.position.x + Math.sin(radians) * this.radius;

		var targetZ:Float = cameraTarget.position.z + Math.cos(radians) * this.radius;
		var dx:Float = targetX - this.position.x;
		var dy:Float = (cameraTarget.position.y + this.heightOffset) - this.position.y;
		var dz:Float = (targetZ) - this.position.z;
		var vx:Float = dx * this.cameraAcceleration * 2;//this is set to .05
		var vy:Float = dy * this.cameraAcceleration;
		var vz:Float = dz * this.cameraAcceleration * 2;

		if (vx > this.maxCameraSpeed || vx < -this.maxCameraSpeed)
		{
			vx = vx < 1 ? -this.maxCameraSpeed : this.maxCameraSpeed;
		}

		if (vy > this.maxCameraSpeed || vy < -this.maxCameraSpeed) 
		{
			vy = vy < 1 ? -this.maxCameraSpeed : this.maxCameraSpeed;
		}

		if (vz > this.maxCameraSpeed || vz < -this.maxCameraSpeed)
		{
			vz = vz < 1 ? -this.maxCameraSpeed : this.maxCameraSpeed;
		}

		this.position = new Vector3(this.position.x + vx, this.position.y + vy, this.position.z + vz);
		this.setTarget(cameraTarget.position);
	}

	override public function _update():Void 
	{
		super._update();
		this.follow(this.target);
	}
	
}