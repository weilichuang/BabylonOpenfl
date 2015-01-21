package babylon;
import haxe.ds.Vector;
import openfl.gl.GL;

/**
 * ...
 * 
 */
class AlphaState
{
	public var isDirty(get, null):Bool;
	public var alphaBlend(get, set):Bool;

	private var _isAlphaBlendDirty:Bool = false;
	private var _isBlendFunctionParametersDirty:Bool = false;
	private var _alphaBlend:Bool = false;
	private var _blendFunctionParameters:Vector<Int>;
	
	public function new()
	{
		_blendFunctionParameters = new Vector<Int>(4);
	}

	private function get_isDirty(): Bool 
	{
		return _isAlphaBlendDirty || _isBlendFunctionParametersDirty;
	}

	private function get_alphaBlend(): Bool
	{
		return _alphaBlend;
	}

	private function set_alphaBlend(value: Bool):Bool
	{
		if (_alphaBlend == value)
		{
			return _alphaBlend;
		}

		_alphaBlend = value;
		_isAlphaBlendDirty = true;
		return _alphaBlend;
	}

	public function setAlphaBlendFunctionParameters(srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int): Void 
	{
		if (_blendFunctionParameters[0] == srcRGB &&
			_blendFunctionParameters[1] == dstRGB &&
			_blendFunctionParameters[2] == srcAlpha &&
			_blendFunctionParameters[3] == dstAlpha)
		{
			return;
		}

		_blendFunctionParameters[0] = srcRGB;                
		_blendFunctionParameters[1] = dstRGB;                
		_blendFunctionParameters[2] = srcAlpha;                
		_blendFunctionParameters[3] = dstAlpha;                

		_isBlendFunctionParametersDirty = true;
	}

	public function reset():Void
	{
		_alphaBlend = false;
		_blendFunctionParameters[0] = GL.ONE;
		_blendFunctionParameters[1] = GL.ONE;
		_blendFunctionParameters[2] = GL.ONE;
		_blendFunctionParameters[3] = GL.ONE;

		_isAlphaBlendDirty = true;
		_isBlendFunctionParametersDirty = false;
	}

	public function apply():Void
	{
		if (!isDirty)
		{
			return;
		}

		// Alpha blend
		if (_isAlphaBlendDirty)
		{
			if (_alphaBlend) 
			{
				GL.enable(GL.BLEND);
			} 
			else
			{
				GL.disable(GL.BLEND);
			}

			_isAlphaBlendDirty = false;
		}

		// Alpha function
		if (_isBlendFunctionParametersDirty)
		{
			GL.blendFuncSeparate(_blendFunctionParameters[0], _blendFunctionParameters[1], _blendFunctionParameters[2], _blendFunctionParameters[3]);
			_isBlendFunctionParametersDirty = false;
		}
	}
}