package example.ui;
import motion.Actuate;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.ui.Mouse;

class JoystickSimulator extends Sprite
{
	private var bg:Bitmap;
	
	private var moveCircle:Sprite;
	
	private var moveHandle:Float->Float->Void;
	
	private var isMouseDown:Bool;
	
	private var centerX:Float;
	private var centerY:Float;
	private var radius:Float;
	
	private var defaultAlpha:Float = 0.6;
	
    public function new() 
	{
		super();
		
		bg = new Bitmap(Assets.getBitmapData("assets/ui/RemoteSending_bg.png"));
		this.addChild(bg);
		
		bg.alpha = defaultAlpha;
		
		radius = bg.width / 2;
		
		moveCircle = new Sprite();
		
		var circle:Bitmap = new Bitmap(Assets.getBitmapData("assets/ui/RemoteSending_Btn.png"));
		moveCircle.addChild(circle);
		circle.x = -circle.width / 2;
		circle.y = -circle.height / 2;
		
		centerX = bg.width / 2;
		centerY = bg.height / 2;
		
		this.addChild(moveCircle);
		moveCircle.x = centerX;
		moveCircle.y = centerY;
		
		
		moveCircle.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		moveCircle.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    }
	
	public function attachChontrol():Void
	{
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
	}
	
	private function onStageMouseUp(e:MouseEvent):Void
	{
		if (!Lib.current.stage.hitTestObject(moveCircle))
		{
			isMouseDown = false;
		
			moveCircle.stopDrag();
			
			Mouse.show();
			
			this.resumePosition();
		}
	}
	
	public function setMoveHandle(handle:Float->Float->Void):Void
	{
		this.moveHandle = handle;
	}
	
	private function onMouseDown(e:MouseEvent):Void
	{
		isMouseDown = true;
		
		Mouse.hide();
		
		moveCircle.startDrag(false, new Rectangle(0, 0, bg.width, bg.height));
		
		moveCircle.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	private function onEnterFrame(e:Event):Void
	{
		var px:Float = moveCircle.x - centerX;
		var py:Float = moveCircle.y - centerY;
		var dis:Float = Math.sqrt(px * px + py * py);
		if (dis >= radius)
		{
			px = px / dis * radius;
			py = py / dis * radius;
			
			moveCircle.x = centerX + px;
			moveCircle.y = centerY + py;
		}
		
		if (isMouseDown)
		{
			if (moveHandle != null)
			{
				moveHandle(px / radius, py / radius);
			}
		}
	}
	
	private function onMouseUp(e:MouseEvent):Void
	{
		isMouseDown = false;
		
		moveCircle.stopDrag();
		
		Mouse.show();
		
		this.resumePosition();
	}
	
	
	private function resumePosition():Void
	{
		if (moveHandle != null)
		{
			moveHandle(0, 0);
		}
			
		moveCircle.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		var px:Float = moveCircle.x - centerX;
		var py:Float = moveCircle.y - centerY;
		var dis:Float = Math.sqrt(px * px + py * py);
		
		var duration:Float = 0.3;
		if (dis < radius)
		{
			duration *= dis / radius;
		}
		
		Actuate.tween(moveCircle, duration, { x:centerX, y:centerY }, true);
	}
}