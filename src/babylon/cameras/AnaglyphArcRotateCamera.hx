package babylon.cameras;
import babylon.materials.Effect;
import babylon.math.FastMath;
import babylon.postprocess.AnaglyphPostProcess;
import babylon.postprocess.PassPostProcess;
import babylon.Scene;
import babylon.tools.Tools;

class AnaglyphArcRotateCamera extends ArcRotateCamera
{
	private var _eyeSpace:Float;
	private var _leftCamera:ArcRotateCamera;
	private var _rightCamera:ArcRotateCamera;
	
	private var _leftTexture:PassPostProcess;
	private var _anaglyphPostProcess:AnaglyphPostProcess;

	public function new(name: String, alpha: Float, beta: Float, radius: Float, target:Dynamic, eyeSpace: Float, scene:Scene) 
	{
		super(name, alpha, beta, radius, target, scene);
		
		this._eyeSpace = FastMath.ToRadians(eyeSpace);
		
		this._leftCamera = new ArcRotateCamera(name + "_left", alpha - this._eyeSpace, beta, radius, target, scene);
		this._rightCamera = new ArcRotateCamera(name + "_right", alpha + this._eyeSpace, beta, radius, target, scene);

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
		this._updateCamera(this._leftCamera);
		this._updateCamera(this._rightCamera);

		this._leftCamera.alpha = this.alpha - this._eyeSpace;
		this._rightCamera.alpha = this.alpha + this._eyeSpace;

		super._update();
	}
	
	public function _updateCamera(camera:ArcRotateCamera):Void
	{
		camera.beta = this.beta;
		camera.radius = this.radius;

		camera.minZ = this.minZ;
		camera.maxZ = this.maxZ;

		camera.fov = this.fov;

		camera.target = this.target;
	}
	
}