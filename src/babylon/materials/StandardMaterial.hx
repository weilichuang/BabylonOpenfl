package babylon.materials;

import babylon.Engine;
import babylon.lights.DirectionalLight;
import babylon.lights.HemisphericLight;
import babylon.lights.Light;
import babylon.lights.PointLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.lights.SpotLight;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.math.Color3;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.VertexBuffer;
import babylon.Scene;

using StringTools;

class StandardMaterial extends Material
{
	public static var maxSimultaneousLights:Int = 4;

	// Flags used to enable or disable a type of texture for all Standard Materials
	public static var DiffuseTextureEnabled:Bool = true;
	public static var AmbientTextureEnabled:Bool = true;
	public static var OpacityTextureEnabled:Bool = true;
	public static var ReflectionTextureEnabled:Bool = true;
	public static var EmissiveTextureEnabled:Bool = true;
	public static var SpecularTextureEnabled:Bool = true;
	public static var BumpTextureEnabled:Bool = true;
	public static var FresnelEnabled:Bool = true;
	
	public var diffuseTexture:BaseTexture = null;
	public var ambientTexture:BaseTexture = null;
	public var opacityTexture:BaseTexture = null;
	public var reflectionTexture:BaseTexture = null;
	public var emissiveTexture:BaseTexture = null;
	public var specularTexture:BaseTexture = null;
	public var bumpTexture:BaseTexture = null;

	public var ambientColor:Color3;
	public var diffuseColor:Color3;
	public var specularColor:Color3;
	public var specularPower:Float;
	public var emissiveColor:Color3;
	public var useAlphaFromDiffuseTexture:Bool = false;
	public var useSpecularOverAlpha:Bool = true;
	public var fogEnabled:Bool = true;
	
	public var diffuseFresnelParameters: FresnelParameters;
	public var opacityFresnelParameters: FresnelParameters;
	public var reflectionFresnelParameters: FresnelParameters;
	public var emissiveFresnelParameters: FresnelParameters;
	
	private var _cachedDefines:String;					
	private var _renderTargets:Array<RenderTargetTexture>;
	private var _worldViewProjectionMatrix:Matrix;
	private var _globalAmbientColor:Color3;
	private var _scaledDiffuse:Color3;
	private var _scaledSpecular:Color3;

	public function new(name:String, scene:Scene)
	{
		super(name, scene);
		
        this.ambientColor = new Color3(0, 0, 0);
        this.diffuseColor = new Color3(1, 1, 1);
        this.specularColor = new Color3(1, 1, 1);
        this.specularPower = 64;
        this.emissiveColor = new Color3(0, 0, 0);

        this._cachedDefines = null;
        this._renderTargets = new Array<RenderTargetTexture>();

        this._worldViewProjectionMatrix = new Matrix();
        this._globalAmbientColor = new Color3();
        this._scaledDiffuse = new Color3();
        this._scaledSpecular = new Color3();
	}
	
	override public function needAlphaBlending():Bool
	{
        return (this.alpha < 1.0) || 
				(this.opacityTexture != null) || 
				this._shouldUseAlphaFromDiffuseTexture() || 
				(this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled);
	}
	
	override public function needAlphaTesting():Bool
	{
        return this.diffuseTexture != null && this.diffuseTexture.hasAlpha && !diffuseTexture.getAlphaFromRGB;
    }
	
	private function _shouldUseAlphaFromDiffuseTexture(): Bool 
	{
		return this.diffuseTexture != null && this.diffuseTexture.hasAlpha && this.useAlphaFromDiffuseTexture;
	}
	
	override public function getAlphaTestTexture(): BaseTexture 
	{
		return this.diffuseTexture;
	}
	
