package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * 
 */
class RoadProceduralTexture extends ProceduralTexture
{
	private var _roadColor: Color3 = new Color3(0.53, 0.53, 0.53);
	
	public var roadColor(get, set):Color3;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture = null, generateMipMaps:Bool = false) 
	{
		super(name, size, "road", scene, fallbackTexture, generateMipMaps);
		
		this.updateShaderUniforms();
		this.refreshRate = 0;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setColor3("roadColor", this._roadColor);
	}
	
	private function get_roadColor(): Color3 
	{
		return this._roadColor;
	}

	private function set_roadColor(value: Color3):Color3
	{
		this._roadColor.copyFrom(value);
		this.updateShaderUniforms();
		return _roadColor;
	}
	
}