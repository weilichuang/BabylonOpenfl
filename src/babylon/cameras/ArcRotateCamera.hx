package babylon.cameras;

import babylon.collisions.Collider;
import babylon.Engine;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.MeshHelper;
import babylon.Scene;
import babylon.tools.Tools.BabylonMinMax;
import openfl.display.DisplayObject;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.Lib;

class ArcRotateCamera extends Camera
{
	public var inertialAlphaOffset:Float = 0;
	public var inertialBetaOffset:Float = 0;
	public var inertialRadiusOffset:Float = 0;
	
	public var lowerAlphaLimit:Null<Float> = null;
	public var upperAlphaLimit:Null<Float> = null;
	
	public var lowerBetaLimit:Float = 0.01;
	public var upperBetaLimit:Float = 3.141592653589; // Math.PI;
	
	public var lowerRadiusLimit:Null<Float> = null;
	public var upperRadiusLimit:Null<Float> = null;
	
	public var angularSensibility:Float = 1000.0;
	public var wheelPrecision:Float = 3.0;
	public var zoomOnFactor:Float = 1;
	
	public var alpha:Float;
	public var beta:Float;
	public var radius:Float;
	public var target:Dynamic;

	private var _keys:Array<Int>;
	public var keysUp:Array<Int>;
	public var keysDown:Array<Int>;
	public var keysLeft:Array<Int>;
	public var keysRight:Array<Int>;
	
	private var _viewMatrix:Matrix;
	private var _attachedCanvas:DisplayObject;
	
	private var _onMouseDown:MouseEvent->Void;
	private var _onMouseUp:MouseEvent->Void;
	private var _onMouseOut:MouseEvent->Void;
	private var _onMouseMove:MouseEvent->Void;
	private var _wheel:MouseEvent->Void;
	
	private var _onKeyDown:KeyboardEvent->Void;
	private var _onKeyUp:KeyboardEvent->Void;
	private var _onLostFocus:Void->Void;
	private var _reset:Void->Void;
	
	// Collisions
	public var onCollide: AbstractMesh->Void;
	public var checkCollisions:Bool;
	public var collisionRadius:Vector3;
	private var _collider:Collider;
	private var _previousPosition:Vector3;
	private var _collisionVelocity:Vector3;
	private var _newPosition:Vector3;
	private var _previousAlpha: Float;
	private var _previousBeta: Float;
	private var _previousRadius: Float;

	public function new(name:String, alpha:Float, beta:Float, radius:Float, target:Dynamic, scene:Scene)
	{
		super(name, Vector3.Zero(), scene);
		
		this.alpha = alpha;
        this.beta = beta;
        this.radius = radius;
        this.target = target;
		        
        this._keys = [];
        this.keysUp = [38];
        this.keysDown = [40];
        this.keysLeft = [37];
        this.keysRight = [39];
		
		checkCollisions = false;
		collisionRadius = new Vector3(0.5, 0.5, 0.5);
		_collider = new Collider();
		_previousPosition = Vector3.Zero();
		_collisionVelocity = Vector3.Zero();
		_newPosition = Vector3.Zero();

        this._viewMatrix = new Matrix();

        this.getViewMatrix();
	}
	
	override private function _initCache():Void
	{
		super._initCache();
		
		this._cache.parent = null;
		this._cache.target = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		this._cache.alpha = null;
		this._cache.beta = null;
		this._cache.radius = null;
		this._cache.position = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		this._cache.upVector = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

		this._cache.mode = null;
		this._cache.minZ = null;
		this._cache.maxZ = null;

		this._cache.fov = null;
		this._cache.aspectRatio = null;

		this._cache.orthoLeft = null;
		this._cache.orthoRight = null;
		this._cache.orthoBottom = null;
		this._cache.orthoTop = null;
		this._cache.renderWidth = null;
		this._cache.renderHeight = null;
    }
	
	override public function internalUpdateCache(ignoreParentClass:Bool = true):Void
	{
        if (!ignoreParentClass)
            super.internalUpdateCache(ignoreParentClass);

        this._cache.target.copyFrom(this._getTargetPosition());
        this._cache.alpha = this.alpha;
        this._cache.beta = this.beta;
        this._cache.radius = this.radius;
    }
	
	public function _getTargetPosition():Vector3 
	{
        return Std.is(this.target, Vector3) ? this.target : this.target.position;
    }
	
	override public function _isSynchronizedViewMatrix():Bool
	{
        if (!super._isSynchronizedViewMatrix())
            return false;

        return this._cache.target.equals(this._getTargetPosition())
				&& this._cache.alpha == this.alpha
				&& this._cache.beta == this.beta
				&& this._cache.radius == this.radius;
    }
		
