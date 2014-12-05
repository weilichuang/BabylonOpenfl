package babylon.postprocess;
import babylon.cameras.Camera;
import babylon.Engine;

class DisplayPassPostProcess extends PostProcess
{
	public function new(name:String, ratio:Float, camera:Camera, samplingMode:Int = 1, engine:Engine, reusable:Bool = false)
	{
		super(name, "displayPass", ["passSampler"], ["passSampler"], ratio, camera, samplingMode,engine, reusable);
	}
}