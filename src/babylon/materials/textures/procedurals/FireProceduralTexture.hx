package materials.textures.procedurals;
import math.Color3;
import math.Vector2;

class FireProceduralTexture extends ProceduralTexture
{
	public static function PurpleFireColors(): Array<Color3>
	{
		return [
			new Color3(0.5, 0.0, 1.0),
			new Color3(0.9, 0.0, 1.0),
			new Color3(0.2, 0.0, 1.0),
			new Color3(1.0, 0.9, 1.0),
			new Color3(0.1, 0.1, 1.0),
			new Color3(0.9, 0.9, 1.0)
		];
	}

	public static function GreenFireColors(): Array<Color3>
	{
		return [
			new Color3(0.5, 1.0, 0.0),
			new Color3(0.5, 1.0, 0.0),
			new Color3(0.3, 0.4, 0.0),
			new Color3(0.5, 1.0, 0.0),
			new Color3(0.2, 0.0, 0.0),
			new Color3(0.5, 1.0, 0.0)
		];
	}

	public static function RedFireColors(): Array<Color3>
	{
		return [
			new Color3(0.5, 0.0, 0.1),
			new Color3(0.9, 0.0, 0.0),
			new Color3(0.2, 0.0, 0.0),
			new Color3(1.0, 0.9, 0.0),
			new Color3(0.1, 0.1, 0.1),
			new Color3(0.9, 0.9, 0.9)
		];
	}

	public static function BlueFireColors(): Array<Color3>
	{
		return [
			new Color3(0.1, 0.0, 0.5),
			new Color3(0.0, 0.0, 0.5),
			new Color3(0.1, 0.0, 0.2),
			new Color3(0.0, 0.0, 1.0),
			new Color3(0.1, 0.2, 0.3),
			new Color3(0.0, 0.2, 0.9)
		];
	}

		
	private var _time: Float = 0.0;
	private var _speed: Vector2 = new Vector2(0.5, 0.3);
	private var _shift: Float = 1.6;
	private var _alpha: Float = 0.0;
	private var _autoGenerateTime: Bool = true;
	private var _fireColors: Array<Color3>;
	private var _alphaThreshold:Float = 0.5;
	
	public var fireColors(get, set):Array<Color3>;
	public var time(get, set):Float;
	public var speed(get, set):Float;
	public var shift(get, set):Float;
	public var alpha(get, set):Float;
	public var alphaThreshold(get, set):Float;

	public function new(name:String, size:Int, scene:Scene, fallbackTexture:Texture = null, generateMipMaps:Bool = false)
	{
		super(name, size, "fire", scene, fallbackTexture, generateMipMaps);
		
		this._fireColors = FireProceduralTexture.RedFireColors();
		this.updateShaderUniforms();

		// Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
		this.refreshRate = 1;
	}
	
	public function updateShaderUniforms():Void
	{
		this.setFloat("iGlobalTime", this._time);
		this.setVector2("speed", this._speed);
		this.setFloat("shift", this._shift);
		this.setFloat("alpha", this._alpha);

		this.setColor3("c1", this._fireColors[0]);
		this.setColor3("c2", this._fireColors[1]);
		this.setColor3("c3", this._fireColors[2]);
		this.setColor3("c4", this._fireColors[3]);
		this.setColor3("c5", this._fireColors[4]);
		this.setColor3("c6", this._fireColors[5]);
		this.setFloat("alphaThreshold", this._alphaThreshold);
	}
	
	override public function render(useCameraPostProcess:Bool = false):Void
	{
		if (this._autoGenerateTime)
		{
			this._time += this.getScene().getAnimationRatio() * 0.03;
			this.updateShaderUniforms();
		}

		super.render(useCameraPostProcess);
	}
	
	public function get_fireColors(): Array<Color3>
	{
		return this._fireColors;
	}

	public function set_fireColors(value: Array<Color3>):Array<Color3>
	{
		this._fireColors = value;
		this.updateShaderUniforms();
		return _fireColors;
	}


	public function get_time(): Float 
	{
		return this._time;
	}

	public function set_time(value: Float):Float
	{
		this._time = value;
		this.updateShaderUniforms();
		return this._time;
	}
	
	public function get_speed(): Vector2 
	{
		return this._speed;
	}

	public function set_speed(value: Vector2):Vector2
	{
		this._speed = value;
		this.updateShaderUniforms();
		return this._speed;
	}
	
	public function get_shift(): Float 
	{
		return this._shift;
	}

	public function set_shift(value: Float):Float
	{
		this._shift = value;
		this.updateShaderUniforms();
		return this._shift;
	}
	
	public function get_alpha(): Float 
	{
		return this._alpha;
	}

	public function set_alpha(value: Float):Float
	{
		this._alpha = value;
		this.updateShaderUniforms();
		return this._alpha;
	}
	
	public function get_alphaThreshold(): Float 
	{
		return this._alphaThreshold;
	}

	public function set_alphaThreshold(value: Float):Float
	{
		this._alphaThreshold = value;
		this.updateShaderUniforms();
		return this._alphaThreshold;
	}
}