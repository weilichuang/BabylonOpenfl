package babylon.lights.shadows;

import babylon.Engine;
import babylon.lights.DirectionalLight;
import babylon.lights.IShadowLight;
import babylon.materials.Effect;
import babylon.materials.Material;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.materials.textures.Texture;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.mesh.InstancedMesh;
import babylon.mesh.InstancesBatch;
import babylon.mesh.Mesh;
import babylon.mesh.SubMesh;
import babylon.mesh.VertexBuffer;
import babylon.Scene;

class ShadowGenerator
{
	public static inline var FILTER_NONE:Int = 0;
	public static inline var FILTER_VARIANCESHADOWMAP:Int = 1;
	public static inline var FILTER_POISSONSAMPLING:Int = 2;
		
	public var useVarianceShadowMap(get,set):Bool;
	public var usePoissonSampling(get, set):Bool;
	
	public var filter:Int = ShadowGenerator.FILTER_VARIANCESHADOWMAP;
	
	private var _light:IShadowLight;
	private var _scene:Scene;
	
	private var _shadowMap:RenderTargetTexture;
	
	private var _darkness:Float = 0;
	private var _transparencyShadow:Bool = false;
	private var _effect:Effect;
	
	private var _viewMatrix:Matrix;
	private var _projectionMatrix:Matrix;
	private var _transformMatrix:Matrix;
	private var _worldViewProjection:Matrix;
	
	private var _cachedDefines:String;
	private var _cachedPosition:Vector3;
	private var _cachedDirection:Vector3;
	private var _targetPosition:Vector3;
	
	public function new(mapSize:Int, light:IShadowLight)
	{
		this._light = light;
        this._scene = light.getScene();

        light.shadowGenerator = this;
		
		// Internals
        this._viewMatrix = Matrix.Zero();
        this._projectionMatrix = Matrix.Zero();
        this._transformMatrix = Matrix.Zero();
        this._worldViewProjection = Matrix.Zero();
		
		this._cachedPosition = new Vector3();
		this._cachedDirection = new Vector3();
		this._targetPosition = new Vector3();
		
        // Render target
        this._shadowMap = new RenderTargetTexture(light.name + "_shadowMap", mapSize, this._scene, false);
        this._shadowMap.wrapU = Texture.CLAMP_ADDRESSMODE;
        this._shadowMap.wrapV = Texture.CLAMP_ADDRESSMODE;
        this._shadowMap.renderParticles = false;
                
        this._shadowMap.customRenderFunction = function(opaqueSubMeshes:Array<SubMesh>, 
														alphaTestSubMeshes:Array<SubMesh>,
														transparentSubMeshes: Array<SubMesh>):Void
		{
            for (index in 0...opaqueSubMeshes.length) 
			{
                renderSubMesh(opaqueSubMeshes[index]);
            }
            
            for (index in 0...alphaTestSubMeshes.length)
			{
                renderSubMesh(alphaTestSubMeshes[index]);
            }
			
			if (this._transparencyShadow) 
			{
				for (index in 0...transparentSubMeshes.length)
				{
					renderSubMesh(transparentSubMeshes[index]);
				}
			}
        };
	}
	
	private function get_useVarianceShadowMap():Bool
	{
		return filter == FILTER_VARIANCESHADOWMAP;
	}
	
	private function set_useVarianceShadowMap(value:Bool):Bool
	{
		if (value == true)
			filter = FILTER_VARIANCESHADOWMAP;
		else 
			filter = FILTER_NONE;
		return value;
	}
	
	private function get_usePoissonSampling():Bool
	{
		return filter == FILTER_POISSONSAMPLING;
	}
	
	private function set_usePoissonSampling(value:Bool):Bool
	{
		if (value == true)
			filter = FILTER_POISSONSAMPLING;
		else 
			filter = FILTER_NONE;
		return value;
	}
	
