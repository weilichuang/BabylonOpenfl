package babylon.utils;
import openfl.gl.GL;

/**
 * ...
 * 
 */
class GLUtil
{
	private static var _activeTextureIndex:Int = -1;
	public static inline function activeTexture (texture:Int):Void 
	{
		if (_activeTextureIndex != texture)
		{
			_activeTextureIndex = texture;
			GL.activeTexture(texture);
		}
	}
	
	public static inline function resetGLStates():Void
	{
		_activeTextureIndex = -1;
	}
}