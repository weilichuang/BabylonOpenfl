package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;

class BlackAndWhitePostProcess extends PostProcess 
{
	public function new(name:String, ratio:Float, camera:Camera, samplingMode:Int = 1,engine:Engine = null, reusable:Bool = false)
	{
		super(name, "blackAndWhite", null, null, ratio, camera, samplingMode,engine, reusable);
	}
	
}