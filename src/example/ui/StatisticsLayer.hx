package example.ui;
import babylon.Scene;
import haxe.ui.toolkit.core.XMLController;

@:build(haxe.ui.toolkit.core.Macros.buildController ("assets/ui/statistics.xml"))
class StatisticsLayer extends XMLController
{
	public var scene:Scene;
	public function new(scene:Scene) 
	{
		this.scene = scene;
	}
	
	public function refreshStatis():Void
	{
		meshCountTF.text = scene.meshes.length + "";
		
		var count:Int = 0;
		for (i in 0...scene.meshes.length)
		{
			count += scene.meshes[i].getTotalVertices();
		}
		verticeCountTF.text = count + "";
		
		activeMeshCountTF.text = scene.getActiveMeshes().length + "";
		
		activeVerticeCountTF.text = scene.statistics.activeVertices + "";
		
		particleCountTF.text = scene.statistics.activeParticles + "";
		
		skeletonCountTF.text = scene.statistics.activeBones + "";
		
		frameDurationTF.text = scene.statistics.lastFrameDuration +"ms";
		
		drawCallTF.text = scene.engine.getDrawCalls() + "";
		
		evaluateMeshDurationTF.text = scene.statistics.evaluateActiveMeshesDuration + "ms";
		
		renderTargetDurationTF.text = scene.statistics.renderTargetsDuration + "ms";
		
		particleDurationTF.text = scene.statistics.particlesDuration + "ms";
	
		spriteDurationTF.text = scene.statistics.spritesDuration + "ms";
		
		renderDurationTF.text = scene.statistics.renderDuration + "ms";
	}
	
}