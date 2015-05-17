package babylon.mesh;

import openfl.gl.GLBuffer;

class BabylonGLBuffer 
{
	public var buffer:GLBuffer;
	public var references:Int;
	
	public var capacity:Int;
	
	public var is32Bits:Bool = false;
	
	public function new(buffer:GLBuffer, is32Bits:Bool = false) 
	{
		this.buffer = buffer;
		this.is32Bits = is32Bits;
		this.references = 1;
	}
}