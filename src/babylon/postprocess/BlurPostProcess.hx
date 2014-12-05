package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.textures.Texture;
import babylon.math.Vector2;

class BlurPostProcess extends PostProcess 
{
	
	public var direction:Vector2;
	public var blurWidth:Float;

	public function new(name:String, 
						direction:Vector2, blurWidth:Float, 
						ratio:Float, camera:Camera, 
						samplingMode:Int = Texture.BILINEAR_SAMPLINGMODE,
						engine:Engine = null,
						reusable:Bool = false)
	{
        super(name, "blur", ["screenSize", "direction", "blurWidth"], null, ratio, camera, samplingMode,engine, reusable);

        this.direction = direction;
        this.blurWidth = blurWidth;
		
        this.onApply = function (effect:Effect):Void
		{
            effect.setFloat2("screenSize", this.width, this.height);
            effect.setVector2("direction", this.direction);
            effect.setFloat("blurWidth", this.blurWidth);
        };
	}
	
}
