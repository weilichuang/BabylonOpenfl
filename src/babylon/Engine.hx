package babylon;

import babylon.audio.AudioEngine;
import babylon.cameras.Camera;
import babylon.Engine.EngineCapabilities;
import babylon.materials.Effect;
import babylon.materials.EffectFallbacks;
import babylon.materials.textures.BabylonGLTexture;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.Texture;
import babylon.materials.textures.VideoTexture;
import babylon.math.Color3;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Viewport;
import babylon.mesh.BabylonGLBuffer;
import babylon.mesh.VertexBuffer;
import babylon.postprocess.PostProcess;
import babylon.tools.Tools;
import babylon.utils.BitmapDataUtils;
import babylon.utils.GLUtil;
import babylon.utils.Logger;
import haxe.ds.StringMap;
import haxe.io.UInt16Array;
import haxe.io.UInt32Array;
import openfl.display.BitmapData;
import openfl.display.OpenGLView;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLShader;
import openfl.gl.GLUniformLocation;
import openfl.Lib;
import openfl.system.Capabilities;
import openfl.utils.Float32Array;
import openfl.utils.Int16Array;
import openfl.utils.Int32Array;

class EngineCapabilities 
{
	public var maxTexturesImageUnits: Int;
	public var maxTextureSize: Int;
	public var maxCubemapTextureSize: Int;
	public var maxRenderTextureSize: Int;
	public var standardDerivatives:Bool = true;
	public var s3tc:Dynamic;
	public var textureFloat: Bool;
	public var textureAnisotropicFilterExtension: Dynamic;
	public var maxAnisotropy: Int;	
	public var instancedArrays:Dynamic = null;
	public var uintIndices: Bool = false;
	public var highPrecisionShaderSupported:Bool;
	
	public function new()
	{
		
	}
}
 
class Engine 
{
    public static inline var ALPHA_DISABLE:Int = 0;
    public static inline var ALPHA_ADD:Int = 1;
    public static inline var ALPHA_COMBINE:Int = 2;
    
    public static inline var DELAYLOADSTATE_NONE:Int = 0;
    public static inline var DELAYLOADSTATE_LOADED:Int = 1;
    public static inline var DELAYLOADSTATE_LOADING:Int = 2;
    public static inline var DELAYLOADSTATE_NOTLOADED:Int = 4;
	
	public static inline var TEXTUREFORMAT_ALPHA:Int = 0;
    public static inline var TEXTUREFORMAT_LUMINANCE:Int = 1;
    public static inline var TEXTUREFORMAT_LUMINANCE_ALPHA:Int = 2;
    public static inline var TEXTUREFORMAT_RGB:Int = 4;
	public static inline var TEXTUREFORMAT_RGBA:Int = 4;
	
	public static inline var TEXTURETYPE_UNSIGNED_INT:Int = 0;
	public static inline var TEXTURETYPE_FLOAT:Int = 1;
	
	public static function Version():String
	{
		return "2.1.0";
	}
	
	// Updatable statics so stick with vars here
	public static var Epsilon:Float = 0.001;
	public static var CollisionsEpsilon:Float = 0.001;

	// Statics
    public static var ShadersRepository:String = "shaders/";
	
	public var scenes:Array<Scene> = [];
	
	public var cullBackFaces:Bool = true;
	//public var isFullscreen:Bool = false;
	public var isPointerLock:Bool = false;
	
	private var _hardwareScalingLevel:Int;
	private var _caps:EngineCapabilities;
	
	private var _pointerLockRequested:Bool;
	private var _alphaTest:Bool;
	
	private var _runningLoop:Bool = false;
	private var _renderFunction:Rectangle-> Void;
	
	private var _windowIsBackground:Bool = false;
	
	private var _loadedTexturesCache:Array<BabylonGLTexture>;
	private var _activeTexturesCache:Array<BaseTexture>;
	
	// States
	private var _depthCullingState:DepthCullingState = new DepthCullingState();
	private var _alphaState:AlphaState = new AlphaState();
	private var _alphaMode:Int = ALPHA_DISABLE;
	
	private var _currentEffect:Effect;
	private var _compiledEffects:StringMap<Effect>;
	
	private var _vertexAttribArrays:Array<Int> = [];
	
	private var _cachedViewport:Viewport;
	private var _cachedVertexBuffers:Dynamic;  
	private var _cachedIndexBuffer:BabylonGLBuffer;
	private var _cachedEffectForVertexBuffers:Effect;
	private var _currentRenderTarget:BabylonGLTexture;
	
	private var _workingCanvas:BitmapData;
	private var _workingContext:OpenGLView;
	
	private var _stage:Stage;

	private var _aspectRatio:Float;
	
	private var _uintIndicesCurrentlySet:Bool = false;
	
	private var _audioEngine: AudioEngine;
	
	private var _drawCalls:Int = 0;
	
	// FPS
    private var fpsRange:Float = 60.0;
    private var previousFramesDuration:Array<Float> = [];
    private var fps:Float = 60.0;
    private var deltaTime:Float = 0.0;
	
	public function new(stage:Stage, antialias:Bool = true, options:Dynamic = null)
	{
		_stage = stage;
		
		if (!OpenGLView.isSupported) 
		{
			throw("GL not supported");
		}

        // Textures
        this._workingContext = new OpenGLView();
		_stage.addChild(this._workingContext);
		
		this._workingContext.addEventListener(OpenGLView.CONTEXT_LOST, onContextLost);
		this._workingContext.addEventListener(OpenGLView.CONTEXT_RESTORED, onContextRestored);
		
        // Viewport
        this._hardwareScalingLevel = Std.int(1.0 / Capabilities.pixelAspectRatio);
        this.resize();

        this.initEngineCaps();
				
        // Cache
        this._loadedTexturesCache = [];
        this._activeTexturesCache = [];
        this._currentEffect = null;

        this._compiledEffects = new StringMap<Effect>();

		// Depth buffer
		this.setDepthTest(true);
		this.setDepthFunctionToLessOrEqual();
		this.setDepthWrite(true);
		
		_audioEngine = new AudioEngine();
		
		// TODO - remove
        /*var onFullscreenChange = function () {
            if (document.fullscreen !== undefined) {
                that.isFullscreen = document.fullscreen;
            } else if (document.mozFullScreen !== undefined) {
                that.isFullscreen = document.mozFullScreen;
            } else if (document.webkitIsFullScreen !== undefined) {
                that.isFullscreen = document.webkitIsFullScreen;
            } else if (document.msIsFullScreen !== undefined) {
                that.isFullscreen = document.msIsFullScreen;
            }

            // Pointer lock
            if (that.isFullscreen && that._pointerLockRequested) {
                canvas.requestPointerLock = canvas.requestPointerLock ||
                                            canvas.msRequestPointerLock ||
                                            canvas.mozRequestPointerLock ||
                                            canvas.webkitRequestPointerLock;

                if (canvas.requestPointerLock) {
                    canvas.requestPointerLock();
                }
            }
        };

        document.addEventListener("fullscreenchange", onFullscreenChange, false);
        document.addEventListener("mozfullscreenchange", onFullscreenChange, false);
        document.addEventListener("webkitfullscreenchange", onFullscreenChange, false);
        document.addEventListener("msfullscreenchange", onFullscreenChange, false);*/

        // Pointer lock
        //this.isPointerLock = false;

		// TODO - remove this
        /*var onPointerLockChange = function () {
            that.isPointerLock = (document.mozPointerLockElement === canvas ||
                                  document.webkitPointerLockElement === canvas ||
                                  document.msPointerLockElement === canvas ||
                                  document.pointerLockElement === canvas
            );
        };

        document.addEventListener("pointerlockchange", onPointerLockChange, false);
        document.addEventListener("mspointerlockchange", onPointerLockChange, false);
        document.addEventListener("mozpointerlockchange", onPointerLockChange, false);
        document.addEventListener("webkitpointerlockchange", onPointerLockChange, false);*/
	}
	
