package example.ui;
import babylon.materials.StandardMaterial;
import babylon.Scene;
import example.BaseDemo;
import haxe.ui.toolkit.core.XMLController;

@:build(haxe.ui.toolkit.core.Macros.buildController ("assets/ui/options.xml"))
class DebugLayer extends XMLController
{
	public var scene:Scene;
	private var demo:BaseDemo;
	public function new(demo:BaseDemo, scene:Scene) 
	{
		this.demo = demo;
		this.scene = scene;
		theView.style.backgroundAlpha = 0.8;
		theView.style.backgroundColor = 0xffffff;
		
		statisticsCB.onClick = function(e) {
			demo.showStatistics(statisticsCB.selected);
        };
		
		wireframeCB.onClick = function(e) {
            this.scene.forceWireframe = wireframeCB.selected;
        };
		
		boundingBoxCB.onClick = function(e) {
            this.scene.forceShowBoundingBoxes = boundingBoxCB.selected;
        };
		
		diffuseCB.onClick = function(e) {
            StandardMaterial.DiffuseTextureEnabled = diffuseCB.selected;
        };
		
		ambientCB.onClick = function(e) {
            StandardMaterial.AmbientTextureEnabled = ambientCB.selected;
        };
		
		specularCB.onClick = function(e) {
            StandardMaterial.SpecularTextureEnabled = specularCB.selected;
        };
		
		emissiveCB.onClick = function(e) {
            StandardMaterial.EmissiveTextureEnabled = emissiveCB.selected;
        };
		
		opacityCB.onClick = function(e) {
            StandardMaterial.OpacityTextureEnabled = opacityCB.selected;
        };
		
		reflectionCB.onClick = function(e) {
            StandardMaterial.ReflectionTextureEnabled = reflectionCB.selected;
        };
		
		shadowsCB.onClick = function(e) {
            scene.shadowsEnabled = shadowsCB.selected;
        };
		
		particlesCB.onClick = function(e) {
            scene.particlesEnabled = particlesCB.selected;
        };
		
		postprocessesCB.onClick = function(e) {
            scene.postProcessesEnabled = postprocessesCB.selected;
        };
		
		collisionsCB.onClick = function(e) {
            scene.collisionsEnabled = collisionsCB.selected;
        };
		
		lightsCB.onClick = function(e) {
            scene.lightsEnabled = lightsCB.selected;
        };
		
		lensflaresCB.onClick = function(e) {
            scene.lensFlaresEnabled = lensflaresCB.selected;
        };
		
		rendertargetsCB.onClick = function(e) {
            scene.renderTargetsEnabled = rendertargetsCB.selected;
        };
		
		proceduraltexturesCB.onClick = function(e) {
            scene.proceduralTexturesEnabled = proceduraltexturesCB.selected;
        };
	}
	
	public function applyConfig():Void
	{
		demo.showStatistics(statisticsCB.selected);
		this.scene.forceWireframe = wireframeCB.selected;
		this.scene.forceShowBoundingBoxes = boundingBoxCB.selected;
		StandardMaterial.DiffuseTextureEnabled = diffuseCB.selected;
		StandardMaterial.AmbientTextureEnabled = ambientCB.selected;
		StandardMaterial.SpecularTextureEnabled = specularCB.selected;
		StandardMaterial.EmissiveTextureEnabled = emissiveCB.selected;
		StandardMaterial.OpacityTextureEnabled = opacityCB.selected;
		StandardMaterial.ReflectionTextureEnabled = reflectionCB.selected;
		scene.shadowsEnabled = shadowsCB.selected;
		scene.particlesEnabled = particlesCB.selected;
		scene.postProcessesEnabled = postprocessesCB.selected;
		scene.collisionsEnabled = collisionsCB.selected;
		scene.lightsEnabled = lightsCB.selected;
		scene.lensFlaresEnabled = lensflaresCB.selected;
		scene.renderTargetsEnabled = rendertargetsCB.selected;
		scene.proceduralTexturesEnabled = proceduraltexturesCB.selected;
	}
	
}