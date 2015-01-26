package babylon.actions;
import babylon.mesh.AbstractMesh;
import babylon.Scene;
import openfl.events.Event;

/**
 * ActionEvent is the event beint sent when an action is triggered.
 */
class ActionEvent
{
	public var source: AbstractMesh;
	public var pointerX: Float;
	public var pointerY: Float;
	public var meshUnderPointer: AbstractMesh;
	public var sourceEvent:Dynamic;

	/**
	 * @constructor
	 * @param source The mesh that triggered the action.
	 * @param pointerX the X mouse cursor position at the time of the event
	 * @param pointerY the Y mouse cursor position at the time of the event
	 * @param meshUnderPointer The mesh that is currently pointed at (can be null)
	 * @param sourceEvent the original (browser) event that triggered the ActionEvent
	 */
	public function new(source:AbstractMesh, pointerX:Float, pointerY:Float, meshUnderPointer:AbstractMesh, sourceEvent:Dynamic = null) 
	{
		this.source = source;
		this.pointerX = pointerX;
		this.pointerY = pointerY;
		this.source = meshUnderPointer;
		this.sourceEvent = sourceEvent;
	}
	
	/**
	 * Helper function to auto-create an ActionEvent from a source mesh.
	 * @param source the source mesh that triggered the event
	 * @param evt {Event} The original (browser) event
	 */
	public static function CreateNew(source:AbstractMesh, event:Dynamic = null):ActionEvent
	{
		var scene:Scene = source.getScene();
		return new ActionEvent(source, scene.pointerX, scene.pointerY, scene.meshUnderPointer, event);
	}
	
	/**
	 * Helper function to auto-create an ActionEvent from a scene. If triggered by a mesh use ActionEvent.CreateNew
	 * @param scene the scene where the event occurred
	 * @param evt {Event} The original (browser) event
	 */
	public static function CreateNewFromScene(scene: Scene,event:Dynamic):ActionEvent
	{
		return new ActionEvent(null, scene.pointerX, scene.pointerY, scene.meshUnderPointer, event);
	}
	
}