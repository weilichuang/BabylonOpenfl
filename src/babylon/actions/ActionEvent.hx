package babylon.actions;
import babylon.mesh.AbstractMesh;
import babylon.Scene;
import openfl.events.Event;

class ActionEvent
{
	public var source: AbstractMesh;
	public var pointerX: Float;
	public var pointerY: Float;
	public var meshUnderPointer: AbstractMesh;

	public function new(source:AbstractMesh,pointerX:Float,pointerY:Float,meshUnderPointer:AbstractMesh) 
	{
		this.source = source;
		this.pointerX = pointerX;
		this.pointerY = pointerY;
		this.source = meshUnderPointer;
	}
	
	public static function CreateNew(source:AbstractMesh):ActionEvent
	{
		var scene:Scene = source.getScene();
		return new ActionEvent(source, scene.pointerX, scene.pointerY, scene.meshUnderPointer);
	}
	
	public static function CreateNewFromScene(scene: Scene,event:Event):ActionEvent
	{
		return new ActionEvent(null, scene.pointerX, scene.pointerY, scene.meshUnderPointer);
	}
	
}