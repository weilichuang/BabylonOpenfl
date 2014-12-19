package babylon.materials.textures;

import babylon.cameras.Camera;
import babylon.Engine;
import babylon.mesh.AbstractMesh;
import babylon.mesh.SubMesh;
import babylon.rendering.RenderingManager;
import babylon.Scene;
import babylon.mesh.Mesh;
import babylon.tools.SmartArray;

class RenderTargetTexture extends Texture
{
	public var renderList:Array<AbstractMesh>;
	public var renderParticles:Bool = true;
    public var renderSprites:Bool = false;

	public var onBeforeRender:Void->Void;
    public var onAfterRender:Void->Void;
	
	public var customRenderFunction:Dynamic;
	
	private var _size:Int;
	
	public var _generateMipMaps:Bool;
	
	private var _renderingManager:RenderingManager;
	
	public var _waitingRenderList:Array<String>;
	
	private var _doNotChangeAspectRatio: Bool;
	private var _currentRefreshId:Int = -1;
	private var _refreshRate:Int = 1;
	
	public var activeCamera:Camera;

	public function new(name:String, size:Int, 
						scene:Scene, generateMipMaps:Bool = false,
						doNotChangeAspectRatio:Bool = true)
	{			
		super(null, scene, !generateMipMaps);
		
		this.name = name;
		this._size = size;
        this._generateMipMaps = generateMipMaps;
		this._doNotChangeAspectRatio = doNotChangeAspectRatio;

		this.isRenderTarget = true;
		this.coordinatesMode = Texture.PROJECTION_MODE;
		// Render list
        this.renderList = [];
        // Rendering groups
        this._renderingManager = new RenderingManager(scene);
		
        this._texture = scene.getEngine().createRenderTargetTexture(size, size, generateMipMaps);
	}
	
	public function resetRefreshCounter():Void
	{
		_currentRefreshId = -1;
	}
	
	public var refreshRate(get, set):Int;
	private function get_refreshRate():Int
	{
		return _refreshRate;
	}
	
	/**
	 * Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
	 * @param	value
	 * @return
	 */
	private function set_refreshRate(value:Int):Int
	{
		_refreshRate = value;
		resetRefreshCounter();
		return _refreshRate;
	}
	
	public function _shouldRender(): Bool
	{
		// At least render once
		if (this._currentRefreshId == -1) 
		{ 
			this._currentRefreshId = 1;
			return true;
		}

		if (this.refreshRate == this._currentRefreshId) 
		{
			this._currentRefreshId = 1;
			return true;
		}

		this._currentRefreshId++;
		return false;
	}
	
	public function getRenderSize(): Int
	{
		return this._size;
	}
	
	public function resize(size:Int, generateMipMaps:Bool):Void
	{
        this.releaseInternalTexture();
        this._texture = getScene().getEngine().createRenderTargetTexture(size, size, generateMipMaps);
    }
	
	public function render(useCameraPostProcess:Bool = false):Void
	{
        var scene:Scene = this.getScene();
        var engine:Engine = scene.getEngine();
		
		var mesh:AbstractMesh;
        if (_waitingRenderList != null)
		{
            this.renderList = [];
            for (index in 0..._waitingRenderList.length) 
			{
                var id:String = _waitingRenderList[index];
				mesh = scene.getMeshByID(id);
				if(mesh != null)
					this.renderList.push(mesh);
            }

            _waitingRenderList = null;
        }
		
		var i:Int = 0;
		while (i < renderList.length)
		{
			mesh = renderList[i];
			if (mesh.isDisposed())
			{
				renderList.splice(i, 1);
				i--;
			}
			i++;
		}

        if (renderList.length == 0)
		{
            return;
        }
		
		// Bind
		if (!useCameraPostProcess || !scene.postProcessManager._prepareFrame(_texture))
		{
			engine.bindFramebuffer(_texture);
		}
		
		// Clear
		engine.clear(scene.clearColor, true, true);

		_renderingManager.reset();

		for (meshIndex in 0...renderList.length)
		{
			mesh = this.renderList[meshIndex];

			if (mesh != null)
			{
				if (!mesh.isReady() || (mesh.material != null && !mesh.material.isReady()))
				{
					// Reset _currentRefreshId
					resetRefreshCounter();
					continue;
				}

				if (mesh.isEnabled() && 
					mesh.isVisible && 
					mesh.subMeshes != null && 
					((mesh.layerMask & scene.activeCamera.layerMask) != 0)) 
				{
					mesh.activate(scene.getRenderId());

					for (subIndex in 0...mesh.subMeshes.length)
					{
						var subMesh = mesh.subMeshes[subIndex];
						scene.statistics.activeVertices += subMesh.indexCount;
						_renderingManager.dispatch(subMesh);
					}
				}
			}
		}
		
		if (!_doNotChangeAspectRatio)
		{
			scene.updateTransformMatrix(true);
		}
		
		if (onBeforeRender != null)
		{
			onBeforeRender();
		}

		// Render
		_renderingManager.render(customRenderFunction, renderList, renderParticles, renderSprites);

		if (useCameraPostProcess)
		{
			scene.postProcessManager._finalizeFrame(false, this._texture);
		}

		if (onAfterRender != null) 
		{
			onAfterRender();
		}
			
		// Unbind
		engine.unBindFramebuffer(this._texture);
		
		if (!_doNotChangeAspectRatio)
		{
			scene.updateTransformMatrix(true);
		}
    }
	
	override public function clone():BaseTexture 
	{
        var textureSize = this.getSize();
        var newTexture:RenderTargetTexture = new RenderTargetTexture(this.name, Std.int(textureSize.width), getScene(), this._generateMipMaps);

        // Base texture
        newTexture.hasAlpha = this.hasAlpha;
        newTexture.level = this.level;

        // RenderTarget Texture
        newTexture.coordinatesMode = this.coordinatesMode;
        newTexture.renderList = this.renderList.copy();

        return newTexture;
    }
	
}
