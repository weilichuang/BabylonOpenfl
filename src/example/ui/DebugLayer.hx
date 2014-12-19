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
		
		statisticsCB.onClick = function(e) {
			demo.showStatistics(statisticsCB.selected);
        };
		
		meshTreeCB.onClick = function(e) {
			demo.showMeshTree(meshTreeCB.selected);
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
		
		fresnelCB.onClick = function(e) {
            StandardMaterial.FresnelEnabled = fresnelCB.selected;
        };
		
		animationsCB.onClick = function(e) {
            scene.shadowsEnabled = animationsCB.selected;
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
		
		fogCB.onClick = function(e) {
            scene.fogEnabled = fogCB.selected;
        };
	}
	
	public function applyConfig():Void
	{
		demo.showStatistics(statisticsCB.selected);
		demo.showMeshTree(meshTreeCB.selected);
		
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