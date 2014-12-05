package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class CloudProceduralTexture extends ProceduralTexture
{
	private var _skyColor: Color3 = new Color3(0.15, 0.68, 1.0);
	private var _cloudColor: Color3 = new Color3(1, 1, 1);
	
	public var skyColor(get, set):Color3;
	public var cloudColor(get, set):Color3;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture=null, generateMipMaps:Bool=false) 
	{
		super(name, size, "cloud", scene, fallbackTexture, generateMipMaps);
		
		this.updateShaderUniforms();

		// Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
		this.refreshRate = 0;
		// https://www.shadertoy.com/view/XsjSRt
	}
	
	public function updateShaderUniforms():Void
	{
		this.setColor3("skyColor", this._skyColor);
		this.setColor3("cloudColor", this._cloudColor);
	}
	
	public function get_skyColor(): Color3 {
		return this._skyColor;
	}

	public function set_skyColor(value: Color3):Color3
	{
		this._skyColor.copyFrom(value);
		this.updateShaderUniforms();
		return _skyColor;
	}


	public function get_cloudColor(): Color3 
	{
		return this._cloudColor;
	}

	public function set_cloudColor(value: Color3):Color3
	{
		this._cloudColor.copyFrom(value);
		this.updateShaderUniforms();
		return this._cloudColor;
	}
}