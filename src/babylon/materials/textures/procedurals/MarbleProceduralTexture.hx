package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.Scene;

/**
 * ...
 * 
 */
class MarbleProceduralTexture extends ProceduralTexture
{
	private var _numberOfTilesHeight: Int = 3;
	private var _numberOfTilesWidth: Int = 3;
	private var _amplitude: Float = 9.0;
	private var _marbleColor: Color3 = new Color3(0.77, 0.47, 0.40);
	private var _jointColor: Color3 = new Color3(0.72, 0.72, 0.72);
	
	public var marbleColor(get, set):Color3;
	public var jointColor(get, set):Color3;
	
	public var numberOfTilesHeight(get, set):Int;
	public var numberOfTilesWidth(get, set):Int;
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
		this.setFloat("numberOfTilesHeight", this._numberOfTilesHeight);
		this.setFloat("numberOfTilesWidth", this._numberOfTilesWidth);
		this.setFloat("amplitude", this._amplitude);
		this.setColor3("marbleColor", this._marbleColor);
		this.setColor3("jointColor", this._jointColor);
	}
	
	private function get_numberOfTilesHeight(): Int
	{
		return this._numberOfTilesHeight;
	}

	private function set_numberOfTilesHeight(value: Int):Int
	{
		this._numberOfTilesHeight = value;
		this.updateShaderUniforms();
		return _numberOfTilesHeight;
	}


	private function get_numberOfTilesWidth(): Int 
	{
		return this._numberOfTilesWidth;
	}

	private function set_numberOfTilesWidth(value: Int):Int
	{
		this._numberOfTilesWidth = value;
		this.updateShaderUniforms();
		return this._numberOfTilesWidth;
	}
	
	private function get_amplitude(): Float 
	{
		return this._amplitude;
	}

	private function set_amplitude(value: Float):Float
	{
		this._amplitude = value;
		this.updateShaderUniforms();
		return this._amplitude;
	}

	private function get_marbleColor(): Color3 
	{
		return this._marbleColor;
	}

	private function set_marbleColor(value: Color3):Color3
	{
		this._marbleColor.copyFrom(value);
		this.updateShaderUniforms();
		return _marbleColor;
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