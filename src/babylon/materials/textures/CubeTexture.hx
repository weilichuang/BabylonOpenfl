package babylon.materials.textures;

import babylon.Scene;
import babylon.Engine;
import babylon.math.Matrix;

class CubeTexture extends BaseTexture 
{	
	public var url:String;
	
	private var _textureMatrix:Matrix;
	private var _extensions:Array<String>;
	private var _noMipmap:Bool = true;

	public function new(rootUrl:String, scene:Scene, ?extensions:Array<String> = null, noMipmap:Bool = false)
	{
		super(scene);
		
		this.name = rootUrl;
        this.url = rootUrl;
		this._noMipmap = noMipmap;
		this.hasAlpha = false;
		this.isCube = true;
		this.coordinatesMode = Texture.CUBIC_MODE;

		if (null == extensions) {
            extensions = ["_px.jpg", "_py.jpg", "_pz.jpg", "_nx.jpg", "_ny.jpg", "_nz.jpg"];
        }
        this._extensions = extensions;
		
		this._texture = this._getFromCache(rootUrl, false);
		
		if (this._texture == null)
		{
            if (!scene.useDelayedTextureLoading)
		    {
				this._texture = scene.getEngine().createCubeTexture(rootUrl, scene, extensions, noMipmap);
			} 
			else 
			{
				this.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
			}        
        } 
		
        this._textureMatrix = new Matrix();
	}
	
	override public function delayLoad():Void
	{
        if (this.delayLoadState != Engine.DELAYLOADSTATE_NOTLOADED) 
		{
            return;
        }

        this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
        this._texture = this._getFromCache(this.url, false);

        if (this._texture == null)
		{
            this._texture = this._scene.getEngine().createCubeTexture(this.url, this._scene, this._extensions);
        }
    }
	
	override public function getReflectionTextureMatrix():Matrix
	{
        return this._textureMatrix;
    }
	
	override public function clone(): BaseTexture
	{
		var newTexture:CubeTexture = new CubeTexture(this.url, this.getScene(), this._extensions, this._noMipmap);

		// Base texture
		newTexture.level = this.level;
		newTexture.wrapU = this.wrapU;
		newTexture.wrapV = this.wrapV;
		newTexture.coordinatesIndex = this.coordinatesIndex;
		newTexture.coordinatesMode = this.coordinatesMode;

		return newTexture;
	}
	
}
