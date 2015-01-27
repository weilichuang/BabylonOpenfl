package babylon.postprocess.renderpipeline;
import babylon.materials.textures.RenderTargetTexture;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;

class PostProcessRenderPass
{
	private var _enabled: Bool = true;
	private var _renderList: Array<AbstractMesh>;
	private var _renderTexture: RenderTargetTexture;
	private var _scene: Scene;
	private var _refCount: Int = 0;

	public var name: String;

	public function new(scene: Scene, name: String, size: Int, 
						renderList: Array<AbstractMesh>, 
						beforeRender: Void->Void, 
						afterRender: Void->Void) 
	{
		this.name = name;

		this._renderTexture = new RenderTargetTexture(name, size, size, scene);
		this.setRenderList(renderList);
		this._renderList = renderList;

		this._renderTexture.onBeforeRender = beforeRender;
		this._renderTexture.onAfterRender = afterRender;

		this._scene = scene;
	}

	// private

	public function _incRefCount(): Int
	{
		if (this._refCount == 0)
		{
			this._scene.customRenderTargets.push(this._renderTexture);
		}

		return ++this._refCount;
	}

	public function _decRefCount(): Int
	{
		this._refCount--;

		if (this._refCount <= 0)
		{
			this._scene.customRenderTargets.splice(this._scene.customRenderTargets.indexOf(this._renderTexture), 1);
		}

		return this._refCount;
	}

	public function update(): Void
	{
		this.setRenderList(this._renderList);
	}

	// public

	public function setRenderList(renderList: Array<AbstractMesh>): Void 
	{
		this._renderTexture.renderList = renderList;
	}

	public function getRenderTexture(): RenderTargetTexture
	{
		return this._renderTexture;
	}
}