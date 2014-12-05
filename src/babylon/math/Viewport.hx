package babylon.math;

import babylon.Engine;

class Viewport 
{
	public var width:Float;
	public var height:Float;
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float, width:Float, height:Float) 
	{
		this.width = width;
        this.height = height;
        this.x = x;
        this.y = y;
	}
	
	public inline function toGlobal(engine:Engine):Viewport
	{
        var sw = engine.getRenderWidth() * engine.getHardwareScalingLevel();
        var sh = engine.getRenderHeight() * engine.getHardwareScalingLevel();
        return new Viewport(this.x * sw, this.y * sh, this.width * sw, this.height * sh);
    }
}