	public function setPosition(position:Vector3):Void
	{
		var radiusv3:Vector3 = position.subtract(this._getTargetPosition());
		
        this.radius = radiusv3.length();

        // Alpha
		this.alpha = Math.acos(radiusv3.x / Math.sqrt(Math.pow(radiusv3.x, 2) + Math.pow(radiusv3.z, 2)));

		if (radiusv3.z < 0) 
		{
			this.alpha = 2 * Math.PI - this.alpha;
		}

		// Beta
		this.beta = Math.acos(radiusv3.y / this.radius);
	}
	
	override public function attachControl(canvas:DisplayObject, noPreventDefault:Bool = false):Void
	{
		var previousPosition:Dynamic = null;   

        if (this._attachedCanvas != null)
		{
            return;
        }
        this._attachedCanvas = canvas;

        var engine:Engine = this._scene.getEngine();
		
		if (this._onMouseDown == null)
		{
            this._onMouseDown = function (evt:MouseEvent) {
                previousPosition = {
                    x: this._attachedCanvas.mouseX,
                    y: this._attachedCanvas.mouseY
                };
            };

            this._onMouseUp = function (evt:MouseEvent) {
                previousPosition = null;
            };

            this._onMouseMove = function (evt:MouseEvent) {
                if (previousPosition == null && !engine.isPointerLock) {
                    return;
                }
				
				var offsetX:Float = 0;
                var offsetY:Float = 0;

                if (!engine.isPointerLock) {
                    offsetX = this._attachedCanvas.mouseX - previousPosition.x;
                    offsetY = this._attachedCanvas.mouseY - previousPosition.y;
                } 
				
                this.inertialAlphaOffset -= offsetX / this.angularSensibility;
                this.inertialBetaOffset -= offsetY / this.angularSensibility;

                previousPosition = {
                    x: this._attachedCanvas.mouseX,
                    y: this._attachedCanvas.mouseY
                };                
            };
			
			this._wheel = function(event:MouseEvent) {
                var delta = event.delta / 3;
                
                this.inertialRadiusOffset += delta;
            };

            this._onKeyDown = function (evt:KeyboardEvent) 
			{
                if (this.keysUp.indexOf(evt.keyCode) != -1 ||
                    this.keysDown.indexOf(evt.keyCode) != -1 ||
                    this.keysLeft.indexOf(evt.keyCode) != -1 ||
                    this.keysRight.indexOf(evt.keyCode) != -1) 
				{
                    var index = this._keys.indexOf(evt.keyCode);

                    if (index == -1) 
					{
                        this._keys.push(evt.keyCode);
                    }
                }
				
				//trace("this.alpha:" + this.alpha);
				//trace("this.beta:" + this.beta);
				//trace("this.radius:" + this.radius);
            };

            this._onKeyUp = function (evt:KeyboardEvent)
			{
                if (this.keysUp.indexOf(evt.keyCode) != -1 ||
                    this.keysDown.indexOf(evt.keyCode) != -1 ||
                    this.keysLeft.indexOf(evt.keyCode) != -1 ||
                    this.keysRight.indexOf(evt.keyCode) != -1) 
				{
                    var index = this._keys.indexOf(evt.keyCode);

                    if (index >= 0)
					{
                        this._keys.splice(index, 1);
                    }
                }
            };

            this._onLostFocus = function () 
			{
                this._keys = [];
            };

            this._reset = function ()
			{
                this._keys = [];
                this.inertialAlphaOffset = 0;
                this.inertialBetaOffset = 0;
				this.inertialRadiusOffset = 0;
                previousPosition = null;
            };
        }
		
		_attachedCanvas.addEventListener(MouseEvent.MOUSE_DOWN, this._onMouseDown, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_UP, this._onMouseUp, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_OUT, this._onMouseOut, false);
        _attachedCanvas.addEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove, false);
        _attachedCanvas.addEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown, false);
        _attachedCanvas.addEventListener(KeyboardEvent.KEY_UP, this._onKeyUp, false);
		_attachedCanvas.addEventListener(MouseEvent.MOUSE_WHEEL, this._wheel, false);
        //window.addEventListener("blur", this._onLostFocus, false);
	}
	
	override public function detachControl():Void
	{
        if (_attachedCanvas != null) 
		{
            _attachedCanvas.removeEventListener(MouseEvent.MOUSE_DOWN, this._onMouseDown);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_UP, this._onMouseUp);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_OUT, this._onMouseOut);
			_attachedCanvas.removeEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove);
			_attachedCanvas.removeEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown);
			_attachedCanvas.removeEventListener(KeyboardEvent.KEY_UP, this._onKeyUp);
			//window.removeEventListener("blur", this._onLostFocus);
			
			_attachedCanvas = null;
        }
        
        if (_reset != null)
		{
            _reset();
        }
    }
	
	override public function _update():Void
	{
		// Keyboard
        for (index in 0...this._keys.length)
		{
            var keyCode = this._keys[index];

            if (this.keysLeft.indexOf(keyCode) != -1)
			{
                this.inertialAlphaOffset -= 0.01;
            } 
			else if (this.keysUp.indexOf(keyCode) != -1)
			{
                this.inertialBetaOffset -= 0.01;
            } 
			else if (this.keysRight.indexOf(keyCode) != -1)
			{
                this.inertialAlphaOffset += 0.01;
            } 
			else if (this.keysDown.indexOf(keyCode) != -1)
			{
                this.inertialBetaOffset += 0.01;
            }
        }

        // Inertia
        if (this.inertialAlphaOffset != 0 || this.inertialBetaOffset != 0 || this.inertialRadiusOffset != 0) 
		{
            this.alpha += this.inertialAlphaOffset;
            this.beta += this.inertialBetaOffset;
            this.radius -= this.inertialRadiusOffset;

            this.inertialAlphaOffset *= this.inertia;
            this.inertialBetaOffset *= this.inertia;
            this.inertialRadiusOffset *= this.inertia;

            if (FastMath.fabs(this.inertialAlphaOffset) < Engine.Epsilon)
                this.inertialAlphaOffset = 0;

            if (FastMath.fabs(this.inertialBetaOffset) < Engine.Epsilon)
                this.inertialBetaOffset = 0;

            if (FastMath.fabs(this.inertialRadiusOffset) < Engine.Epsilon)
                this.inertialRadiusOffset = 0;
        }

        // Limits
        if (this.lowerAlphaLimit != null && this.alpha < this.lowerAlphaLimit)
		{
            this.alpha = this.lowerAlphaLimit;
        }
        if (this.upperAlphaLimit != null && this.alpha > this.upperAlphaLimit)
		{
            this.alpha = this.upperAlphaLimit;
        }

		this.beta = FastMath.clamp(this.beta, this.lowerBetaLimit, this.upperBetaLimit);
		
        if (this.lowerRadiusLimit != null && this.radius < this.lowerRadiusLimit)
		{
            this.radius = this.lowerRadiusLimit;
        }
        if (this.upperRadiusLimit != null && this.radius > this.upperRadiusLimit) 
		{
            this.radius = this.upperRadiusLimit;
        }
	}
	
	override public function _getViewMatrix():Matrix
	{        
		// Compute
        var cosa:Float = Math.cos(this.alpha);
        var sina:Float = Math.sin(this.alpha);
        var cosb:Float = Math.cos(this.beta);
        var sinb:Float = Math.sin(this.beta);

        var target:Vector3 = this._getTargetPosition();						
		this.position.x = target.x + this.radius * cosa * sinb;
		this.position.y = target.y + this.radius * cosb;
		this.position.z = target.z + this.radius * sina * sinb;
									
		if (this.checkCollisions) 
		{
			this._collider.radius = this.collisionRadius;
			this.position.subtractToRef(this._previousPosition, this._collisionVelocity);

			this.getScene()._getNewPosition(this._previousPosition, this._collisionVelocity, this._collider, 3, this._newPosition);

			if (!this._newPosition.equalsWithEpsilon(this.position))
			{
				this.position.copyFrom(this._previousPosition);

				this.alpha = this._previousAlpha;
				this.beta = this._previousBeta;
				this.radius = this._previousRadius;

				if (this.onCollide != null) 
				{
					this.onCollide(this._collider.collidedMesh);
				}
			}
		}
			
        Matrix.LookAtLHToRef(this.position, target, this.upVector, this._viewMatrix);
		
		this._previousAlpha = this.alpha;
		this._previousBeta = this.beta;
		this._previousRadius = this.radius;
		this._previousPosition.copyFrom(this.position);

        return this._viewMatrix;
    }
	
	public function zoomOn(?meshes: Array<AbstractMesh>): Void
	{
		if(meshes == null)
			meshes = this.getScene().meshes;

		var minMaxVector:BabylonMinMax = MeshHelper.MinMax(meshes);
		var distance:Float = minMaxVector.minimum.distanceTo(minMaxVector.maximum);

		this.radius = distance * this.zoomOnFactor;

		this.focusOn({ minimum: minMaxVector.minimum, maximum: minMaxVector.maximum, distance: distance });
	}
	
	public function focusOn(meshesOrMinMaxVectorAndDistance:Dynamic): Void 
	{
		this.target = MeshHelper.Center(meshesOrMinMaxVectorAndDistance);

		this.maxZ = meshesOrMinMaxVectorAndDistance.distance * 2;
	}
	
}