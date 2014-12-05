package babylon.materials;
import haxe.ds.IntMap;

using StringTools;
/**
 * ...
 * @author weilichuang
 */
class EffectFallbacks
{
	private var _defines:IntMap<Array<String>>;

	private var _currentRank:Int = 32;
	private var _maxRank:Int = -1;
	
	public function new()
	{
		_defines = new IntMap<Array<String>>();
	}

	public function addFallback(rank: Int, define: String): Void 
	{
		if (!_defines.exists(rank))
		{
			if (rank < this._currentRank)
			{
				this._currentRank = rank;
			}

			if (rank > this._maxRank)
			{
				this._maxRank = rank;
			}

			this._defines.set(rank, []);
		}

		this._defines.get(rank).push(define);
	}

	public function isMoreFallbacks(): Bool
	{
		return this._currentRank <= this._maxRank;
	}

	public function reduce(currentDefines: String): String
	{
		var currentFallbacks:Array<String> = this._defines.get(this._currentRank);

		for (index in 0...currentFallbacks.length) 
		{
			currentDefines = currentDefines.replace("#define " + currentFallbacks[index], "");
		}

		this._currentRank++;

		return currentDefines;
	}
	
}