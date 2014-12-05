package babylon.actions;
import babylon.Scene;
import babylon.utils.Logger;

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
		
	private var _scene:Scene;
	
	public var actions:Array<Action>;
	
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
	
	public var hasPointerTriggers(get, null):Bool;
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

	public var hasPickTriggers(get, null):Bool;
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
	
	public function _getEffectiveTarget(target: Dynamic, propertyPath: String): Dynamic
	{
		var properties = propertyPath.split(".");

		for (index in 0...properties.length - 1) 
		{
			target = Reflect.getProperty(target,properties[index]);
		}

		return target;
	}

	public function _getProperty(propertyPath: String): String
	{
		var properties = propertyPath.split(".");

		return properties[properties.length - 1];
	}
	
}