	override public function isReady(mesh:AbstractMesh = null, useInstances:Bool = false):Bool
	{
        if (checkReadyOnlyOnce && _wasPreviouslyReady)
		{
			return true;
        }

        if (!checkReadyOnEveryCall && _renderId == _scene.getRenderId())
		{
			return true;
        }       

        var engine:Engine = this._scene.getEngine();
        var defines:Array<String> = [];
        var fallbacks:EffectFallbacks = new EffectFallbacks();

        // Textures
        if (_scene.texturesEnabled)
		{
            if (this.diffuseTexture != null && StandardMaterial.DiffuseTextureEnabled)
			{
                if (!this.diffuseTexture.isReady())
				{
                    return false;
                } 
				else 
				{
                    defines.push("#define DIFFUSE");
                }
            }

            if (this.ambientTexture != null && StandardMaterial.AmbientTextureEnabled)
			{
                if (!this.ambientTexture.isReady())
				{
                    return false;
                } 
				else
				{
                    defines.push("#define AMBIENT");
                }
            }

            if (this.opacityTexture != null && StandardMaterial.OpacityTextureEnabled)
			{
                if (!this.opacityTexture.isReady())
				{
                    return false;
                } 
				else
				{
                    defines.push("#define OPACITY");
					
					if (this.opacityTexture.getAlphaFromRGB)
					{
						defines.push("#define OPACITYRGB");
					}
                }
            }

            if (this.reflectionTexture != null && StandardMaterial.ReflectionTextureEnabled)
			{
                if (!this.reflectionTexture.isReady())
				{
                    return false;
                } 
				else
				{
                    defines.push("#define REFLECTION");
					fallbacks.addFallback(0, "REFLECTION");
                }
            }

            if (this.emissiveTexture != null && StandardMaterial.EmissiveTextureEnabled)
			{
                if (!this.emissiveTexture.isReady())
				{
                    return false;
                } 
				else
				{
                    defines.push("#define EMISSIVE");
                }
            }

            if (this.specularTexture != null && StandardMaterial.SpecularTextureEnabled) 
			{
                if (!this.specularTexture.isReady()) 
				{
                    return false;
                }
				else
				{
                    defines.push("#define SPECULAR");
                    fallbacks.addFallback(0, "SPECULAR");
                }
            }
        }

        if (engine.getCaps().standardDerivatives && this.bumpTexture != null && StandardMaterial.BumpTextureEnabled)
		{
            if (!this.bumpTexture.isReady())
			{
                return false;
            } 
			else
			{
                defines.push("#define BUMP");
                fallbacks.addFallback(0, "BUMP");
            }
        }

        // Effect
		if (this.useSpecularOverAlpha)
		{
			defines.push("#define SPECULAROVERALPHA");
			fallbacks.addFallback(0, "SPECULAROVERALPHA");
		}
			
        if (_scene.clipPlane != null)
		{
            defines.push("#define CLIPPLANE");
        }

        if (engine.getAlphaTesting())
		{
            defines.push("#define ALPHATEST");
        }
		
		if (this._shouldUseAlphaFromDiffuseTexture())
		{
			defines.push("#define ALPHAFROMDIFFUSE");
		}
		
		// Point size
		if (this.pointsCloud || _scene.forcePointsCloud) 
		{
			defines.push("#define POINTSIZE");
		}

        // Fog
        if (_scene.fogEnabled && mesh != null && mesh.applyFog && fogEnabled && _scene.fogInfo.fogMode != FogInfo.FOGMODE_NONE)
		{
            defines.push("#define FOG");
            fallbacks.addFallback(1, "FOG");
        }

        var shadowsActivated:Bool = false;
        var lightIndex:Int = 0;
        if (_scene.lightsEnabled) 
		{
			var lights:Array<Light> = _scene.lights;
            for (index in 0...lights.length)
			{
                var light:Light = lights[index];

                if (!light.isEnabled())
				{
                    continue;
                }
				
				// Excluded check
				var excludedMeshesIds:Array<String> = light._excludedMeshesIds;
				if (excludedMeshesIds.length > 0)
				{
					for (excludedIndex in 0...excludedMeshesIds.length)
					{
						var excludedMesh = _scene.getMeshByID(excludedMeshesIds[excludedIndex]);

						if (excludedMesh != null) 
						{
							light.excludedMeshes.push(excludedMesh);
						}
					}

					light._excludedMeshesIds = [];
				}
				
				// Included check
				if (light._includedOnlyMeshesIds.length > 0) 
				{
					for (includedOnlyIndex in 0...light._includedOnlyMeshesIds.length) 
					{
						var includedOnlyMesh:AbstractMesh = _scene.getMeshByID(light._includedOnlyMeshesIds[includedOnlyIndex]);

						if (includedOnlyMesh != null)
						{
							light.includedOnlyMeshes.push(includedOnlyMesh);
						}
					}

					light._includedOnlyMeshesIds = [];
				}
				
				if (!light.canAffectMesh(mesh))
				{
					continue;
				}

                defines.push("#define LIGHT" + lightIndex);

                if (lightIndex > 0) 
				{
                    fallbacks.addFallback(lightIndex, "LIGHT" + lightIndex);
                }

                var type:String = "";
                if (Std.is(light, SpotLight))
				{
                    type = "#define SPOTLIGHT" + lightIndex;
                } 
				else if (Std.is(light, HemisphericLight))
				{
                    type = "#define HEMILIGHT" + lightIndex;
                }
				else
				{
                    type = "#define POINTDIRLIGHT" + lightIndex;
                }

                defines.push(type);
                if (lightIndex > 0) 
				{
                    fallbacks.addFallback(lightIndex, type.replace("#define ", ""));
                }

                // Shadows
				if (_scene.shadowsEnabled)
				{
					var shadowGenerator:ShadowGenerator = light.shadowGenerator;
					if (mesh != null && mesh.receiveShadows && shadowGenerator != null)
					{
						defines.push("#define SHADOW" + lightIndex);
						fallbacks.addFallback(0, "SHADOW" + lightIndex);

						if (!shadowsActivated)
						{
							defines.push("#define SHADOWS");
							shadowsActivated = true;
						}

						if (shadowGenerator.useVarianceShadowMap)
						{
							defines.push("#define SHADOWVSM" + lightIndex);
							if (lightIndex > 0)
							{
								fallbacks.addFallback(0, "SHADOWVSM" + lightIndex);
							}
						}
						
						if (shadowGenerator.usePoissonSampling)
						{
							defines.push("#define SHADOWPCF" + lightIndex);
							if (lightIndex > 0)
							{
								fallbacks.addFallback(0, "SHADOWPCF" + lightIndex);
							}
						}
					}
				}

                lightIndex++;
                if (lightIndex >= maxSimultaneousLights)
                    break;
            }
        }
		
		// Fresnel
		if (StandardMaterial.FresnelEnabled)
		{
			if ((this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled) ||
			(this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled) ||
			(this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled) ||
			(this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled))
			{

				var fresnelRank:Int = 1;

				if (this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled)
				{
					defines.push("#define DIFFUSEFRESNEL");
					fallbacks.addFallback(fresnelRank, "DIFFUSEFRESNEL");
					fresnelRank++;
				}

				if (this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled)
				{
					defines.push("#define OPACITYFRESNEL");
					fallbacks.addFallback(fresnelRank, "OPACITYFRESNEL");
					fresnelRank++;
				}

				if (this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled) 
				{
					defines.push("#define REFLECTIONFRESNEL");
					fallbacks.addFallback(fresnelRank, "REFLECTIONFRESNEL");
					fresnelRank++;
				}

				if (this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled)
				{
					defines.push("#define EMISSIVEFRESNEL");
					fallbacks.addFallback(fresnelRank, "EMISSIVEFRESNEL");
					fresnelRank++;
				}

				defines.push("#define FRESNEL");
				fallbacks.addFallback(fresnelRank - 1, "FRESNEL");
			}
		}

		// Attribs
        var attribs:Array<String> = [VertexBuffer.PositionKind, VertexBuffer.NormalKind];
        if (mesh != null)
		{
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
			
            if (mesh.useVertexColors && mesh.isVerticesDataPresent(VertexBuffer.ColorKind))
			{
                attribs.push(VertexBuffer.ColorKind);
                defines.push("#define VERTEXCOLOR");
				
				if (mesh.hasVertexAlpha)
				{
					defines.push("#define VERTEXALPHA");
				}
            }
			
            if (mesh.skeleton != null && _scene.skeletonsEnabled &&
				mesh.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind) && 
				mesh.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind)) 
			{
                attribs.push(VertexBuffer.MatricesIndicesKind);
                attribs.push(VertexBuffer.MatricesWeightsKind);
                defines.push("#define BONES");
                defines.push("#define BonesPerMesh " + mesh.skeleton.bones.length);
                defines.push("#define BONES4");
                fallbacks.addFallback(0, "BONES4");
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
        }
		
