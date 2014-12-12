package example;

import babylon.cameras.ArcRotateCamera;
import babylon.lights.PointLight;
import babylon.materials.Effect;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.math.Viewport;
import babylon.mesh.MeshHelper;
import babylon.postprocess.BlackAndWhitePostProcess;
import babylon.postprocess.BlurPostProcess;
import babylon.postprocess.PostProcess;
import babylon.postprocess.renderpipeline.PostProcessRenderEffect;
import babylon.postprocess.renderpipeline.PostProcessRenderPipeline;
import openfl.Lib;

class PostProcessRenderPipelineManagerDemo extends BaseDemo
{
    override function onInit():Void
    {
		//左下角是0,0
    	var camera_01 = new ArcRotateCamera("Camera_01", 1, 0.8, 10, new Vector3(0, 0, 0), scene);
		var camera_02 = new ArcRotateCamera("Camera_02", 1, 0.8, 10, new Vector3(0, 0, 0), scene);
		var camera_03 = new ArcRotateCamera("Camera_03", 1, 0.8, 10, new Vector3(0, 0, 0), scene);
		var camera_04 = new ArcRotateCamera("Camera_04", 1, 0.8, 10, new Vector3(0, 0, 0), scene);

		camera_01.viewport = new Viewport(0.0, 0.0, 0.5, 0.5);
		camera_02.viewport = new Viewport(0.5, 0.0, 0.5, 0.5);
		camera_03.viewport = new Viewport(0.0, 0.5, 0.5, 0.5);
		camera_04.viewport = new Viewport(0.5, 0.5, 0.5, 0.5);

		scene.activeCameras.push(camera_01);
		scene.activeCameras.push(camera_02);
		scene.activeCameras.push(camera_03);
		scene.activeCameras.push(camera_04);

		var light0 = new PointLight("Omni_0", new Vector3(0, 0, 10), scene);
		var light1 = new PointLight("Omni_1", new Vector3(0, 10, 0), scene);
		var light2 = new PointLight("Omni_2", new Vector3(10, 0, 0), scene);
		
		light0.diffuse = new Color3(0.8, 0, 0);
    	light0.specular = new Color3(0.8, 0, 0);
		
		light1.diffuse = new Color3(0, 0.8, 0);
    	light1.specular = new Color3(0, 0.8, 0);
		
		light2.diffuse = new Color3(0, 0, 0.8);
    	light2.specular = new Color3(0, 0, 0.8);

		var box = MeshHelper.CreateBox("Box", 3.0, scene);
		box.showBoundingBox = true;
		
		var sm:StandardMaterial = new StandardMaterial("yellow", scene);
		sm.diffuseColor = new Color3(1, 1, 1);
		sm.specularColor = new Color3(0, 0, 0);
		sm.emissiveColor = new Color3(0.2, 0.2, 0.2);
		box.material = sm;
		
		// Skybox
		var skybox = MeshHelper.CreateBox("skyBox", 1000.0, scene);
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;

		camera_01.attachControl(this.touchLayer);
		camera_02.attachControl(this.touchLayer);
		camera_03.attachControl(this.touchLayer);
		camera_04.attachControl(this.touchLayer);

		var standardPipeline = new PostProcessRenderPipeline(engine, "standardPipeline");

		var blackAndWhiteEffect = new PostProcessRenderEffect(engine, "blackAndWhiteEffect", function():PostProcess
		{
			return new BlackAndWhitePostProcess("blackAndWhiteEffect", 1.0, null, 1, engine);
		});

		var horizontalBlur = new PostProcessRenderEffect(engine, "horizontalBlurEffect", function():PostProcess
		{
			var postProcess:PostProcess = new BlurPostProcess("horizontalBlurEffect", new Vector2(0, 0), 1, 1, null, 1, engine);
			postProcess.onApply = function(effect:Effect):Void 
			{
				effect.setFloat2("screenSize", engine.getStage().stageWidth, engine.getStage().stageHeight);  
				effect.setVector2("direction", new Vector2(1.0, 0));
				effect.setFloat("blurWidth", 3);
			};
			return postProcess;
		});
		
		

		var verticalBlur = new PostProcessRenderEffect(engine, "verticalBlurEffect", function():PostProcess
		{
			var postProcess:PostProcess = new BlurPostProcess("verticalBlurEffect", new Vector2(0, 0), 1, 1, null, 1, engine);
			postProcess.onApply = function(effect:Effect):Void 
			{
				effect.setFloat2("screenSize", engine.getStage().stageWidth, engine.getStage().stageHeight);  
				effect.setVector2("direction", new Vector2(0, 1.0));
				effect.setFloat("blurWidth", 3);
			};
			return postProcess;
		});
		

		standardPipeline.addEffect(blackAndWhiteEffect);
		standardPipeline.addEffect(horizontalBlur);
		standardPipeline.addEffect(verticalBlur);

		scene.postProcessRenderPipelineManager.addPipeline(standardPipeline);
		scene.postProcessRenderPipelineManager.attachCamerasToRenderPipeline("standardPipeline", camera_01);
		scene.postProcessRenderPipelineManager.attachCamerasToRenderPipeline("standardPipeline", camera_02);
		scene.postProcessRenderPipelineManager.attachCamerasToRenderPipeline("standardPipeline", camera_03);
		scene.postProcessRenderPipelineManager.attachCamerasToRenderPipeline("standardPipeline", camera_04);

		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "blackAndWhiteEffect", camera_01);

		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "blackAndWhiteEffect", camera_02);
		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "horizontalBlurEffect", camera_02);
		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "verticalBlurEffect", camera_02);

		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "horizontalBlurEffect", camera_03);
		scene.postProcessRenderPipelineManager.disableEffectInPipeline("standardPipeline", "verticalBlurEffect", camera_03);
		
    	scene.executeWhenReady(function() {
    		engine.runRenderLoop(scene.render);
    	});
    }

    public function new()
    {
    	super();
    }

    public static function main()
    {
    	Lib.current.addChild(new PostProcessRenderPipelineManagerDemo());
    }
}
