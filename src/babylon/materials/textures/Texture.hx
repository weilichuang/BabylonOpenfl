package babylon.materials.textures;

import babylon.Scene;
import babylon.Engine;
import babylon.materials.textures.BaseTexture;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.animations.Animation;
import openfl.Lib;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLTexture;

class Texture extends BaseTexture 
{
    public static inline var NEAREST_SAMPLINGMODE:Int = 1;
    public static inline var BILINEAR_SAMPLINGMODE:Int = 2;
    public static inline var TRILINEAR_SAMPLINGMODE:Int = 3;

    public static inline var EXPLICIT_MODE:Int = 0;
    public static inline var SPHERICAL_MODE:Int = 1;
    public static inline var PLANAR_MODE:Int = 2;
    public static inline var CUBIC_MODE:Int = 3;
    public static inline var PROJECTION_MODE:Int = 4;
    public static inline var SKYBOX_MODE:Int = 5;

    public static inline var CLAMP_ADDRESSMODE:Int = 0;
    public static inline var WRAP_ADDRESSMODE:Int = 1;
    public static inline var MIRROR_ADDRESSMODE:Int = 2;
	
	public var url: String;
	
	public var uOffset:Float = 0;
    public var vOffset:Float = 0;
    public var uScale:Float = 1.0;
    public var vScale:Float = 1.0;
    public var uAng:Float = 0;
    public var vAng:Float = 0;
    public var wAng:Float = 0;
	
	
	private var _noMipmap:Bool = false;
	private var _invertY:Bool = true;
	private var _rowGenerationMatrix:Matrix;
	private var _cachedTextureMatrix:Matrix;
	private var _projectionModeMatrix:Matrix;
	
	private var _t0:Vector3;
	private var _t1:Vector3;
	private var _t2:Vector3;
	
	private var _cachedUOffset:Float=-1;
	private var _cachedVOffset:Float=-1;
	private var _cachedUScale:Float=-1;
	private var _cachedVScale:Float=-1;
	private var _cachedUAng:Float=-1;
	private var _cachedVAng:Float=-1;
	private var _cachedWAng:Float=-1;
	private var _cachedCoordinatesMode:Int=-1;
	private var _samplingMode:Int = 0;
	
	public function new(url:String, scene:Scene, 
						noMipmap:Bool = false, 
						invertY:Bool = true, 
						samplingMode:Int = Texture.TRILINEAR_SAMPLINGMODE)
	{
		super(scene);
		
        this.name = url;
        this.url = url;
        this._noMipmap = noMipmap;
        this._invertY = invertY;
		this._samplingMode = samplingMode;
		
		if (url == null || url == "")
			return;
			
		_texture = _getFromCache(url, noMipmap, _samplingMode);
		
		if (_texture == null)
		{		
			if (!scene.useDelayedTextureLoading)
			{
				_texture = scene.getEngine().createTexture(url, noMipmap, invertY, scene, _samplingMode);
			} 
			else
			{
				this.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
			}			
		}
	}
		
	override public function delayLoad():Void
	{
        if (this.delayLoadState != Engine.DELAYLOADSTATE_NOTLOADED)
		{
            return;
        }
        
        this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
        this._texture = _getFromCache(this.url, _noMipmap, _samplingMode);

        if (_texture == null)
		{
            _texture = getScene().getEngine().createTexture(this.url, _noMipmap, _invertY, getScene(), _samplingMode);
        }
    }
	
	public function _prepareRowForTextureGeneration(x:Float, y:Float, z:Float, t:Vector3):Void
	{
        x -= this.uOffset + 0.5;
        y -= this.vOffset + 0.5;
        z -= 0.5;

        Vector3.TransformCoordinatesFromFloatsToRef(x, y, z, _rowGenerationMatrix, t);

        t.x *= this.uScale;
        t.y *= this.vScale;

        t.x += 0.5;
        t.y += 0.5;
        t.z += 0.5;
    }
	
