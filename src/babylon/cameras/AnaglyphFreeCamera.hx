package babylon.cameras;

import babylon.materials.Effect;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.postprocess.AnaglyphPostProcess;
import babylon.postprocess.PassPostProcess;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class AnaglyphFreeCamera extends FreeCamera
{
	private var _eyeSpace:Float;
	private var _leftCamera:FreeCamera;
	private var _rightCamera:FreeCamera;
	private var _transformMatrix:Matrix;
	
	private var _leftTexture:PassPostProcess;
	private var _anaglyphPostProcess:AnaglyphPostProcess;

	public function new(name:String, position:Vector3, eyeSpace:Float,scene:Scene) 
	{
		super(name, position, scene);
		
		this._eyeSpace = FastMath.ToRadians(eyeSpace);
		this._transformMatrix = new Matrix();

		this._leftCamera = new FreeCamera(name + "_left", position.clone(), scene);
		this._rightCamera = new FreeCamera(name + "_right", position.clone(), scene);

		buildCamera(name);
	}
	
	private function buildCamera(name:String):Void
	{
        _leftCamera.isIntermediate = true;

        subCameras.push(_leftCamera);
        subCameras.push(_rightCamera);

        _leftTexture = new PassPostProcess(name + "_leftTexture", 1.0, _leftCamera);
        _anaglyphPostProcess = new AnaglyphPostProcess(name + "_anaglyph", 1.0, _rightCamera);

        _anaglyphPostProcess.onApply = function(effect:Effect):Void 
		{
            effect.setTextureFromPostProcess("leftSampler", _leftTexture);
        };

        _update();
    }
	
	override public function _update():Void
	{
		this._getSubCameraPosition(-this._eyeSpace, this._leftCamera.position);
		this._getSubCameraPosition(this._eyeSpace, this._rightCamera.position);

		this._updateCamera(this._leftCamera);
		this._updateCamera(this._rightCamera);

		super._update();
	}
	
	public function _getSubCameraPosition(eyeSpace:Float, result:Vector3):Void 
	{
		var target:Vector3 = this.getTarget();
		Matrix.Translation(-target.x, -target.y, -target.z).multiplyToRef(Matrix.RotationY(eyeSpace), this._transformMatrix);

		this._transformMatrix = this._transformMatrix.multiply(Matrix.Translation(target.x, target.y, target.z));

		Vector3.TransformCoordinatesToRef(this.position, this._transformMatrix, result);
	}
	
	public function _updateCamera(camera:FreeCamera):Void
	{
		camera.minZ = this.minZ;
		camera.maxZ = this.maxZ;

		camera.fov = this.fov;

		camera.viewport = this.viewport;

		camera.setTarget(this.getTarget());
	}
	
}