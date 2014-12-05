package babylon.actions;

/**
 * ...
 * @author 
 */
class PredicateCondition extends Condition
{
	public var predicate:Void->Bool;

	public function new(actionManager:ActionManager,predicate:Void->Bool) 
	{
		super(actionManager);
		
		this.predicate = predicate;
	}
	
	override public function isValid():Bool
	{
		return this.predicate();
	}
	
}