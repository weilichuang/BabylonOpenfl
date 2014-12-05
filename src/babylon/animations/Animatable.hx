package babylon.animations;

class Animatable
{
	public var target:Dynamic;
    public var loopAnimation:Bool;
    public var fromFrame:Float;
    public var toFrame:Float;
    public var speedRatio:Float;
	public var onAnimationEnd:Void->Void;

	private var _localDelayOffset: Float = 0;
	private var _pausedDelay:Float = 0;
	private var _animations:Array<Animation>;
	private var _paused:Bool = false;
	
	private var _scene: Scene;

	public var animationStarted:Bool = false;
		
	public function new(scene: Scene, target:Dynamic, 
						fromFrame: Float = 0, toFrame: Float = 100, 
						loopAnimation: Bool = false, 
						speedRatio: Float = 1.0, 
						onAnimationEnd:Void->Void = null, 
						animations: Array<Animation> = null) 
	{
		this._scene = scene;
		this.target = target;
        this.fromFrame = fromFrame;
        this.toFrame = toFrame;
        this.loopAnimation = loopAnimation;
        this.speedRatio = speedRatio;
        this.onAnimationEnd = onAnimationEnd;
		
		scene._activeAnimatables.push(this);
		
		_animations = new Array<Animation>();
		if (animations != null)
		{
			appendAnimations(target, animations);
		}
	}
	
	public function appendAnimations(target: Dynamic, animations: Array<Animation>): Void 
	{
		for (index in 0...animations.length)
		{
			var animation:Animation = animations[index];

			animation._target = target;
			_animations.push(animation);    
		}            
	}

	public function getAnimationByTargetProperty(property: String):Animation 
	{
		var animations = this._animations;

		for (index in 0...animations.length)
		{
			if (animations[index].targetProperty == property)
			{
				return animations[index];
			}
		}

		return null;
	}

	public function pause(): Void
	{
		if (_paused)
			return;
			
		_paused = true;
	}

	public function restart(): Void 
	{
		_paused = false;
	}

	public function stop(): Void 
	{
		var index = _scene._activeAnimatables.indexOf(this);

		if (index > -1) 
		{
			_scene._activeAnimatables.splice(index, 1);
		}

		if (this.onAnimationEnd != null)
		{
			this.onAnimationEnd();
		}
	}

	public function _animate(delay: Float): Bool 
	{
		if (_paused)
		{
			if (_pausedDelay <= 0)
			{
				_pausedDelay = delay;
			}
			return true;
		}

		if (this._localDelayOffset == 0)
		{
			this._localDelayOffset = delay;
		}
		else if (_pausedDelay != 0)
		{
			this._localDelayOffset += delay - this._pausedDelay;
			this._pausedDelay = 0;
		}

		// Animating
		var running:Bool = false;
		var animations = this._animations;
		for (index in 0...animations.length)
		{
			var isRunning:Bool = animations[index].animate(delay - _localDelayOffset, fromFrame, toFrame, loopAnimation, speedRatio);
			running = running || isRunning;
		}

		if (!running && this.onAnimationEnd != null)
		{
			this.onAnimationEnd();
		}

		return running;
	}
}