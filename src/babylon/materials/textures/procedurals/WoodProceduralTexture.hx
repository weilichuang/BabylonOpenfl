package babylon.materials.textures.procedurals;
import babylon.math.Color3;

class WoodProceduralTexture extends ProceduralTexture
{
	private var _ampScale: Float = 100.0;
	private var _woodColor: Color3 = new Color3(0.32, 0.17, 0.09);
	
	public var ampScale(get, set):Float;
	public var woodColor(get, set):Color3;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture = null, generateMipMaps:Bool = false)
	{
		super(name, size, "wood", scene, fallbackTexture, generateMipMaps);
		
		this.updateShaderUniforms();
		
		this.refreshRate = 0;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setFloat("ampScale", this._ampScale);
		this.setColor3("woodColor", this._woodColor);
	}
	
	public function get_ampScale(): Float {
		return this._ampScale;
	}

	public function set_ampScale(value: Float):Float
	{
		this._ampScale = value;
		this.updateShaderUniforms();
		return _ampScale;
	}


	public function get_woodColor(): Color3 
	{
		return this._woodColor;
	}

	public function set_woodColor(value: Color3):Color3
	{
		this._woodColor.copyFrom(value);
		this.updateShaderUniforms();
		return this._woodColor;
	}
}