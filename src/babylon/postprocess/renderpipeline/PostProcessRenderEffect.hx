package babylon.postprocess.renderpipeline;
import babylon.cameras.Camera;
import babylon.materials.Effect;
import babylon.math.Vector2;
import babylon.postprocess.BlackAndWhitePostProcess;
import babylon.postprocess.PostProcess;
import babylon.tools.Tools;

class PostProcessRenderEffect
{

	private var _engine: Engine;

	private var _postProcesses: Map<String,PostProcess>;
	private var _getPostProcess:Void->PostProcess;

	private var _singleInstance: Bool;

	private var _cameras: Map<String,Camera>;
	private var _indicesForCamera: Map<String,Array<Int>>;

	private var _renderPasses: Map<String,PostProcessRenderPass>;
	private var _renderEffectAsPasses: Map<String,PostProcessRenderEffect>;

	// private
	public var name: String;

	public var applyParameters: PostProcess->Void;
		
	public function new(engine: Engine, name: String, getPostProcess:Void->PostProcess, singleInstance: Bool = false)
	{
		this._engine = engine;
		this.name = name;
		this._getPostProcess = getPostProcess;

		this._singleInstance = singleInstance;
		
		this._cameras = new Map<String,Camera>();
		this._indicesForCamera = new Map<String,Array<Int>>();
		this._postProcesses = new Map<String,PostProcess>();
		this._renderPasses = new Map<String,PostProcessRenderPass>();
		this._renderEffectAsPasses = new Map<String,PostProcessRenderEffect>();
	}
	
	//private static function _GetInstance(engine:Engine, postProcessType:String, ratio:Float, samplingMode:Int):PostProcess
	//{
		//switch(postProcessType)
		//{
			//case "DisplayPassPostProcess":
				//return new DisplayPassPostProcess(postProcessType, ratio, null, samplingMode, engine, true);
			//case "BlackAndWhitePostProcess":
				//return new BlackAndWhitePostProcess(postProcessType, ratio, null, samplingMode, engine, true);
			//case "BlurPostProcess":
				//return new BlurPostProcess(postProcessType, new Vector2(0, 0), 1, ratio, null, samplingMode, engine, true);
		//}
		//return null;
	//}
	
	//private static function getSimpleClassName(type:Class<Dynamic>):String
	//{
		//var className:String = Type.getClassName(BlackAndWhitePostProcess);
		//var index = className.lastIndexOf(".");
		//return className.substr(index);
	//}
	
	public function update():Void
	{
		for (renderPass in _renderPasses)
		{
			renderPass.update();
		}
	}
	
	public function addPass(renderPass:PostProcessRenderPass):Void
	{
		_renderPasses.set(renderPass.name, renderPass);
		
		this._linkParameters();
	}
	
	public function removePass(renderPass:PostProcessRenderPass):Void
	{
		_renderPasses.remove(renderPass.name);
		
		this._linkParameters();
	}
	
	public function addRenderEffectAsPass(renderEffect: PostProcessRenderEffect): Void 
	{
		this._renderEffectAsPasses[renderEffect.name] = renderEffect;

		this._linkParameters();
	}

	public function getPass(passName: String): PostProcessRenderPass 
	{
		return this._renderPasses.get(passName);
	}

	public function emptyPasses(): Void
	{
		this._renderPasses = new Map<String,PostProcessRenderPass>();

		this._linkParameters();
	}

	public function _attachCameras(cameras: Dynamic): Void 
	{
		var cameraKey:String;

		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		for (i in 0..._cam.length)
		{
			var camera:Camera = _cam[i];
			
			var cameraName:String = camera.name;

			if (this._singleInstance)
			{
				cameraKey = "0";
			}
			else 
			{
				cameraKey = cameraName;
			}
			
			if (!_postProcesses.exists(cameraKey))
			{
				_postProcesses.set(cameraKey, this._getPostProcess());
			}
			
			var index = camera.attachPostProcess(this._postProcesses.get(cameraKey));

			if (!_indicesForCamera.exists(cameraName))
			{
				_indicesForCamera.set(cameraName, []);
			}

			this._indicesForCamera.get(cameraName).push(index);

			if (!_cameras.exists(cameraName))
			{
				this._cameras.set(cameraName, camera);
			}

			for (renderPass in _renderPasses)
			{
				renderPass._incRefCount();
			}
		}

		this._linkParameters();
	}

	public function _detachCameras(cameras: Dynamic): Void 
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		for (i in 0..._cam.length)
		{
			var camera = _cam[i];
			var cameraName = camera.name;

			camera.detachPostProcess(this._postProcesses.get(this._singleInstance ? "0" : cameraName), this._indicesForCamera.get(cameraName));

			_cameras.remove(cameraName);
			_indicesForCamera.remove(cameraName);

			for (renderPass in _renderPasses)
			{
				renderPass._decRefCount();
			}
		}
	}

	public function _enable(cameras: Dynamic): Void 
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		for (i in 0..._cam.length)
		{
			var camera:Camera = _cam[i];
			var cameraName = camera.name;

			var indices = this._indicesForCamera.get(cameraName);
			for (j in 0...indices.length)
			{
				if (camera._postProcesses[indices[j]] == null)
				{
					cameras[i].attachPostProcess(_postProcesses.get(_singleInstance ? "0" : cameraName), indices[j]);
				}
			}

			for (renderPass in _renderPasses)
			{
				renderPass._incRefCount();
			}
		}
	}

	public function _disable(cameras: Dynamic): Void
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		for (i in 0..._cam.length)
		{
			var camera:Camera = _cam[i];
			var cameraName = camera.name;

			camera.detachPostProcess(_postProcesses.get(_singleInstance ? "0" : cameraName), this._indicesForCamera.get(cameraName));

			var renderPass:PostProcessRenderPass;
			for (renderPass in _renderPasses)
			{
				renderPass._decRefCount();
			}
		}
	}

	public function getPostProcess(camera: Camera = null): PostProcess 
	{
		if (this._singleInstance) 
		{
			return this._postProcesses.get("0");
		}
		else
		{
			return this._postProcesses.get(camera.name);
		}
	}

	private function _linkParameters(): Void 
	{
		var keys = this._postProcesses.keys();
		for (key in keys) 
		{
			if (this.applyParameters != null)
			{
				this.applyParameters(_postProcesses.get(key));
			}
			
			this._postProcesses.get(key).onBeforeRender = function(effect: Effect):Void {
				this._linkTextures(effect);
			};
		}
	}

	private function _linkTextures(effect): Void 
	{
		var keys = this._renderPasses.keys();
		for (renderPassName in keys)
		{
			effect.setTexture(renderPassName, this._renderPasses.get(renderPassName).getRenderTexture());
		}

		keys = this._renderEffectAsPasses.keys();
		for (renderEffectName in keys) 
		{
			effect.setTextureFromPostProcess(renderEffectName + "Sampler", this._renderEffectAsPasses.get(renderEffectName).getPostProcess());
		}
	}
	
}