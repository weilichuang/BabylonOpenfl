package babylon.cameras;

import babylon.Scene;
import babylon.math.Vector3;

class TouchCamera extends FreeCamera
{
	
	public var _offsetX:Float;
	public var _offsetY:Float;
	public var _pointerCount:Int = 0;

	public function new(name:String, position:Vector3, scene:Scene)
	{
		super(name, position, scene);
		
		this._offsetX = 0;
        this._offsetY = 0;
        this._pointerCount = 0;
        this._pointerPressed = [];
	}
	
}