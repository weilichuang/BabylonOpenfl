package babylon.mesh;

interface IGetSetVerticesData 
{
	function isVerticesDataPresent(kind:String):Bool;
	function getVerticesData(kind:String):Array<Float>;
	function getIndices():Array<Int>;
	function setVerticesData(kind:String, data:Array<Float>, updatable:Bool = false, stride:Int = 0):Void;
	function updateVerticesData(kind:String, data:Array<Float>, updateExtends:Bool = true, makeItUnique:Bool = true):Void;
	function setIndices(indices:Array<Int>, totalVertices:Int = 0):Void;
}