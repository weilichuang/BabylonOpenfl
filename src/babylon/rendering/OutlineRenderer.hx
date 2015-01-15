package babylon.rendering;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.Material;
import babylon.materials.textures.BaseTexture;
import babylon.mesh.InstancedMesh;
import babylon.mesh.InstancesBatch;
import babylon.mesh.Mesh;
import babylon.mesh.SubMesh;
import babylon.mesh.VertexBuffer;
import babylon.Scene;

class OutlineRenderer
{
	private var _scene: Scene;
	private var _effect: Effect;
	private var _cachedDefines: String;

	public function new(scene:Scene) 
	{
		this._scene = scene;
	}
	
	public function render(subMesh:SubMesh, batch:InstancesBatch, useOverlay: Bool = false):Void
	{
		var engine:Engine = _scene.getEngine();
		
		var hardwareInstancedRendering:Bool = engine.getCaps().instancedArrays != null && 
											(batch.visibleInstances[subMesh._id] != null); 
											
		if (!this.isReady(subMesh, hardwareInstancedRendering))
		{
			return;
		}
		
		var mesh:Mesh = subMesh.getRenderingMesh();
		var material:Material = subMesh.getMaterial();
		
		engine.enableEffect(this._effect);
		this._effect.setFloat("offset", useOverlay ? 0 : mesh.outlineWidth);
		this._effect.setColor4("color", useOverlay ? mesh.overlayColor : mesh.outlineColor, useOverlay ? mesh.overlayAlpha : 1.0);
		this._effect.setMatrix("viewProjection", _scene.getTransformMatrix());

		// Bones
		var useBones:Bool = _scene.skeletonsEnabled && mesh.isSkeletonsEnabled();
		if (useBones)
		{
			this._effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices());
		}

		mesh._bind(subMesh, this._effect, Material.TriangleFillMode);

		// Alpha test
		if (material != null && material.needAlphaTesting())
		{
			var alphaTexture:BaseTexture = material.getAlphaTestTexture();
			this._effect.setTexture("diffuseSampler", alphaTexture);
			this._effect.setMatrix("diffuseMatrix", alphaTexture.getTextureMatrix());
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

			var instances:Array<InstancedMesh> = batch.visibleInstances[subMesh._id];
			if (instances != null)
			{
				for (instanceIndex in 0...instances.length)
				{
					var instance:InstancedMesh = instances[instanceIndex];

					this._effect.setMatrix("world", instance.getWorldMatrix());

					// Draw
					mesh._draw(subMesh, Material.TriangleFillMode);
				}
			}
		}
	}
	
	public function isReady(subMesh: SubMesh, useInstances: Bool): Bool
	{
		var defines = [];
		var attribs = [VertexBuffer.PositionKind, VertexBuffer.NormalKind];

		var mesh = subMesh.getMesh();
		var material = subMesh.getMaterial();

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
		if (_scene.skeletonsEnabled && mesh.isSkeletonsEnabled()) 
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
		var join = defines.join("\n");
		if (this._cachedDefines != join)
		{
			this._cachedDefines = join;
			_effect = _scene.getEngine().createEffect("outline",
				attribs,
				["world", "mBones", "viewProjection", "diffuseMatrix", "offset", "color"],
				["diffuseSampler"], join);
		}

		return _effect.isReady();
	}
	
}