package babylon.cameras;

import babylon.collisions.Collider;
import babylon.Engine;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.Scene;
import babylon.tools.Tools;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.Lib;

class FreeCamera extends TargetCamera 
{
	public var ellipsoid:Vector3;
		
	public var _attachedCanvas:Sprite;
	
	public var _keys:Array<Int>;
	public var keysUp:Array<Int>;
	public var keysDown:Array<Int>;
	public var keysLeft:Array<Int>;
	public var keysRight:Array<Int>;
	
	public var checkCollisions:Bool = false;
    public var applyGravity:Bool = false;
	public var angularSensibility:Float = 2000.0;
	public var onCollide:AbstractMesh->Void = null;
	
	public var _collider:Collider;
	public var _needMoveForGravity:Bool;
	
	public var _oldPosition:Vector3;
	public var _diffPosition:Vector3;
	public var _newPosition:Vector3;
	
	public var _localDirection:Vector3;
	public var _transformedDirection:Vector3;
	
	public var _onMouseDown:MouseEvent->Void;
	public var _onMouseUp:MouseEvent->Void;
	public var _onMouseOut:MouseEvent->Void;
	public var _onMouseMove:MouseEvent->Void;
	
	public var _onKeyDown:KeyboardEvent->Void;
	public var _onKeyUp:KeyboardEvent->Void;
	public var _onLostFocus:Void->Void;

	public function new(name:String, position:Vector3, scene:Scene)
	{
		super(name, position, scene);

        this.ellipsoid = new Vector3(0.5, 1, 0.5);

        this._keys = [];
        this.keysUp = [38];
        this.keysDown = [40];
        this.keysLeft = [37];
        this.keysRight = [39];

        // Collisions
        this._collider = new Collider();
        this._needMoveForGravity = true;

        this._oldPosition = Vector3.Zero();
        this._diffPosition = Vector3.Zero();
        this._newPosition = Vector3.Zero();
	}
	
