package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.textures.Texture;

class AnaglyphPostProcess extends PostProcess
{

	public function new(name:String, ratio:Float = 1.0, camera:Camera = null, samplingMode:Int = Texture.NEAREST_SAMPLINGMODE, engine:Engine = null, reusable:Bool = false) 
	{
		super(name, "anaglyph", null, ["leftSampler"], ratio, camera, samplingMode, engine, reusable);
	}
	
}