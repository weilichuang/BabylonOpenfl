package babylon.materials;

import babylon.Engine;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Color4;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.Scene;

class ShaderMaterial extends Material
{
	private var _shaderPath: Dynamic;
	private var _options: Dynamic;
	private var _textures:Map<String,Texture>;
	private var _floats:Map<String,Float>;
	private var _floatsArrays:Map<String,Array<Float>>;
	private var _colors3:Map<String,Color3>;
	private var _colors4:Map<String,Color4>;
	private var _vectors2:Map<String,Vector2>;
	private var _vectors3:Map<String,Vector3>;
	private var _matrices:Map<String,Matrix>;
	private var _cachedWorldViewMatrix:Matrix;
		
	public function new(name:String, scene:Scene, shaderPath:Dynamic, options:Dynamic) 
	{
		super(name, scene);
		
		_shaderPath = shaderPath;
		
		if (options.needAlphaBlending == null)
			options.needAlphaBlending = false;
		
		if (options.needAlphaTesting == null)
			options.needAlphaTesting = false;
		
		if (options.attributes == null)
			options.attributes = ["position", "normal", "uv"];
			
		if (options.uniforms == null)
			options.uniforms = ["worldViewProjection"];
			
		if (options.samplers == null)
			options.samplers = [];
		
		_options = options;
		
		_textures = new Map<String,Texture>();
		_floats = new Map<String,Float>();
		_floatsArrays = new Map<String,Array<Float>>();
		_colors3 = new Map<String,Color3>();
		_colors4 = new Map<String,Color4>();
		_vectors2 = new Map<String,Vector2>();
		_vectors3 = new Map<String,Vector3>();
		_matrices = new Map<String,Matrix>();
		_cachedWorldViewMatrix = new Matrix();
	}
	
	override public function needAlphaBlending(): Bool 
	{
		return _options.needAlphaBlending;
	}

	override public function needAlphaTesting(): Bool
	{
		return _options.needAlphaTesting;
	}

	private function _checkUniform(uniformName:String): Void 
	{
		if (_options.uniforms.indexOf(uniformName) == -1)
		{
			_options.uniforms.push(uniformName);
		}
	}

	public function setTexture(name: String, texture: Texture): ShaderMaterial
	{
		if (_options.samplers.indexOf(name) == -1)
		{
			_options.samplers.push(name);
		}
		_textures.set(name, texture);

		return this;
	}

	public function setFloat(name: String, value: Float): ShaderMaterial
	{
		_checkUniform(name);
		_floats.set(name, value);

		return this;
	}

	public function setFloats(name: String, value: Array<Float>): ShaderMaterial 
	{
		_checkUniform(name);
		_floatsArrays.set(name, value);

		return this;
	}

	public function setColor3(name: String, value: Color3): ShaderMaterial
	{
		_checkUniform(name);
		_colors3.set(name, value);

		return this;
	}

	public function setColor4(name: String, value: Color4): ShaderMaterial
	{
		_checkUniform(name);
		_colors4.set(name, value);

		return this;
	}

	public function setVector2(name: String, value: Vector2): ShaderMaterial 
	{
		_checkUniform(name);
		_vectors2.set(name, value);

		return this;
	}

	public function setVector3(name: String, value: Vector3): ShaderMaterial 
	{
		_checkUniform(name);
		_vectors3.set(name, value);

		return this;
	}

	public function setMatrix(name: String, value: Matrix): ShaderMaterial 
	{
		_checkUniform(name);
		_matrices.set(name, value);

		return this;
	}

	override public function isReady(mesh:AbstractMesh = null, useInstances:Bool = false): Bool
	{
		var engine:Engine = getScene().getEngine();

		_effect = engine.createEffect(_shaderPath,
			_options.attributes,
			_options.uniforms,
			_options.samplers,
			"", null, onCompiled, onError);

		if (!_effect.isReady())
		{
			return false;
		}

		return true;
	}

	override public function bind(world: Matrix, mesh:Mesh): Void
	{
		var scene:Scene = getScene();
		
		var uniforms = _options.uniforms;
		if (uniforms.indexOf("world") != -1)
		{
			_effect.setMatrix("world", world);
		}

		if (uniforms.indexOf("view") != -1)
		{
			_effect.setMatrix("view", scene.getViewMatrix());
		}

		if (uniforms.indexOf("worldView") != -1)
		{
			world.multiplyToRef(scene.getViewMatrix(), _cachedWorldViewMatrix);
			_effect.setMatrix("worldView", _cachedWorldViewMatrix);
		}

		if (uniforms.indexOf("projection") != -1)
		{
			_effect.setMatrix("projection", scene.getProjectionMatrix());
		}

		if (uniforms.indexOf("worldViewProjection") != -1) 
		{
			_effect.setMatrix("worldViewProjection", world.multiply(scene.getTransformMatrix()));
		}

		// Texture
		var keys = _textures.keys();
		for (name in keys)
		{
			_effect.setTexture(name, _textures.get(name));
		}

		// Float    
		keys = _floats.keys();
		for (name in keys)
		{
			_effect.setFloat(name, _floats.get(name));
		}

		// Float s   
		keys = _floatsArrays.keys();
		for (name in keys)
		{
			_effect.setArray(name, _floatsArrays.get(name));
		}

		// Color3        
		keys = _colors3.keys();
		for (name in keys)
		{
			_effect.setColor3(name, _colors3.get(name));
		}

		// Color4     
		keys = _colors4.keys();
		for (name in keys)
		{
			var color = _colors4.get(name);
			_effect.setFloat4(name, color.r, color.g, color.b, color.a);
		}

		// Vector2 
		keys = _vectors2.keys();
		for (name in keys)
		{
			_effect.setVector2(name, _vectors2.get(name));
		}

		// Vector3        
		keys = _vectors3.keys();
		for (name in keys)
		{
			_effect.setVector3(name, _vectors3.get(name));
		}

		// Matrix     
		keys = _matrices.keys();
		for (name in keys)
		{
			_effect.setMatrix(name, _matrices.get(name));
		}
	}

	override public function dispose(forceDisposeEffect:Bool = false): Void
	{
		for (texture in _textures)
		{
			texture.dispose();
		}
		_textures = new Map<String,Texture>();

		super.dispose(forceDisposeEffect);
	}
	
}