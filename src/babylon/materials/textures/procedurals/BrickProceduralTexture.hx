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
		this.setFloat("numberOfBricksHeight", this._numberOfBricksHeight);
		this.setFloat("numberOfBricksWidth", this._numberOfBricksWidth);
		this.setColor3("brickColor", this._brickColor);
		this.setColor3("jointColor", this._jointColor);
	}
	
	private function get_numberOfBricksHeight(): Int
	{
		return this._numberOfBricksHeight;
	}

	private function set_numberOfBricksHeight(value: Int):Int
	{
		this._numberOfBricksHeight = value;
		this.updateShaderUniforms();
		return _numberOfBricksHeight;
	}


	private function get_numberOfBricksWidth(): Int 
	{
		return this._numberOfBricksWidth;
	}

	private function set_numberOfBricksWidth(value: Int):Int
	{
		this._numberOfBricksWidth = value;
		this.updateShaderUniforms();
		return this._numberOfBricksWidth;
	}
	
	private function get_brickColor(): Color3 
	{
		return this._brickColor;
	}

	private function set_brickColor(value: Color3):Color3
	{
		this._brickColor.copyFrom(value);
		this.updateShaderUniforms();
		return _brickColor;
	}


	private function get_jointColor(): Color3 
	{
		return this._jointColor;
	}

	private function set_jointColor(value: Color3):Color3
	{
		this._jointColor.copyFrom(value);
		this.updateShaderUniforms();
		return this._jointColor;
	}
	
}