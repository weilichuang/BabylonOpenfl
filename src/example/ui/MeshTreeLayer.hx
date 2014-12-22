package example.ui;
import babylon.materials.StandardMaterial;
import babylon.mesh.AbstractMesh;
import babylon.Scene;
import example.BaseDemo;
import haxe.ui.toolkit.containers.VBox;
import haxe.ui.toolkit.controls.CheckBox;
import haxe.ui.toolkit.core.interfaces.IDisplayObject;
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
		theView.style.backgroundAlpha = 0.5;
		theView.style.backgroundColor = 0xffffff;
		
		
		visableBtn.onClick = function(e) {
            var meshes:Array<AbstractMesh> = scene.meshes;
			for (i in 0...meshes.length)
			{
				var mesh:AbstractMesh = meshes[i];
				mesh.isVisible = true;
			}
			
			var children:Array<IDisplayObject> = meshBox.children;
			for (i in 0...children.length)
			{
				if (Std.is(children[i], CheckBox))
				{
					cast(children[i], CheckBox).selected = true;
				}
			}
        };
		
		diableBtn.onClick = function(e) {
            var meshes:Array<AbstractMesh> = scene.meshes;
			for (i in 0...meshes.length)
			{
				var mesh:AbstractMesh = meshes[i];
				mesh.isVisible = false;
			}

			var children:Array<IDisplayObject> = meshBox.children;
			for (i in 0...children.length)
			{
				if (Std.is(children[i], CheckBox))
				{
					cast(children[i], CheckBox).selected = false;
				}
			}
        };
		
		hideBtn.onClick = function(e) {
            demo.showMeshTree(false);
        };
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