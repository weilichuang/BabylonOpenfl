package babylon.actions;

class Condition
{
	public var actionManager:ActionManager;
	
	public var _evaluationId: Int;
	public var _currentResult: Bool;

	public function new(actionManager: ActionManager) 
	{
		this.actionManager = actionManager;
	}
	
	
	public function isValid(): Bool
	{
		return true;
	}

	public function _getProperty(propertyPath: String): String
	{
		return actionManager._getProperty(propertyPath);
	}

	public function _getEffectiveTarget(target: Dynamic, propertyPath: String): Dynamic 
	{
		return actionManager._getEffectiveTarget(target, propertyPath);
	}
}