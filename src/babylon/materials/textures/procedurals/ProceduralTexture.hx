package babylon.materials.textures.procedurals;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.textures.ISize;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Color4;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.mesh.BabylonGLBuffer;
import babylon.Scene;
import haxe.ds.StringMap;

/**
 * ...
 * @author weilichuang
 */
class ProceduralTexture extends Texture
{
	private var _size: Int;
	public var _generateMipMaps: Bool;
	private var _doNotChangeAspectRatio: Bool;
	private var _currentRefreshId:Int = -1;
	private var _refreshRate:Int = 1;

	private var _vertexBuffer: BabylonGLBuffer;
	private var _indexBuffer: BabylonGLBuffer;
	private var _effect: Effect;

	private var _vertexDeclaration:Array<Int> = [2];
	private var _vertexStrideSize:Int = 2 * 4;

	private var _uniforms:Array<String> = new Array<String>();
	private var _samplers:Array<String> = new Array<String>();
	private var _fragment: String;

	private var _textures:StringMap<Texture> = new StringMap<Texture>();
	private var _floats:StringMap<Float> = new StringMap<Float>();
	private var _floatsArrays:StringMap<Array<Float>> = new StringMap<Array<Float>>();
	private var _colors3:StringMap<Color3> = new StringMap<Color3>();
	private var _colors4:StringMap<Color4> = new StringMap<Color4>();
	private var _vectors2:StringMap<Vector2> = new StringMap<Vector2>();
	private var _vectors3:StringMap<Vector3> = new StringMap<Vector3>();
	private var _matrices:StringMap<Matrix> = new StringMap<Matrix>();

	private var _fallbackTexture: Texture;

	public function new(name:String, size:Int, fragment:String, scene:Scene, fallbackTexture:Texture = null, generateMipMaps:Bool = false)
	{
		super(null, scene, !generateMipMaps);
		
		scene._proceduralTextures.push(this);
		
		this.name = name;
		this.isRenderTarget = true;
		this._size = size;
		this._generateMipMaps = generateMipMaps;
		
		this._fragment = fragment;
		
		this._fallbackTexture = fallbackTexture;
		
		//VBO
		var vertices:Array<Float> = [1., 1, -1, 1, -1, -1, 1, -1];
		
		this._vertexBuffer = scene.getEngine().createVertexBuffer(vertices);
		
		//Indices
		var indices:Array<Int> = [0, 1, 2, 0, 2, 3];
		this._indexBuffer = scene.getEngine().createIndexBuffer(indices);
	}
	
	public function setFragment(fragment: String):Void
	{
		this._fragment = fragment;
	}
	
	override public function isReady():Bool
	{
		var engine:Engine = this.getScene().getEngine();

		this._effect = engine.createEffect({ vertex: "procedural", fragment: this._fragment },
			["position"],
			this._uniforms,
			this._samplers,
			"", null, null, function(effect:Effect,errorMsg:String):Void {
				this.releaseInternalTexture();

				this._texture = this._fallbackTexture._texture;
				this._texture.references++;
			});

		return this._effect.isReady();
	}
	
	public function resetRefreshCounter(): Void 
	{
		this._currentRefreshId = -1;
	}
	
	public var refreshRate(get, set):Int;
	private function get_refreshRate():Int
	{
		return _refreshRate;
	}
	
	private function set_refreshRate(value:Int):Int
	{
		_refreshRate = value;
		resetRefreshCounter();
		return _refreshRate;
	}
	
	public function _shouldRender():Bool
	{
		if (!this.isReady() || this._texture == null)
		{
			return false;
		}

		if (this._currentRefreshId == -1) // At least render once
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
		this._texture = this.getScene().getEngine().createRenderTargetTexture(size, size, generateMipMaps);
	}

	private function _checkUniform(uniformName:String): Void
	{
		if (this._uniforms.indexOf(uniformName) == -1)
		{
			this._uniforms.push(uniformName);
		}
	}