        // Get correct effect      
        var join:String = defines.join("\n");
        if (this._cachedDefines != join) 
		{
            this._cachedDefines = join;
			
			_scene.resetCachedMaterial();

            var shaderName:String = "default";
			// Legacy browser patch
			if (!engine.getCaps().standardDerivatives) 
			{
				shaderName = "legacydefault";
			}
						
            this._effect = engine.createEffect(shaderName,
                    attribs,
                    ["world", "view", "viewProjection", "vEyePosition", "vLightsType", "vAmbientColor", "vDiffuseColor", "vSpecularColor", "vEmissiveColor",
                        "vLightData0", "vLightDiffuse0", "vLightSpecular0", "vLightDirection0", "vLightGround0", "lightMatrix0",
                        "vLightData1", "vLightDiffuse1", "vLightSpecular1", "vLightDirection1", "vLightGround1", "lightMatrix1",
                        "vLightData2", "vLightDiffuse2", "vLightSpecular2", "vLightDirection2", "vLightGround2", "lightMatrix2",
                        "vLightData3", "vLightDiffuse3", "vLightSpecular3", "vLightDirection3", "vLightGround3", "lightMatrix3",
                        "vFogInfos", "vFogColor","pointSize",
                        "vDiffuseInfos", "vAmbientInfos", "vOpacityInfos", "vReflectionInfos", "vEmissiveInfos", "vSpecularInfos", "vBumpInfos",
                        "mBones",
                        "vClipPlane", "diffuseMatrix", "ambientMatrix", "opacityMatrix", "reflectionMatrix", "emissiveMatrix", "specularMatrix", "bumpMatrix",
                        "darkness0", "darkness1", "darkness2", "darkness3",
                        "diffuseLeftColor", "diffuseRightColor", "opacityParts", "reflectionLeftColor", "reflectionRightColor", "emissiveLeftColor", "emissiveRightColor"
                    ],
                    ["diffuseSampler", "ambientSampler", "opacitySampler", "reflectionCubeSampler", "reflection2DSampler", "emissiveSampler", "specularSampler", "bumpSampler",
                        "shadowSampler0", "shadowSampler1", "shadowSampler2", "shadowSampler3"
                    ],
                    join, fallbacks, this.onCompiled, this.onError);
        }
		