	public function getFps():Float
	{
        return fps;
    }

    public function getDeltaTime():Float 
	{
        return deltaTime;
    }

    private function _MeasureFps():Void
	{
        previousFramesDuration.push(Lib.getTimer());
		
        var length = previousFramesDuration.length;

        if (length >= 2)
		{
            deltaTime = previousFramesDuration[length - 1] - previousFramesDuration[length - 2];
        }

        if (length >= fpsRange)
		{
            if (length > fpsRange)
			{
                previousFramesDuration.splice(0, 1);
                length--;
            }

            var sum:Float = 0;
			var count:Int = length - 1;
            for (i in 0...count)
			{
                sum += previousFramesDuration[i + 1] - previousFramesDuration[i];
            }

            fps = 1000.0 * count / sum;
        }
    }
	
	public function getAudioEngine():AudioEngine
	{
		return _audioEngine;
	}
	
	public function displayLoadingUI():Void
	{
		
	}
	
	public function hideLoadingUI():Void
	{
		
	}
	
	private function onContextLost(event:Event):Void
	{
		Logger.log("GL Context Lost");
	}
	
	private function onContextRestored(event:Event):Void
	{
		Logger.log("GL Context Restored");
	}
	
	private function initEngineCaps():Void
	{
		// Caps
        _caps = new EngineCapabilities();
        _caps.maxTexturesImageUnits = GL.getParameter(GL.MAX_TEXTURE_IMAGE_UNITS);
        _caps.maxTextureSize = GL.getParameter(GL.MAX_TEXTURE_SIZE);
        _caps.maxCubemapTextureSize = GL.getParameter(GL.MAX_CUBE_MAP_TEXTURE_SIZE);
		
		//cpp GL.getParameter(GL.MAX_RENDERBUFFER_SIZE):0
		#if html5
		_caps.maxRenderTextureSize = GL.getParameter(GL.MAX_RENDERBUFFER_SIZE);
		#else
		_caps.maxRenderTextureSize = 2048;
		#end

        // Extensions
		#if cpp
		_caps.standardDerivatives = true;
		#else
        _caps.standardDerivatives = GL.getExtension('OES_standard_derivatives') != null;	
		#end
		_caps.s3tc = GL.getExtension('WEBGL_compressed_texture_s3tc') != null;	
		
        _caps.textureFloat = GL.getExtension('OES_texture_float') != null;  
		
		// TODO - this fails on desktops
		function get_EXT_texture_filter_anisotropic():Dynamic
		{				
			if (GL.getExtension('EXT_texture_filter_anisotropic') != null) 
			{
				return GL.getExtension('EXT_texture_filter_anisotropic');
			}
			if (GL.getExtension('GL_EXT_texture_filter_anisotropic') != null)
			{
				return GL.getExtension('GL_EXT_texture_filter_anisotropic');
			}
			if (GL.getExtension('WEBKIT_EXT_texture_filter_anisotropic') != null)
			{
				return GL.getExtension('WEBKIT_EXT_texture_filter_anisotropic');
			}
			if (GL.getExtension('MOZ_EXT_texture_filter_anisotropic') != null) 
			{
				return GL.getExtension('MOZ_EXT_texture_filter_anisotropic');
			}	
			return null;
		}		
		
		this._caps.textureAnisotropicFilterExtension = get_EXT_texture_filter_anisotropic();
		
        this._caps.maxAnisotropy = this._caps.textureAnisotropicFilterExtension != null ? GL.getParameter(this._caps.textureAnisotropicFilterExtension.MAX_TEXTURE_MAX_ANISOTROPY_EXT) : 1;
		
		this._caps.instancedArrays = GL.getExtension('ANGLE_instanced_arrays');
		this._caps.uintIndices = GL.getExtension('OES_element_index_uint') != null;
		
		var highp = GL.getShaderPrecisionFormat(GL.FRAGMENT_SHADER, GL.HIGH_FLOAT);
		this._caps.highPrecisionShaderSupported = highp != null && highp.precision != 0;
	}
	
	// Properties
    public function getAspectRatio(camera:Camera):Float 
	{
		var viewport = camera.viewport;
        return (this.getRenderWidth() * viewport.width) / (this.getRenderWidth() * viewport.height);
    }
	
    public function getRenderWidth():Int 
	{
		if (this._currentRenderTarget != null)
		{
			return Std.int(this._currentRenderTarget._width);
		}
		return Lib.current.stage.stageWidth;
    }

    public function getRenderHeight():Int
	{
		if (this._currentRenderTarget != null)
		{
			return Std.int(this._currentRenderTarget._height);
		}
		return Lib.current.stage.stageHeight;
    }

    public inline function getStage():Stage
	{
        return this._stage;
    }

    public function setHardwareScalingLevel(level:Int):Void
	{
        this._hardwareScalingLevel = level;
        this.resize();
    }

    public function getHardwareScalingLevel():Int 
	{
        return this._hardwareScalingLevel;
    }

    public function getLoadedTexturesCache():Array<BabylonGLTexture>
	{
        return this._loadedTexturesCache;
    }

    public function getCaps():EngineCapabilities 
	{
        return this._caps;
    }
	
	public function getDrawCalls(): Int 
	{
		return this._drawCalls;
	}

	// Methods
	public function resetDrawCalls(): Void 
	{
		this._drawCalls = 0;
	}
	
	public inline function setDepthFunctionToGreater(): Void 
	{
		this._depthCullingState.depthFunc = GL.GREATER;
	}

	public inline function setDepthFunctionToGreaterOrEqual(): Void 
	{
		this._depthCullingState.depthFunc = GL.GEQUAL;
	}

	public inline function setDepthFunctionToLess(): Void 
	{
		this._depthCullingState.depthFunc = GL.LESS;
	}

	public inline function setDepthFunctionToLessOrEqual(): Void
	{
		this._depthCullingState.depthFunc = GL.LEQUAL;
	}
	
	// Methods
    public function stopRenderLoop():Void
	{
        this._renderFunction = null;
        this._runningLoop = false;
    }

    private function _renderLoop(rect:Rectangle):Void
	{
		var shouldRender:Bool = true;
		if (this._windowIsBackground)
		{
			shouldRender = false;
		}
			
		if (shouldRender)
		{
			// Start new frame
			this.beginFrame();

			if (this._renderFunction != null)
			{
				this._renderFunction(rect);			
			}

			// Present
			this.endFrame();
		}
    }

    public function runRenderLoop(renderFunction:Rectangle-> Void):Void
	{
        this._runningLoop = true;
        this._renderFunction = renderFunction;		
		this._workingContext.render = this._renderLoop;
    }