	public function setTexture(name: String, texture: Texture): ProceduralTexture 
	{
		if (this._samplers.indexOf(name) == -1)
		{
			this._samplers.push(name);
		}
		this._textures.set(name, texture);

		return this;
	}

	public function setFloat(name: String, value: Float): ProceduralTexture 
	{
		this._checkUniform(name);
		this._floats.set(name,value);

		return this;
	}

	public function setFloats(name: String, value: Array<Float>): ProceduralTexture
	{
		this._checkUniform(name);
		this._floatsArrays.set(name,value);

		return this;
	}

	public function setColor3(name: String, value: Color3): ProceduralTexture 
	{
		this._checkUniform(name);
		this._colors3.set(name,value);

		return this;
	}

	public function setColor4(name: String, value: Color4): ProceduralTexture 
	{
		this._checkUniform(name);
		this._colors4.set(name,value);

		return this;
	}

	public function setVector2(name: String, value: Vector2): ProceduralTexture
	{
		this._checkUniform(name);
		this._vectors2.set(name,value);

		return this;
	}

	public function setVector3(name: String, value: Vector3): ProceduralTexture
	{
		this._checkUniform(name);
		this._vectors3.set(name,value);

		return this;
	}

	public function setMatrix(name: String, value: Matrix): ProceduralTexture
	{
		this._checkUniform(name);
		this._matrices.set(name,value);

		return this;
	}

	public function render(useCameraPostProcess: Bool = false):Void
	{
		var scene:Scene = this.getScene();
		var engine:Engine = scene.getEngine();

		engine.bindFramebuffer(this._texture);

		// Clear
		engine.clear(scene.clearColor, true, true);

		// Render
		engine.enableEffect(this._effect);
		engine.setCullState(false);

		// Texture
		var keys = _textures.keys();
		for (name in keys)
		{
			this._effect.setTexture(name, this._textures.get(name));
		}

		// Float    
		keys = _floats.keys();
		for (name in keys)
		{
			this._effect.setFloat(name, this._floats.get(name));
		}

		// Float s   
		keys = _floatsArrays.keys();
		for (name in keys)
		{
			this._effect.setArray(name, this._floatsArrays.get(name));
		}

		// Color3        
		keys = _colors3.keys();
		for (name in keys)
		{
			this._effect.setColor3(name, this._colors3.get(name));
		}

		// Color4      
		keys = _colors4.keys();
		for (name in keys)
		{
			var color = this._colors4.get(name);
			this._effect.setFloat4(name, color.r, color.g, color.b, color.a);
		}

		// Vector2        
		keys = _vectors2.keys();
		for (name in keys)
		{
			this._effect.setVector2(name, this._vectors2.get(name));
		}

		// Vector3        
		keys = _vectors3.keys();
		for (name in keys)
		{
			this._effect.setVector3(name, this._vectors3.get(name));
		}

		// Matrix      
		keys = _matrices.keys();
		for (name in keys)
		{
			this._effect.setMatrix(name, this._matrices.get(name));
		}

		// VBOs
		engine.bindBuffers(this._vertexBuffer, this._indexBuffer, this._vertexDeclaration, this._vertexStrideSize, this._effect);

		// Draw order
		engine.draw(true, 0, 6);

		// Unbind
		engine.unBindFramebuffer(this._texture);
	}

	override public function clone(): BaseTexture
	{
		var textureSize:ISize = this.getSize();
		var newTexture = new ProceduralTexture(this.name, Std.int(textureSize.width), this._fragment, this.getScene(), this._fallbackTexture, this._generateMipMaps);

		// Base texture
		newTexture.hasAlpha = this.hasAlpha;
		newTexture.level = this.level;

		// RenderTarget Texture
		newTexture.coordinatesMode = this.coordinatesMode;

		return newTexture;
	}

	override public function dispose(): Void 
	{
		this.getScene()._proceduralTextures.remove(this);
		super.dispose();
	}
}