package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class GrassProceduralTexture extends ProceduralTexture
{
	private var _grassColors: Array<Color3>;
	private var _herb1: Color3 = new Color3(0.29, 0.38, 0.02);
	private var _herb2: Color3 = new Color3(0.36, 0.49, 0.09);
	private var _herb3: Color3 = new Color3(0.51, 0.6, 0.28);
	private var _dirtColor: Color3 = new Color3(0.6, 0.46, 0.13);
	private var _groundColor: Color3 = new Color3(1, 1, 1);
	
	public var grassColors(get, set):Array<Color3>;
	public var dirtColor(get, set):Color3;
	public var groundColor(get, set):Color3;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture=null, generateMipMaps:Bool=false) 
	{
		super(name, size, "grass", scene, fallbackTexture, generateMipMaps);
		
		this._grassColors = [
			new Color3(0.29, 0.38, 0.02),
			new Color3(0.36, 0.49, 0.09),
			new Color3(0.51, 0.6, 0.28),
		];

		this.updateShaderUniforms();
		this.refreshRate = 0;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setColor3("herb1", this._grassColors[0]);
		this.setColor3("herb2", this._grassColors[1]);
		this.setColor3("herb3", this._grassColors[2]);
		this.setColor3("dirt", this._dirtColor);
		this.setColor3("ground", this._groundColor);
	}
	
	public function get_grassColors(): Array<Color3> 
	{
		return this._grassColors;
	}

	public function set_grassColors(value: Array<Color3>):Array<Color3>
	{
		this._grassColors = value;
		this.updateShaderUniforms();
		return _grassColors;
	}
	
	public function get_dirtColor(): Color3 
	{
		return this._dirtColor;
	}

	public function set_dirtColor(value: Color3):Color3
	{
		this._dirtColor.copyFrom(value);
		this.updateShaderUniforms();
		return _dirtColor;
	}
	
	public function get_groundColor(): Color3 
	{
		return this._groundColor;
	}

	public function set_groundColor(value: Color3):Color3
	{
		this._groundColor.copyFrom(value);
		this.updateShaderUniforms();
		return _groundColor;
	}
	
}