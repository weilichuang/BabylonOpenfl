package babylon.tools;

class SmartArray<T>
{
	public var data:Array<T>;
	public var length:Int;

	public function new()
	{
		this.data = [];
		this.length = 0;
	}
	
	public inline function push(value:T):Void
	{
		this.data[this.length++] = value;
	}
	
	public inline function pushNoDuplicate(value:T):Void
	{
		if (this.data.indexOf(value) == -1)
		{
            this.push(value);
        }        
	}
	
	public inline function sort(compareFn:T->T->Int):Void
	{
		this.data.sort(compareFn);
	}
	
	public function reset():Void
	{
		this.length = 0;
		this.data = [];
	}
	
	public function concat(array:Array<T>):Void
	{		
		for (index in 0...array.length) 
		{
			this.data[this.length++] = array[index];
		}
	}
	
	public function concatWithNoDuplicate(array:Array<T>):Void
	{
		if (array.length == 0)
		{
            return;
        }
		
        for (index in 0...array.length)
		{
			this.pushNoDuplicate(array[index]);
        }
	}
	
	public function indexOf(value:T):Int 
	{
		var position = this.data.indexOf(value);
        
        if (position >= this.length) 
		{
            return -1;
        }

        return position;
	}
		
}
