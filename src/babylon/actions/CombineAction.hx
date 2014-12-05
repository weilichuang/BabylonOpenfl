package babylon.actions;

class CombineAction extends Action
{
	public var children:Array<Action>;

	public function new(trigger:Int, triggerParameter:Dynamic = null, 
						children:Array<Action> = null,
						condition:Condition = null) 
	{
		super(trigger, triggerParameter, condition);
		this.children = children;
	}
	
	override public function _prepare():Void 
	{
		for (index in 0...this.children.length) 
		{
			this.children[index].actionManager = this.actionManager;
			this.children[index]._prepare();
		}
	}
	
	override public function execute(evt:ActionEvent):Void 
	{
		for (index in 0...this.children.length) 
		{
			this.children[index].actionManager = this.actionManager;
			this.children[index].execute(evt);
		}
	}
	
}