package babylon.postprocess;

import babylon.cameras.Camera;

class PassPostProcess extends PostProcess 
{
	public function new(name:String, ratio:Float, camera:Camera, samplingMode:Int = 1, engine:Engine = null, reusable:Bool = false)
	{
		super(name, "pass", null, null, ratio, camera, samplingMode, engine, reusable);	
	}
	
}