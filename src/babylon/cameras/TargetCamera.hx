package babylon.cameras;
import babylon.Engine;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.tools.Tools;

/**
 * ...
 * 
 */
class TargetCamera extends Camera
{
	public var cameraDirection:Vector3;
	public var cameraRotation:Vector2;
	public var rotation:Vector3;
	
	public var speed:Float = 2.0;
	public var noRotationConstraint:Bool = false;
	public var lockedTarget:Dynamic = null;
	
	public var _currentTarget:Vector3;
	public var _viewMatrix:Matrix;
	public var _camMatrix:Matrix;
	public var _cameraTransformMatrix:Matrix;
	public var _cameraRotationMatrix:Matrix;
	public var _referencePoint:Vector3;
	public var _transformedReferencePoint:Vector3;
	public var _lookAtTemp:Matrix;
	public var _tempMatrix:Matrix;
	
	public var _reset:Void->Void;
	
	public var _waitingLockedTargetId:String;
	
	public function new(name:String, position:Vector3, scene:Scene)
	{
		super(name, position, scene);
		
		this.cameraDirection = new Vector3(0, 0, 0);
        this.cameraRotation = new Vector2(0, 0);
        this.rotation = new Vector3(0, 0, 0);

        // Internals
        this._currentTarget = Vector3.Zero();
        this._viewMatrix = Matrix.Zero();
        this._camMatrix = Matrix.Zero();
        this._cameraTransformMatrix = Matrix.Zero();
        this._cameraRotationMatrix = Matrix.Zero();
        this._referencePoint = new Vector3(0, 0, 1);
        this._transformedReferencePoint = Vector3.Zero();

        this._lookAtTemp = Matrix.Zero();
        this._tempMatrix = Matrix.Zero();
	}
	
	public function _getLockedTargetPosition():Vector3 
	{
		if (this.lockedTarget == null)
			return null;
			
		var ret:Vector3 = Std.is(this.lockedTarget, Vector3) ? this.lockedTarget : this.lockedTarget.position;
        return ret;
    }
	
	override private function _initCache():Void
	{
		super._initCache();
		
		this._cache.lockedTarget = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		this._cache.rotation = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
	}
	
	override public function internalUpdateCache(ignoreParentClass:Bool = false):Void
	{
        if (!ignoreParentClass)
            super.internalUpdateCache(ignoreParentClass);

        var lockedTargetPosition = this._getLockedTargetPosition();
        if (lockedTargetPosition == null)
		{
            this._cache.lockedTarget = null;
        }
        else 
		{
            if (this._cache.lockedTarget == null)
                this._cache.lockedTarget = lockedTargetPosition.clone();
            else
                this._cache.lockedTarget.copyFrom(lockedTargetPosition);
        }

        this._cache.rotation.copyFrom(this.rotation);
    }
	
	override public function _isSynchronizedViewMatrix():Bool
	{
        if (!super._isSynchronizedViewMatrix()) 
		{
            return false;
        }

        var lockedTargetPosition:Vector3 = this._getLockedTargetPosition();
		
        return (this._cache.lockedTarget != null ? this._cache.lockedTarget.equals(lockedTargetPosition) : lockedTargetPosition == null)
            && this._cache.rotation.equals(this.rotation);
    }
	
	public inline function _computeLocalCameraSpeed():Float
	{
		var engine:Engine = getEngine();
		return this.speed * (engine.getDeltaTime() / (engine.getFps() * 10.0));
    }
	
