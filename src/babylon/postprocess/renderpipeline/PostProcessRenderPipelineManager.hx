package babylon.postprocess.renderpipeline;

class PostProcessRenderPipelineManager
{
	private var _renderPipelines: Map<String,PostProcessRenderPipeline>;

	public function new() 
	{
		_renderPipelines = new Map<String,PostProcessRenderPipeline>();
	}
	
	public function addPipeline(renderPipeline: PostProcessRenderPipeline): Void 
	{
		this._renderPipelines.set(renderPipeline.name, renderPipeline);
	}
	
	public function attachCamerasToRenderPipeline(renderPipelineName:String, cameras:Dynamic, unique:Bool = false):Void
	{
		var renderPipeline = this._renderPipelines.get(renderPipelineName);

		if (renderPipeline == null)
		{
			return;
		}

		renderPipeline.attachCameras(cameras, unique);
	}
	
	public function detachCamerasFromRenderPipeline(renderPipelineName: String, cameras: Dynamic): Void 
	{
		var renderPipeline = this._renderPipelines.get(renderPipelineName);

		if (renderPipeline == null)
		{
			return;
		}

		renderPipeline.detachCameras(cameras);
	}
	
	public function enableEffectInPipeline(renderPipelineName: String, renderEffectName: String, cameras: Dynamic): Void
	{
		var renderPipeline = this._renderPipelines.get(renderPipelineName);

		if (renderPipeline == null)
		{
			return;
		}

		renderPipeline.enableEffect(renderEffectName, cameras);
	}
	
	public function disableEffectInPipeline(renderPipelineName: String, renderEffectName: String, cameras: Dynamic): Void
	{
		var renderPipeline:PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

		if (renderPipeline == null)
		{
			return;
		}

		renderPipeline.disableEffect(renderEffectName, cameras);
	}
	
	public function disableDisplayOnlyPassInPipeline(renderPipelineName: String, cameras: Dynamic): Void 
	{
		var renderPipeline:PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

		if (renderPipeline == null)
		{
			return;
		}

		renderPipeline.disableDisplayOnlyPass(cameras);
	}
	
	public function update():Void
	{
		for (renderPipeline in _renderPipelines)
		{
			renderPipeline.update();
		}
	}
	
}