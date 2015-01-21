package babylon.particles;

import babylon.math.Vector3;
import babylon.math.Color4;

class Particle 
{
	public var lifeTime:Float = 1.0;
    public var age:Float = 0;
    public var size:Float = 0;
    public var angle:Float = 0;
    public var angularSpeed:Float = 0;
	
	public var position:Vector3;
	public var direction:Vector3;
	public var color:Color4;
	public var colorStep:Color4;

	public function new() 
	{
		this.position = Vector3.Zero();
        this.direction = Vector3.Zero();
        this.color = new Color4(0, 0, 0, 0);
        this.colorStep = new Color4(0, 0, 0, 0);
	}
	
	public function copyTo(other: Particle):Void
	{
		other.position.copyFrom(this.position);
		other.direction.copyFrom(this.direction);
		other.color.copyFrom(this.color);
		other.colorStep.copyFrom(this.colorStep);
		other.lifeTime = this.lifeTime;
		other.age = this.age;
		other.size = this.size;
		other.angle = this.angle;
		other.angularSpeed = this.angularSpeed;
	}
	
}
