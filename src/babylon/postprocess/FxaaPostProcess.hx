package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.materials.Effect;

class FxaaPostProcess extends PostProcess
{
	
	public var texelWidth:Float;
	public var texelHeight:Float;

	public function new(name:String, ratio:Float, 
						camera:Camera, samplingMode:Int = 1,
						engine:Engine = null, reusable:Bool = false) 
	{
		super(this, name, "fxaa", ["texelSize"], null, ratio, camera, samplingMode, engine, reusable);	
		
		texelWidth = 0;
		texelHeight = 0;
	}
	
	public function onSizeChanged():Void
	{
        this.texelWidth = 1.0 / this.width;
        this.texelHeight = 1.0 / this.height;
    }
	
	public function onApply(effect:Effect):Void
	{
        effect.setFloat2("texelSize", this.texelWidth, this.texelHeight);
    }
	
}
