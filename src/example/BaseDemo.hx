package example;

import babylon.Engine;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.Scene;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display.FPS;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pgr.dconsole.DC;

class BaseDemo extends Sprite
{
	public var engine:Engine;
	public var scene:Scene;
	
	private var inited:Bool;

	public function new() 
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}
	
	private function onAddedToStage(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.addEventListener(Event.RESIZE, onResize);
		
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	private function onResize(e:Event):Void 
	{
		if (!inited) 
			init();
    }
	
	private function init():Void
	{
		if (inited)
			return;
		
		inited = true;
		
		engine = new Engine(this.stage, true);
		scene = new Scene(engine);
		
		SceneLoader.ForceFullSceneLoadingForIncremental = true;
		
		var tf:TextField = new FPS(10, 10, 0xFF0000);
		var format:TextFormat = tf.defaultTextFormat;
		format.size = 16;
		tf.defaultTextFormat = format;
		stage.addChild(tf);
		
		DC.init();
		DC.log("Dconsole loading success.");
		DC.registerObject(this, "global");
		
		onInit();
	}
	
	public function setDiffuseTextureEnabled(value:Bool):Void
	{
		StandardMaterial.DiffuseTextureEnabled = value;
	}
	
	public function setAmbientTextureEnabled(value:Bool):Void
	{
		StandardMaterial.AmbientTextureEnabled = value;
	}
	
	public function setOpacityTextureEnabled(value:Bool):Void
	{
		StandardMaterial.OpacityTextureEnabled = value;
	}
	
	public function setReflectionTextureEnabled(value:Bool):Void
	{
		StandardMaterial.ReflectionTextureEnabled = value;
	}
	
	public function setEmissiveTextureEnabled(value:Bool):Void
	{
		StandardMaterial.EmissiveTextureEnabled = value;
	}
	
	public function setSpecularTextureEnabled(value:Bool):Void
	{
		StandardMaterial.SpecularTextureEnabled = value;
	}
	
	public function setBumpTextureEnabled(value:Bool):Void
	{
		StandardMaterial.BumpTextureEnabled = value;
	}
	
	private function onInit():Void
	{
		
	}
}