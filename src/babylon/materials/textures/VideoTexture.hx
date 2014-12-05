package babylon.materials.textures;

/**
 * ...
 * @author 
 */
class VideoTexture extends Texture
{

	public function new(url:String, scene:Scene, 
						noMipmap:Bool = false, 
						invertY:Bool = false, 
						samplingMode:Int = Texture.TRILINEAR_SAMPLINGMODE) 
	{
		super(url, scene, noMipmap, invertY, samplingMode);
	}
	
}