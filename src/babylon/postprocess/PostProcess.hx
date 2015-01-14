package babylon.postprocess;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.textures.BabylonGLTexture;
import babylon.materials.textures.Texture;
import babylon.math.FastMath;
import babylon.Scene;

class PostProcess 
{
	public var name:String;
	
	public var onApply:Effect->Void;
	public var onBeforeRender:Effect->Void;
    public var onActivate:Camera->Void;
    public var onSizeChanged:Void->Void;
	
	public var width:Int = -1;
	public var height:Int = -1;
	public var renderTargetSamplingMode:Int;
	
	private var _camera:Camera;
	private var _scene:Scene;
	private var _engine:Engine;
	private var _renderRatio:Float;
	private var _reusable:Bool = false;
	private var _effect:Effect;
	public var textures:Array<BabylonGLTexture>;
	public var _currentRenderTextureId:Int = 0;
	
	public var samplers:Array<String>;
	
	public function new(name:String, 
						fragmentUrl:String, 
						parameters:Array<String> = null, 
						samplers:Array<String> = null, 
						ratio:Float = 1.0, 
						camera:Camera = null, 
						samplingMode:Int = Texture.NEAREST_SAMPLINGMODE, 
						engine:Engine = null,
						reusable:Bool = false) 
	{
		this.name = name;
		
		if (camera != null)
		{
			this._camera = camera;
			this._scene = camera.getScene();
			camera.attachPostProcess(this);
			_engine = _scene.getEngine();
		}
		else
		{
			this._engine = engine;
		}
		
        this._renderRatio = ratio;
        this.renderTargetSamplingMode = samplingMode;
		this._reusable = reusable;
		
		this.textures = [];
		this._currentRenderTextureId = 0;

        this.samplers = samplers == null ? [] : samplers;
        this.samplers.push("textureSampler");
		
		if (parameters == null)
			parameters = [];

        this._effect = _engine.createEffect({ vertex: "postprocess", fragment: fragmentUrl },
											["position"], parameters, this.samplers, "");
	}
	
	public function isReusable():Bool
	{
		return _reusable;
	}
	
	public function activate(camera:Camera, sourceTexture:BabylonGLTexture = null):Void
	{
		if (camera == null)
			camera = this._camera;

		var scene:Scene = camera.getScene();
		var maxSize:Int = camera.getEngine().getCaps().maxTextureSize;
		
        var desiredWidth:Int = Std.int((sourceTexture != null ? sourceTexture._width : scene.getStageWidth()) * this._renderRatio);
        var desiredHeight:Int = Std.int((sourceTexture != null ? sourceTexture._height : scene.getStageHeight()) * this._renderRatio);
		
		desiredWidth = FastMath.getExponantOfTwo(desiredWidth, maxSize);
		desiredHeight = FastMath.getExponantOfTwo(desiredHeight, maxSize);
		
        if (this.width != desiredWidth || this.height != desiredHeight)
		{
            if (textures.length > 0)
			{
                for (i in 0...textures.length)
				{
                    _engine.releaseTexture(textures[i]);
                }
                textures = [];
            }
			
            this.width = desiredWidth;
            this.height = desiredHeight;
			
			var needDepthBuffer:Bool = camera._postProcesses.indexOf(this) == camera._postProcessesTakenIndices[0];
			
            this.textures.push(_engine.createRenderTargetTexture( this.width, this.height, 
								{ generateMipMaps: false, 
								  generateDepthBuffer: needDepthBuffer, 
								  samplingMode: this.renderTargetSamplingMode } ));
			
			if (this._reusable) 
			{
                this.textures.push(_engine.createRenderTargetTexture(this.width, this.height, 
									{ generateMipMaps: false, 
									  generateDepthBuffer: needDepthBuffer, 								
									  samplingMode: this.renderTargetSamplingMode }));
            }
			
            if (this.onSizeChanged != null) 
			{
                this.onSizeChanged();
            }
        }
		
        this._engine.bindFramebuffer(this.textures[this._currentRenderTextureId]);
        
		if (this.onActivate != null)
		{
			this.onActivate(camera);
		}
		
        // Clear
        this._engine.clear(scene.clearColor, scene.autoClear || scene.forceWireframe, true);
		
		if (this._reusable)
		{
            this._currentRenderTextureId = (this._currentRenderTextureId + 1) % 2;
        }
    }
	
	public function apply():Effect 
	{
        // Check
        if (!_effect.isReady())
            return null;

        // States
        _engine.enableEffect(_effect);
        _engine.setCullState(false);
        _engine.setAlphaMode(Engine.ALPHA_DISABLE);
        _engine.setDepthTest(false);
        _engine.setDepthWrite(false);

        // Texture
        _effect.bindTexture("textureSampler", textures[_currentRenderTextureId]);
        
        // Parameters
        if (onApply != null) 
		{
            onApply(_effect);
        }

        return _effect;
    }
	
	public function dispose(camera:Camera = null):Void
	{
		camera = camera == null ? this._camera : camera;
		
		if (textures.length > 0)
		{
            for (i in 0...this.textures.length)
			{
                _engine.releaseTexture(textures[i]);
            }
            textures = [];
        }
		
		camera.detachPostProcess(this);

        var index = camera._postProcesses.indexOf(this);
        if (camera._postProcessesTakenIndices.length > 0 && index == camera._postProcessesTakenIndices[0]) 
		{
			// invalidate frameBuffer to hint the postprocess to create a depth buffer
            _camera._postProcesses[camera._postProcessesTakenIndices[0]].width = -1; 
        }
    }
	
}
