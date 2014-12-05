package babylon.actions;

class Action
{
	public var trigger:Int;
	public var actionManager:ActionManager;
	
	private var _nextActiveAction:Action;
	private var _child:Action;
	private var _condition:Condition;
	private var _triggerParameter:Dynamic;
	
	

	public function new(trigger:Int, triggerParameter:Dynamic = null, condition:Condition = null)
	{
		this.trigger = trigger;
		this._triggerParameter = triggerParameter;
		this._condition = condition;
		_nextActiveAction = this;
	}
	
	public function _prepare():Void
	{
		
	}
	
	public function getTriggerParameter(): Dynamic
	{
		return this._triggerParameter;
	}
	
	public function _executeCurrent(evt: ActionEvent): Void 
	{
		if (this._condition != null) 
		{
			var currentRenderId = actionManager.getScene().getRenderId();

			// We cache the current evaluation for the current frame
			if (this._condition._evaluationId == currentRenderId)
			{
				if (!this._condition._currentResult)
				{
					return;
				}
			}
			else
			{
				this._condition._evaluationId = currentRenderId;

				if (!this._condition.isValid()) 
				{
					this._condition._currentResult = false;
					return;
				}

				this._condition._currentResult = true;
			}
		}

		this._nextActiveAction.execute(evt);

		if (this._nextActiveAction._child != null) 
		{
			this._nextActiveAction = this._nextActiveAction._child;
		} 
		else 
		{
			this._nextActiveAction = this;
		}
	}

	public function execute(evt: ActionEvent): Void
	{

	}

	public function then(action: Action): Action
	{
		this._child = action;

		action.actionManager = this.actionManager;
		action._prepare();

		return action;
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