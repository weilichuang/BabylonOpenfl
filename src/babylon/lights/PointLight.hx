package babylon.lights;

import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.Effect;
import babylon.Scene;
import babylon.math.Color3;
import babylon.math.Vector3;
import babylon.math.Matrix;

class PointLight extends Light 
{
	private var _transformedPosition:Vector3;
	
	public function new(name:String, position:Vector3, scene:Scene) 
	{
		super(name, scene);
		        
        this.position = position;
	}
	
	override public function getAbsolutePosition(): Vector3
	{
		return this._transformedPosition != null ? this._transformedPosition : this.position;
	}
	
	override public function transferToEffect(effect:Effect, uniformName0:String = "", uniformName1:String = ""):Void
	{
        if (this.parent != null) 
		{
            if (this._transformedPosition == null) 
			{
                this._transformedPosition = Vector3.Zero();
            }

            Vector3.TransformCoordinatesToRef(this.position, this.parent.getWorldMatrix(), this._transformedPosition);			
            effect.setFloat4(uniformName0, this._transformedPosition.x, this._transformedPosition.y, this._transformedPosition.z, 0);
        } 
		else
		{
		    effect.setFloat4(uniformName0, this.position.x, this.position.y, this.position.z, 0);
		}
    }
	
	override public function _getWorldMatrix():Matrix 
	{
		this._worldMatrix.setTranslation(this.position);

        return this._worldMatrix;
    }
	
}