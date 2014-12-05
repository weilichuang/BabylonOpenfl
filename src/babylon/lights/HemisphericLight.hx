package babylon.lights;

import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.Effect;
import babylon.Scene;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.math.Vector3;

class HemisphericLight extends Light
{
	public var direction:Vector3;
	
	public var groundColor:Color3;

	private var _normalizeDirection:Vector3;
	
	public function new(name:String, direction:Vector3, scene:Scene) 
	{
		super(name, scene);
		
		this.direction = direction;
        this.groundColor = new Color3(0.0, 0.0, 0.0);
		
		this._normalizeDirection = new Vector3();
	}
	
	override private function get_shadowGenerator():ShadowGenerator 
	{
        return null;
    }
	
	override public function transferToEffect(effect:Effect, uniformName0:String = "", uniformName1:String = ""):Void
	{
		_normalizeDirection.copyFrom(this.direction);
		_normalizeDirection.normalize();
        effect.setFloat4(uniformName0, _normalizeDirection.x, _normalizeDirection.y, _normalizeDirection.z, 0);
        effect.setColor3(uniformName1, this.groundColor.scale(this.intensity));
    }
	
	override public function _getWorldMatrix():Matrix 
	{
        return this._worldMatrix;
    }
	
}
