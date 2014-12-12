package example;

import babylon.cameras.FreeCamera;
import babylon.Engine;
import babylon.load.SceneLoader;
import babylon.materials.StandardMaterial;
import babylon.Scene;
import example.ui.DebugLayer;
import example.ui.JoystickSimulator;
import example.ui.StatisticsLayer;
import haxe.ui.toolkit.controls.Button;
import haxe.ui.toolkit.core.interfaces.IDisplayObject;
import haxe.ui.toolkit.core.Root;
import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.events.UIEvent;
import haxe.ui.toolkit.themes.GradientTheme;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display.FPS;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pgr.dconsole.DC;

class BaseDemo extends Sprite
{
	public var engine:Engine;
	public var scene:Scene;
	
	private var inited:Bool;
	
	private var uiLayer:Sprite;
	
	private var joystickui:JoystickSimulator;
	private var settingBtn:Sprite;

	private var debugLayer:DebugLayer;
	private var statisicLayer:StatisticsLayer;
	
	private var fps:TextField;

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
		{
			init();
		}
		else
		{
			joystickui.x = 50;
			joystickui.y = stage.stageHeight - joystickui.height - 50;
			
			settingBtn.x = stage.stageWidth - settingBtn.width;
			settingBtn.y = 0;
			
			fps.x = stage.stageWidth - 60;
			fps.y = stage.stageHeight - 30;
			
			if (statisicLayer != null)
			{
				statisicLayer.view.x = stage.stageWidth - statisicLayer.view.width;
				statisicLayer.view.y = stage.stageHeight - statisicLayer.view.height;
			}
		}
    }
	
	private function init():Void
	{
		if (inited)
			return;
		
		inited = true;
		
		engine = new Engine(this.stage, true);
		scene = new Scene(engine);
		
		SceneLoader.ForceFullSceneLoadingForIncremental = true;
		
		uiLayer = new Sprite();
		uiLayer.graphics.beginFill(0x0, 0);
		uiLayer.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		uiLayer.graphics.endFill();
		uiLayer.width = stage.stageWidth;
		uiLayer.height = stage.stageHeight;
		stage.addChild(uiLayer);
		
		//init UI
		Toolkit.theme = new GradientTheme();
		Toolkit.init();
		Toolkit.open(onHaxeUIInit,{x: 0, y: 0, percentWidth: 100, percentHeight: 100, styleName: "fullscreen",parent:uiLayer});
	}
	
	public var touchLayer(get, null):Sprite;
	
	private var rootUI:Root;
	private function get_touchLayer():Sprite
	{
		return uiLayer;
	}
	
	private function onHaxeUIInit(root:Root):Void
	{
		rootUI = root;
		
		rootUI.style.backgroundAlpha = 0;

		debugLayer = new DebugLayer(this,this.scene);
		rootUI.addChild(debugLayer.view);
		debugLayer.view.visible = false;
		
		statisicLayer = new StatisticsLayer(this.scene);
		rootUI.addChild(statisicLayer.view);
		statisicLayer.view.visible = false;

		fps = new FPS(stage.stageWidth - 60, stage.stageHeight - 30, 0xFF0000);
		var format:TextFormat = fps.defaultTextFormat;
		format.size = 16;
		fps.defaultTextFormat = format;
		stage.addChild(fps);
		
		settingBtn = new Sprite();
		var image:Bitmap = new Bitmap(Assets.getBitmapData("assets/ui/setting.png"));
		settingBtn.addChild(image);
		settingBtn.buttonMode = true;
		settingBtn.addEventListener(MouseEvent.CLICK, onClickSetting);
		stage.addChild(settingBtn);

		joystickui = new JoystickSimulator();
		stage.addChild(joystickui);
		joystickui.attachChontrol();
		joystickui.setMoveHandle(onJoystickMove);
		
		DC.init();
		DC.log("Dconsole loading success.");
		DC.registerObject(this, "global");
		
		this.addEventListener(Event.ENTER_FRAME, onEnterframe);
		
		onResize(null);
		
		debugLayer.applyConfig();
		
		onInit();
	}
	
	private function onEnterframe(event:Event):Void
	{
		if (statisicLayer != null && statisicLayer.view.visible)
		{
			statisicLayer.refreshStatis();
		}
	}

	private function onClickSetting(event:MouseEvent):Void
	{
		if (debugLayer == null)
			return;
			
		debugLayer.view.visible =  !debugLayer.view.visible;
	}
	
	private function onJoystickMove(px:Float, pz:Float):Void
	{
		if (scene == null)
			return;
		
		if (scene.activeCamera == null)
			return;
			
		if (!Std.is(scene.activeCamera, FreeCamera))
			return;
		
		if (px == 0 && pz == 0)
			return;
			
		cast(scene.activeCamera, FreeCamera).move(-px, pz);
	}
	
	public function showStatistics(value:Bool):Void
	{
		statisicLayer.view.visible = value;
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