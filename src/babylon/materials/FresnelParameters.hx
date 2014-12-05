package babylon.materials;
import babylon.math.Color3;

class FresnelParameters
{
	public var isEnabled:Bool;
	public var leftColor:Color3;
	public var rightColor:Color3;
	public var bias:Float;
	public var power:Float;

	public function new() 
	{
		this.isEnabled = true;
		this.leftColor = new Color3(1,1,1);
		this.rightColor = new Color3(0, 0, 0);
		this.bias = 0;
		this.power = 1;
	}
	
}