package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * 
 */
class BrickProceduralTexture extends ProceduralTexture
{
	private var _numberOfBricksHeight: Int = 15;
	private var _numberOfBricksWidth: Int = 5;
	
	private var _jointColor: Color3 = new Color3(0.72, 0.72, 0.72);
	private var _brickColor: Color3 = new Color3(0.77, 0.47, 0.40);
	
	public var jointColor(get, set):Color3;
	public var brickColor(get, set):Color3;
	
	public var numberOfBricksHeight(get, set):Int;
	public var numberOfBricksWidth(get, set):Int;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture=null, generateMipMaps:Bool=false) 
	{
		super(name, size, "brick", scene, fallbackTexture, generateMipMaps);
		
		this.updateShaderUniforms();
		this.refreshRate = 0;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setColor3("numberOfBricksHeight", this._numberOfBricksHeight);
		this.setColor3("numberOfBricksWidth", this._numberOfBricksWidth);
		this.setColor3("brickColor", this._brickColor);
		this.setColor3("jointColor", this._jointColor);
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
	
	public function get_brickColor(): Color3 
	{
		return this._brickColor;
	}

	public function set_brickColor(value: Color3):Color3
	{
		this._brickColor.copyFrom(value);
		this.updateShaderUniforms();
		return _brickColor;
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