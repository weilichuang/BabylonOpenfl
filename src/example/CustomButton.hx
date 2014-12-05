package example;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * ...
 * @author weilichuang
 */
class CustomButton extends Sprite
{
	private var textField:TextField;

	public function new(label:String,backgroundColor:UInt=0xffffff) 
	{
		super();
		
		this.mouseChildren = false;
		
		this.textField = new TextField();
		var format:TextFormat = this.textField .defaultTextFormat;
		format.size = 16;
		format.color = 0x0000FF;
		this.textField .defaultTextFormat = format;
		this.textField.text = label;
		this.addChild(this.textField);
		
		this.graphics.clear();
		this.graphics.beginFill(backgroundColor,0.6);
		this.graphics.drawRect(0, 0, 100, 100);
	}
	
}