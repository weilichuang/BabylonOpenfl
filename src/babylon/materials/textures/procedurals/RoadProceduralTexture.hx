package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class RoadProceduralTexture extends ProceduralTexture
{

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture=null, generateMipMaps:Bool=false) 
	{
		super(name, size, "road", scene, fallbackTexture, generateMipMaps);
		
		// Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
		this.refreshRate = 0;
	}
	
}