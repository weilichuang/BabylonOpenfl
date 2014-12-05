package babylon.lensflare;

import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.materials.textures.Texture;

class LensFlare 
{
	public var size:Float;
	public var position:Float;
	public var color:Color3;
	public var texture:Texture;
	
	private var _system:LensFlareSystem;
	

	public function new(system:LensFlareSystem, size:Float, position:Float, color:Color3 = null, imgUrl:String = null) 
	{
		this.size = size;
		
        this.position = position;
        this._system = system;
		_system.lensFlares.push(this);
		
		this.color = color != null ? color : new Color3(1, 1, 1);
        this.texture = imgUrl != null ? new Texture(imgUrl, system.getScene(), true) : null;
	}
	
	public function dispose() 
	{
		if (this.texture != null)
		{
            this.texture.dispose();
        }
        
        // Remove from scene
		this._system.lensFlares.remove(this);
	}
}
