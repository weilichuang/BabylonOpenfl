package babylon.tools;

//TODO 抽个时间删除SmartArray
class SmartArray<T>
{
	
	public var data:Array<T>;
	public var length:Int;

	public function new()
	{
		this.data = [];
		this.length = 0;
	}
	
	public function push(value:T):Void
	{
		this.data[this.length++] = value;
        
        /*if (this.length > this.data.length) {
            this.data.length *= 2;
        }*/
	}
	
	public function pushNoDuplicate(value:T):Void
	{
		if (this.data.indexOf(value) == -1)
		{
            this.push(value);
        }        
	}
	
	public function sort(compareFn:T->T->Int):Void
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
		
        /*if (this.length + array.length > this.data.length) {
            this.data.length = (this.length + array.length) * 2;
        }*/

        for (index in 0...array.length)
		{
            var item:T = array[index];
			
            var pos = this.data.indexOf(item);
            if (pos == -1 || pos >= this.length) 
			{
                this.data[this.length++] = item;
            }
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
