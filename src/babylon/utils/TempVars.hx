package babylon.utils;
import babylon.math.Matrix;
import babylon.math.Vector3;

/**
 * Temporary variables . Engine classes may access
 * these temp variables with TempVars.getTempVars(), all retrieved TempVars
 * instances must be returned via TempVars.release().
 * This returns an available instance of the TempVar class ensuring this
 * particular instance is never used elsewhere in the mean time.
 */
class TempVars
{
	/**
	 * Allow X instances of TempVars.
	 */
	private static var STACK_SIZE:Int = 5;

	private static var currentIndex:Int = 0;

	private static var varStack:Array<TempVars> = new Array<TempVars>();

	public static function getTempVars():TempVars
	{
		#if debug
		Assert.assert(currentIndex <= STACK_SIZE - 1, 
					"Only Allow " + STACK_SIZE + " instances of TempVars");
		#end

		var instance:TempVars = varStack[currentIndex];
		if (instance == null)
		{
			instance = new TempVars();
			varStack[currentIndex] = instance;
		}

		currentIndex++;

		instance.isUsed = true;

		return instance;
	}

	private var isUsed:Bool;

	/**
	 * General vectors.
	 */
	public var vect1:Vector3;
	public var vect2:Vector3;
	public var vect3:Vector3;
	public var vect4:Vector3;
	public var vect5:Vector3;
	public var vect6:Vector3;
	/**
	 * General matrices.
	 */
	public var tempMat:Matrix;

	public function new()
	{
		isUsed = false;

		vect1 = new Vector3();
		vect2 = new Vector3();
		vect3 = new Vector3();
		vect4 = new Vector3();
		vect5 = new Vector3();
		vect6 = new Vector3();

		tempMat = new Matrix();
	}

	public function release():Void
	{
		Assert.assert(isUsed, "This instance of TempVars was already released!");

		isUsed = false;

		currentIndex--;

		Assert.assert(varStack[currentIndex] == this, "An instance of TempVars has not been released in a called method!");
	}
}

