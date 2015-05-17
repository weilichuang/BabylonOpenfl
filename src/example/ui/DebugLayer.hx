package example.ui;
import babylon.materials.StandardMaterial;
import babylon.Scene;
import example.BaseDemo;
import haxe.ui.toolkit.core.XMLController;

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
		
		statisticsCB.onChange = function(e) {
			demo.showStatistics(statisticsCB.selected);
        };
		
		meshTreeBtn.onClick = function(e) {
			demo.showMeshTree(true);
        };
		
		renderMode.onChange = function(e) {
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
		};
		
		boundingBoxCB.onChange = function(e) {
            this.scene.forceShowBoundingBoxes = boundingBoxCB.selected;
        };
		
		diffuseCB.onChange = function(e) {
            StandardMaterial.DiffuseTextureEnabled = diffuseCB.selected;
        };
		
		ambientCB.onChange = function(e) {
            StandardMaterial.AmbientTextureEnabled = ambientCB.selected;
        };
		
		specularCB.onChange = function(e) {
            StandardMaterial.SpecularTextureEnabled = specularCB.selected;
        };
		
		emissiveCB.onChange = function(e) {
            StandardMaterial.EmissiveTextureEnabled = emissiveCB.selected;
        };
		
		opacityCB.onChange = function(e) {
            StandardMaterial.OpacityTextureEnabled = opacityCB.selected;
        };
		
		reflectionCB.onChange = function(e) {
            StandardMaterial.ReflectionTextureEnabled = reflectionCB.selected;
        };
		
		fresnelCB.onChange = function(e) {
            StandardMaterial.FresnelEnabled = fresnelCB.selected;
        };
		
		animationsCB.onChange = function(e) {
            scene.animationsEnabled = animationsCB.selected;
        };
		
		shadowsCB.onChange = function(e) {
            scene.shadowsEnabled = shadowsCB.selected;
        };
		
		particlesCB.onChange = function(e) {
            scene.particlesEnabled = particlesCB.selected;
        };
		
		postprocessesCB.onChange = function(e) {
            scene.postProcessesEnabled = postprocessesCB.selected;
        };
		
		collisionsCB.onChange = function(e) {
            scene.collisionsEnabled = collisionsCB.selected;
        };
		
		lightsCB.onChange = function(e) {
            scene.lightsEnabled = lightsCB.selected;
        };
		
		lensflaresCB.onChange = function(e) {
            scene.lensFlaresEnabled = lensflaresCB.selected;
        };
		
		rendertargetsCB.onChange = function(e) {
            scene.renderTargetsEnabled = rendertargetsCB.selected;
        };
		
		proceduraltexturesCB.onChange = function(e) {
            scene.proceduralTexturesEnabled = proceduraltexturesCB.selected;
        };
		
		fogCB.onChange = function(e) {
            scene.fogEnabled = fogCB.selected;
        };
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