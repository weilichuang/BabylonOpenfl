package babylon.rendering;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.Material;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.materials.textures.Texture;
import babylon.math.Matrix;
import babylon.mesh.AbstractMesh;
import babylon.mesh.InstancedMesh;
import babylon.mesh.InstancesBatch;
import babylon.mesh.Mesh;
import babylon.mesh.SubMesh;
import babylon.mesh.VertexBuffer;
import babylon.Scene;
import babylon.tools.SmartArray;

/**
 * ...
 * @author weilichuang
 */
class DepthRenderer
{
	private var _scene: Scene;
	private var _depthMap: RenderTargetTexture;
	private var _effect: Effect;

	private var _viewMatrix = Matrix.Zero();
	private var _projectionMatrix = Matrix.Zero();
	private var _transformMatrix = Matrix.Zero();
	private var _worldViewProjection = Matrix.Zero();

	private var _cachedDefines: String;

	public function new(scene: Scene, type:Int = Engine.TEXTURETYPE_FLOAT) 
	{
		this._scene = scene;
		var engine = scene.getEngine();

		// Render target
		this._depthMap = new RenderTargetTexture("depthMap", engine.getRenderWidth(), engine.getRenderHeight(), this._scene, false, true, type);
		this._depthMap.wrapU = Texture.CLAMP_ADDRESSMODE;
		this._depthMap.wrapV = Texture.CLAMP_ADDRESSMODE;
		this._depthMap.refreshRate = 1;
		this._depthMap.renderParticles = false;
		this._depthMap.renderList = null;

		// Custom render function
		function renderSubMesh(subMesh: SubMesh): Void
		{
			var mesh:Mesh = subMesh.getRenderingMesh();
			var scene:Scene = this._scene;
			var engine:Engine = scene.getEngine();
			
			var material:Material = subMesh.getMaterial();

			// Culling
			engine.setCullState(material.backFaceCulling);

			// Managing instances
			var batch:InstancesBatch = mesh._getInstancesRenderList(subMesh._id);

			if (batch.mustReturn)
			{
				return;
			}

			var hardwareInstancedRendering:Bool = (engine.getCaps().instancedArrays != null) && (batch.visibleInstances[subMesh._id] != null);

			if (this.isReady(subMesh, hardwareInstancedRendering))
			{
				engine.enableEffect(this._effect);
				mesh._bind(subMesh, this._effect, Material.TriangleFillMode);
				
				this._effect.setMatrix("viewProjection", scene.getTransformMatrix());

				this._effect.setFloat("far", scene.activeCamera.maxZ);

				// Alpha test
				if (material != null && material.needAlphaTesting()) 
				{
					var alphaTexture:BaseTexture = material.getAlphaTestTexture();
					this._effect.setTexture("diffuseSampler", alphaTexture);
					this._effect.setMatrix("diffuseMatrix", alphaTexture.getTextureMatrix());
				}

				// Bones
				var useBones:Bool = scene.skeletonsEnabled && mesh.isSkeletonsEnabled();
				if (useBones)
				{
					this._effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices());
				}

				if (hardwareInstancedRendering)
				{
					#if html5
					mesh._renderWithInstances(subMesh, Material.TriangleFillMode, batch, this._effect, engine);
					#end
				} 
				else 
				{
					if (batch.renderSelf[subMesh._id])
					{
						this._effect.setMatrix("world", mesh.getWorldMatrix());

						// Draw
						mesh._draw(subMesh, Material.TriangleFillMode);
					}

					if (batch.visibleInstances[subMesh._id] != null)
					{
						for (instanceIndex in 0...batch.visibleInstances[subMesh._id].length)
						{
							var instance:InstancedMesh = batch.visibleInstances[subMesh._id][instanceIndex];

							this._effect.setMatrix("world", instance.getWorldMatrix());

							// Draw
							mesh._draw(subMesh, Material.TriangleFillMode);
						}
					}
				}
			}
		}

		this._depthMap.customRenderFunction = function(opaqueSubMeshes: Array<SubMesh>, alphaTestSubMeshes: Array<SubMesh>, transparentSubMeshes: Array<SubMesh>): Void 
		{
			for (index in 0...opaqueSubMeshes.length)
			{
				renderSubMesh(opaqueSubMeshes[index]);
			}

			for (index in 0...alphaTestSubMeshes.length)
			{
				renderSubMesh(alphaTestSubMeshes[index]);
			}
		}
	}

	public function isReady(subMesh: SubMesh, useInstances: Bool): Bool
	{
		var defines:Array<String> = [];

		var attribs:Array<String> = [VertexBuffer.PositionKind];

		var mesh:AbstractMesh = subMesh.getMesh();
		var scene:Scene = mesh.getScene();
		var material:Material = subMesh.getMaterial();

		// Alpha test
		if (material != null && material.needAlphaTesting())
		{
			defines.push("#define ALPHATEST");
			
			if (mesh.isVerticesDataPresent(VertexBuffer.UVKind)) 
			{
				attribs.push(VertexBuffer.UVKind);
				defines.push("#define UV1");
			}
			if (mesh.isVerticesDataPresent(VertexBuffer.UV2Kind))
			{
				attribs.push(VertexBuffer.UV2Kind);
				defines.push("#define UV2");
			}
		}

		// Bones
		if (scene.skeletonsEnabled && mesh.isSkeletonsEnabled())
		{
			attribs.push(VertexBuffer.MatricesIndicesKind);
			attribs.push(VertexBuffer.MatricesWeightsKind);
			defines.push("#define BONES");
			defines.push("#define BonesPerMesh " + (mesh.skeleton.bones.length + 1));
		}

		// Instances
		if (useInstances) 
		{
			defines.push("#define INSTANCES");
			attribs.push("world0");
			attribs.push("world1");
			attribs.push("world2");
			attribs.push("world3");
		}

		// Get correct effect      
		var join:String = defines.join("\n");
		if (this._cachedDefines != join) 
		{
			this._cachedDefines = join;
			this._effect = this._scene.getEngine().createEffect("depth",
				attribs,
				["world", "mBones", "viewProjection", "diffuseMatrix", "far"],
				["diffuseSampler"], join);
		}

		return this._effect.isReady();
	}

	public function getDepthMap(): RenderTargetTexture
	{
		return this._depthMap;
	}

	// Methods
	public function dispose(): Void 
	{
		this._depthMap.dispose();
	}
	
}