	public function renderSubMesh(subMesh:SubMesh):Void
	{
		var mesh:Mesh = subMesh.getRenderingMesh();
		
		var world:Matrix = mesh.getWorldMatrix();
		
		var engine:Engine = _scene.getEngine();
		
		var material:Material = subMesh.getMaterial();
		
		//Culling
		engine.setCullState(material.backFaceCulling);
		
		// Managing instances
		var batch:InstancesBatch = mesh._getInstancesRenderList(subMesh._id);
		if (batch.mustReturn)
		{
			return;
		}
		
		var hardwareInstancedRendering:Bool = engine.getCaps().instancedArrays != null && 
											(batch.visibleInstances[subMesh._id] != null);
		
		if (this.isReady(subMesh, hardwareInstancedRendering))
		{
			engine.enableEffect(_effect);
			
			mesh._bind(subMesh, _effect, Material.TriangleFillMode);
			
			_effect.setMatrix("viewProjection", this.getTransformMatrix());
			
			// Alpha test
			if (material != null && material.needAlphaTesting())
			{
				var alphaTeture:BaseTexture = material.getAlphaTestTexture();
				_effect.setTexture("diffuseSampler", alphaTeture);
				_effect.setMatrix("diffuseMatrix", alphaTeture.getTextureMatrix());
			}
			
			// Bones
			var useBones:Bool = _scene.skeletonsEnabled && mesh.isSkeletonsEnabled();
			if (useBones)
			{
				_effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices());
			}
			
			if (hardwareInstancedRendering)
			{
				#if html5
				mesh._renderWithInstances(subMesh, Material.TriangleFillMode, batch, _effect, engine);
				#end
			}
			else
			{
				if (batch.renderSelf[subMesh._id]) 
				{
					_effect.setMatrix("world", mesh.getWorldMatrix());

					// Draw
					mesh._draw(subMesh, Material.TriangleFillMode);
				}

				var instances:Array<InstancedMesh> = batch.visibleInstances[subMesh._id];
				if (instances != null)
				{
					for (instanceIndex in 0...instances.length)
					{
						var instance:InstancedMesh = instances[instanceIndex];

						_effect.setMatrix("world", instance.getWorldMatrix());

						// Draw
						mesh._draw(subMesh, Material.TriangleFillMode);
					}
				}
			}
		}
		else
		{
			// Need to reset refresh rate of the shadowMap
			_shadowMap.resetRefreshCounter();
		}
	}
	
	public function isReady(subMesh:SubMesh, useInstances:Bool):Bool
	{
        var defines:Array<String> = [];
        
        if (this.useVarianceShadowMap)
		{
            defines.push("#define VSM");
        }
        
        var attribs:Array<String> = [VertexBuffer.PositionKind];
		
		var mesh = subMesh.getMesh();
		var scene = mesh.getScene();
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
        if (_cachedDefines != join)
		{
            _cachedDefines = join;
            _effect = _scene.getEngine().createEffect("shadowMap",
                attribs,
                ["world", "mBones", "viewProjection", "diffuseMatrix"],
                ["diffuseSampler"], join);
        }

        return _effect.isReady();
    }
	
	public function getShadowMap():RenderTargetTexture 
	{
        return this._shadowMap;
    }
	
	public function getLight():IShadowLight
	{
        return this._light;
    }
	
	private static var UP:Vector3 = new Vector3(0, 1, 0);
	public function getTransformMatrix():Matrix
	{
        var lightPosition:Vector3 = _light.position;
        var lightDirection:Vector3 = _light.direction;
        
        if (_light.computeTransformedPosition()) 
		{
            lightPosition = _light.transformedPosition;
        }

        if (!lightPosition.equals(this._cachedPosition) || 
			!lightDirection.equals(this._cachedDirection))
		{
            this._cachedPosition.copyFrom(lightPosition);
            this._cachedDirection.copyFrom(lightDirection);

            var activeCamera = this._scene.activeCamera;
			
			_targetPosition = _light.position.addToRef(lightDirection, _targetPosition);

            Matrix.LookAtLHToRef(lightPosition, _targetPosition, UP, this._viewMatrix);
            Matrix.PerspectiveFovLHToRef(Math.PI / 2.0, 1.0, activeCamera.minZ, activeCamera.maxZ, this._projectionMatrix);

            this._viewMatrix.multiplyToRef(this._projectionMatrix, this._transformMatrix);
        }

        return this._transformMatrix;
    }
	
	public function getDarkness(): Float
	{
		return this._darkness;
	}

	public function setDarkness(darkness: Float): Void 
	{
		this._darkness = FastMath.clamp(darkness, 0, 1);
	}

	public function setTransparencyShadow(value: Bool): Void 
	{
		this._transparencyShadow = value;
	}
	
	public function dispose():Void
	{
		if (_shadowMap != null)
		{
			this._shadowMap.dispose();
			this._shadowMap = null;
		}
		
		_light = null;
		_scene = null;
		_effect = null;
    }
	
}
