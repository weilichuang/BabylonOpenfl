package babylon.lights;

import babylon.materials.Effect;
import babylon.Scene;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.math.Vector3;

class DirectionalLight extends Light implements IShadowLight
{
	public var direction:Vector3;
	public var transformedPosition:Vector3;
	
	public var _transformedDirection:Vector3;
	
	public function new(name:String, direction:Vector3, scene:Scene)
	{
		super(name, scene);
		
		this.position = direction.scale(-1);
        this.direction = direction;
	}
	
	override public function getAbsolutePosition(): Vector3
	{
		return this.transformedPosition != null ? this.transformedPosition : this.position;
	}
	
	public function setDirectionToTarget(target: Vector3): Vector3
	{
		target.subtract(this.position, this.direction);
		direction.normalize();
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

            Vector3.TransformNormalToRef(this.direction, this.parent.getWorldMatrix(), this._transformedDirection);			
            effect.setFloat4(uniformName0, _transformedDirection.x, _transformedDirection.y, _transformedDirection.z, 1);
        } 
		else
		{
			effect.setFloat4(uniformName0, this.direction.x, this.direction.y, this.direction.z, 1);
		}
    }
	
	override public function _getWorldMatrix():Matrix
	{
		this._worldMatrix.setTranslation(this.position);
        return this._worldMatrix;
    }
	
}
