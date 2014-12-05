package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.math.Matrix;

class FilterPostProcess extends PostProcess
{
	public var kernelMatrix:Matrix;

	public function new(name:String, kernelMatrix: Matrix, ratio: Float, 
						camera:Camera = null, samplingMode:Int = 1,
						engine:Engine = null,reusable:Bool = false) 
	{
		this.kernelMatrix = kernelMatrix;
		
		super(name, "filter", ["kernelMatrix"], null, ratio, camera, samplingMode,engine, reusable);
		
		this.onApply = function(effect:Effect):Void
		{
			effect.setMatrix("kernelMatrix", this.kernelMatrix);
		}
	}
	
}