	public function setTarget(target:Vector3):Void
	{
        this.upVector.normalize();
        
        Matrix.LookAtLHToRef(this.position, target, this.upVector, this._camMatrix);
        this._camMatrix.invert();

        this.rotation.x = Math.atan(this._camMatrix.m[6] / this._camMatrix.m[10]);

        var vDir:Vector3 = target.subtract(this.position);

        if (vDir.x >= 0.0)
		{
            this.rotation.y = (-Math.atan(vDir.z / vDir.x) + Math.PI / 2.0);
        } 
		else
		{
            this.rotation.y = (-Math.atan(vDir.z / vDir.x) - Math.PI / 2.0);
        }

        this.rotation.z = -Math.acos(new Vector3(0, 1.0, 0).dot(this.upVector));

        if (Math.isNaN(this.rotation.x))
            this.rotation.x = 0;

        if (Math.isNaN(this.rotation.y))
            this.rotation.y = 0;

        if (Math.isNaN(this.rotation.z))
            this.rotation.z = 0;
    }
	
	public function _decideIfNeedsToMove():Bool
	{
		return FastMath.fabs(this.cameraDirection.x) > 0 || FastMath.fabs(this.cameraDirection.y) > 0 || FastMath.fabs(this.cameraDirection.z) > 0;
	}
	
	public function getTarget():Vector3
	{
		return this._currentTarget;
	}
	
	public function _updatePosition():Void
	{
		this.position.addInPlace(this.cameraDirection);
	}
	
	override public function _update():Void
	{
        var needToMove = _decideIfNeedsToMove();
						
        var needToRotate = FastMath.fabs(this.cameraRotation.x) > 0 || FastMath.fabs(this.cameraRotation.y) > 0;
		
		if (needToMove) 
		{
			this._updatePosition();
		}
		
        // Rotate
        if (needToRotate)
		{
            this.rotation.x += this.cameraRotation.x;
            this.rotation.y += this.cameraRotation.y;

            if (!this.noRotationConstraint) 
			{
                var limit:Float = (Math.PI / 2) * 0.95;

                if (this.rotation.x > limit)
                    this.rotation.x = limit;
                if (this.rotation.x < -limit)
                    this.rotation.x = -limit;
            }
        }

        // Inertia
        if (needToMove)
		{
            if (FastMath.fabs(this.cameraDirection.x) < Engine.Epsilon)
                this.cameraDirection.x = 0;

            if (FastMath.fabs(this.cameraDirection.y) < Engine.Epsilon)
                this.cameraDirection.y = 0;

            if (FastMath.fabs(this.cameraDirection.z) < Engine.Epsilon)
                this.cameraDirection.z = 0;

            this.cameraDirection.scaleInPlace(this.inertia);
        }
		
        if (needToRotate)
		{
            if (FastMath.fabs(this.cameraRotation.x) < Engine.Epsilon)
                this.cameraRotation.x = 0;

            if (FastMath.fabs(this.cameraRotation.y) < Engine.Epsilon)
                this.cameraRotation.y = 0;

            this.cameraRotation.scaleInPlace(this.inertia);
        }
    }
	
	override public function _getViewMatrix():Matrix
	{
        if (this.lockedTarget == null) 
		{
            // Compute
            if (this.upVector.x != 0 || this.upVector.y != 1.0 || this.upVector.z != 0)
			{
                Matrix.LookAtLHToRef(Vector3.Zero(), this._referencePoint, this.upVector, this._lookAtTemp);
                Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this._cameraRotationMatrix);

                this._lookAtTemp.multiplyToRef(this._cameraRotationMatrix, this._tempMatrix);
                this._lookAtTemp.invert();
                this._tempMatrix.multiplyToRef(this._lookAtTemp, this._cameraRotationMatrix);
            } 
			else 
			{
                Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this._cameraRotationMatrix);
            }

            Vector3.TransformCoordinatesToRef(this._referencePoint, this._cameraRotationMatrix, this._transformedReferencePoint);

            // Computing target and final matrix
            this.position.addToRef(this._transformedReferencePoint, this._currentTarget);
        }
		else 
		{
            this._currentTarget.copyFrom(this._getLockedTargetPosition());
        }
        
        Matrix.LookAtLHToRef(this.position, this._currentTarget, this.upVector, this._viewMatrix);
        return this._viewMatrix;
    }
}