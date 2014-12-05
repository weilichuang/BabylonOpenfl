package babylon.physics;

typedef PhysicsBodyCreationOptions =
{
	var mass: Float;
	@:optional var density:Float;
	@:optional var friction: Float;
	@:optional var restitution: Float;
}