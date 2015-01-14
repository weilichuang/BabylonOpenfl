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
	public var sourceEvent:Dynamic;

	public function new(source:AbstractMesh, pointerX:Float, pointerY:Float, meshUnderPointer:AbstractMesh, sourceEvent:Dynamic = null) 
	{
		this.source = source;
		this.pointerX = pointerX;
		this.pointerY = pointerY;
		this.source = meshUnderPointer;
		this.sourceEvent = sourceEvent;
	}
	
	public static function CreateNew(source:AbstractMesh, event:Dynamic = null):ActionEvent
	{
		var scene:Scene = source.getScene();
		return new ActionEvent(source, scene.pointerX, scene.pointerY, scene.meshUnderPointer, event);
	}
	
	public static function CreateNewFromScene(scene: Scene,event:Dynamic):ActionEvent
	{
		return new ActionEvent(null, scene.pointerX, scene.pointerY, scene.meshUnderPointer, event);
	}
	
}