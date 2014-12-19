package example.ui;
import babylon.materials.StandardMaterial;
import babylon.mesh.AbstractMesh;
import babylon.Scene;
import example.BaseDemo;
import haxe.ui.toolkit.containers.VBox;
import haxe.ui.toolkit.controls.CheckBox;
import haxe.ui.toolkit.core.XMLController;

@:build(haxe.ui.toolkit.core.Macros.buildController ("assets/ui/meshtree.xml"))
class MeshTreeLayer extends XMLController
{
	private var scene:Scene;
	private var demo:BaseDemo;
	public function new(demo:BaseDemo, scene:Scene) 
	{
		this.demo = demo;
		this.scene = scene;
		theView.style.backgroundAlpha = 0.8;
		theView.style.backgroundColor = 0xffffff;
	}
	
	public function refreshList():Void
	{
		meshBox.removeAllChildren();
		
		var meshes:Array<AbstractMesh> = scene.meshes;
		for (i in 0...meshes.length)
		{
			var mesh:AbstractMesh = meshes[i];
			var checkBox:CheckBox = new CheckBox();
			checkBox.text = mesh.name;
			checkBox.selected = mesh.isVisible;
			checkBox.onClick = function(e) {
				mesh.isVisible = checkBox.selected;
			};
			
			meshBox.addChild(checkBox);
		}
	}
	
}