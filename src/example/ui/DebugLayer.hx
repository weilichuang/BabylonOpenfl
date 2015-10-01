package example.ui;
import babylon.materials.StandardMaterial;
import babylon.Scene;
import example.BaseDemo;
import haxe.ui.toolkit.core.XMLController;
import haxe.ui.toolkit.events.UIEvent;

@:build(haxe.ui.toolkit.core.Macros.buildController ("assets/ui/options.xml"))
class DebugLayer extends XMLController
{
	private var scene:Scene;
	private var demo:BaseDemo;
	public function new(demo:BaseDemo, scene:Scene) 
	{
		this.demo = demo;
		this.scene = scene;
		theView.style.backgroundAlpha = 0.8;
		theView.style.backgroundColor = 0xffffff;
		
		statisticsCB.addEventListener(UIEvent.CHANGE,function(e) {
			demo.showStatistics(statisticsCB.selected);
        });
		
		meshTreeBtn.addEventListener(UIEvent.CLICK,function(e) {
			demo.showMeshTree(true);
        });
		
		renderMode.addEventListener(UIEvent.CHANGE,function(e) {
			switch(renderMode.selectedIndex) {
				case 0:
					scene.forceWireframe = false;
					scene.forcePointsCloud = false;
				case 1:
					scene.forceWireframe = true;
					scene.forcePointsCloud = false;
				case 2:
					scene.forcePointsCloud = true;
					scene.forceWireframe = false;
			}
		});
		
		boundingBoxCB.addEventListener(UIEvent.CHANGE,function(e) {
            this.scene.forceShowBoundingBoxes = boundingBoxCB.selected;
        });
		
		diffuseCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.DiffuseTextureEnabled = diffuseCB.selected;
        });
		
		ambientCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.AmbientTextureEnabled = ambientCB.selected;
        });
		
		specularCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.SpecularTextureEnabled = specularCB.selected;
        });
		
		emissiveCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.EmissiveTextureEnabled = emissiveCB.selected;
        });
		
		opacityCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.OpacityTextureEnabled = opacityCB.selected;
        });
		
		reflectionCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.ReflectionTextureEnabled = reflectionCB.selected;
        });
		
		fresnelCB.addEventListener(UIEvent.CHANGE,function(e) {
            StandardMaterial.FresnelEnabled = fresnelCB.selected;
        });
		
		animationsCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.animationsEnabled = animationsCB.selected;
        });
		
		shadowsCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.shadowsEnabled = shadowsCB.selected;
        });
		
		particlesCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.particlesEnabled = particlesCB.selected;
        });
		
		postprocessesCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.postProcessesEnabled = postprocessesCB.selected;
        });
		
		collisionsCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.collisionsEnabled = collisionsCB.selected;
        });
		
		lightsCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.lightsEnabled = lightsCB.selected;
        });
		
		lensflaresCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.lensFlaresEnabled = lensflaresCB.selected;
        });
		
		rendertargetsCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.renderTargetsEnabled = rendertargetsCB.selected;
        });
		
		proceduraltexturesCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.proceduralTexturesEnabled = proceduraltexturesCB.selected;
        });
		
		fogCB.addEventListener(UIEvent.CHANGE,function(e) {
            scene.fogEnabled = fogCB.selected;
        });
	}
	
	public function applyConfig():Void
	{
		demo.showStatistics(statisticsCB.selected);
		demo.showMeshTree(false);
		
		renderMode.selectedIndex = scene.forcePointsCloud ? 2 : (scene.forceWireframe ? 1 : 0);
		boundingBoxCB.selected = scene.forceShowBoundingBoxes;
		diffuseCB.selected = StandardMaterial.DiffuseTextureEnabled;
		ambientCB.selected = StandardMaterial.AmbientTextureEnabled;
		specularCB.selected = StandardMaterial.SpecularTextureEnabled;
		emissiveCB.selected = StandardMaterial.EmissiveTextureEnabled;
		opacityCB.selected = StandardMaterial.OpacityTextureEnabled;
		reflectionCB.selected = StandardMaterial.ReflectionTextureEnabled;
		fresnelCB.selected = StandardMaterial.FresnelEnabled;
		
		animationsCB.selected = scene.shadowsEnabled;
		shadowsCB.selected = scene.shadowsEnabled;
		particlesCB.selected = scene.particlesEnabled;
		postprocessesCB.selected = scene.postProcessesEnabled;
		collisionsCB.selected = scene.collisionsEnabled;
		lightsCB.selected = scene.lightsEnabled;
		lensflaresCB.selected = scene.lensFlaresEnabled;
		rendertargetsCB.selected = scene.renderTargetsEnabled;
		proceduraltexturesCB.selected = scene.proceduralTexturesEnabled;
		fogCB.selected = scene.fogEnabled;
	}
	
}