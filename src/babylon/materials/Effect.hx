package babylon.materials;

import babylon.Engine;
import babylon.materials.textures.BabylonGLTexture;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.postprocess.PostProcess;
import babylon.tools.Tools;
import babylon.utils.CompileTime;
import babylon.utils.Logger;
import haxe.ds.StringMap;
import openfl.Assets;
import openfl.gl.GLProgram;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;

class Effect 
{
	public static var ShadersStore:StringMap<String>;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		ShadersStore = new StringMap<String>();
		
		ShadersStore.set("blackAndWhitePixelShader", CompileTime.readFile("babylon/materials/shaders/blackAndWhite.frag"));
		ShadersStore.set("blurPixelShader", CompileTime.readFile("babylon/materials/shaders/blur.frag"));
		ShadersStore.set("convolutionPixelShader", CompileTime.readFile("babylon/materials/shaders/convolution.frag"));
		ShadersStore.set("defaultPixelShader", CompileTime.readFile("babylon/materials/shaders/default.frag"));
		ShadersStore.set("defaultVertexShader", CompileTime.readFile("babylon/materials/shaders/default.vert"));
		ShadersStore.set("fxaaPixelShader", CompileTime.readFile("babylon/materials/shaders/fxaa.frag"));
		ShadersStore.set("iedefaultPixelShader", CompileTime.readFile("babylon/materials/shaders/iedefault.frag"));
		ShadersStore.set("iedefaultVertexShader", CompileTime.readFile("babylon/materials/shaders/iedefault.vert"));
		ShadersStore.set("layerPixelShader", CompileTime.readFile("babylon/materials/shaders/layer.frag"));
		ShadersStore.set("layerVertexShader", CompileTime.readFile("babylon/materials/shaders/layer.vert"));
		ShadersStore.set("lensFlarePixelShader", CompileTime.readFile("babylon/materials/shaders/lensFlare.frag"));
		ShadersStore.set("lensFlareVertexShader", CompileTime.readFile("babylon/materials/shaders/lensFlare.vert"));
		ShadersStore.set("particlesPixelShader", CompileTime.readFile("babylon/materials/shaders/particles.frag"));
		ShadersStore.set("particlesVertexShader", CompileTime.readFile("babylon/materials/shaders/particles.vert"));
		ShadersStore.set("passPixelShader", CompileTime.readFile("babylon/materials/shaders/pass.frag"));
		ShadersStore.set("postprocessVertexShader", CompileTime.readFile("babylon/materials/shaders/postprocess.vert"));
		ShadersStore.set("refractionPixelShader", CompileTime.readFile("babylon/materials/shaders/refraction.frag"));
		ShadersStore.set("shadowMapPixelShader", CompileTime.readFile("babylon/materials/shaders/shadowMap.frag"));
		ShadersStore.set("shadowMapVertexShader", CompileTime.readFile("babylon/materials/shaders/shadowMap.vert"));
		ShadersStore.set("spritesPixelShader", CompileTime.readFile("babylon/materials/shaders/sprites.frag"));
		ShadersStore.set("spritesVertexShader", CompileTime.readFile("babylon/materials/shaders/sprites.vert"));
		ShadersStore.set("filterPixelShader", CompileTime.readFile("babylon/materials/shaders/filter.frag"));
		ShadersStore.set("colorVertexShader", CompileTime.readFile("babylon/materials/shaders/color.vert"));
		ShadersStore.set("colorPixelShader", CompileTime.readFile("babylon/materials/shaders/color.frag"));
		ShadersStore.set("outlineVertexShader", CompileTime.readFile("babylon/materials/shaders/outline.vert"));
		ShadersStore.set("outlinePixelShader", CompileTime.readFile("babylon/materials/shaders/outline.frag"));
		ShadersStore.set("proceduralVertexShader", CompileTime.readFile("babylon/materials/shaders/procedural.vert"));
		ShadersStore.set("cloudPixelShader", CompileTime.readFile("babylon/materials/shaders/cloud.frag"));
		ShadersStore.set("firePixelShader", CompileTime.readFile("babylon/materials/shaders/fire.frag"));
		ShadersStore.set("grassPixelShader", CompileTime.readFile("babylon/materials/shaders/grass.frag"));
		ShadersStore.set("roadPixelShader", CompileTime.readFile("babylon/materials/shaders/road.frag"));
		ShadersStore.set("rockPixelhader", CompileTime.readFile("babylon/materials/shaders/rock.frag"));
		ShadersStore.set("woodPixelShader", CompileTime.readFile("babylon/materials/shaders/wood.frag"));
		ShadersStore.set("brickPixelShader", CompileTime.readFile("babylon/materials/shaders/brick.frag"));
		ShadersStore.set("marblePixelShader", CompileTime.readFile("babylon/materials/shaders/marble.frag"));
		ShadersStore.set("anaglyphPixelShader", CompileTime.readFile("babylon/materials/shaders/anaglyph.frag"));
		ShadersStore.set("depthVertexShader", CompileTime.readFile("babylon/materials/shaders/depth.vert"));
		ShadersStore.set("depthPixelShader", CompileTime.readFile("babylon/materials/shaders/depth.frag"));
	}

	public var name:Dynamic;
	public var defines:String;
	public var onCompiled:Effect->Void;
	public var onError:Effect->String->Void;
	public var onBind: Effect->Void;
	
	private var _engine:Engine;
	private var _uniformsNames:Array<String>;
	private var _samplers:Array<String>;
	private var _isReady:Bool = false;
	private var _compilationError:String = "";
	private var _attributesNames:Array<String>;
	private var _attributes:Array<Int>;
	private var _uniforms:Array<GLUniformLocation>;
	
	public var _key:String;

	private var _program:GLProgram;
	
	private var _valueCache:Map<String, Array<Float>>;
	
	public function new(baseName:Dynamic,
						attributesNames:Array<String>, 
						uniformsNames:Array<String>, 
						samplers:Array<String>, 
						engine:Engine, 
						defines:String = null, 
						fallbacks:EffectFallbacks = null,
						onCompiled:Effect->Void = null,
						onError:Effect->String->Void = null) 
	{
		this._engine = engine;
        this.name = baseName;
        this.defines = defines;
        this._uniformsNames = uniformsNames.concat(samplers);
        this._samplers = samplers;
        this._isReady = false;
        this._compilationError = "";
        this._attributesNames = attributesNames;
		
		this.onError = onError;
		this.onCompiled = onCompiled;
		
		// Cache
        _valueCache = new Map<String, Array<Float>>();
		
        var vertex:String = Reflect.hasField(baseName, "vertex") ? baseName.vertex : baseName;
        var fragment:String = Reflect.hasField(baseName, "fragment") ? baseName.fragment : baseName;
		
		_loadVertexShader(vertex, function(vertexCode:String):Void
		{
			_loadFragmentShader(fragment, function(fragmentCode:String):Void
			{
				_prepareEffect(vertexCode, fragmentCode, attributesNames, defines, fallbacks);
			});
		});	
	}
	
	public function release():Void
	{
		
	}
	
	public inline function isReady():Bool
	{
        return _isReady;
    }
	
	public inline function getProgram():GLProgram
	{
        return _program;
    }
	
	public function getAttributesNames():Array<String>
	{
        return _attributesNames;
    }
	
	public inline function getAttributeLocation(index:Int):Int
	{
        return _attributes[index];
    }
	
	//public inline function getAttribute(index:Int):Int
	//{
        //return _attributes[index];
    //}
	
	public function getAttributeLocationByName(name:String):Int
	{
		var index = _attributesNames.indexOf(name);
        return _attributes[index];
    }
	
	public inline function getAttributesCount():Int
	{
        return _attributes.length;
    }
	
	public inline function getAttributes():Array<Int>
	{
        return _attributes;
    }
	
	public inline function getUniformIndex(uniformName:String):Int
	{
        return _uniformsNames.indexOf(uniformName);
    }
	
	public inline function getUniform(uniformName:String):GLUniformLocation 
	{	 
		return _uniforms[_uniformsNames.indexOf(uniformName)];
    }
	
	public function getSamplers():Array<String>
	{
        return _samplers;
    }
	
	public function getCompilationError():String
	{
        return _compilationError;
    }
	
	public function _loadVertexShader(vertex:String, callbackFn:String->Void):Void
	{
		var key = vertex + "VertexShader";
        // Is in local store ?
        if (Effect.ShadersStore.exists(key))
		{
            callbackFn(Effect.ShadersStore.get(key));
            return;
        }

        // Vertex shader
        Tools.LoadFile(Engine.ShadersRepository + vertex + ".vert", callbackFn);
    }
	
	public function _loadFragmentShader(fragment:String, callbackFn:String->Void):Void
	{
		var key = fragment + "PixelShader";
        // Is in local store ?
        if (Effect.ShadersStore.exists(key)) 
		{
            callbackFn(Effect.ShadersStore.get(key));
            return;
        }
        
        // Fragment shader
        Tools.LoadFile(Engine.ShadersRepository + fragment + ".frag", callbackFn);
    }
	
	private function _prepareEffect(vertexSourceCode:String,
									fragmentSourceCode:String, 
									attributesNames:Array<String>, 
									defines:String, 
									fallbacks:EffectFallbacks = null):Void
	{
        try 
		{
            _program = _engine.createShaderProgram(vertexSourceCode, fragmentSourceCode, defines);

            _uniforms = _engine.getUniforms(_program, _uniformsNames);
            _attributes = _engine.getAttributes(_program, attributesNames);			
			
			var index:Int = 0;
			while (index < _samplers.length) 
			{
                var sampler = getUniform(_samplers[index]);
				//cpp中GLUniformLocation是int类型
				#if html5
				if (sampler == null)
				#else
                if (sampler < 0)
				#end
				{
                    _samplers.splice(index, 1);
                    index--;
                }
				
				index++;
            }
			
            _engine.bindSamplers(this);

            _isReady = true;
			
			if (onCompiled != null)
			{
				onCompiled(this);
			}
        } 
		catch (e:Dynamic) 
		{
            if (fallbacks != null && fallbacks.isMoreFallbacks())
			{
				defines = fallbacks.reduce(defines);
                _prepareEffect(vertexSourceCode, fragmentSourceCode, attributesNames, defines, fallbacks);
            } 
			else 
			{
                Logger.log("Unable to compile effect: " + name);
                Logger.log("Defines: " + defines);
				Logger.log("Error: " + e);
                _compilationError = cast e;
				
				if (onError != null)
				{
					onError(this, _compilationError);
				}
            }
        }
    }
	
	public inline function bindTexture(channel:String, texture:BabylonGLTexture):Void
	{
        _engine.bindTexture(_samplers.indexOf(channel), texture);
    }
	
	public inline function setTexture(channel:String, texture:BaseTexture):Void
	{
        _engine.setTexture(_samplers.indexOf(channel), texture);
    }
	
	public inline function setTextureFromPostProcess(channel:String, postProcess:PostProcess):Void
	{
        _engine.setTextureFromPostProcess(_samplers.indexOf(channel), postProcess);
    }
	
	public function _cacheMatrix(uniformName, matrix:Matrix):Void
	{
        if (!_valueCache.exists(uniformName))
		{
            _valueCache.set(uniformName,[]);
        }

		var caches:Array<Float> = _valueCache.get(uniformName);
		for (i in 0...16)
		{
			caches[i] = matrix.m[i];
		}
    }

    public function _cacheFloat2(uniformName:String, x:Float, y:Float)
	{
         var values:Array<Float> = _valueCache.get(uniformName);
        if (values == null)
		{
            _valueCache.set(uniformName, [x, y]);
        } 
		else 
		{
			values[0] = x;
			values[1] = y;
		}
    }

	public function _cacheFloat3(uniformName:String, x:Float, y:Float, z:Float):Void
	{
        var values:Array<Float> = _valueCache.get(uniformName);
        if (values == null)
		{
            _valueCache.set(uniformName, [x, y, z]);
        } 
		else
		{
			values[0] = x;
			values[1] = y;
			values[2] = z;
		}
    }

    public function _cacheFloat4(uniformName:String, x:Float, y:Float, z:Float, w:Float):Void
	{		
		var values:Array<Float> = _valueCache.get(uniformName);
        if (values == null)
		{
            _valueCache.set(uniformName, [x, y, z, w]);
        } 
		else 
		{
			values[0] = x;
			values[1] = y;
			values[2] = z;
			values[3] = w;
		}
    }
	
	public function setMatrices(uniformName:String, matrices: #if html5 Float32Array #else Array<Float> #end ):Void
	{
        _engine.setMatrices(getUniform(uniformName), matrices);
    }

	public function setArray(uniformName:String, array:Array<Float>):Void
	{
		_engine.setArray(getUniform(uniformName), array);
	}
	
    public function setMatrix(uniformName:String, matrix:Matrix):Void
	{
        if (_valueCache.exists(uniformName))
		{
			var array:Array<Float> = _valueCache.get(uniformName);
			
			var isEqual:Bool = true;
			for (i in 0...16)
			{
				if (array[i] != matrix.m[i])
				{
					isEqual = false;
					break;
				}
			}
			
			if(isEqual)
				return;
		}

        _cacheMatrix(uniformName, matrix);
        _engine.setMatrix(getUniform(uniformName), matrix);
    }

    public function setFloat(uniformName:String, value:Float):Void
	{
        if (!(_valueCache.exists(uniformName) && _valueCache.get(uniformName)[0] == value)) 
		{
			_valueCache.set(uniformName, [value]);
			_engine.setFloat(getUniform(uniformName), value);
		}
    }

    public function setBool(uniformName:String, bool:Bool):Void
	{
		var value:Float = bool ? 1.0 : 0.0;
		
        if (!(_valueCache.exists(uniformName) && _valueCache.get(uniformName)[0] == value))
		{
			_valueCache.set(uniformName, [value]);
			_engine.setBool(getUniform(uniformName), bool);
		}
    }
    
    public function setVector2(uniformName:String, vector2:Vector2):Void 
	{
        var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == vector2.x && 
			  values[1] == vector2.y)) 
		{
			_cacheFloat2(uniformName, vector2.x, vector2.y);
			_engine.setFloat2(getUniform(uniformName), vector2.x, vector2.y);
		}
    }

    public function setFloat2(uniformName:String, x:Float, y:Float):Void 
	{
		var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == x && 
			  values[1] == y)) 
		{
			_cacheFloat2(uniformName, x, y);
			_engine.setFloat2(getUniform(uniformName), x, y);
		}
    }
    
    public function setVector3(uniformName:String, vector3:Vector3):Void
	{
        var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == vector3.x && 
			  values[1] == vector3.y && 
			  values[2] == vector3.z)) 
		{	
			_cacheFloat3(uniformName, vector3.x, vector3.y, vector3.z);
			_engine.setFloat3(getUniform(uniformName), vector3.x, vector3.y, vector3.z);
		}
    }

    public function setFloat3(uniformName:String, x:Float, y:Float, z:Float):Void 
	{		
        var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == x && 
			  values[1] == y && 
			  values[2] == z)) 
		{	
			_cacheFloat3(uniformName, x, y, z);
			_engine.setFloat3(getUniform(uniformName), x, y, z);
		}
    }

    public function setFloat4(uniformName:String, x:Float, y:Float, z:Float, w:Float):Void 
	{
		var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == x && 
			  values[1] == y && 
			  values[2] == z && 
			  values[3] == w)) 
		{
			_cacheFloat4(uniformName, x, y, z, w);
			_engine.setFloat4(getUniform(uniformName), x, y, z, w);
		}
    }

    public function setColor3(uniformName:String, color3:Color3):Void 
	{
		var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == color3.r && 
			  values[1] == color3.g && 
			  values[2] == color3.b)) 
		{
			_cacheFloat3(uniformName, color3.r, color3.g, color3.b);
			_engine.setColor3(getUniform(uniformName), color3);
		}
    }

    public function setColor4(uniformName:String, color3:Color3, alpha:Float):Void 
	{
		var values:Array<Float> = _valueCache.get(uniformName);
		
        if (!(values != null && 
			  values[0] == color3.r && 
			  values[1] == color3.g && 
			  values[2] == color3.b && 
			  values[3] == alpha)) 
		{
			_cacheFloat4(uniformName, color3.r, color3.g, color3.b, alpha);
			_engine.setColor4(getUniform(uniformName), color3, alpha);
		}
    }
	
}
