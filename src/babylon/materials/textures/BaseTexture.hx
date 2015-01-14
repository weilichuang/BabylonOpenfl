package babylon.materials.textures;

import babylon.animations.Animation;
import babylon.materials.textures.Texture;
import babylon.math.Matrix;
import babylon.Scene;
import babylon.Engine;
import openfl.display.BitmapData;
import openfl.gl.GLTexture;

class BaseTexture 
{
	public var name:String;

	public var delayLoadState:Int;
	
    public var hasAlpha:Bool = false;
	public var getAlphaFromRGB:Bool = false;
	
    public var level:Float = 1.0;
	public var isCube:Bool = false;
	public var isRenderTarget:Bool = false;
	
	public var animations:Array<Animation>;
	
	public var onDispose:Void->Void;
	
	
	public var coordinatesIndex:Int = 0;
	public var coordinatesMode:Int = Texture.EXPLICIT_MODE;
	public var wrapU:Int = Texture.WRAP_ADDRESSMODE;
	public var wrapV:Int = Texture.WRAP_ADDRESSMODE;
	public var anisotropicFilteringLevel:Int = 4;
	public var _cachedAnisotropicFilteringLevel: Int = -1;
	
	public var _texture:BabylonGLTexture;		

	private var _scene:Scene;

	public function new(scene:Scene) 
	{
		this._scene = scene;
        this._scene.textures.push(this);
		
		// Animations
        this.animations = [];
		
		delayLoadState = Engine.DELAYLOADSTATE_NONE;
		coordinatesMode = Texture.EXPLICIT_MODE;
		wrapU = Texture.WRAP_ADDRESSMODE;
		wrapV = Texture.WRAP_ADDRESSMODE;
	}
	
	public inline function getScene():Scene
	{
		return _scene;
	}
	
	public function getTextureMatrix(): Matrix
	{
		return null;
	}
	
	public function getReflectionTextureMatrix(): Matrix 
	{
		return null;
	}
	
	public function getInternalTexture():BabylonGLTexture
	{
        return this._texture;
    }
	
	public function isReady():Bool 
	{
		if (this.delayLoadState == Engine.DELAYLOADSTATE_NOTLOADED)
		{
			return true;
		}
			
        if (_texture != null) 
		{
            return _texture.isReady;
        }
		
        return false;
    }
	
	public function getSize():ISize 
	{
        if (_texture._width != -1)
		{
            return { width: _texture._width, height: _texture._height };
        }

        if (_texture._size != -1) 
		{
            return { width: _texture._size, height: _texture._size };
        }

        return { width: 0, height: 0 };
    }
	
	public function getBaseSize():ISize
	{
        if (!this.isReady())
            return { width: 0, height: 0 };

        if (_texture._size > 1)
		{
            return { width: _texture._size, height: _texture._size };
        }

        return { width: _texture._baseWidth, height: _texture._baseHeight };
    }
	
	public function _getFromCache(url:String, noMipmap:Bool, sampling:Int = 0):BabylonGLTexture
	{
        var texturesCache:Array<BabylonGLTexture> = this.getScene().getEngine().getLoadedTexturesCache();
        for (index in 0...texturesCache.length)
		{
            var texturesCacheEntry:BabylonGLTexture = texturesCache[index];

            if (texturesCacheEntry.url == url && texturesCacheEntry.noMipmap == noMipmap) 
			{
				if (sampling > 0 || sampling == texturesCacheEntry.samplingMode)
				{
					texturesCacheEntry.references++;
					return texturesCacheEntry;
				}
            }
        }

        return null;
    }
	
	public function delayLoad()
	{
		
    }
	
	public function releaseInternalTexture()
	{
        if (this._texture == null)
		{
            return;
        }
		
        var texturesCache:Array<BabylonGLTexture> = this._scene.getEngine().getLoadedTexturesCache();
        this._texture.references--;

        // Final reference ?
        if (this._texture.references == 0)
		{
			texturesCache.remove(this._texture);

            this.getScene().getEngine().releaseTexture(this._texture);

            this._texture = null;
        }
    }
	
	public function clone():BaseTexture
	{
		return null;
	}
	
	public function dispose() 
	{
        // Remove from scene
        var index:Int = this._scene.textures.indexOf(this);

        if (index >= 0)
		{
            this._scene.textures.splice(index, 1);
        }

        if (this._texture == null)
		{
            return;
        }

        this.releaseInternalTexture();


        // Callback
        if (this.onDispose != null) {
            this.onDispose();
        }
    }
	
	public function toString():String
	{
		return '$name,isCube:$isCube';
	}
	
}
