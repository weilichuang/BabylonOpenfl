package babylon;

/**
 * 统计信息
 */
class Statistics
{
	public var totalVertices:Int;
	public var activeIndices:Int;
	public var activeParticles:Int;
	
	public var lastFrameDuration:Int;
	public var evaluateActiveMeshesDuration:Int;
	public var renderTargetsDuration:Int;
	public var renderDuration:Int;
	public var particlesDuration:Int;
	public var spritesDuration:Int;
	public var activeBones:Int;

	public function new() 
	{
		reset();
	}

	public function reset():Void
	{
		this.totalVertices = 0;
        this.activeIndices = 0;
        this.activeParticles = 0;
		
		this.lastFrameDuration = 0;
        this.evaluateActiveMeshesDuration = 0;
        this.renderTargetsDuration = 0;
        this.renderDuration = 0;
		this.spritesDuration = 0;
		this.particlesDuration = 0;
		this.activeBones = 0;
	}
	
}