        if (!this._effect.isReady())
		{
            return false;
        }

        _renderId = _scene.getRenderId();
        _wasPreviouslyReady = true;
        return true;    
	}
	
	override public function unbind():Void
	{
        if (this.reflectionTexture != null && this.reflectionTexture.isRenderTarget) 
		{
            this._effect.setTexture("reflection2DSampler", null);
        }
    }
	
	override public function getRenderTargetTextures():Array<RenderTargetTexture>
	{
        _renderTargets = [];

        if (reflectionTexture != null && reflectionTexture.isRenderTarget) 
		{
            this._renderTargets.push(cast(reflectionTexture,RenderTargetTexture));
        }

        return _renderTargets;
    }
	
	override public function bindOnlyWorldMatrix(world: Matrix): Void
	{
		this._effect.setMatrix("world", world);
	}
	
	override public function bind(world:Matrix, mesh:Mesh):Void
	{
        // Matrices        
        this.bindOnlyWorldMatrix(world);
        _effect.setMatrix("viewProjection", _scene.getTransformMatrix());

        // Bones
        if (_scene.skeletonsEnabled && mesh.isSkeletonsEnabled())
		{
            _effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices());
        }
		
		if (_scene.getCachedMaterial() != this)
		{
			// Fresnel
			if (StandardMaterial.FresnelEnabled) 
			{
				if (this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled)
				{
					this._effect.setColor4("diffuseLeftColor", this.diffuseFresnelParameters.leftColor, this.diffuseFresnelParameters.power);
					this._effect.setColor4("diffuseRightColor", this.diffuseFresnelParameters.rightColor, this.diffuseFresnelParameters.bias);
				}

				if (this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled)
				{
					this._effect.setColor4("opacityParts", new Color3(this.opacityFresnelParameters.leftColor.toLuminance(), this.opacityFresnelParameters.rightColor.toLuminance(), this.opacityFresnelParameters.bias), this.opacityFresnelParameters.power);
				}

				if (this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled) 
				{
					this._effect.setColor4("reflectionLeftColor", this.reflectionFresnelParameters.leftColor, this.reflectionFresnelParameters.power);
					this._effect.setColor4("reflectionRightColor", this.reflectionFresnelParameters.rightColor, this.reflectionFresnelParameters.bias);
				}

				if (this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled) 
				{
					this._effect.setColor4("emissiveLeftColor", this.emissiveFresnelParameters.leftColor, this.emissiveFresnelParameters.power);
					this._effect.setColor4("emissiveRightColor", this.emissiveFresnelParameters.rightColor, this.emissiveFresnelParameters.bias);
				}
			}
			

			// Textures        
			if (this.diffuseTexture != null && StandardMaterial.DiffuseTextureEnabled)
			{
				_effect.setTexture("diffuseSampler", this.diffuseTexture);
				_effect.setFloat2("vDiffuseInfos", this.diffuseTexture.coordinatesIndex, this.diffuseTexture.level);
				_effect.setMatrix("diffuseMatrix", this.diffuseTexture.getTextureMatrix());
			}

			if (this.ambientTexture != null && StandardMaterial.AmbientTextureEnabled)
			{
				_effect.setTexture("ambientSampler", this.ambientTexture);

				_effect.setFloat2("vAmbientInfos", this.ambientTexture.coordinatesIndex, this.ambientTexture.level);
				_effect.setMatrix("ambientMatrix", this.ambientTexture.getTextureMatrix());
			}

			if (this.opacityTexture != null && StandardMaterial.OpacityTextureEnabled)
			{
				_effect.setTexture("opacitySampler", this.opacityTexture);

				_effect.setFloat2("vOpacityInfos", this.opacityTexture.coordinatesIndex, this.opacityTexture.level);
				_effect.setMatrix("opacityMatrix", this.opacityTexture.getTextureMatrix());
			}

			if (this.reflectionTexture != null && StandardMaterial.ReflectionTextureEnabled)
			{
				if (this.reflectionTexture.isCube)
				{
					_effect.setTexture("reflectionCubeSampler", this.reflectionTexture);
				} 
				else 
				{
					_effect.setTexture("reflection2DSampler", this.reflectionTexture);
				}

				_effect.setMatrix("reflectionMatrix", this.reflectionTexture.getReflectionTextureMatrix());
				_effect.setFloat3("vReflectionInfos", this.reflectionTexture.coordinatesMode, this.reflectionTexture.level, this.reflectionTexture.isCube ? 1.0 : 0.0);	
			}

			if (this.emissiveTexture != null && StandardMaterial.EmissiveTextureEnabled)
			{
				_effect.setTexture("emissiveSampler", this.emissiveTexture);

				_effect.setFloat2("vEmissiveInfos", this.emissiveTexture.coordinatesIndex, this.emissiveTexture.level);
				_effect.setMatrix("emissiveMatrix", this.emissiveTexture.getTextureMatrix());
			}

			if (this.specularTexture != null && StandardMaterial.SpecularTextureEnabled)
			{
				_effect.setTexture("specularSampler", this.specularTexture);

				_effect.setFloat2("vSpecularInfos", this.specularTexture.coordinatesIndex, this.specularTexture.level);
				_effect.setMatrix("specularMatrix", this.specularTexture.getTextureMatrix());
			}

			if (this.bumpTexture != null && 
				_scene.getEngine().getCaps().standardDerivatives && 
				StandardMaterial.BumpTextureEnabled)
			{
				_effect.setTexture("bumpSampler", this.bumpTexture);

				_effect.setFloat2("vBumpInfos", this.bumpTexture.coordinatesIndex, 1.0 / this.bumpTexture.level);
				_effect.setMatrix("bumpMatrix", this.bumpTexture.getTextureMatrix());
			}
			
			// Clip plane
			if (_scene.clipPlane != null)
			{
				var clipPlane:Plane = _scene.clipPlane;
				this._effect.setFloat4("vClipPlane", clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.d);
			}
			
			// Point size
			if (this.pointsCloud || _scene.forcePointsCloud) 
			{
				this._effect.setFloat("pointSize", this.pointSize);
			}

			// Colors
			_scene.ambientColor.multiplyToRef(this.ambientColor, this._globalAmbientColor);
			
			// Scaling down colors according to emissive
			this._scaledSpecular.r = this.specularColor.r * FastMath.clamp(1.0 - this.emissiveColor.r);
			this._scaledSpecular.g = this.specularColor.g * FastMath.clamp(1.0 - this.emissiveColor.g);
			this._scaledSpecular.b = this.specularColor.b * FastMath.clamp(1.0 - this.emissiveColor.b);

			_effect.setVector3("vEyePosition", this._scene.activeCamera.position);
			_effect.setColor3("vAmbientColor", this._globalAmbientColor);
			_effect.setColor4("vSpecularColor", this._scaledSpecular, this.specularPower);
			_effect.setColor3("vEmissiveColor", this.emissiveColor);
		}
		
		// Scaling down color according to emissive
		this._scaledDiffuse.r = this.diffuseColor.r * FastMath.clamp(1.0 - this.emissiveColor.r);
		this._scaledDiffuse.g = this.diffuseColor.g * FastMath.clamp(1.0 - this.emissiveColor.g);
		this._scaledDiffuse.b = this.diffuseColor.b * FastMath.clamp(1.0 - this.emissiveColor.b);
		
		_effect.setColor4("vDiffuseColor", this._scaledDiffuse, this.alpha * mesh.visibility);
				
		//TODO 添加材质是否接受光照
        if (_scene.lightsEnabled) 
		{
            var lightIndex:Int = 0;
            for (index in 0..._scene.lights.length)
			{
                var light:Light = _scene.lights[index];

                if (!light.isEnabled())
				{
                    continue;
                }

                if (!light.canAffectMesh(mesh))
				{
					continue;
				}

                if (Std.is(light, PointLight))
				{
                    light.transferToEffect(_effect, "vLightData" + lightIndex);
                } 
				else if (Std.is(light, DirectionalLight))
				{
                    light.transferToEffect(_effect, "vLightData" + lightIndex);
                } 
				else if (Std.is(light, SpotLight))
				{
                    light.transferToEffect(_effect, "vLightData" + lightIndex, "vLightDirection" + lightIndex);
                } 
				else if (Std.is(light, HemisphericLight)) 
				{
                    light.transferToEffect(_effect, "vLightData" + lightIndex, "vLightGround" + lightIndex);
                }
				
                light.diffuse.scaleToRef(light.intensity, this._scaledDiffuse);
                light.specular.scaleToRef(light.intensity, this._scaledSpecular);
                _effect.setColor4("vLightDiffuse" + lightIndex, this._scaledDiffuse, light.range);
                _effect.setColor3("vLightSpecular" + lightIndex, this._scaledSpecular);
				
                // Shadows
				if (_scene.shadowsEnabled)
				{
					var shadowGenerator:ShadowGenerator = light.shadowGenerator;
					if (mesh.receiveShadows && shadowGenerator != null)
					{
						_effect.setMatrix("lightMatrix" + lightIndex, shadowGenerator.getTransformMatrix());
						_effect.setTexture("shadowSampler" + lightIndex, shadowGenerator.getShadowMap());
						_effect.setFloat("darkness" + lightIndex, shadowGenerator.getDarkness());
					}
				}
                
                lightIndex++;

                if (lightIndex == maxSimultaneousLights)
                    break;
            }
        }

        // View
		var fogInfo = this._scene.fogInfo;
        if ((_scene.fogEnabled && mesh.applyFog && fogInfo.fogMode != FogInfo.FOGMODE_NONE) || this.reflectionTexture != null)
		{
            _effect.setMatrix("view", this._scene.getViewMatrix());
        }

        // Fog
        if (_scene.fogEnabled && mesh.applyFog && fogInfo.fogMode != FogInfo.FOGMODE_NONE)
		{
            _effect.setFloat4("vFogInfos", fogInfo.fogMode, fogInfo.fogStart, fogInfo.fogEnd, fogInfo.fogDensity);
            _effect.setColor3("vFogColor", fogInfo.fogColor);
        }
		
		super.bind(world, mesh);
    }
	
	public function getAnimatables():Array<Dynamic>
	{
        var results:Array<Dynamic> = [];

        if (this.diffuseTexture != null && 
			this.diffuseTexture.animations != null && 
			this.diffuseTexture.animations.length > 0)
		{
            results.push(this.diffuseTexture);
        }

        if (this.ambientTexture != null && 
			this.ambientTexture.animations != null && 
			this.ambientTexture.animations.length > 0)
		{
            results.push(this.ambientTexture);
        }

        if (this.opacityTexture != null && 
			this.opacityTexture.animations != null && 
			this.opacityTexture.animations.length > 0)
		{
            results.push(this.opacityTexture);
        }

        if (this.reflectionTexture != null &&
			this.reflectionTexture.animations != null && 
			this.reflectionTexture.animations.length > 0) 
		{
            results.push(this.reflectionTexture);
        }

        if (this.emissiveTexture != null && 
			this.emissiveTexture.animations != null && 
			this.emissiveTexture.animations.length > 0) 
		{
            results.push(this.emissiveTexture);
        }

        if (this.specularTexture != null && 
			this.specularTexture.animations != null && 
			this.specularTexture.animations.length > 0) 
		{
            results.push(this.specularTexture);
        }

        if (this.bumpTexture != null && 
			this.bumpTexture.animations != null && 
			this.bumpTexture.animations.length > 0)
		{
            results.push(this.bumpTexture);
        }

        return results;
    }
	
	override public function dispose(forceDisposeEffect:Bool = false):Void 
	{
        if (this.diffuseTexture != null)
		{
            this.diffuseTexture.dispose();
			this.diffuseTexture = null;
        }

        if (this.ambientTexture != null)
		{
            this.ambientTexture.dispose();
			this.ambientTexture = null;
        }

        if (this.opacityTexture != null)
		{
            this.opacityTexture.dispose();
			this.opacityTexture = null;
        }

        if (this.reflectionTexture != null)
		{
            this.reflectionTexture.dispose();
			this.reflectionTexture = null;
        }

        if (this.emissiveTexture != null)
		{
            this.emissiveTexture.dispose();
			this.emissiveTexture = null;
        }

        if (this.specularTexture != null)
		{
            this.specularTexture.dispose();
			this.specularTexture = null;
        }

        if (this.bumpTexture != null)
		{
            this.bumpTexture.dispose();
			this.bumpTexture = null;
        }

		super.dispose(forceDisposeEffect);
    }
	
	public function clone(name:String):StandardMaterial
	{
        var newStandardMaterial:StandardMaterial = new StandardMaterial(name, this._scene);

        // Base material
        newStandardMaterial.checkReadyOnEveryCall = this.checkReadyOnEveryCall;
        newStandardMaterial.alpha = this.alpha;
        newStandardMaterial.fillMode = this.fillMode;
        newStandardMaterial.backFaceCulling = this.backFaceCulling;

        // Standard material
        if (this.diffuseTexture != null)
		{
            newStandardMaterial.diffuseTexture = this.diffuseTexture.clone();
        }
		
        if (this.ambientTexture != null) 
		{
            newStandardMaterial.ambientTexture = this.ambientTexture.clone();
        }
		
        if (this.opacityTexture != null) 
		{
            newStandardMaterial.opacityTexture = this.opacityTexture.clone();
        }
		
        if (this.reflectionTexture != null)
		{
            newStandardMaterial.reflectionTexture = this.reflectionTexture.clone();
        }
		
        if (this.emissiveTexture != null)
		{
            newStandardMaterial.emissiveTexture = this.emissiveTexture.clone();
        }
		
        if (this.specularTexture != null) 
		{
            newStandardMaterial.specularTexture = this.specularTexture.clone();
        }
		
        if (this.bumpTexture != null)
		{
            newStandardMaterial.bumpTexture = this.bumpTexture.clone();
        }

        newStandardMaterial.ambientColor = this.ambientColor.clone();
        newStandardMaterial.diffuseColor = this.diffuseColor.clone();
        newStandardMaterial.specularColor = this.specularColor.clone();
        newStandardMaterial.specularPower = this.specularPower;
        newStandardMaterial.emissiveColor = this.emissiveColor.clone();

        return newStandardMaterial;
    }
	
}