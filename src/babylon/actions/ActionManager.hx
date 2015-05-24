package babylon.actions;
import babylon.Scene;
import babylon.utils.Logger;

/**
 * Action Manager manages all events to be triggered on a given mesh or the global scene.
 * A single scene can have many Action Managers to handle predefined actions on specific meshes.
 */
class ActionManager
{
	public static inline var NothingTrigger:Int = 0;
	public static inline var OnPickTrigger:Int = 1;
	public static inline var OnLeftPickTrigger:Int = 2;
	public static inline var OnRightPickTrigger:Int = 3;
	public static inline var OnCenterPickTrigger:Int = 4;
	public static inline var OnPointerOverTrigger:Int = 5;
	public static inline var OnPointerOutTrigger:Int = 6;
	public static inline var OnEveryFrameTrigger:Int = 7;
	public static inline var OnIntersectionEnterTrigger:Int = 8;
	public static inline var OnIntersectionExitTrigger:Int = 9;
	public static inline var OnKeyDownTrigger:Int = 10;
    public static inline var OnKeyUpTrigger:Int = 11;
	public static inline var OnPickUpTrigger:Int = 12;
	
	
	public static function getTriggerByName(name:String):Int
	{
		switch(name)
		{
			case "NothingTrigger":
				return 0;
			case "OnPickTrigger":
				return 1;
			case "OnLeftPickTrigger":
				return 2;
			case "OnRightPickTrigger":
				return 3;
			case "OnCenterPickTrigger":
				return 4;
			case "OnPointerOverTrigger":
				return 5;
			case "OnPointerOutTrigger":
				return 6;
			case "OnEveryFrameTrigger":
				return 7;
			case "OnIntersectionEnterTrigger":
				return 8;
			case "OnIntersectionExitTrigger":
				return 9;
			case "OnKeyDownTrigger":
				return 10;
			case "OnKeyUpTrigger":
				return 11;
			case "OnPickUpTrigger":
				return 12;
			default:
				return -1;
		}
	}
	
	/**
	 * Does this action manager has pointer triggers
	 * @return {boolean} whether or not it has pointer triggers
	 */
	public var hasPointerTriggers(get, null):Bool;
	
	/**
	 * Does this action manager has pick triggers
	 * @return {boolean} whether or not it has pick triggers
	 */
	public var hasPickTriggers(get, null):Bool;
	
	
	public var actions:Array<Action>;
		
	private var _scene:Scene;
	
	public function new(scene:Scene) 
	{
		this._scene = scene;
		scene._actionManagers.push(this);
		
		this.actions = new Array<Action>();
	}
	
	public function dispose(): Void 
	{
		var index = this._scene._actionManagers.indexOf(this);

		if (index > -1) {
			this._scene._actionManagers.splice(index, 1);
		}
	}

	
	public function getScene():Scene
	{
		return this._scene;
	}
	
	/**
	 * Does this action manager handles actions of any of the given triggers
	 * @param triggers {Array<Int>} the triggers to be tested
	 * @return {Bool} whether one (or more) of the triggers is handeled 
	 */
	public function hasSpecificTriggers(triggers: Array<Int>): Bool 
	{
		for (index in 0...this.actions.length)
		{
			var action = this.actions[index];

			if (triggers.indexOf(action.trigger) > -1)
			{
				return true;
			}
		}

		return false;
	}
	
	/**
	 * Does this action manager handles actions of a given trigger
	 * @param {Int} trigger - the trigger to be tested
	 * @return {Bool} whether the trigger is handeled 
	 */
	public function hasSpecificTrigger(trigger: Int): Bool 
	{
		for (index in 0...this.actions.length)
		{
			var action = this.actions[index];
			if (action.trigger == trigger)
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * Registers an action to this action manager
	 * @param action {BABYLON.Action} the action to be registered
	 * @return {BABYLON.Action} the action amended (prepared) after registration
	 */
	public function registerAction(action:Action):Action
	{
		if (action.trigger == ActionManager.OnEveryFrameTrigger) 
		{
			if (this.getScene().actionManager != this)
			{
				Logger.log("OnEveryFrameTrigger can only be used with scene.actionManager");
				return null;
			}
		}


		this.actions.push(action);

		action.actionManager = this;
		action._prepare();

		return action;
	}
	
	public function processTrigger(trigger:Int, evt:ActionEvent):Void
	{
		for (index in 0...this.actions.length) 
		{
			var action = this.actions[index];

			if (action.trigger == trigger)
			{
				action._executeCurrent(evt);
			}
		}
	}
	
	@:dox(hide)
	public function _getEffectiveTarget(target: Dynamic, propertyPath: String): Dynamic
	{
		var properties = propertyPath.split(".");

		for (index in 0...properties.length - 1) 
		{
			target = Reflect.getProperty(target,properties[index]);
		}

		return target;
	}

	@:dox(hide)
	public function _getProperty(propertyPath: String): String
	{
		var properties = propertyPath.split(".");

		return properties[properties.length - 1];
	}
	
	private function get_hasPointerTriggers(): Bool 
	{
		for (index in 0...this.actions.length)
		{
			var action = this.actions[index];

			if (action.trigger >= ActionManager.OnPickTrigger && 
				action.trigger <= ActionManager.OnPointerOutTrigger)
			{
				return true;
			}
		}

		return false;
	}

	
	private function get_hasPickTriggers(): Bool
	{
		for (index in 0...this.actions.length)
		{
			var action = this.actions[index];

			if (action.trigger >= ActionManager.OnPickTrigger && 
				action.trigger <= ActionManager.OnCenterPickTrigger) 
			{
				return true;
			}
		}

		return false;
	}
}