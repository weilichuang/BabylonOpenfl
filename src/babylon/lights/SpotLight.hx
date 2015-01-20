package babylon.lights;

import babylon.materials.Effect;
import babylon.Scene;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.math.Vector3;

class SpotLight extends Light implements IShadowLight
{
	public var direction:Vector3;
	public var angle:Float;
	public var exponent:Float;
	
	public var transformedPosition:Vector3;
	
	private var _transformedDirection:Vector3;

	private var _normalizeDirection:Vector3;
	
	public function new(name:String, position:Vector3, direction:Vector3, angle:Float, exponent:Float, scene:Scene)
	{
		super(name, scene);
		
		this.position = position;
        this.direction = direction;
        this.angle = angle;
        this.exponent = exponent;
		
		this._normalizeDirection = new Vector3();
	}
	
	override public function getAbsolutePosition(): Vector3
	{
		return this.transformedPosition != null ? this.transformedPosition : this.position;
	}
	
	public function setDirectionToTarget(target: Vector3): Vector3
	{
		target.subtract(this.position, this.direction);
		this.direction.normalize();
		return this.direction;
	}
	
	public function computeTransformedPosition():Bool
	{
        if (this.parent != null)
		{
            if (this.transformedPosition == null)
			{
                this.transformedPosition = Vector3.Zero();
            }

            Vector3.TransformCoordinatesToRef(this.position, this.parent.getWorldMatrix(), this.transformedPosition);
            return true;
        }

        return false;
    }
	
	override public function transferToEffect(effect:Effect, uniformName0:String = "", uniformName1:String = ""):Void
	{
        if (this.parent != null)
		{
            if (this._transformedDirection == null)
			{
                this._transformedDirection = Vector3.Zero();
            }
            
			this.computeTransformedPosition();
            
            Vector3.TransformNormalToRef(this.direction, parent.getWorldMatrix(), this._transformedDirection);

            effect.setFloat4(uniformName0, this.transformedPosition.x, this.transformedPosition.y, this.transformedPosition.z, this.exponent);
            
			this._normalizeDirection.copyFrom(this._transformedDirection);
			this._normalizeDirection.normalize();
        }
		else 
		{
            effect.setFloat4(uniformName0, this.position.x, this.position.y, this.position.z, this.exponent);

			this._normalizeDirection.copyFrom(this.direction);
			this._normalizeDirection.normalize();
        }

        effect.setFloat4(uniformName1, _normalizeDirection.x, _normalizeDirection.y, _normalizeDirection.z, Math.cos(this.angle * 0.5));
    }
	
	override public function _getWorldMatrix():Matrix 
	{
        this._worldMatrix.setTranslation(this.position);
        return this._worldMatrix;
    }
	
}
