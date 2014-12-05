package babylon.materials.textures;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLTexture;

class BabylonGLTexture
{
	public var data:GLTexture;
	
	// TODO - Are these really members of this class
	public var _framebuffer:GLFramebuffer;
	
	public var _depthBuffer:GLRenderbuffer;
	
	public var generateMipMaps:Bool;
	
	public var isCube:Bool;
	public var _size:Float;
	
	public var isReady:Bool;
	public var noMipmap:Bool = true;
	public var references:Int;
	public var url:String;
	
	public var _baseHeight:Int;
	public var _baseWidth:Int;
	public var _cachedWrapU:Int = -1;
	public var _cachedWrapV:Int = -1;
	public var _cachedCoordinatesMode:Int = -1;
	
	public var _width:Float;	
	public var _height:Float;
	
	
	public function new(url:String, data:GLTexture)
	{
		this.url = url;
		this.data = data;
		
		this._framebuffer = null;
		this._depthBuffer = null;
		this.generateMipMaps = false;
		this.isCube = false;
		
		this._size = 1;
		this._width = 1;
		this._height = 1;
		this._baseHeight = 1;
		this._baseWidth = 1;
		this._cachedWrapU = -1;
		this._cachedWrapV = -1;
		
		this.isReady = false;
		this.noMipmap = false;
		this.references = 0;
	}
	
}