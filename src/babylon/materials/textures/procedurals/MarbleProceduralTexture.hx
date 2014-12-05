package babylon.materials.textures.procedurals;

import babylon.materials.textures.Texture;
import babylon.Scene;

/**
 * ...
 * @author weilichuang
 */
class MarbleProceduralTexture extends ProceduralTexture
{
	private var _numberOfBricksHeight: Int = 3;
	private var _numberOfBricksWidth: Int = 3;
	
	public var numberOfBricksHeight(get, set):Int;
	public var numberOfBricksWidth(get, set):Int;

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
		return this.numberOfBricksWidth;
	}

	public function set_numberOfBricksWidth(value: Int):Int
	{
		this.numberOfBricksWidth = value;
		this.updateShaderUniforms();
		return this.numberOfBricksWidth;
	}
	
}