    public function switchFullscreen(requestPointerLock):Void
	{
		// TODO
        /*if (this.isFullscreen) {
            BABYLON.Tools.ExitFullscreen();
        } else {
            this._pointerLockRequested = requestPointerLock;
            BABYLON.Tools.RequestFullscreen(this._renderingCanvas);
        }*/
    }

	// color can be Color4 or Color3
    public function clear(color:Dynamic, backBuffer:Bool, depthStencil:Bool):Void
	{
		this.applyStates();
		
		GL.clearColor(color.r, color.g, color.b, 1.0);

		if(_depthCullingState.depthMask)
			GL.clearDepth(1.0);
			
        var mode:Int = 0;

        if (backBuffer)
            mode |= GL.COLOR_BUFFER_BIT;

        if (depthStencil && _depthCullingState.depthMask)
            mode |= GL.DEPTH_BUFFER_BIT;

        GL.clear(mode);
    }
    
    public function setViewport(viewport:Viewport, requiredWidth:Float = 0, requiredHeight:Float = 0):Void
	{
        var width = requiredWidth == 0 ? _stage.stageWidth : requiredWidth;
        var height = requiredHeight == 0 ? _stage.stageHeight : requiredHeight;
		
        this._cachedViewport = viewport;
		
		//Logger.log("viewport width:" + Std.int(width * viewport.width) + ",height:" + Std.int(height * viewport.height));
		
        GL.viewport(Std.int(viewport.x * width), Std.int(viewport.y * height),
					Std.int(width * viewport.width), Std.int(height * viewport.height));
		
        this._aspectRatio = (width * viewport.width) / (height * viewport.height);
    }
    
    public function setDirectViewport(x:Int, y:Int, width:Int, height:Int):Void
	{
        this._cachedViewport = null;

        GL.viewport(x, y, width, height);
        this._aspectRatio = width / height;
    }

    public function beginFrame():Void
	{
		_MeasureFps();
		
		//openfl内部可能会修改gl state
		GLUtil.resetGLStates();
		
		#if cpp
		setDepthTest(true);
		setCullState(true);
		setAlphaMode(ALPHA_DISABLE);
		#end
    }
	
	/** clearing GL state to allow mixing with OpenFL display list */
	private function cleanGLStates():Void
	{
		clearProgram();
		
		disableVertexAttribArray();
		_resetVertexBufferBinding();
		_resetIndexBufferBinding();
		
		GL.bindTexture(GL.TEXTURE_2D, null);
		GL.bindTexture(GL.TEXTURE_CUBE_MAP, null);
		
		GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
		
		setCullState(false);
        setDepthTest(false);
		setDepthWrite(true);
		//openfl文本显示时需要用到这种模式
		setAlphaMode(ALPHA_COMBINE);
		
		applyStates();
	}

    public function endFrame():Void
	{
        //this.flushFramebuffer();
		
		#if cpp
		cleanGLStates();
		#end
    }

    public function resize():Void
	{
		// This is handled by OpenFL
        //this._renderingCanvas.width = this._renderingCanvas.clientWidth / this._hardwareScalingLevel;
        //this._renderingCanvas.height = this._renderingCanvas.clientHeight / this._hardwareScalingLevel;   
		
		for (index in 0...scenes.length) 
		{
			var scene:Scene = this.scenes[index];
			for (camIndex in 0...scene.cameras.length)
			{
				var cam:Camera = scene.cameras[camIndex];
				cam._currentRenderId = 0;
			}
		}
    }

    public function bindFramebuffer(texture:BabylonGLTexture):Void
	{
		_currentRenderTarget = texture;
		
        GL.bindFramebuffer(GL.FRAMEBUFFER, texture._framebuffer);
        GL.viewport(0, 0, Std.int(texture._width), Std.int(texture._height));
		
        this._aspectRatio = texture._width / texture._height;

        this.wipeCaches();
    }

    public function unBindFramebuffer(texture:BabylonGLTexture):Void
	{
		_currentRenderTarget = null;
		
        if (texture.generateMipMaps) 
		{
            GL.bindTexture(GL.TEXTURE_2D, texture.data);
            GL.generateMipmap(GL.TEXTURE_2D);
            GL.bindTexture(GL.TEXTURE_2D, null);
        }
		
		GL.bindFramebuffer(GL.FRAMEBUFFER, null);
    }

    public inline function flushFramebuffer():Void
	{
        //GL.flush();
    }

    public function restoreDefaultFramebuffer():Void
	{
		this._currentRenderTarget = null;
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        this.setViewport(this._cachedViewport);
        this.wipeCaches();
    }
	
	private function _resetVertexBufferBinding():Void
	{
		GL.bindBuffer(GL.ARRAY_BUFFER, null);
		this._cachedVertexBuffers = null;
	}
	