	override public function attachControl(canvas:Sprite, noPreventDefault:Bool = false) 
	{
        var previousPosition:Dynamic = null;
        var engine:Engine = this._scene.getEngine();
        
        if (this._attachedCanvas != null) 
		{
            return;
        }
		
        this._attachedCanvas = canvas;

        if (this._onMouseDown == null)
		{
            this._onMouseDown = function (evt:MouseEvent):Void
			{
                previousPosition = {
                    x: this._attachedCanvas.mouseX,
                    y: this._attachedCanvas.mouseY
                };
            };

            this._onMouseUp = function (evt:MouseEvent) 
			{
                previousPosition = null;
            };

            this._onMouseOut = function (evt:MouseEvent)
			{
                previousPosition = null;
                this._keys = [];
            };

            this._onMouseMove = function (evt:MouseEvent) 
			{
                if (previousPosition == null && !engine.isPointerLock) 
				{
                    return;
                }

                var offsetX:Float = 0;
                var offsetY:Float = 0;

                if (!engine.isPointerLock)
				{
                    offsetX = this._attachedCanvas.mouseX - previousPosition.x;
                    offsetY = this._attachedCanvas.mouseY - previousPosition.y;
                } 

                this.cameraRotation.y += offsetX / this.angularSensibility;
                this.cameraRotation.x += offsetY / this.angularSensibility;

                previousPosition = {
                    x: this._attachedCanvas.mouseX,
                    y: this._attachedCanvas.mouseY
                };
            };

            this._onKeyDown = function (evt:KeyboardEvent)
			{
                if (this.keysUp.indexOf(evt.keyCode) != -1 ||
                    this.keysDown.indexOf(evt.keyCode) != -1 ||
                    this.keysLeft.indexOf(evt.keyCode) != -1 ||
                    this.keysRight.indexOf(evt.keyCode) != -1)
				{
                    var index = this._keys.indexOf(evt.keyCode);

                    if (index == -1) {
                        this._keys.push(evt.keyCode);
                    }
                    /*if (!noPreventDefault) {
                        evt.preventDefault();
                    }*/
                }
            };

            this._onKeyUp = function (evt:KeyboardEvent)
			{
                if (this.keysUp.indexOf(evt.keyCode) != -1 ||
                    this.keysDown.indexOf(evt.keyCode) != -1 ||
                    this.keysLeft.indexOf(evt.keyCode) != -1 ||
                    this.keysRight.indexOf(evt.keyCode) != -1)
				{
                    var index = this._keys.indexOf(evt.keyCode);

                    if (index >= 0) {
                        this._keys.splice(index, 1);
                    }
                    /*if (!noPreventDefault) {
                        evt.preventDefault();
                    }*/
                }
            };

            this._onLostFocus = function ()
			{
                this._keys = [];
            };

            this._reset = function()
			{
                this._keys = [];
                previousPosition = null;
                this.cameraDirection = new Vector3(0, 0, 0);
                this.cameraRotation = new Vector2(0, 0);
            };
        }

        _attachedCanvas.addEventListener(MouseEvent.MOUSE_DOWN, this._onMouseDown, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_UP, this._onMouseUp, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_OUT, this._onMouseOut, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove, false);
        _attachedCanvas.stage.addEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown, false);
        _attachedCanvas.stage.addEventListener(KeyboardEvent.KEY_UP, this._onKeyUp, false);
    }
	
	override public function detachControl():Void
	{
        if (_attachedCanvas != null)
		{
            _attachedCanvas.removeEventListener(MouseEvent.MOUSE_DOWN, this._onMouseDown);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_UP, this._onMouseUp);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_OUT, this._onMouseOut);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove);
			_attachedCanvas.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown);
			_attachedCanvas.stage.removeEventListener(KeyboardEvent.KEY_UP, this._onKeyUp);
			
			_attachedCanvas = null;
        }

        if (_reset != null)
		{
            _reset();
        }
    }
	
	public function _collideWithWorld(velocity:Vector3):Void
	{
		var globalPosition: Vector3;
		if (this.parent != null)
		{
			globalPosition = Vector3.TransformCoordinates(this.position, this.parent.getWorldMatrix());
		} 
		else
		{
			globalPosition = this.position;
		}
		
        globalPosition.subtractFromFloatsToRef(0, this.ellipsoid.y, 0, this._oldPosition);
        this._collider.radius = this.ellipsoid;

        this._scene._getNewPosition(this._oldPosition, velocity, this._collider, 3, this._newPosition);
        this._newPosition.subtractToRef(this._oldPosition, this._diffPosition);

        if (this._diffPosition.length() > Engine.CollisionsEpsilon)
		{
            this.position.addInPlace(this._diffPosition);
            if (this.onCollide != null)
			{
                this.onCollide(this._collider.collidedMesh);
            }
        }
    }
	
	public function _checkInputs():Void
	{
        if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }

        // Keyboard
        for (index in 0...this._keys.length) 
		{
            var keyCode = this._keys[index];
            var speed:Float = this._computeLocalCameraSpeed();

            if (this.keysLeft.indexOf(keyCode) != -1) 
			{
                this._localDirection.setTo(-speed, 0, 0);
            }
			else if (this.keysUp.indexOf(keyCode) != -1)
			{
                this._localDirection.setTo(0, 0, speed);
            } 
			else if (this.keysRight.indexOf(keyCode) != -1)
			{
                this._localDirection.setTo(speed, 0, 0);
            } 
			else if (this.keysDown.indexOf(keyCode) != -1) 
			{
                this._localDirection.setTo(0, 0, -speed);
            }

            this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
            Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
            this.cameraDirection.addInPlace(this._transformedDirection);
        }
    }
	
	public function move(sx:Float, sz:Float):Void
	{
		if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }
		
		var speed:Float = this._computeLocalCameraSpeed();

		this._localDirection.setTo( -speed * sx, 0, -speed * sz);

		this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
		Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
		this.cameraDirection.addInPlace(this._transformedDirection);
	}
	
	public function moveLeft():Void
	{
		if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }
		
		var speed:Float = this._computeLocalCameraSpeed();

		this._localDirection.setTo(-speed, 0, 0);

		this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
		Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
		this.cameraDirection.addInPlace(this._transformedDirection);
	}
	
	public function moveRight():Void
	{
		if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }
		
		var speed:Float = this._computeLocalCameraSpeed();

		this._localDirection.setTo(speed, 0, 0);

		this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
		Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
		this.cameraDirection.addInPlace(this._transformedDirection);
	}
	
	public function moveFront():Void
	{
		if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }
		
		var speed:Float = this._computeLocalCameraSpeed();

		this._localDirection.setTo(0, 0, speed);

		this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
		Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
		this.cameraDirection.addInPlace(this._transformedDirection);
	}
	
	public function moveBehind():Void
	{
		if (this._localDirection == null) 
		{
            this._localDirection = Vector3.Zero();
            this._transformedDirection = Vector3.Zero();
        }
		
		var speed:Float = this._computeLocalCameraSpeed();

		this._localDirection.setTo(0, 0, -speed);

		this.getViewMatrix().invertToRef(this._cameraTransformMatrix);
		Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
		this.cameraDirection.addInPlace(this._transformedDirection);
	}
	
	override public function _decideIfNeedsToMove(): Bool
	{
		return this._needMoveForGravity || 
				FastMath.fabs(this.cameraDirection.x) > 0 ||
				FastMath.fabs(this.cameraDirection.y) > 0 || 
				FastMath.fabs(this.cameraDirection.z) > 0;
	}
	
	override public function _updatePosition(): Void
	{
		if (this.checkCollisions && this.getScene().collisionsEnabled)
		{
			this._collideWithWorld(this.cameraDirection);
			if (this.applyGravity)
			{
				var oldPosition:Vector3 = this.position.clone();
				this._collideWithWorld(this.getScene().gravity);
				this._needMoveForGravity = (oldPosition.distanceSquaredTo(this.position) != 0);
			}
		} 
		else 
		{
			this.position.addInPlace(this.cameraDirection);
		}
	}
	
	override public function _update():Void
	{
        this._checkInputs();

        super._update();
    }
}