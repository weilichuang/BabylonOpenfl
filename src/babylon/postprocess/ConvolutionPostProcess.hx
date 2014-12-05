package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.math.Matrix;

class ConvolutionPostProcess extends PostProcess 
{
	// Based on http://en.wikipedia.org/wiki/Kernel_(image_processing)
    public static var EdgeDetect0Kernel = [1, 0, -1, 0, 0, 0, -1, 0, 1];
    public static var EdgeDetect1Kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    public static var EdgeDetect2Kernel = [-1, -1, -1, -1, 8, -1, -1, -1, -1];
    public static var SharpenKernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];
    public static var EmbossKernel = [-2, -1, 0, -1, 1, 1, 0, 1, 2];
    public static var GaussianKernel = [0, 1, 0, 1, 1, 1, 0, 1, 0];
	
	public var kernel:Array<Float>;
	public var onApply:Effect->Void;

	public function new(name:String, kernel:Array<Float>, ratio:Float, camera:Camera, samplingMode:Int = 1,
						engine:Engine = null, reuable:Bool = false)
	{
		super(name, "convolution", ["kernel", "screenSize"], null, ratio, camera, samplingMode, engine, reuable);
        
        this.kernel = kernel;
		
        this.onApply = function(effect:Effect):Void {
			effect.setFloat2("screenSize", this.width, this.height);
            effect.setMatrices("kernel", that.kernelMatrix);
        };
		
	}
	
}