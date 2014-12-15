package babylon;
import openfl.gl.GL;

/**
 * ...
 * 
 */
class DepthCullingState
{
	public var cullFace(get, set):Int;
	public var cull(get, set):Bool;
	public var depthFunc(get, set):Int;
	public var depthMask(get, set):Bool;
	public var depthTest(get, set):Bool;
	public var isDirty(get, null):Bool;
	
	private var _isDepthTestDirty:Bool = false;
	private var _isDepthMaskDirty:Bool = false;
	private var _isDepthFuncDirty:Bool = false;
	private var _isCullFaceDirty:Bool = false;
	private var _isCullDirty:Bool = false;

	private var _depthTest:Bool;
	private var _depthMask:Bool;
	private var _depthFunc:Int;
	private var _cull:Bool;
	private var _cullFace:Int;
	
	public function new()
	{
		
	}

	private function get_isDirty(): Bool
	{
		return _isDepthFuncDirty || _isDepthTestDirty || _isDepthMaskDirty || _isCullFaceDirty || _isCullDirty;
	}

	private function get_cullFace(): Int 
	{
		return _cullFace;
	}

	private function set_cullFace(value: Int):Int
	{
		if (_cullFace == value)
		{
			return _cullFace;
		}

		_cullFace = value;
		_isCullFaceDirty = true;
		return _cullFace;
	}

	private function get_cull():Bool
	{
		return _cull;
	}

	private function set_cull(value: Bool):Bool
	{
		if (_cull == value) 
		{
			return _cull;
		}

		_cull = value;
		_isCullDirty = true;
		return _cull;
	}

	private function get_depthFunc(): Int 
	{
		return _depthFunc;
	}

	private function set_depthFunc(value: Int):Int
	{
		if (_depthFunc == value)
		{
			return _depthFunc;
		}

		_depthFunc = value;
		_isDepthFuncDirty = true;
		return _depthFunc;
	}

	private function get_depthMask(): Bool 
	{
		return _depthMask;
	}

	private function set_depthMask(value: Bool):Bool
	{
		if (_depthMask == value)
		{
			return _depthMask;
		}

		_depthMask = value;
		_isDepthMaskDirty = true;
		return _depthMask;
	}

	private function get_depthTest(): Bool 
	{
		return _depthTest;
	}

	private function set_depthTest(value: Bool):Bool
	{
		if (_depthTest == value) 
		{
			return _depthTest;
		}

		_depthTest = value;
		_isDepthTestDirty = true;
		return _depthTest;
	}

	public function reset():Void
	{
		_depthMask = true;
		_depthTest = true;
		_depthFunc = GL.LEQUAL;
		_cull = true;
		_cullFace = GL.BACK;

		_isDepthTestDirty = true;
		_isDepthMaskDirty = true;
		_isDepthFuncDirty = false;
		_isCullFaceDirty = false;
		_isCullDirty = false;
	}

	public function apply():Void
	{
		if (!isDirty) 
		{
			return;
		}

		// Cull
		if (_isCullDirty)
		{
			if (_cull == true) 
			{
				GL.enable(GL.CULL_FACE);
				
				//after change enable/disable cullface, GL.cullFace() may need call again
				//if don`t add this code, Flat2009Demo example will be wrong
				_isCullFaceDirty = true;
			} 
			else
			{
				GL.disable(GL.CULL_FACE);
			}

			_isCullDirty = false;
		}

		// Cull face
		if (_isCullFaceDirty)
		{
			GL.cullFace(cullFace);
			_isCullFaceDirty = false;
		}

		// Depth mask
		if (_isDepthMaskDirty) 
		{
			GL.depthMask(depthMask);
			_isDepthMaskDirty = false;
		}

		// Depth test
		if (_isDepthTestDirty)
		{
			if (depthTest == true) 
			{
				GL.enable(GL.DEPTH_TEST);
			} 
			else if (depthTest == false) 
			{
				GL.disable(GL.DEPTH_TEST);
			}
			_isDepthTestDirty = false;
		}

		// Depth func
		if (_isDepthFuncDirty) 
		{
			GL.depthFunc(depthFunc);
			_isDepthFuncDirty = false;
		}
	}
}