package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class MarbleProceduralTexture extends ProceduralTexture
{
	private var _numberOfBricksHeight: Int = 3;
	private var _numberOfBricksWidth: Int = 3;
	private var _amplitude: Float = 9.0;
	private var _marbleColor: Color3 = new Color3(0.77, 0.47, 0.40);
	private var _jointColor: Color3 = new Color3(0.72, 0.72, 0.72);
	
	public var marbleColor(get, set):Color3;
	public var jointColor(get, set):Color3;
	
	public var numberOfBricksHeight(get, set):Int;
	public var numberOfBricksWidth(get, set):Int;
	public var amplitude(get, set):Float;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture=null, generateMipMaps:Bool=false) 
	{
		super(name, size, "marble", scene, fallbackTexture, generateMipMaps);
		
		this.updateShaderUniforms();

		// Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
		this.refreshRate = 0;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setColor3("numberOfBricksHeight", this._numberOfBricksHeight);
		this.setColor3("numberOfBricksWidth", this._numberOfBricksWidth);
		this.setFloat("amplitude", this._amplitude);
		this.setColor3("brick", this._marbleColor);
		this.setColor3("joint", this._jointColor);
	}
	
	public function get_numberOfBricksHeight(): Int
	{
		return this._numberOfBricksHeight;
	}

	public function set_numberOfBricksHeight(value: Int):Int
	{
		this._numberOfBricksHeight = value;
		this.updateShaderUniforms();
		return _numberOfBricksHeight;
	}


	public function get_numberOfBricksWidth(): Int 
	{
		return this._numberOfBricksWidth;
	}

	public function set_numberOfBricksWidth(value: Int):Int
	{
		this._numberOfBricksWidth = value;
		this.updateShaderUniforms();
		return this._numberOfBricksWidth;
	}
	
	public function get_amplitude(): Int 
	{
		return this._amplitude;
	}

	public function set_amplitude(value: Int):Int
	{
		this._amplitude = value;
		this.updateShaderUniforms();
		return this._amplitude;
	}

	public function get_marbleColor(): Color3 
	{
		return this._marbleColor;
	}

	public function set_marbleColor(value: Color3):Color3
	{
		this._marbleColor.copyFrom(value);
		this.updateShaderUniforms();
		return _marbleColor;
	}


	public function get_jointColor(): Color3 
	{
		return this._jointColor;
	}

	public function set_jointColor(value: Color3):Color3
	{
		this._jointColor.copyFrom(value);
		this.updateShaderUniforms();
		return this._jointColor;
	}
}