	// VBOs
    public function createVertexBuffer(vertices:Array<Float>):BabylonGLBuffer 
	{
        var vbo:GLBuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);
        _resetVertexBufferBinding();
        return new BabylonGLBuffer(vbo);
    }

    public function createDynamicVertexBuffer(capacity:Int):BabylonGLBuffer
	{
        var vbo:GLBuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(capacity), GL.DYNAMIC_DRAW);
        _resetVertexBufferBinding();
        return new BabylonGLBuffer(vbo);
    }

    public function updateDynamicVertexBuffer(vertexBuffer:BabylonGLBuffer, vertices:Dynamic, offset:Int = 0):Void
	{
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer.buffer);

        if (!Std.is(vertices,Array)) 
		{
            GL.bufferSubData(GL.ARRAY_BUFFER, offset, cast vertices);
        } 
		else
		{
            GL.bufferSubData(GL.ARRAY_BUFFER, offset, new Float32Array(vertices));
        }
        
        _resetVertexBufferBinding();
    }
	
	private function _resetIndexBufferBinding():Void
	{
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		this._cachedIndexBuffer = null;
	}

    public function createIndexBuffer(indices:Array<Int>):BabylonGLBuffer
	{
        var vbo:GLBuffer = GL.createBuffer();
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, vbo);
		
		// Check for 32 bits indices
		var arrayBuffer:Dynamic;
		var need32Bits:Bool = false;

		if (_caps.uintIndices)
		{
			for (index in 0...indices.length)
			{
				if (indices[index] > 65535)
				{
					need32Bits = true;
					break;
				}
			}
				
			arrayBuffer = need32Bits ? new Int32Array(indices) : new Int16Array(indices);
		}
		else
		{
			arrayBuffer = new Int16Array(indices);
		}

		GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, arrayBuffer, GL.STATIC_DRAW);
		
		_resetIndexBufferBinding();
		
		return new BabylonGLBuffer(vbo,need32Bits);
    }

    public function bindBuffers(vertexBuffer:BabylonGLBuffer, 
								indexBuffer:BabylonGLBuffer, 
								vertexDeclaration:Array<Int>, 
								vertexStrideSize:Int, effect:Effect):Void
	{
        if (this._cachedVertexBuffers != vertexBuffer || 
			this._cachedEffectForVertexBuffers != effect) 
		{
            this._cachedVertexBuffers = vertexBuffer;
            this._cachedEffectForVertexBuffers = effect;
			
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer.buffer);
			
            var offset:Int = 0;
            for (index in 0...vertexDeclaration.length) 
			{
                var order:Int = effect.getAttributeLocation(index);
                if (order >= 0) 
				{
                    GL.vertexAttribPointer(order, vertexDeclaration[index], GL.FLOAT, false, vertexStrideSize, offset);
                }
                offset += vertexDeclaration[index] * 4;
            }
        }

        if (this._cachedIndexBuffer != indexBuffer)
		{
            this._cachedIndexBuffer = indexBuffer;
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buffer);
			this._uintIndicesCurrentlySet = indexBuffer.is32Bits;
        }
    }

    public function bindMultiBuffers(vertexBuffers:Map<String, VertexBuffer>, 
									indexBuffer:BabylonGLBuffer, effect:Effect):Void
	{
        if (_cachedVertexBuffers != vertexBuffers || 
			_cachedEffectForVertexBuffers != effect)
		{
            _cachedVertexBuffers = vertexBuffers;
            _cachedEffectForVertexBuffers = effect;

            var attributes:Array<String> = effect.getAttributesNames();
			
            for (index in 0...attributes.length)
			{
                var order:Int = effect.getAttributeLocation(index);
                if (order >= 0) 
				{
                    var vertexBuffer:VertexBuffer = vertexBuffers.get(attributes[index]);
					
					if (vertexBuffer == null)
						continue;
					
                    var stride:Int = vertexBuffer.getStrideSize();
                    GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer.getBuffer().buffer);					
                    GL.vertexAttribPointer(order, stride, GL.FLOAT, false, stride * 4, 0);
                }
            }
        }

        if (indexBuffer != null && _cachedIndexBuffer != indexBuffer) 
		{
            _cachedIndexBuffer = indexBuffer;
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buffer);
			this._uintIndicesCurrentlySet = indexBuffer.is32Bits;
        }
    }

    public function releaseBuffer(buffer:BabylonGLBuffer):Bool
	{
        buffer.references--;

        if (buffer.references <= 0) 
		{
            GL.deleteBuffer(buffer.buffer);
			buffer.buffer = null;
			return true;
        }
		
		return false;
    }
	
	#if html5
	public function createInstancesBuffer(capacity: Int): BabylonGLBuffer
	{
		var buffer = GL.createBuffer();

		GL.bindBuffer(GL.ARRAY_BUFFER, buffer);
		untyped GL.context.bufferData(GL.ARRAY_BUFFER, capacity, GL.DYNAMIC_DRAW);
		
		var babylonBuffer = new BabylonGLBuffer(buffer);
		babylonBuffer.capacity = capacity;
		return babylonBuffer;
	}

	public function deleteInstancesBuffer(buffer: BabylonGLBuffer): Void 
	{
		GL.deleteBuffer(buffer.buffer);
		buffer.buffer = null;
	}
	
	public function updateAndBindInstancesBuffer(instancesBuffer: BabylonGLBuffer, data: Float32Array, offsetLocations: Array<Int>): Void 
	{
		GL.bindBuffer(GL.ARRAY_BUFFER, instancesBuffer.buffer);
		GL.bufferSubData(GL.ARRAY_BUFFER, 0, data);

		for (index in 0...4)
		{
			var offsetLocation = offsetLocations[index];
			GL.enableVertexAttribArray(offsetLocation);
			GL.vertexAttribPointer(offsetLocation, 4, GL.FLOAT, false, 64, index * 16);
			_caps.instancedArrays.vertexAttribDivisorANGLE(offsetLocation, 1);
		}
	}
	
	public function unBindInstancesBuffer(instancesBuffer: BabylonGLBuffer, offsetLocations: Array<Int>): Void
	{
		GL.bindBuffer(GL.ARRAY_BUFFER, instancesBuffer.buffer);
		for (index in 0...4)
		{
			var offsetLocation = offsetLocations[index];
			GL.disableVertexAttribArray(offsetLocation);
			this._caps.instancedArrays.vertexAttribDivisorANGLE(offsetLocation, 0);
		}
	}
	#end
	
	public inline function applyStates():Void
	{
		_depthCullingState.apply();
		_alphaState.apply();
	}

    public function draw(useTriangles:Bool, indexStart:Int, indexCount:Int, instancesCount:Int = 0):Void 
	{
		// Apply states
		this.applyStates();
		
		this._drawCalls++;
		
		// Render
		var indexFormat:Int = this._uintIndicesCurrentlySet ? GL.UNSIGNED_INT : GL.UNSIGNED_SHORT;
		
		#if html5
		if (instancesCount > 0)
		{
			_caps.instancedArrays.drawElementsInstancedANGLE(useTriangles ? GL.TRIANGLES : GL.LINES, indexCount, indexFormat, indexStart * 2, instancesCount);
			return;
		}
		#end
			
        GL.drawElements(useTriangles ? GL.TRIANGLES : GL.LINES, indexCount, indexFormat, indexStart * 2);
    }
	
	public function drawPointClouds(verticesStart:Int, verticesCount:Int, instancesCount:Int = 0):Void
	{
		// Apply states
		this.applyStates();
		
		this._drawCalls++;
		
		#if html5
		if (instancesCount > 0)
		{
			_caps.instancedArrays.drawArraysInstancedANGLE(GL.POINTS, verticesStart, verticesCount, instancesCount);
			return;
		}
		#end
		
		GL.drawArrays(GL.POINTS, verticesStart, verticesCount);
	}
	
	public function releaseEffect(effect: Effect): Void
	{
		if (_compiledEffects.exists(effect._key))
		{
			_compiledEffects.remove(effect._key);
			if (effect.getProgram() != null) 
			{
				GL.deleteProgram(effect.getProgram());
			}
			effect.release();
		}
	}
		
	// Shaders
    public function createEffect(baseName:Dynamic, 
								attributesNames:Array<String>, 
								uniformsNames:Array<String>, 
								samplers:Array<String>, 
								defines:String, 
								fallbacks:EffectFallbacks = null,
								onCompiled:Effect->Void = null,
								onError:Effect->String->Void = null):Effect
	{
        var vertex = Reflect.hasField(baseName, "vertex") ? baseName.vertex : baseName;
        var fragment = Reflect.hasField(baseName, "fragment") ? baseName.fragment : baseName;
		        
        var name = vertex + "+" + fragment + "@" + defines;
        if (_compiledEffects.exists(name))
		{
            return _compiledEffects.get(name);
        }

        var effect = new Effect(baseName, attributesNames, uniformsNames, samplers, this, defines, fallbacks, onCompiled, onError);
		effect._key = name;
        _compiledEffects.set(name, effect);

        return effect;
    }
	
	public function createEffectForParticles(fragmentName: String, 
											uniformsNames:Array<String>, 
											samplers:Array<String>, 
											defines:String, 
											fallbacks:EffectFallbacks = null,
											onCompiled:Effect->Void = null,
											onError:Effect->String->Void = null): Effect
	{
		return this.createEffect(
			{
				vertex: "particles",
				fragment: fragmentName
			},
			["position", "color", "options"],
			["view", "projection"].concat(uniformsNames),
			["diffuseSampler"].concat(samplers), defines, fallbacks, onCompiled, onError);
	}
	
	public function getSamplingParameters(samplingMode: Int, generateMipMaps: Bool): { min:Int, mag:Int }	
	{
        var magFilter = GL.NEAREST;
        var minFilter = GL.NEAREST;
        if (samplingMode == Texture.BILINEAR_SAMPLINGMODE)
		{
            magFilter = GL.LINEAR;
            if (generateMipMaps)
			{
                minFilter = GL.LINEAR_MIPMAP_NEAREST;
            } 
			else 
			{
                minFilter = GL.LINEAR;
            }
        } 
		else if (samplingMode == Texture.TRILINEAR_SAMPLINGMODE)
		{
            magFilter = GL.LINEAR;
            if (generateMipMaps) 
			{
                minFilter = GL.LINEAR_MIPMAP_LINEAR;
            } 
			else
			{
                minFilter = GL.LINEAR;
            }
        } 
		else if (samplingMode == Texture.NEAREST_SAMPLINGMODE) 
		{
            magFilter = GL.NEAREST;
            if (generateMipMaps)
			{
                minFilter = GL.NEAREST_MIPMAP_LINEAR;
            } 
			else
			{
                minFilter = GL.NEAREST;
            }
        }

        return {
            min: minFilter,
            mag: magFilter
        };
    }
	
	public function getGLTextureType(type:Int):Int
	{
		if (type == Engine.TEXTURETYPE_FLOAT)
			return GL.FLOAT;
		else
			return GL.UNSIGNED_BYTE;
	}

    public function compileShader(source:String, type:String, defines:String = ""):GLShader 
	{
        var shader:GLShader = GL.createShader(type == "vertex" ? GL.VERTEX_SHADER : GL.FRAGMENT_SHADER);
		
		defines = "precision mediump float;\n" + defines;
		
        GL.shaderSource(shader, defines + "\n" + source);
		
        GL.compileShader(shader);
		
		#if debug
		if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0)
		{
			if (type == "vertex")
				Logger.warn("Error compiling vertex shader");
			else
				Logger.warn("Error compiling fragment shader");
				
			Logger.warn("shaderInfoLog:" + GL.getShaderInfoLog(shader));
		}
		#end

        return shader;
    }

    public function createShaderProgram(vertexCode:String, fragmentCode:String, defines:String):GLProgram
	{					
        var vertexShader:GLShader = compileShader(vertexCode, "vertex", defines);
        var fragmentShader:GLShader = compileShader(fragmentCode, "fragment", defines);

        var shaderProgram:GLProgram = GL.createProgram();
        GL.attachShader(shaderProgram, vertexShader);
        GL.attachShader(shaderProgram, fragmentShader);

        GL.linkProgram(shaderProgram);
		
		#if debug
		if (GL.getProgramParameter(shaderProgram, GL.LINK_STATUS) == 0)
		{
			var error:String = GL.getProgramInfoLog(shaderProgram);
			if (error != "") 
			{
				throw error;
			}
		}
		#end

        GL.deleteShader(vertexShader);
        GL.deleteShader(fragmentShader);

        return shaderProgram;
    }

    public function getUniforms(shaderProgram:GLProgram, uniformsNames:Array<String>):Array<GLUniformLocation> 
	{
        var results:Array<GLUniformLocation> = [];

        for (index in 0...uniformsNames.length) 
		{
            results.push(GL.getUniformLocation(shaderProgram, uniformsNames[index]));
        }

        return results;
    }

    public function getAttributes(shaderProgram:GLProgram, attributesNames:Array<String>):Array<Int> 
	{
        var results:Array<Int> = [];

        for (index in 0...attributesNames.length)
		{
            try 
			{
				results.push(GL.getAttribLocation(shaderProgram, attributesNames[index]));
            } 
			catch (e:Dynamic)
			{
				Logger.log("getAttributes() -> ERROR: " + e);
                results.push(-1);
            }
        }

        return results;
    }
	
	public function clearProgram():Void
	{
		GL.useProgram(null);
		_currentEffect = null;
	}
	
	public function disableVertexAttribArray():Void
	{
		for (i in 0..._vertexAttribArrays.length)
		{
			var loc:Int = _vertexAttribArrays[i];
			GL.disableVertexAttribArray(loc);
		}
		_vertexAttribArrays = [];
	}

    public function enableEffect(effect:Effect):Void
	{
		if (effect == null || effect.getAttributesCount() == 0 || _currentEffect == effect)
		{
			if (effect != null && effect.onBind != null)
			{
				effect.onBind(effect);
			}
			return;
		}
		
        // Use program
        GL.useProgram(effect.getProgram());
		
		//disableVertexAttribArray();
        //for (i in 0...attributesCount) 
		//{
            //// Attributes
            //var order:Int = effect.getAttribute(i);
            //if (order >= 0)
			//{
				//_vertexAttribArrays.push(order);
				//GL.enableVertexAttribArray(order);
            //}
        //}
		
		//only active not actived vertex attribute
		var attributesCount:Int = effect.getAttributesCount();
        for (i in 0...attributesCount) 
		{
            // Attributes
            var order:Int = effect.getAttributeLocation(i);
            if (order >= 0)
			{
				var index:Int = _vertexAttribArrays.indexOf(order);
				if (index == -1)
				{
					GL.enableVertexAttribArray(order);
				}
				else
				{
					_vertexAttribArrays.splice(index, 1);
				}
            }
        }
		
		//only disable not used vertex attribute
		for (i in 0..._vertexAttribArrays.length) 
		{
			if(_vertexAttribArrays[i] >= 0)
				GL.disableVertexAttribArray(_vertexAttribArrays[i]);
        }
		
		_vertexAttribArrays = effect.getAttributes().slice(0);
		

        this._currentEffect = effect;
		
		if (effect.onBind != null)
		{
			effect.onBind(effect);
		}
    }
	
	public function setArray(uniform:GLUniformLocation, array:Array<Float>):Void
	{
		if (uniform == null)
			return;
			
		GL.uniform1fv(uniform, new Float32Array(array));
	}
	
	public function setArray2(uniform:GLUniformLocation, array:Array<Float>):Void
	{
		if (uniform == null || array.length % 2 != 0)
			return;
			
		GL.uniform2fv(uniform, new Float32Array(array));
	}
	
	public function setArray3(uniform:GLUniformLocation, array:Array<Float>):Void
	{
		if (uniform == null || array.length % 3 != 0)
			return;
			
		GL.uniform3fv(uniform, new Float32Array(array));
	}
	
	public function setArray4(uniform:GLUniformLocation, array:Array<Float>):Void
	{
		if (uniform == null || array.length % 4 != 0)
			return;
			
		GL.uniform4fv(uniform, new Float32Array(array));
	}

    public inline function setMatrices(uniform:GLUniformLocation, matrices: #if html5 Float32Array #else Array<Float> #end ):Void
	{
        if (uniform != null)
		{
			GL.uniformMatrix4fv(uniform, false, #if html5 matrices #else new Float32Array(matrices) #end );
		}
    }

    public inline function setMatrix(uniform:GLUniformLocation, matrix:Matrix):Void
	{
        if (uniform != null) 
		{
			GL.uniformMatrix4fv(uniform, false, #if html5 matrix.toArray() #else new Float32Array(matrix.toArray()) #end );
		}
    }
    
    public inline function setFloat(uniform:GLUniformLocation, value:Float):Void
	{
        if (uniform != null) 
		{
			GL.uniform1f(uniform, value);
		}
    }

    public inline function setFloat2(uniform:GLUniformLocation, x:Float, y:Float):Void
	{
        if (uniform != null) 
		{
			GL.uniform2f(uniform, x, y);
		}
    }

    public inline function setFloat3(uniform:GLUniformLocation, x:Float, y:Float, z:Float):Void
	{
        if (uniform != null) 
		{
			GL.uniform3f(uniform, x, y, z);
		}
    }
    
    public inline function setBool(uniform:GLUniformLocation, bool:Bool):Void 
	{
        if (uniform != null)
		{
			GL.uniform1i(uniform, bool ? 1 : 0);
		}
    }

    public inline function setFloat4(uniform:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void
	{
        if (uniform != null) 
		{
			GL.uniform4f(uniform, x, y, z, w);
		}
    }

    public inline function setColor3(uniform:GLUniformLocation = null, color3:Color3):Void
	{
        if (uniform != null)
		{
			GL.uniform3f(uniform, color3.r, color3.g, color3.b);
		}
    }

    public inline function setColor4(uniform:GLUniformLocation = null, color3:Color3, alpha:Float):Void
	{
        if (uniform != null) 
		{
			GL.uniform4f(uniform, color3.r, color3.g, color3.b, alpha);
		}
    }
	
	
	// States
    public function setCullState(culling:Bool,zOffset:Float=0, force:Bool = false):Void
	{
        // Culling        
		if (_depthCullingState.cull != culling || force) 
		{
			if (culling)
			{
				_depthCullingState.cullFace = this.cullBackFaces ? GL.BACK : GL.FRONT;
				_depthCullingState.cull = true;
			} 
			else
			{
				_depthCullingState.cull = false;
			}
		}
		
		// Z offset
		this._depthCullingState.zOffset = zOffset;
    }

    public function setDepthTest(enable:Bool):Void
	{
		_depthCullingState.depthTest = enable;
    }

    public function setDepthWrite(enable:Bool):Void
	{
        _depthCullingState.depthMask = enable;
    }
	
	public function getDepthWrite(): Bool
	{
		return _depthCullingState.depthMask;
	}

    public function setColorWrite(enable:Bool):Void
	{
        GL.colorMask(enable, enable, enable, enable);
    }

    public function setAlphaMode(mode:Int):Void
	{
        switch (mode)
		{
            case Engine.ALPHA_DISABLE:
                setDepthWrite(true);
				_alphaState.alphaBlend = false;
				
            case Engine.ALPHA_COMBINE:
                setDepthWrite(false);
                _alphaState.setAlphaBlendFunctionParameters(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA, GL.ONE, GL.ONE);
				_alphaState.alphaBlend = true;
                
            case Engine.ALPHA_ADD:
                setDepthWrite(false);
                _alphaState.setAlphaBlendFunctionParameters(GL.ONE, GL.ONE, GL.ZERO, GL.ONE);
				_alphaState.alphaBlend = true;
                
        }
		
		this._alphaMode = mode;
    }
	
	public function getAlphaMode(): Int
	{
		return this._alphaMode;
	}

    public function setAlphaTesting(enable:Bool):Void
	{
        this._alphaTest = enable;
    }

    public function getAlphaTesting():Bool
	{
        return this._alphaTest;
    }

    // Textures
    public function wipeCaches():Void
	{
        this._activeTexturesCache = [];
        this._currentEffect = null;

		this._depthCullingState.reset();
		this._alphaState.reset();

		this._cachedVertexBuffers = null;
        this._cachedVertexBuffers = null;
        this._cachedEffectForVertexBuffers = null;
    }
	
	private function getScaled(source:BitmapData, newWidth:Int, newHeight:Int):BitmapData
	{
		var m:openfl.geom.Matrix = new openfl.geom.Matrix();
		m.scale(newWidth / source.width, newHeight / source.height);
		var bmp:BitmapData = new BitmapData(newWidth, newHeight, true);
		bmp.draw(source, m);
		return bmp;
	}
	
	public function setSamplingMode(texture: BabylonGLTexture, samplingMode: Int): Void 
	{
		GL.bindTexture(GL.TEXTURE_2D, texture.data);

		var magFilter = GL.NEAREST;
		var minFilter = GL.NEAREST;

		if (samplingMode == Texture.BILINEAR_SAMPLINGMODE)
		{
			magFilter = GL.LINEAR;
			minFilter = GL.LINEAR;
		} 
		else if (samplingMode == Texture.TRILINEAR_SAMPLINGMODE)
		{
			magFilter = GL.LINEAR;
			minFilter = GL.LINEAR_MIPMAP_LINEAR;
		}

		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, magFilter);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, minFilter);

		GL.bindTexture(GL.TEXTURE_2D, null);

		texture.samplingMode = samplingMode;
	}

    public function createTexture(url:String, 
									noMipmap:Bool = false, 
									invertY:Bool = true,
									scene:Scene = null,
									samplingMode:Int = Texture.TRILINEAR_SAMPLINGMODE,
									onLoad:Void->Void = null, onError:Void->Void = null):BabylonGLTexture
									
	{
		var extension: String;
		var fromData: Bool = false;
		if (url.substr(0, 5) == "data:")
		{
			fromData = true;
		}
		
		if (!fromData)
			extension = url.substr(url.length - 4, 4).toLowerCase();
		else 
		{
			var oldUrl:String = url;
			var data:Array<String> = oldUrl.split(':');
			url = oldUrl;
			extension = data[1].substr(data[1].length - 4, 4).toLowerCase();
		}
			
        var texture:BabylonGLTexture = new BabylonGLTexture(url, GL.createTexture());
		
		function onLoadError():Void
		{
			scene._removePendingData(texture);
			
			if (onError != null)
			{
				onError();
			}
		}
		            
        var onLoadSuccess = function(bitmapData:BitmapData):Void
		{
            //this.setTextureData(texture, img, noMipmap, invertY, scene, samplingMode);
			var potWidth = FastMath.getExponantOfTwo(bitmapData.width, _caps.maxTextureSize);
			var potHeight = FastMath.getExponantOfTwo(bitmapData.height, _caps.maxTextureSize);
			var isPot = (bitmapData.width == potWidth && bitmapData.height == potHeight);
			
			var curBitmapData:BitmapData = bitmapData;

			if (!isPot) 
			{
				_workingCanvas = getScaled(bitmapData, Std.int(potWidth/2), Std.int(potHeight/2));
			}
			
			// IMAGE FLIPPING IS ONLY SUPPORTED IN WebGL
			#if html5
			GL.pixelStorei(GL.UNPACK_FLIP_Y_WEBGL, invertY ? 1 : 0);
			#else
			if(invertY)
				curBitmapData = BitmapDataUtils.flipBitmapData(curBitmapData, false, true);
			#end
												
			var pixelData = BitmapDataUtils.getPixelData(curBitmapData);
						
			GL.bindTexture(GL.TEXTURE_2D, texture.data);

			GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, curBitmapData.width, curBitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);
			
			var filters = getSamplingParameters(samplingMode, !noMipmap);
			
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, filters.mag);
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, filters.min);
			
			//Non-power-of-2 texture disable mippmapping 
			if (!isPot)
				noMipmap = true;

			if (!noMipmap)
			{
				GL.generateMipmap(GL.TEXTURE_2D);
			}
			
			GL.bindTexture(GL.TEXTURE_2D, null);

			_activeTexturesCache = [];
			texture._baseWidth = bitmapData.width;
			texture._baseHeight = bitmapData.height;
			texture._width = potWidth;
			texture._height = potHeight;
			texture.isReady = true;
			texture.samplingMode = samplingMode;
			scene._removePendingData(texture);
			
			if (onLoad != null)
			{
				onLoad();
			}
        }

        scene._addPendingData(texture);
		texture.url = url;
        texture.noMipmap = noMipmap;
        texture.references = 1;
		texture.samplingMode = samplingMode;
		
        _loadedTexturesCache.push(texture);
		
        Tools.LoadImage(url, onLoadSuccess, onLoadError);

        return texture;
    }

    public function createDynamicTexture(width:Float, height:Float, generateMipMaps:Bool, samplingMode:Int):BabylonGLTexture
	{
        var texture:BabylonGLTexture = new BabylonGLTexture("", GL.createTexture());

        var nw:Int = FastMath.getExponantOfTwo(Std.int(width), _caps.maxTextureSize);
        var nh:Int = FastMath.getExponantOfTwo(Std.int(height), _caps.maxTextureSize);

        _activeTexturesCache = [];
        texture._baseWidth = nw;
        texture._baseHeight = nh;
        texture._width = nw;
        texture._height = nh;
        texture.isReady = false;
        texture.generateMipMaps = generateMipMaps;
		texture.samplingMode = samplingMode;
        texture.references = 1;

        _loadedTexturesCache.push(texture);
		
		this.updateTextureSamplingMode(samplingMode, texture);

        return texture;
    }
	
	public function updateTextureSamplingMode(samplingMode: Int, texture: BabylonGLTexture): Void 
	{
		var filters = getSamplingParameters(samplingMode, texture.generateMipMaps);

		GL.bindTexture(GL.TEXTURE_2D, texture.data);

		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, filters.mag);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, filters.min);
		GL.bindTexture(GL.TEXTURE_2D, null);
	}

    public function updateDynamicTexture(texture:BabylonGLTexture, canvas:BitmapData, invertY:Bool):Void
	{
        GL.bindTexture(GL.TEXTURE_2D, texture.data);
		
		// IMAGE FLIPPING IS ONLY SUPPORTED IN WebGL
		#if html5
		GL.pixelStorei(GL.UNPACK_FLIP_Y_WEBGL, invertY ? 1 : 0);
		#else
		if(invertY)
			canvas = BitmapDataUtils.flipBitmapData(canvas, false, true);
		#end

		var pixelData = BitmapDataUtils.getPixelData(canvas);
		
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, canvas.width, canvas.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, cast pixelData);
		
        if (texture.generateMipMaps) 
		{
            GL.generateMipmap(GL.TEXTURE_2D);
        }
        GL.bindTexture(GL.TEXTURE_2D, null);
        _activeTexturesCache = [];
        texture.isReady = true;
    }

    public function updateVideoTexture(texture:BabylonGLTexture, video:Dynamic, invertY: Bool):Void
	{
		// TODO
        /*GL.bindTexture(GL.TEXTURE_2D, texture.data);
        GL.pixelStorei(GL.UNPACK_FLIP_Y_WEBGL, false);

        // Scale the video if it is a NPOT
        if (video.videoWidth !== texture._width || video.videoHeight !== texture._height) {
            if (!texture._workingCanvas) {
                texture._workingCanvas = document.createElement("canvas");
                texture._workingContext = texture._workingCanvas.getContext("2d");
                texture._workingCanvas.width = texture._width;
                texture._workingCanvas.height = texture._height;
            }

            texture._workingContext.drawImage(video, 0, 0, video.videoWidth, video.videoHeight, 0, 0, texture._width, texture._height);

            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, texture._workingCanvas);
        } else {
            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, video);
        }

        if (texture.generateMipMaps) {
            GL.generateMipmap(GL.TEXTURE_2D);
        }

        GL.bindTexture(GL.TEXTURE_2D, null);
        _activeTexturesCache = [];
        texture.isReady = true;*/
    }

    public function createRenderTargetTexture(width:Int, height:Int, options:Dynamic):BabylonGLTexture
	{
        var generateMipMaps:Bool = false;
        var generateDepthBuffer:Bool = true;
        var samplingMode:Int = Texture.TRILINEAR_SAMPLINGMODE;
		var type:Int = Engine.TEXTURETYPE_UNSIGNED_INT;
        if (options != null) 
		{
            generateMipMaps = Reflect.hasField(options, "generateMipMaps") ? options.generateMipMaps : options;
            generateDepthBuffer = Reflect.field(options, "generateDepthBuffer") ? options.generateDepthBuffer : true;
			
			if (Reflect.hasField(options, "type")) 
			{
                type = options.type;
            }
			
            if (Reflect.hasField(options, "samplingMode")) 
			{
                samplingMode = options.samplingMode;
            }
			
			if (type == Engine.TEXTURETYPE_FLOAT)
			{
				// if floating point (gl.FLOAT) then force to NEAREST_SAMPLINGMODE
				samplingMode = Texture.NEAREST_SAMPLINGMODE;
			}
        }
		
		#if debug
		Logger.log("createRenderTargetTexture: width:" + width + ",height:" + height);
		#end
		
		if (type == Engine.TEXTURETYPE_FLOAT && !this._caps.textureFloat)
		{
			type = Engine.TEXTURETYPE_UNSIGNED_INT;
			Logger.warn("Float textures are not supported. Render target forced to TEXTURETYPE_UNSIGNED_BYTE type");
		}
		
        var texture:BabylonGLTexture = new BabylonGLTexture("", GL.createTexture());
        GL.bindTexture(GL.TEXTURE_2D, texture.data);

        var filters = getSamplingParameters(samplingMode, generateMipMaps);
		
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, filters.mag);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, filters.min);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, getGLTextureType(type), null);

        var depthBuffer:GLRenderbuffer = null;
        // Create the depth buffer
        if (generateDepthBuffer)
		{
            depthBuffer = GL.createRenderbuffer();
            GL.bindRenderbuffer(GL.RENDERBUFFER, depthBuffer);
            GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);
        }
		
        // Create the framebuffer
        var framebuffer:GLFramebuffer = GL.createFramebuffer();
        GL.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.data, 0);
        if (generateDepthBuffer)
		{
            GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, depthBuffer);
        }

        // Unbind
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);

        texture._framebuffer = framebuffer;
        if (generateDepthBuffer) 
		{
            texture._depthBuffer = depthBuffer;
        }
        texture._width = width;
        texture._height = height;
        texture.isReady = true;
        texture.generateMipMaps = generateMipMaps;
		texture.samplingMode = samplingMode;
        texture.references = 1;
		
        _activeTexturesCache = [];
		
        _loadedTexturesCache.push(texture);

        return texture;
    }
	
	private static var faces = [
                GL.TEXTURE_CUBE_MAP_POSITIVE_X, GL.TEXTURE_CUBE_MAP_POSITIVE_Y, GL.TEXTURE_CUBE_MAP_POSITIVE_Z,
                GL.TEXTURE_CUBE_MAP_NEGATIVE_X, GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, GL.TEXTURE_CUBE_MAP_NEGATIVE_Z
            ];
	public function createCubeTexture(rootUrl:String, scene:Scene, extensions:Array<String> = null, noMipmap:Bool = false):BabylonGLTexture 
	{	
		var texture = new BabylonGLTexture(rootUrl, GL.createTexture());
        texture.isCube = true;
        texture.url = rootUrl;
        texture.references = 1;
        texture.isReady = false;

		_activeTexturesCache = [];
		
		_loadedTexturesCache.push(texture);
		
		function onAllLoad(bitmapDatas:Array<BitmapData>):Void
		{
			GL.bindTexture(GL.TEXTURE_CUBE_MAP, texture.data);	
		
			GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
			
			//Logger.log("cube texture:"+bitmapDatas.length);
			for (i in 0...bitmapDatas.length)
			{
				var img:BitmapData = bitmapDatas[i];				
					
				var potWidth = FastMath.getExponantOfTwo(img.width, _caps.maxTextureSize);
				var potHeight = FastMath.getExponantOfTwo(img.height, _caps.maxTextureSize);
				var isPot = (img.width == potWidth && img.height == potHeight);
				_workingCanvas = img;
				
				if (!isPot) 
				{
					_workingCanvas = getScaled(img, Std.int(potWidth/2), Std.int(potHeight/2));
				}
				
				#if html5
				GL.pixelStorei(GL.UNPACK_FLIP_Y_WEBGL, 0);
				#end
				
				var pixelData = BitmapDataUtils.getPixelData(_workingCanvas);				
				GL.texImage2D(faces[i], 0, GL.RGBA, _workingCanvas.width, _workingCanvas.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);
			}
			
			GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
			
			GL.generateMipmap(GL.TEXTURE_CUBE_MAP);
			GL.bindTexture(GL.TEXTURE_CUBE_MAP, null);
			
			texture.isReady = true;
		}
		
		Tools.LoadCubeImages(rootUrl, onAllLoad);
		
		return texture;
	}   

    public function releaseTexture(texture:BabylonGLTexture):Void
	{
        if (texture._framebuffer != null) 
		{
            GL.deleteFramebuffer(texture._framebuffer);
        }

        if (texture._depthBuffer != null) 
		{
            GL.deleteRenderbuffer(texture._depthBuffer);
        }

        GL.deleteTexture(texture.data);

        // Unbind channels
        for (channel in 0..._caps.maxTexturesImageUnits)
		{
			GLUtil.activeTexture(getGLTexture(channel));
            GL.bindTexture(GL.TEXTURE_2D, null);
            GL.bindTexture(GL.TEXTURE_CUBE_MAP, null);
            _activeTexturesCache[channel] = null;
        }

        var index:Int = _loadedTexturesCache.indexOf(texture);
        if (index != -1)
		{
            _loadedTexturesCache.splice(index, 1);
        }
    }

    public function bindSamplers(effect:Effect):Void
	{
        GL.useProgram(effect.getProgram());
        var samplers:Array<String> = effect.getSamplers();
        for (index in 0...samplers.length)
		{
            var uniform = effect.getUniform(samplers[index]);
            GL.uniform1i(uniform, index);
        }
        _currentEffect = null;
    }


    public function bindTexture(channel:Int, texture:BabylonGLTexture):Void
	{
		GLUtil.activeTexture(getGLTexture(channel));
        GL.bindTexture(GL.TEXTURE_2D, texture.data);	        
        _activeTexturesCache[channel] = null;
    }

    public function setTextureFromPostProcess(channel:Int, postProcess:PostProcess):Void
	{
        bindTexture(channel, postProcess.textures[postProcess._currentRenderTextureId]);
    }
	
	private inline function getGLTexture(channel:Int):Int 
	{
		return GL.TEXTURE0 + channel;
	}

    public function setTexture(channel:Int, texture:BaseTexture):Void
	{
        if (channel < 0)
		{
            return;
        }
		
        // Not ready?
        if (texture == null || !texture.isReady())
		{
            if (_activeTexturesCache[channel] != null)
			{					
				GLUtil.activeTexture(getGLTexture(channel));
                GL.bindTexture(GL.TEXTURE_2D, null);
                GL.bindTexture(GL.TEXTURE_CUBE_MAP, null);
                _activeTexturesCache[channel] = null;
            }
            return;
        }

        // Video
		if (Std.is(texture, VideoTexture))
		{
			return;
			
            //if (texture._update()) 
			//{
                //_activeTexturesCache[channel] = null;
            //}
        } 
		//// Delay loading
		else if (texture.delayLoadState == Engine.DELAYLOADSTATE_NOTLOADED)
		{ 
            texture.delayLoad();
            return;
        }

        if (_activeTexturesCache[channel] == texture)
		{
            return;
        }
		
        _activeTexturesCache[channel] = texture;

        var internalTexture:BabylonGLTexture = texture.getInternalTexture();
		GLUtil.activeTexture(getGLTexture(channel));
		
        if (internalTexture.isCube)
		{
            GL.bindTexture(GL.TEXTURE_CUBE_MAP, internalTexture.data);		
			
			if (internalTexture._cachedCoordinatesMode != texture.coordinatesMode)
			{
                    internalTexture._cachedCoordinatesMode = texture.coordinatesMode;
                    // CUBIC_MODE and SKYBOX_MODE both require CLAMP_TO_EDGE.  All other modes use REPEAT.
                    var textureWrapMode = (texture.coordinatesMode != Texture.CUBIC_MODE &&
											texture.coordinatesMode != Texture.SKYBOX_MODE) ? GL.REPEAT : GL.CLAMP_TO_EDGE;
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, textureWrapMode);
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, textureWrapMode);
                }

            setAnisotropicLevel(GL.TEXTURE_CUBE_MAP, texture);
        } 
		else 
		{
            GL.bindTexture(GL.TEXTURE_2D, internalTexture.data);

            if (internalTexture._cachedWrapU != texture.wrapU)
			{
                internalTexture._cachedWrapU = texture.wrapU;
				
                switch (texture.wrapU)
				{
                    case Texture.WRAP_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
						
                    case Texture.CLAMP_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
						
                    case Texture.MIRROR_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.MIRRORED_REPEAT);
						
                }
            }

            if (internalTexture._cachedWrapV != texture.wrapV) 
			{
                internalTexture._cachedWrapV = texture.wrapV;
                switch (texture.wrapV) 
				{
                    case Texture.WRAP_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
                        
                    case Texture.CLAMP_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                        
                    case Texture.MIRROR_ADDRESSMODE:
                        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.MIRRORED_REPEAT);
                        
                }
            }

            setAnisotropicLevel(GL.TEXTURE_2D, texture);
        }
    }

    public function setAnisotropicLevel(key:Int, texture:BaseTexture):Void
	{
        var anisotropicFilterExtension = _caps.textureAnisotropicFilterExtension;
		
        if (anisotropicFilterExtension != null && 
			texture._cachedAnisotropicFilteringLevel != texture.anisotropicFilteringLevel)
		{
            GL.texParameterf(key, anisotropicFilterExtension.TEXTURE_MAX_ANISOTROPY_EXT, 
							Math.min(texture.anisotropicFilteringLevel, _caps.maxAnisotropy));
            texture._cachedAnisotropicFilteringLevel = texture.anisotropicFilteringLevel;
        }
    }
	
	//openfl中js和cpp中readPixels参数不一样，待测试
	//public function readPixels(x: Int, y: Int, width: Int, height: Int): UInt8Array
	//{
		//var data = new UInt8Array(height * width * 4);
		//GL.readPixels(x, y, width, height, GL.RGBA, GL.UNSIGNED_BYTE, data);
		//return data;
	//}

    // Dispose
    public function dispose():Void
	{
		stopRenderLoop();
		
		// Unbind
		disableVertexAttribArray();

        // Release effects
        for (effect in _compiledEffects)
		{
            GL.deleteProgram(effect.getProgram());
        }
    }
	
}
