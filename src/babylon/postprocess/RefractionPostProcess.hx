package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.textures.Texture;
import babylon.math.Color3;

class RefractionPostProcess extends PostProcess 
{
	
	public var color:Color3;
	public var depth:Float;
	public var colorLevel:Float;
	public var _refTexture:Texture;

	public function new(name:String, 
						refractionTextureUrl:String, 
						color:Color3,
						depth:Float,
						colorLevel:Float, 
						ratio:Float, 
						camera:Camera, 
						samplingMode:Int = 1,
						engine:Engine = null,
						reusable:Bool = false)
	{
		super(name, "refraction", 
			["baseColor", "depth", "colorLevel"], ["refractionSampler"], 
			ratio, camera, samplingMode, engine,reusable);
			
		this.color = color;
        this.depth = depth;
        this.colorLevel = colorLevel;
		
		this.onActivate = function(cam:Camera):Void
		{
			if (this._refTexture == null)
				this._refTexture = new Texture(refractionTextureUrl, camera.getScene());
		};

        this.onApply = function(effect:Effect):Void 
		{
            effect.setColor3("baseColor", this.color);
            effect.setFloat("depth", this.depth);
            effect.setFloat("colorLevel", this.colorLevel);

            effect.setTexture("refractionSampler", this._refTexture);
        };
	}
	
	override public function dispose(camera:Camera = null):Void
	{
		if (_refTexture != null)
		{
			_refTexture.dispose();
			_refTexture = null;
		}
		
		super.dispose(camera);
	}
		
}