	override public function getTextureMatrix():Matrix
	{	
        if (uOffset == _cachedUOffset &&
			vOffset == _cachedVOffset &&
			uScale == _cachedUScale &&
			vScale == _cachedVScale &&
			uAng == _cachedUAng &&
			vAng == _cachedVAng &&
			wAng == _cachedWAng)
		{
			return _cachedTextureMatrix;
		}

		_cachedUOffset = uOffset;
		_cachedVOffset = vOffset;
		_cachedUScale = uScale;
		_cachedVScale = vScale;
		_cachedUAng = uAng;
		_cachedVAng = vAng;
		_cachedWAng = wAng;

		if (_cachedTextureMatrix == null)
		{
			_cachedTextureMatrix = Matrix.Zero();
			_rowGenerationMatrix = new Matrix();
			_t0 = Vector3.Zero();
			_t1 = Vector3.Zero();
			_t2 = Vector3.Zero();
		}

		Matrix.RotationYawPitchRollToRef(vAng, uAng, wAng, _rowGenerationMatrix);

		_prepareRowForTextureGeneration(0, 0, 0, _t0);
		_prepareRowForTextureGeneration(1.0, 0, 0, _t1);
		_prepareRowForTextureGeneration(0, 1.0, 0, _t2);

		_t1.subtractInPlace(_t0);
		_t2.subtractInPlace(_t0);

		_cachedTextureMatrix.identity();
		_cachedTextureMatrix.m[0] = _t1.x; _cachedTextureMatrix.m[1] = _t1.y; _cachedTextureMatrix.m[2] = _t1.z;
		_cachedTextureMatrix.m[4] = _t2.x; _cachedTextureMatrix.m[5] = _t2.y; _cachedTextureMatrix.m[6] = _t2.z;
		_cachedTextureMatrix.m[8] = _t0.x; _cachedTextureMatrix.m[9] = _t0.y; _cachedTextureMatrix.m[10] = _t0.z;

		return _cachedTextureMatrix;		
    }
	
	override public function getReflectionTextureMatrix():Matrix
	{
        if (uOffset == _cachedUOffset &&
			vOffset == _cachedVOffset &&
			uScale == _cachedUScale &&
			vScale == _cachedVScale &&
			coordinatesMode == _cachedCoordinatesMode)
		{
			return _cachedTextureMatrix;
		}

		if (_cachedTextureMatrix == null)
		{
			_cachedTextureMatrix = Matrix.Zero();
			_projectionModeMatrix = Matrix.Zero();
		}
		
		this._cachedCoordinatesMode = this.coordinatesMode;

		switch (coordinatesMode)
		{
			case Texture.SPHERICAL_MODE:
				_cachedTextureMatrix.identity();
				_cachedTextureMatrix.m[0] = -0.5 * uScale;
				_cachedTextureMatrix.m[5] = -0.5 * vScale;
				_cachedTextureMatrix.m[12] = 0.5 + uOffset;
				_cachedTextureMatrix.m[13] = 0.5 + vOffset;

			case Texture.PLANAR_MODE:
				_cachedTextureMatrix.identity();
				_cachedTextureMatrix.m[0] = uScale;
				_cachedTextureMatrix.m[5] = vScale;
				_cachedTextureMatrix.m[12] = uOffset;
				_cachedTextureMatrix.m[13] = vOffset;

			case Texture.PROJECTION_MODE:
				_projectionModeMatrix.identity();
				_projectionModeMatrix.m[0] = 0.5;
				_projectionModeMatrix.m[5] = -0.5;
				_projectionModeMatrix.m[10] = 0.0;
				_projectionModeMatrix.m[12] = 0.5;
				_projectionModeMatrix.m[13] = 0.5;
				_projectionModeMatrix.m[14] = 1.0;
				_projectionModeMatrix.m[15] = 1.0;

				getScene().getProjectionMatrix().multiplyToRef(_projectionModeMatrix, _cachedTextureMatrix);

			default:
				_cachedTextureMatrix.identity();

		}
		return _cachedTextureMatrix;
    }
	
	override public function clone():BaseTexture 
	{
        var newTexture:Texture = new Texture(_texture.url, getScene(), _noMipmap, _invertY, _samplingMode);

        // Base texture
        newTexture.hasAlpha = hasAlpha;
        newTexture.level = level;
		newTexture.wrapU = wrapU;
        newTexture.wrapV = wrapV;
        newTexture.coordinatesIndex = coordinatesIndex;
        newTexture.coordinatesMode = coordinatesMode;

        // Texture
        newTexture.uOffset = uOffset;
        newTexture.vOffset = vOffset;
        newTexture.uScale = uScale;
        newTexture.vScale = vScale;
        newTexture.uAng = uAng;
        newTexture.vAng = vAng;
        newTexture.wAng = wAng;
        
        return newTexture;
    }
	
}
