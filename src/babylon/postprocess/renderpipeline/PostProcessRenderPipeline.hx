package babylon.postprocess.renderpipeline;
import babylon.cameras.Camera;
import babylon.postprocess.DisplayPassPostProcess;
import babylon.tools.Tools;

class PostProcessRenderPipeline
{
	private static inline var PASS_EFFECT_NAME: String = "passEffect";
	private static inline var PASS_SAMPLER_NAME: String = "passSampler";
	
	private var _engine: Engine;

	private var _renderEffects: Map<String,PostProcessRenderEffect>;
	private var _renderEffectsForIsolatedPass: Map<String,PostProcessRenderEffect>;

	private var _cameras: Map<String,Camera>;

	public var name: String;

	public function new(engine: Engine, name: String) 
	{
		this._engine = engine;
		this.name = name;

		this._renderEffects = new Map<String,PostProcessRenderEffect>();
		this._renderEffectsForIsolatedPass = new Map<String,PostProcessRenderEffect>();

		this._cameras = new Map<String,Camera>();
	}
	
	public function addEffect(renderEffect: PostProcessRenderEffect): Void
	{
		this._renderEffects.set(renderEffect.name, renderEffect);
	}

	public function enableEffect(renderEffectName: String, cameras: Dynamic): Void
	{
		var renderEffects:PostProcessRenderEffect = this._renderEffects.get(renderEffectName);

		if (renderEffects == null) 
		{
			return;
		}

		renderEffects._enable(Tools.MakeArray(cameras != null ? cameras : this._cameras));
	}

	public function disableEffect(renderEffectName: String, cameras:Dynamic): Void
	{
		var renderEffects:PostProcessRenderEffect = this._renderEffects.get(renderEffectName);

		if (renderEffects == null)
		{
			return;
		}

		renderEffects._disable(Tools.MakeArray(cameras != null ? cameras : this._cameras));
	}

	public function attachCameras(cameras: Dynamic, unique: Bool): Void
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		var indicesToDelete = [];

		for (i in 0..._cam.length)
		{
			var camera:Camera = _cam[i];
			var cameraName = camera.name;
			
			if (!_cameras.exists(cameraName))
			{
				_cameras.set(cameraName, camera);
			}
			else if (unique)
			{
				indicesToDelete.push(i);
			}
		}

		for (i in 0...indicesToDelete.length)
		{
			cameras.splice(indicesToDelete[i], 1);
		}

		var renderEffect:PostProcessRenderEffect;
		for (renderEffect in _renderEffects)
		{
			renderEffect._attachCameras(_cam);
		}
	}

	public function detachCameras(cameras: Dynamic): Void
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		var keys = _renderEffects.keys();
		for (renderEffectName in keys)
		{
			this._renderEffects.get(renderEffectName)._detachCameras(_cam);
		}

		for (i in 0..._cam.length)
		{
			_cameras.remove(_cam[i].name);
		}
	}

	public function enableDisplayOnlyPass(passName, cameras: Dynamic): Void
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		var pass = null;

		for (renderEffect in _renderEffects)
		{
			pass = renderEffect.getPass(passName);

			if (pass != null)
			{
				break;
			}
		}

		if (pass == null) 
		{
			return;
		}
		
		var renderEffect:PostProcessRenderEffect;
		for (renderEffect in _renderEffects)
		{
			renderEffect._disable(_cam);
		}

		pass.name = PostProcessRenderPipeline.PASS_SAMPLER_NAME;

		for (i in 0..._cam.length) 
		{
			var camera = _cam[i];
			var cameraName = camera.name;
			
			var renderEffect:PostProcessRenderEffect = _renderEffectsForIsolatedPass.get(cameraName);
			if (renderEffect == null)
			{
				renderEffect = new PostProcessRenderEffect(_engine, PostProcessRenderPipeline.PASS_EFFECT_NAME, 
														function():PostProcess 
														{
															return new DisplayPassPostProcess(PostProcessRenderPipeline.PASS_EFFECT_NAME, 1.0, null, 1, this._engine, true);
														});
				_renderEffectsForIsolatedPass.set(cameraName, renderEffect);
			}

			renderEffect.emptyPasses();
			renderEffect.addPass(pass);
			renderEffect._attachCameras(camera);
		}
	}

	public function disableDisplayOnlyPass(cameras: Dynamic): Void
	{
		var _cam = Tools.MakeArray(cameras != null ? cameras : this._cameras);

		for (i in 0..._cam.length)
		{
			var camera:Camera = _cam[i];
			var cameraName = camera.name;

			var renderEffect:PostProcessRenderEffect = _renderEffectsForIsolatedPass.get(cameraName);
			if (renderEffect == null)
			{
				renderEffect = new PostProcessRenderEffect(_engine, PostProcessRenderPipeline.PASS_EFFECT_NAME, function():PostProcess 
														{
															return new DisplayPassPostProcess(PostProcessRenderPipeline.PASS_EFFECT_NAME, 1.0, null, 1, this._engine, true);
														});
				_renderEffectsForIsolatedPass.set(cameraName, renderEffect);
			}
			
			renderEffect._disable(camera);
		}

		var renderEffect:PostProcessRenderEffect;
		for (renderEffect in _renderEffects)
		{
			renderEffect._enable(_cam);
		}
	}

	public function update(): Void 
	{
		var renderEffect:PostProcessRenderEffect;
		for (renderEffect in _renderEffects)
		{
			renderEffect.update();
		}

		var keys = _cameras.keys();
		for (cameraName in keys)
		{
			if (this._renderEffectsForIsolatedPass.exists(cameraName))
			{
				this._renderEffectsForIsolatedPass.get(cameraName).update();
			}
		}
	}
}