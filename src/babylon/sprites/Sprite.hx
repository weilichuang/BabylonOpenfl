package babylon.sprites;

import babylon.animations.Animation;
import babylon.math.Color4;
import babylon.math.Vector3;
import openfl.display.Bitmap;

class Sprite 
{

	public var name:String;
	public var color:Color4;

	public var position:Vector3;
	public var size:Float = 1.0;
	public var angle:Float = 0;
	public var cellIndex:Float = 0;
	public var invertU:Bool = false;
	public var invertV:Bool = false;
	
	public var disposeWhenFinishedAnimating:Bool;
	
	public var animations:Array<Animation> = [];
	
	private var _manager:SpriteManager;
	private var _animationStarted:Bool = false;
    private var _loopAnimation:Bool = false;
    private var _fromIndex:Float = 0;
    private var _toIndex:Float = 0;
    private var _delay:Float = 0;
    private var _direction:Int = 1;
	private var _time:Float = 0;
	private var _frameCount:Int = 0;

	public function new(name:String, manager:SpriteManager) 
	{
		this.name = name;
		
        _manager = manager;
        _manager.sprites.push(this);

        position = Vector3.Zero();
        color = new Color4(1.0, 1.0, 1.0, 1.0);
	}
	

	public function playAnimation(from:Float, to:Float, loop:Bool, delay:Float):Void
	{
		_fromIndex = from;
        _toIndex = to;
        _loopAnimation = loop;
        _delay = delay;
        _animationStarted = true;

        _direction = from < to ? 1 : -1;

        cellIndex = from;
        _time = 0;
	}
	
	public function stopAnimation():Void
	{
		_animationStarted = false;
	}
	
	public function animate(deltaTime:Float):Void
	{
		if (!_animationStarted)
		{
			return;
		}
		
		_time += deltaTime;
		if (_time > _delay)
		{
			_time = _time % _delay;
			cellIndex += _direction;
			if (cellIndex == _toIndex)
			{
				if (_loopAnimation) 
				{
					cellIndex = _fromIndex;
				} 
				else 
				{
					_animationStarted = false;
					if (disposeWhenFinishedAnimating)
					{
						dispose();
					}
				}
			}
		}
	}
	
	public function dispose():Void
	{
		_manager.sprites.remove(this);
	}
		
}
