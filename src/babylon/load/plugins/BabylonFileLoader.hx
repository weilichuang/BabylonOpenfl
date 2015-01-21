package babylon.load.plugins;

import babylon.actions.Action;
import babylon.actions.ActionManager;
import babylon.actions.Condition;
import babylon.actions.ValueCondition;
import babylon.animations.Animation;
import babylon.bones.Bone;
import babylon.bones.Skeleton;
import babylon.cameras.AnaglyphArcRotateCamera;
import babylon.cameras.AnaglyphFreeCamera;
import babylon.cameras.ArcRotateCamera;
import babylon.cameras.Camera;
import babylon.cameras.FollowCamera;
import babylon.cameras.FreeCamera;
import babylon.culling.BoundingInfo;
import babylon.Engine;
import babylon.lensflare.LensFlare;
import babylon.lensflare.LensFlareSystem;
import babylon.lights.DirectionalLight;
import babylon.lights.HemisphericLight;
import babylon.lights.Light;
import babylon.lights.PointLight;
import babylon.lights.shadows.ShadowGenerator;
import babylon.lights.SpotLight;
import babylon.load.plugins.BabylonFileLoader;
import babylon.materials.FresnelParameters;
import babylon.materials.Material;
import babylon.materials.MultiMaterial;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.CubeTexture;
import babylon.materials.textures.MirrorTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.materials.textures.Texture;
import babylon.math.Color3;
import babylon.math.Color4;
import babylon.math.FastMath;
import babylon.math.Matrix;
import babylon.math.Quaternion;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.math.Vector4;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Geometry;
import babylon.mesh.InstancedMesh;
import babylon.mesh.Mesh;
import babylon.mesh.primitives.Box;
import babylon.mesh.primitives.Cylinder;
import babylon.mesh.primitives.Ground;
import babylon.mesh.primitives.Plane;
import babylon.mesh.primitives.Sphere;
import babylon.mesh.primitives.Torus;
import babylon.mesh.primitives.TorusKnot;
import babylon.mesh.SubMesh;
import babylon.mesh.VertexBuffer;
import babylon.mesh.VertexData;
import babylon.particles.ParticleSystem;
import babylon.Scene;
import babylon.utils.Logger;
import haxe.Json;
import openfl.Lib;
import openfl.utils.ByteArray;

using babylon.utils.StringUtil;

class BabylonFileLoader implements ISceneLoaderPlugin
{

	public function new() 
	{
		
	}
	
	private function checkColors4(colors: Array<Float>, count:Int):Array<Float>
	{
        // Check if color3 was used
        if (colors.length == count * 3)
		{
            var colors4:Array<Float> = [];
			var index:Int = 0;
			while (index < colors.length) 
			{
                var newIndex:Int = Std.int(index / 3) * 4;
                colors4[newIndex] = colors[index];
                colors4[newIndex + 1] = colors[index + 1];
                colors4[newIndex + 2] = colors[index + 2];
                colors4[newIndex + 3] = 1.0;
				
				index += 3;
            }

            return colors4;
        } 

        return colors;
    }
	
	private function loadCubeTexture(rootUrl:String, parsedTexture:Dynamic, scene:Scene):CubeTexture
	{
        var texture:CubeTexture = new CubeTexture(rootUrl + parsedTexture.name, scene);

        texture.name = parsedTexture.name;
        texture.hasAlpha = parsedTexture.hasAlpha;
        texture.level = parsedTexture.level;
        texture.coordinatesMode = parsedTexture.coordinatesMode;

        return texture;
    }
	
	private function loadTexture(rootUrl:String, parsedTexture:Dynamic, scene:Scene):Dynamic 
	{
        if (parsedTexture.name == null && (parsedTexture.isRenderTarget == null || parsedTexture.isRenderTarget == false))
		{
            return null;
        }

        if (parsedTexture.isCube != null && parsedTexture.isCube == true)
		{
            return loadCubeTexture(rootUrl, parsedTexture, scene);
        }

        var texture:Texture = null;

        if (parsedTexture.mirrorPlane != null) 
		{
            texture = new MirrorTexture(parsedTexture.name, parsedTexture.renderTargetSize, scene);
            Std.instance(texture, MirrorTexture)._waitingRenderList = parsedTexture.renderList;
            Std.instance(texture, MirrorTexture).mirrorPlane = babylon.math.Plane.FromArray(parsedTexture.mirrorPlane);
        } 
		else if (parsedTexture.isRenderTarget) 
		{
            texture = new RenderTargetTexture(parsedTexture.name, parsedTexture.renderTargetSize, scene);
            Std.instance(texture, RenderTargetTexture)._waitingRenderList = parsedTexture.renderList;
        }
		else 
		{
            texture = new Texture(rootUrl + parsedTexture.name, scene);
        }

        texture.name = parsedTexture.name;								
        texture.hasAlpha = parsedTexture.hasAlpha;	
		texture.getAlphaFromRGB = parsedTexture.getAlphaFromRGB;
        texture.level = parsedTexture.level;	

        texture.coordinatesIndex = parsedTexture.coordinatesIndex;	    
        texture.coordinatesMode = parsedTexture.coordinatesMode;		
        texture.uOffset = parsedTexture.uOffset;						
        texture.vOffset = parsedTexture.vOffset;						
        texture.uScale = parsedTexture.uScale;							
        texture.vScale = parsedTexture.vScale;							
        texture.uAng = parsedTexture.uAng;								
        texture.vAng = parsedTexture.vAng;								
        texture.wAng = parsedTexture.wAng;								

        texture.wrapU = parsedTexture.wrapU;							
        texture.wrapV = parsedTexture.wrapV;
		
        // Animations
		var animations:Array<Dynamic> = parsedTexture.animations;
        if (animations != null) 
		{
            for (animationIndex in 0...animations.length) 
			{
                var animation = animations[animationIndex];

                texture.animations.push(parseAnimation(animation));
            }
        }
		
        return texture;
    }
	
	private function parseSkeleton(parsedSkeleton:Dynamic, scene:Scene):Skeleton 
	{
        var skeleton:Skeleton = new Skeleton(parsedSkeleton.name, parsedSkeleton.id, scene);

		var bones:Array<Dynamic> = parsedSkeleton.bones;
        for (index in 0...bones.length) 
		{
            var parsedBone:Dynamic = bones[index];

            var parentBone:Bone = null;
            if (parsedBone.parentBoneIndex > -1) 
			{
                parentBone = skeleton.bones[parsedBone.parentBoneIndex];
            }

            var bone:Bone = new Bone(parsedBone.name, skeleton, parentBone, Matrix.FromArray(parsedBone.matrix));

            if (parsedBone.animation != null) 
			{
                bone.animations.push(parseAnimation(parsedBone.animation));
            }
        }

        return skeleton;
    }
	
	private function  parseFresnelParameters(parsedFresnelParameters:Dynamic):FresnelParameters 
	{
        var fresnelParameters:FresnelParameters = new FresnelParameters();

        fresnelParameters.isEnabled = parsedFresnelParameters.isEnabled;
		if(parsedFresnelParameters.leftColor != null)
			fresnelParameters.leftColor = Color3.FromArray(parsedFresnelParameters.leftColor);
		if(parsedFresnelParameters.rightColor != null)
			fresnelParameters.rightColor = Color3.FromArray(parsedFresnelParameters.rightColor);
		if(parsedFresnelParameters.bias != null)
			fresnelParameters.bias = parsedFresnelParameters.bias;
		if(parsedFresnelParameters.power != null)
			fresnelParameters.power = parsedFresnelParameters.power;

        return fresnelParameters;
    }
	
	private function parseMaterial(parsedMaterial:Dynamic, scene:Scene, rootUrl:String):Material 
	{
        var material:StandardMaterial = new StandardMaterial(parsedMaterial.name, scene);
		
        material.ambientColor = Color3.FromArray(parsedMaterial.ambient);
        material.diffuseColor = Color3.FromArray(parsedMaterial.diffuse);
        material.specularColor = Color3.FromArray(parsedMaterial.specular);
        material.specularPower = parsedMaterial.specularPower;
        material.emissiveColor = Color3.FromArray(parsedMaterial.emissive);

        material.alpha = parsedMaterial.alpha;

        material.id = parsedMaterial.id;
		
		//Tags.AddTagsTo(material, parsedMaterial.tags);
		
		if(parsedMaterial.backFaceCulling != null)
			material.backFaceCulling = parsedMaterial.backFaceCulling;
			
		if(parsedMaterial.wireframe != null)
			material.wireframe = parsedMaterial.wireframe;

        if (parsedMaterial.diffuseTexture != null) 
		{
            material.diffuseTexture = loadTexture(rootUrl, parsedMaterial.diffuseTexture, scene);
        }
		
		if (parsedMaterial.diffuseFresnelParameters != null)
		{
            material.diffuseFresnelParameters = parseFresnelParameters(parsedMaterial.diffuseFresnelParameters);
        }

        if (parsedMaterial.ambientTexture != null)
		{
            material.ambientTexture = loadTexture(rootUrl, parsedMaterial.ambientTexture, scene);
        }

        if (parsedMaterial.opacityTexture != null) 
		{
            material.opacityTexture = loadTexture(rootUrl, parsedMaterial.opacityTexture, scene);
        }
		
		if (parsedMaterial.opacityFresnelParameters != null)
		{
            material.opacityFresnelParameters = parseFresnelParameters(parsedMaterial.opacityFresnelParameters);
        }

        if (parsedMaterial.reflectionTexture != null) 
		{
            material.reflectionTexture = loadTexture(rootUrl, parsedMaterial.reflectionTexture, scene);
        }
		
		if (parsedMaterial.reflectionFresnelParameters != null)
		{
            material.reflectionFresnelParameters = parseFresnelParameters(parsedMaterial.reflectionFresnelParameters);
        }

        if (parsedMaterial.emissiveTexture != null) 
		{
            material.emissiveTexture = loadTexture(rootUrl, parsedMaterial.emissiveTexture, scene);
        }
		
		if (parsedMaterial.emissiveFresnelParameters != null)
		{
            material.emissiveFresnelParameters = parseFresnelParameters(parsedMaterial.emissiveFresnelParameters);
        }

        if (parsedMaterial.specularTexture != null) 
		{
            material.specularTexture = loadTexture(rootUrl, parsedMaterial.specularTexture, scene);
        }

        if (parsedMaterial.bumpTexture != null) 
		{
            material.bumpTexture = loadTexture(rootUrl, parsedMaterial.bumpTexture, scene);
        }

        return material;
    }
	
	private function parseMaterialById(id:String, parsedData:Dynamic, scene:Scene, rootUrl:String):Material
	{
        for (index in 0...parsedData.materials.length) 
		{
            var parsedMaterial = parsedData.materials[index];
            if (parsedMaterial.id == id) 
			{
                return parseMaterial(parsedMaterial, scene, rootUrl);
            }
        }

        return null;
    }
	
	private function parseMultiMaterial(parsedMultiMaterial:Dynamic, scene:Scene):MultiMaterial
	{
        var multiMaterial:MultiMaterial = new MultiMaterial(parsedMultiMaterial.name, scene);

        multiMaterial.id = parsedMultiMaterial.id;
		
		//Tags.AddTagsTo(multiMaterial, parsedMultiMaterial.tags);

        for (matIndex in 0...parsedMultiMaterial.materials.length)
		{
            var subMatId:String = parsedMultiMaterial.materials[matIndex];

            if (subMatId.isValid()) 
			{
                multiMaterial.subMaterials.push(scene.getMaterialByID(subMatId));
            }
			else
			{
                multiMaterial.subMaterials.push(null);
            }
        }

        return multiMaterial;
    }
	
	private function parseLensFlareSystem(parsedLensFlareSystem:Dynamic, scene:Scene, rootUrl:String):LensFlareSystem 
	{
        var emitter = scene.getLastEntryByID(parsedLensFlareSystem.emitterId);

        var lensFlareSystem:LensFlareSystem = new LensFlareSystem("lensFlareSystem#" + parsedLensFlareSystem.emitterId, emitter, scene);
        lensFlareSystem.borderLimit = parsedLensFlareSystem.borderLimit;
        
        for (index in 0...parsedLensFlareSystem.flares.length) 
		{
            var parsedFlare = parsedLensFlareSystem.flares[index];
            var flare:LensFlare = new LensFlare(lensFlareSystem,parsedFlare.size, parsedFlare.position, 
									Color3.FromArray(parsedFlare.color), 
									rootUrl + parsedFlare.textureName);
        }

        return lensFlareSystem;
    }
	
	private function parseParticleSystem(parsedParticleSystem:Dynamic, scene:Scene, rootUrl:String):ParticleSystem 
	{
        var emitter = scene.getLastMeshByID(parsedParticleSystem.emitterId);

        var particleSystem = new ParticleSystem("particles#" + emitter.name, parsedParticleSystem.capacity, scene);
		var textureName:String = parsedParticleSystem.textureName;
        if (textureName.isValid())
		{
            particleSystem.particleTexture = new Texture(rootUrl + textureName, scene);
			particleSystem.particleTexture.name = parsedParticleSystem.textureName;
        }
        particleSystem.minAngularSpeed = parsedParticleSystem.minAngularSpeed;
        particleSystem.maxAngularSpeed = parsedParticleSystem.maxAngularSpeed;
        particleSystem.minSize = parsedParticleSystem.minSize;
        particleSystem.maxSize = parsedParticleSystem.maxSize;
        particleSystem.minLifeTime = parsedParticleSystem.minLifeTime;
        particleSystem.maxLifeTime = parsedParticleSystem.maxLifeTime;
        particleSystem.emitter = emitter;
        particleSystem.emitRate = parsedParticleSystem.emitRate;
        particleSystem.minEmitBox = Vector3.FromArray(parsedParticleSystem.minEmitBox);
        particleSystem.maxEmitBox = Vector3.FromArray(parsedParticleSystem.maxEmitBox);
        particleSystem.gravity = Vector3.FromArray(parsedParticleSystem.gravity);
        particleSystem.direction1 = Vector3.FromArray(parsedParticleSystem.direction1);
        particleSystem.direction2 = Vector3.FromArray(parsedParticleSystem.direction2);
        particleSystem.color1 = Color4.FromArray(parsedParticleSystem.color1);
        particleSystem.color2 = Color4.FromArray(parsedParticleSystem.color2);
        particleSystem.colorDead = Color4.FromArray(parsedParticleSystem.colorDead);
        particleSystem.updateSpeed = parsedParticleSystem.updateSpeed;
        particleSystem.targetStopDuration = parsedParticleSystem.targetStopFrame;
        particleSystem.textureMask = Color4.FromArray(parsedParticleSystem.textureMask);
        particleSystem.blendMode = parsedParticleSystem.blendMode;
        particleSystem.start();
		
        return particleSystem;
    }
	
	private function parseShadowGenerator(parsedShadowGenerator:Dynamic, scene:Scene):ShadowGenerator 
	{
        var light:Light = scene.getLightByID(parsedShadowGenerator.lightId);
        var shadowGenerator:ShadowGenerator = new ShadowGenerator(parsedShadowGenerator.mapSize, cast light);

		var renderList:Array<Dynamic> = parsedShadowGenerator.renderList;
        for (meshIndex in 0...renderList.length)
		{
            var mesh:AbstractMesh = scene.getMeshByID(renderList[meshIndex]);

            shadowGenerator.getShadowMap().renderList.push(mesh);
        }
		
		if (parsedShadowGenerator.usePoissonSampling)
		{
            shadowGenerator.usePoissonSampling = true;
        } 
		else 
		{
            shadowGenerator.useVarianceShadowMap = parsedShadowGenerator.useVarianceShadowMap;
        }

        return shadowGenerator;
    }
	
	private function parseAnimation(parsedAnimation:Dynamic):Animation 
	{
        var animation = new Animation(parsedAnimation.name, 
										parsedAnimation.property, 
										parsedAnimation.framePerSecond, 
										parsedAnimation.dataType, 
										parsedAnimation.loopBehavior);

        var dataType = parsedAnimation.dataType;
        var keys:Array<BabylonFrame> = [];
        for (index in 0...parsedAnimation.keys.length) 
		{
            var key:Dynamic = parsedAnimation.keys[index];

            var data:Dynamic = null;

            switch (dataType) 
			{
                case Animation.ANIMATIONTYPE_FLOAT:
                    data = key.values[0];
                
                case Animation.ANIMATIONTYPE_QUATERNION:
                    data = Quaternion.FromArray(key.values);
              
                case Animation.ANIMATIONTYPE_MATRIX:
                    data = Matrix.FromArray(key.values);
                
                case Animation.ANIMATIONTYPE_VECTOR3:
                    data = Vector3.FromArray(key.values);
					
				case Animation.ANIMATIONTYPE_VECTOR2:
                    data = Vector2.FromArray(key.values);
					
                default:
                    data = Vector3.FromArray(key.values);
                
            }

            keys.push({
                frame: key.frame,
                value: data
            });
        }

        animation.setKeys(keys);

        return animation;
    }
	
	private function parseLight(parsedLight:Dynamic, scene:Scene):Light 
	{
        var light:Light = null;

        switch (parsedLight.type) 
		{
            case 0:
                light = new PointLight(parsedLight.name, Vector3.FromArray(parsedLight.position), scene);
                
            case 1:
                light = new DirectionalLight(parsedLight.name, Vector3.FromArray(parsedLight.direction), scene);
                light.position = Vector3.FromArray(parsedLight.position);
            
            case 2:
                light = new SpotLight(parsedLight.name, 
									Vector3.FromArray(parsedLight.position), 
									Vector3.FromArray(parsedLight.direction), 
									parsedLight.angle, parsedLight.exponent, scene);
            
            case 3:
                light = new HemisphericLight(parsedLight.name, 
											Vector3.FromArray(parsedLight.direction), scene);
                cast(light, HemisphericLight).groundColor = Color3.FromArray(parsedLight.groundColor);
        }

        light.id = parsedLight.id;
		
		//Tags.AddTagsTo(light, parsedLight.tags);

        if (parsedLight.intensity != null)
		{
            light.intensity = parsedLight.intensity;
        }
		
		if (parsedLight.range != null)
		{
            light.range = parsedLight.range;
        }
		
        light.diffuse = Color3.FromArray(parsedLight.diffuse);
        light.specular = Color3.FromArray(parsedLight.specular);
		
		if (parsedLight.excludedMeshesIds != null) 
		{
            light._excludedMeshesIds = parsedLight.excludedMeshesIds;
        }
		
		if (parsedLight.includedOnlyMeshesIds != null) 
		{
            light._includedOnlyMeshesIds = parsedLight.includedOnlyMeshesIds;
        }
		
		// Parent
        if (parsedLight.parentId != null)
		{
            light._waitingParentId = parsedLight.parentId;
        }
		
		// Animations
        if (parsedLight.animations != null)
		{
            for (animationIndex in 0...parsedLight.animations.length)
			{
                var parsedAnimation = parsedLight.animations[animationIndex];

                light.animations.push(parseAnimation(parsedAnimation));
            }
        }

        if (parsedLight.autoAnimate != null && parsedLight.autoAnimate == true)
		{
            scene.beginAnimation(light, parsedLight.autoAnimateFrom, parsedLight.autoAnimateTo, parsedLight.autoAnimateLoop, 1.0);
        }
				
		return light;
    }
	
	private function parseCamera(parsedCamera:Dynamic, scene:Scene):Camera
	{
        var camera:Dynamic;
        var position:Vector3 = Vector3.FromArray(parsedCamera.position);
        var lockedTargetMesh:AbstractMesh = StringUtil.isValid(parsedCamera.lockedTargetId) ? scene.getLastMeshByID(parsedCamera.lockedTargetId) : null;
		
		if (parsedCamera.type == null)
		{
			parsedCamera.type = "FreeCamera";
		}

        if (parsedCamera.type == "AnaglyphArcRotateCamera" || parsedCamera.type == "ArcRotateCamera") 
		{
            var alpha:Float = parsedCamera.alpha;
            var beta:Float = parsedCamera.beta;
            var radius:Float = parsedCamera.radius;
            if (parsedCamera.type == "AnaglyphArcRotateCamera")
			{
                var eye_space = parsedCamera.eye_space;
                camera = new AnaglyphArcRotateCamera(parsedCamera.name, alpha, beta, radius, lockedTargetMesh, eye_space, scene);
            } 
			else 
			{
                camera = new ArcRotateCamera(parsedCamera.name, alpha, beta, radius, lockedTargetMesh, scene);
            }

        } 
		else if (parsedCamera.type == "AnaglyphFreeCamera")
		{
            var eye_space = parsedCamera.eye_space;
            camera = new AnaglyphFreeCamera(parsedCamera.name, position, eye_space, scene);

        }
		//else if (parsedCamera.type == "DeviceOrientationCamera")
		//{
            //camera = new DeviceOrientationCamera(parsedCamera.name, position, scene);
        //} 
		else if (parsedCamera.type == "FollowCamera")
		{
            camera = new FollowCamera(parsedCamera.name, position, scene);
            cast(camera,FollowCamera).heightOffset = parsedCamera.heightOffset;
            cast(camera,FollowCamera).radius = parsedCamera.radius;
            cast(camera,FollowCamera).rotationOffset = parsedCamera.rotationOffset;
            if (lockedTargetMesh != null)
                cast(camera,FollowCamera).target = lockedTargetMesh;

        } 
		//else if (parsedCamera.type == "GamepadCamera")
		//{
            //camera = new GamepadCamera(parsedCamera.name, position, scene);
        //} 
		//else if (parsedCamera.type == "OculusCamera") 
		//{
            //camera = new OculusCamera(parsedCamera.name, position, scene);
        //} 
		//else if (parsedCamera.type == "TouchCamera")
		//{
            //camera = new TouchCamera(parsedCamera.name, position, scene);
        //}
		//else if (parsedCamera.type == "VirtualJoysticksCamera") 
		//{
            //camera = new VirtualJoysticksCamera(parsedCamera.name, position, scene);
        //} 
		//else if (parsedCamera.type == "WebVRCamera")
		//{
            //camera = new WebVRCamera(parsedCamera.name, position, scene);
        //}
		//else if (parsedCamera.type == "VRDeviceOrientationCamera") 
		//{
            //camera = new VRDeviceOrientationCamera(parsedCamera.name, position, scene);
        //}
		else 
		{
            // Free Camera is the default value
            camera = new FreeCamera(parsedCamera.name, position, scene);
        }
		
        camera.id = parsedCamera.id;

		//Tags.AddTagsTo(camera, parsedCamera.tags);
		
        // Parent
        if (parsedCamera.parentId != null)
		{
            camera._waitingParentId = parsedCamera.parentId;
        }

        // Target
        if (parsedCamera.target != null)
		{
            camera.setTarget(Vector3.FromArray(parsedCamera.target));
        } 
		else 
		{
            camera.rotation = Vector3.FromArray(parsedCamera.rotation);
        }

        camera.fov = parsedCamera.fov;
        camera.minZ = parsedCamera.minZ;
        camera.maxZ = parsedCamera.maxZ;

        camera.speed = parsedCamera.speed;
        camera.inertia = parsedCamera.inertia;

        camera.checkCollisions = parsedCamera.checkCollisions;
        camera.applyGravity = parsedCamera.applyGravity;
        if (parsedCamera.ellipsoid != null) 
		{
            camera.ellipsoid = Vector3.FromArray(parsedCamera.ellipsoid);
        }

        // Animations
		var animations:Array<Dynamic> = parsedCamera.animations;
        if (animations != null) 
		{
            for (animationIndex in 0...animations.length)
			{
                camera.animations.push(parseAnimation(animations[animationIndex]));
            }
        }

        if (parsedCamera.autoAnimate != null && parsedCamera.autoAnimate == true)
		{
            scene.beginAnimation(camera, parsedCamera.autoAnimateFrom, parsedCamera.autoAnimateTo, parsedCamera.autoAnimateLoop, 1.0);
        }
		
		// Layer Mask
        if (parsedCamera.layerMask != null && !Math.isNaN(parsedCamera.layerMask))
		{
            camera.layerMask = FastMath.iabs(Std.parseInt(parsedCamera.layerMask));
        } 
		else
		{
            camera.layerMask = 0xFFFFFFFF;
        }

        return camera;
    }
	
	private function parseGeometry(parsedGeometry:Dynamic, scene:Scene):Geometry
	{
		var id:String = parsedGeometry.id;
		return scene.getGeometryByID(id);
	}
	
	private function parseBox(parsedBox:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedBox, scene) != null)
		{
			return null; //null since geometry could be something else than a box...
		}
		
		var box:Box = new Box(parsedBox.id, scene, parsedBox.size, parsedBox.canBeRegenerated, null);
		
		//Tags.AddTagsTo(box, parsedBox.tags);
		
		scene.pushGeometry(box, true);
		
		return box;
	}
	
	private function parseSphere(parsedSphere:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedSphere, scene) != null)
		{
			return null; //null since geometry could be something else than a sphere...
		}
		
		var sphere = new Sphere(parsedSphere.id, scene, parsedSphere.segments, parsedSphere.diameter, parsedSphere.canBeRegenerated, null);
		
		//Tags.AddTagsTo(sphere, parsedSphere.tags);
		
		scene.pushGeometry(sphere, true);
		
		return sphere;
	}
	
	private function parseCylinder(parsedCylinder:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedCylinder, scene) != null) 
		{
			return null; //null since geometry could be something else than a cylinder...
		}
		
		if (parsedCylinder.subdivisions == null)
			parsedCylinder.subdivisions = 1;
		
		var cylinder = new Cylinder(parsedCylinder.id, scene, parsedCylinder.height, parsedCylinder.diameterTop, parsedCylinder.diameterBottom, parsedCylinder.tessellation, parsedCylinder.subdivisions, parsedCylinder.canBeRegenerated, null);
		
		//Tags.AddTagsTo(cylinder, parsedCylinder.tags);
		
		scene.pushGeometry(cylinder, true);
		
		return cylinder;
	}
	
	private function parseTorus(parsedTorus:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedTorus, scene) != null)
		{
			return null; //null since geometry could be something else than a torus...
		}
		
		var torus = new Torus(parsedTorus.id, scene, parsedTorus.diameter, parsedTorus.thickness, parsedTorus.tessellation, parsedTorus.canBeRegenerated, null);
		
		//Tags.AddTagsTo(torus, parsedTorus.tags);
		
		scene.pushGeometry(torus, true);
		
		return torus;
	}
	
	private function parseGround(parsedGround:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedGround, scene) != null)
		{
			return null; //null since geometry could be something else than a ground...
		}
		
		var ground = new Ground(parsedGround.id, scene, parsedGround.width, parsedGround.height, parsedGround.subdivisions, parsedGround.canBeRegenerated, null);
		
		//Tags.AddTagsTo(ground, parsedGround.tags);
		
		scene.pushGeometry(ground, true);
		
		return ground;
	}
	
	private function parsePlane(parsedPlane:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedPlane, scene) != null)
		{
			return null; //null since geometry could be something else than a plane...
		}
		
		var plane = new Plane(parsedPlane.id, scene, parsedPlane.size, parsedPlane.canBeRegenerated, null);
		
		//Tags.AddTagsTo(plane, parsedPlane.tags);
		
		scene.pushGeometry(plane, true);
		
		return plane;
	}
	
	private function parseTorusKnot(parsedTorusKnot:Dynamic, scene:Scene):Geometry
	{
		if (parseGeometry(parsedTorusKnot, scene) != null) 
		{
			return null; //null since geometry could be something else than a torusKnot...
		}
		
		var torusKnot = new TorusKnot(parsedTorusKnot.id, scene, parsedTorusKnot.radius, parsedTorusKnot.tube, parsedTorusKnot.radialSegments, parsedTorusKnot.tubularSegments, parsedTorusKnot.p, parsedTorusKnot.q, parsedTorusKnot.canBeRegenerated, null);
		//Tags.AddTagsTo(torusKnot, parsedTorusKnot.tags);
		
		scene.pushGeometry(torusKnot, true);
		
		return torusKnot;
	}
	
	private function parseVertexData(parsedVertexData:Dynamic, scene:Scene, rootUrl:String):Geometry
	{
		if (parseGeometry(parsedVertexData, scene) != null)
		{
			return null; //null since geometry could be a primitive
		}
		
		var geometry:Geometry = new Geometry(parsedVertexData.id, scene);
		
		//Tags.AddTagsTo(geometry, parsedVertexData.tags);
		
		var delayLoadingFile:String = parsedVertexData.delayLoadingFile;
		if (delayLoadingFile.isValid())
		{
			#if debug
			Logger.log(parsedVertexData.id + "需要加载VertexData:" + delayLoadingFile);
			#end
            
			geometry.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
            geometry.delayLoadingFile = rootUrl + delayLoadingFile;
            geometry._boundingInfo = new BoundingInfo(Vector3.FromArray(parsedVertexData.boundingBoxMinimum), Vector3.FromArray(parsedVertexData.boundingBoxMaximum));

            geometry._delayInfo = [];
            if (parsedVertexData.hasUVs)
			{
                geometry._delayInfo.push(VertexBuffer.UVKind);
            }

            if (parsedVertexData.hasUVs2)
			{
                geometry._delayInfo.push(VertexBuffer.UV2Kind);
            }

            if (parsedVertexData.hasColors)
			{
                geometry._delayInfo.push(VertexBuffer.ColorKind);
            }

            if (parsedVertexData.hasMatricesIndices) 
			{
                geometry._delayInfo.push(VertexBuffer.MatricesIndicesKind);
            }

            if (parsedVertexData.hasMatricesWeights)
			{
                geometry._delayInfo.push(VertexBuffer.MatricesWeightsKind);
            }

            geometry._delayLoadingFunction = importVertexData;
        } 
		else
		{
            importVertexData(parsedVertexData, geometry);
        }
		
		scene.pushGeometry(geometry, true);
		
		return geometry;
	}
	
	private function parseMesh(parsedMesh:Dynamic, scene:Scene, rootUrl:String):Mesh
	{
        var mesh:Mesh = new Mesh(parsedMesh.name, scene);
		
        mesh.id = parsedMesh.id;
        mesh.position = Vector3.FromArray(parsedMesh.position);
		
		if (parsedMesh.rotationQuaternion != null) 
		{
            mesh.rotationQuaternion = Quaternion.FromArray(parsedMesh.rotationQuaternion);
        }
        else if (parsedMesh.rotation != null) 
		{
            mesh.rotation = Vector3.FromArray(parsedMesh.rotation);
        } 
		
		if(parsedMesh.scaling != null)
			mesh.scaling = Vector3.FromArray(parsedMesh.scaling);

        if (parsedMesh.localMatrix != null) 
		{
            mesh.setPivotMatrix(Matrix.FromArray(parsedMesh.localMatrix));
        }
		else if (parsedMesh.pivotMatrix != null) 
		{
            mesh.setPivotMatrix(Matrix.FromArray(parsedMesh.pivotMatrix));
        }

        mesh.setEnabled(parsedMesh.isEnabled);
        mesh.isVisible = parsedMesh.isVisible;
		if (parsedMesh.infiniteDistance != null)
		{
			mesh.infiniteDistance = parsedMesh.infiniteDistance;
		}
        
		if (parsedMesh.showBoundingBox != null)
		{
			mesh.showBoundingBox = parsedMesh.showBoundingBox;
		}
		
		if (parsedMesh.showSubMeshesBoundingBox != null) 
		{
			mesh.showSubMeshesBoundingBox = parsedMesh.showSubMeshesBoundingBox;
		}
		
		if (parsedMesh.applyFog != null) 
		{
            mesh.applyFog = parsedMesh.applyFog;
        }
		
		if (parsedMesh.pickable != null) 
		{
			mesh.isPickable = parsedMesh.pickable;
		}
		
		if (parsedMesh.alphaIndex != null)
		{
            mesh.alphaIndex = parsedMesh.alphaIndex;
        }
        
		if (parsedMesh.receiveShadows != null) 
		{
			mesh.receiveShadows = parsedMesh.receiveShadows;
		}
        
		if (parsedMesh.billboardMode != null) 
		{
			mesh.billboardMode = parsedMesh.billboardMode;
		}
        
        if (parsedMesh.visibility != null) 
		{
            mesh.visibility = parsedMesh.visibility;
        }

		if (parsedMesh.checkCollisions != null) 
		{
            mesh.checkCollisions = parsedMesh.checkCollisions;
        }
		
		if (parsedMesh.useFlatShading != null) 
		{
            mesh._shouldGenerateFlatShading = parsedMesh.useFlatShading;
        }
		
        // Parent
        if (StringUtil.isValid(parsedMesh.parentId)) 
		{
            mesh.parent = scene.getLastEntryByID(parsedMesh.parentId);
        }
		
		if (StringUtil.isValid(parsedMesh.hasVertexAlpha)) 
		{
            mesh.hasVertexAlpha = parsedMesh.hasVertexAlpha;
        }
		
		// Actions
        if (parsedMesh.actions != null)
		{
            mesh._waitingActions = parsedMesh.actions;
        }
		
        // Geometry
        if (StringUtil.isValid(parsedMesh.delayLoadingFile))
		{
			#if debug
			Logger.log(parsedMesh.id + "需要加载Mesh:" + parsedMesh.delayLoadingFile);
			#end
			
            mesh.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
            mesh.delayLoadingFile = rootUrl + parsedMesh.delayLoadingFile;
            mesh._boundingInfo = new BoundingInfo(Vector3.FromArray(parsedMesh.boundingBoxMinimum), Vector3.FromArray(parsedMesh.boundingBoxMaximum));
			
			if (parsedMesh._binaryInfo != null) 
			{
                mesh._binaryInfo = parsedMesh._binaryInfo;
            }

            mesh._delayInfo = [];
            if (parsedMesh.hasUVs) 
			{
                mesh._delayInfo.push(VertexBuffer.UVKind);
            }

            if (parsedMesh.hasUVs2)
			{
                mesh._delayInfo.push(VertexBuffer.UV2Kind);
            }

            if (parsedMesh.hasColors)
			{
                mesh._delayInfo.push(VertexBuffer.ColorKind);
            }

            if (parsedMesh.hasMatricesIndices)
			{
                mesh._delayInfo.push(VertexBuffer.MatricesIndicesKind);
            }

            if (parsedMesh.hasMatricesWeights)
			{
                mesh._delayInfo.push(VertexBuffer.MatricesWeightsKind);
            }
			
			mesh._delayLoadingFunction = importGeometry;
			
			if (SceneLoader.ForceFullSceneLoadingForIncremental) 
			{
				mesh._checkDelayState();
			}

        } else
		{
            importGeometry(parsedMesh, mesh);
        }

        // Material
        if (parsedMesh.materialId != null) 
		{
            mesh.setMaterialByID(parsedMesh.materialId);
        } 
		else 
		{
            mesh.material = null;
        }

        // Skeleton
        if (parsedMesh.skeletonId > -1) 
		{
            mesh.skeleton = scene.getLastSkeletonByID(parsedMesh.skeletonId);
        }
        
        // Physics
        if (parsedMesh.physicsImpostor != null)
		{
            if (!scene.isPhysicsEnabled())
			{
                scene.enablePhysics();
            }
			
			mesh.setPhysicsState(parsedMesh.physicsImpostor, { mass: parsedMesh.physicsMass, friction: parsedMesh.physicsFriction, restitution: parsedMesh.physicsRestitution } );
        }

        // Animations
		var animations:Array<Dynamic> = parsedMesh.animations;
        if (animations != null) 
		{
            for (animationIndex in 0...animations.length) 
			{
                var parsedAnimation = animations[animationIndex];
                mesh.animations.push(parseAnimation(parsedAnimation));
            }
        }

        if (parsedMesh.autoAnimate != null && parsedMesh.autoAnimate != false) 
		{
            scene.beginAnimation(mesh, parsedMesh.autoAnimateFrom, parsedMesh.autoAnimateTo, parsedMesh.autoAnimateLoop, 1.0);
        }
		
		// Layer Mask
        if (parsedMesh.layerMask != null && (!Math.isNaN(parsedMesh.layerMask)))
		{
            mesh.layerMask = FastMath.iabs(Std.parseInt(parsedMesh.layerMask));
        } 
		else
		{
            mesh.layerMask = 0xFFFFFFFF;
        }
		
		// Instances
        if (parsedMesh.instances != null)
		{
            for (index in 0...parsedMesh.instances.length)
			{
                var parsedInstance = parsedMesh.instances[index];
				
                var instance:InstancedMesh = mesh.createInstance(parsedInstance.name);

                //Tags.AddTagsTo(instance, parsedInstance.tags);

                instance.position = Vector3.FromArray(parsedInstance.position);

                if (parsedInstance.rotationQuaternion != null)
				{
                    instance.rotationQuaternion = Quaternion.FromArray(parsedInstance.rotationQuaternion);
                } 
				else if (parsedInstance.rotation != null)
				{
                    instance.rotation = Vector3.FromArray(parsedInstance.rotation);
                }

				if(parsedInstance.scaling != null)
					instance.scaling = Vector3.FromArray(parsedInstance.scaling);

				if(mesh.checkCollisions)
					instance.checkCollisions = mesh.checkCollisions;

                if (parsedMesh.animations != null)
				{
                    for (animationIndex in 0...parsedMesh.animations.length)
					{
                        var parsedAnimation = parsedMesh.animations[animationIndex];

                        instance.animations.push(parseAnimation(parsedAnimation));
                    }
                }
            }
        }

        return mesh;
    }
	
	//TODO need test
	private function parseActions(parsedActions:Dynamic, object:AbstractMesh, scene: Scene):Void
	{
        object.actionManager = new ActionManager(scene);
		
		function parseParameter(name:String, value:String, target:Dynamic, propertyPath:String):Dynamic
		{
			var split:Array<String> = value.split(",");

            if (split.length == 1) 
			{
                var num:Float = Std.parseFloat(split[0]);
                if (Math.isNaN(num))
                    return split[0];
                else
                    return num;
            }

            var effectiveTarget:Array<String> = propertyPath.split(".");
            for (i in 0...effectiveTarget.length) 
			{
                target = Reflect.field(target, effectiveTarget[i]);
            }

            if (split.length == 3)
			{
                var values:Array<Float> = [Std.parseFloat(split[0]), Std.parseFloat(split[1]), Std.parseFloat(split[2])];
                if (Std.is(target,Vector3))
                    return Vector3.FromArray(values);
                else
                    return Color3.FromArray(values);
            }
            else if (split.length == 4)
			{
                var values = [Std.parseFloat(split[0]), Std.parseFloat(split[1]), Std.parseFloat(split[2]), Std.parseFloat(split[3])];
                if (Std.is(target,Vector4))
                    return Vector4.FromArray(values);
                else
                    return Color4.FromArray(values);
            }
			
			return null;
		}
		
        // traverse graph per trigger
        function traverse(parsedAction:Dynamic, trigger:Dynamic, condition:Condition, action:Action, actionManager:ActionManager):Void
		{
            var parameters:Array<Dynamic> = [];
			var target: Dynamic = null;
            var propertyPath: Dynamic = null;

            // Parameters
            if (parsedAction.type == 2)
                parameters.push(actionManager);
            else
                parameters.push(trigger);

			var properties:Array<Dynamic> = parsedAction.properties;
            for (i in 0...properties.length) 
			{
				var property:Dynamic = properties[i];
				
                var value:Dynamic = property.value;
                if (property.name == "target")
				{
                    value = scene.getNodeByName(value);
					target = value;
                }
                else if (property.name != "propertyPath") 
				{
                    if (value == "false" || value == "true")
                        value = (value == "true");
                    else if (parsedAction.type == 2 && property.name == "operator")
                        value = ValueCondition.getConditionByName(value);
                    else
                        value = parseParameter(property.name, value, target, propertyPath);
                }
				else
				{
					propertyPath = value;
				}
                parameters.push(value);
            }
			
            parameters.push(condition);

            // If interpolate value action
            if (parsedAction.name == "InterpolateValueAction") 
			{
                var param = parameters[parameters.length - 2];
                parameters[parameters.length - 1] = param;
                parameters[parameters.length - 2] = condition;
            }

            // Action or condition
            var newAction:Dynamic = Type.createInstance(Type.resolveClass(parsedActions.name), parameters);
            if (Std.is(newAction, Condition))
			{
                condition = newAction;
                newAction = action;
            } 
			else 
			{
                condition = null;
                if (action != null)
                    action.then(newAction);
                else
                    actionManager.registerAction(newAction);
            }

            for (i in 0...parsedAction.children.length)
                traverse(parsedAction.children[i], trigger, condition, newAction, actionManager);
        }

        // triggers
        for (i in 0...parsedActions.children.length)
		{
            var triggerParams: Dynamic;
            var trigger:Dynamic = parsedActions.children[i];

            if (trigger.properties.length > 0)
			{
                triggerParams = { trigger: ActionManager.getTriggerByName(trigger.name), 
									parameter: scene.getMeshByName(trigger.properties[0].value) };
            }
            else
                triggerParams = ActionManager.getTriggerByName(trigger.name);

            for (j in 0...trigger.children.length)
                traverse(trigger.children[j], triggerParams, null, null, object.actionManager);
        }
    }
	
	private function isDescendantOf(mesh:Dynamic, names:Dynamic, hierarchyIds:Array<String>):Bool
	{
		var nameList:Array<String>;
		if (Std.is(names, Array))
		{
			nameList = cast names;
		}
		else
		{
			nameList = [names];
		}
		
		for (name in nameList)
		{
			if (mesh.name == name)
			{
				hierarchyIds.push(mesh.id);
				return true;
			}
		}

		var parentId:String = mesh.parentId;
        if (parentId.isValid() && hierarchyIds.indexOf(mesh.parentId) != -1) 
		{
            hierarchyIds.push(mesh.id);
            return true;
        }

        return false;
    }
	
	private function importVertexData(parsedVertexData:Dynamic, geometry:Geometry):Void 
	{
		var vertexData:VertexData = new VertexData();
		
		// positions
        var positions = parsedVertexData.positions;
        if (positions != null) 
		{
            vertexData.set(positions, VertexBuffer.PositionKind);
        }

        // normals
        var normals = parsedVertexData.normals;
        if (normals != null)
		{
            vertexData.set(normals, VertexBuffer.NormalKind);
        }

        // uvs
        var uvs = parsedVertexData.uvs;
        if (uvs != null)
		{
            vertexData.set(uvs, VertexBuffer.UVKind);
        }

        // uv2s
        var uv2s = parsedVertexData.uv2s;
        if (uv2s != null) 
		{
            vertexData.set(uv2s, VertexBuffer.UV2Kind);
        }

        // colors
        var colors = parsedVertexData.colors;
        if (colors != null) 
		{
            vertexData.set(checkColors4(colors,Std.int(positions.length/3)), VertexBuffer.ColorKind);
        }

        // matricesIndices
        var matricesIndices = parsedVertexData.matricesIndices;
        if (matricesIndices != null)
		{
            vertexData.set(matricesIndices, VertexBuffer.MatricesIndicesKind);
        }

        // matricesWeights
        var matricesWeights = parsedVertexData.matricesWeights;
        if (matricesWeights != null)
		{
            vertexData.set(matricesWeights, VertexBuffer.MatricesWeightsKind);
        }

        // indices
        var indices = parsedVertexData.indices;
        if (indices != null) 
		{
            vertexData.indices = indices;
        }

        geometry.setAllVerticesData(vertexData, parsedVertexData.updatable);
	}
	
	private function importGeometry(parsedGeometry:Dynamic, mesh:Mesh):Void  
	{
		var scene:Scene = mesh.getScene();
		
		// Geometry
		if (Std.is(parsedGeometry,ByteArray))
		{
			trace("parse binary geometry");
			
			var byteArray:ByteArray = cast parsedGeometry;

			var binaryInfo:Dynamic = mesh._binaryInfo;

            if (binaryInfo.positionsAttrDesc != null && binaryInfo.positionsAttrDesc.count > 0)
			{
                var positionsData:Array<Float> = [];
				
				byteArray.position = binaryInfo.positionsAttrDesc.offset;
				for (i in 0...binaryInfo.positionsAttrDesc.count)
				{
					positionsData[i] = byteArray.readFloat();
				}

                mesh.setVerticesData(VertexBuffer.PositionKind, positionsData, false);
            }

            if (binaryInfo.normalsAttrDesc != null && binaryInfo.normalsAttrDesc.count > 0) 
			{
				var normalsData:Array<Float> = [];
				
				byteArray.position = binaryInfo.normalsAttrDesc.offset;
				for (i in 0...binaryInfo.normalsAttrDesc.count)
				{
					normalsData[i] = byteArray.readFloat();
				}

                mesh.setVerticesData(VertexBuffer.NormalKind, normalsData, false);
            }

            if (binaryInfo.uvsAttrDesc != null && binaryInfo.uvsAttrDesc.count > 0) 
			{
				var uvsData:Array<Float> = [];
				
				byteArray.position = binaryInfo.uvsAttrDesc.offset;
				for (i in 0...binaryInfo.uvsAttrDesc.count)
				{
					uvsData[i] = byteArray.readFloat();
				}
				
                mesh.setVerticesData(VertexBuffer.UVKind, uvsData, false);
            }

            if (binaryInfo.uvs2AttrDesc != null && binaryInfo.uvs2AttrDesc.count > 0)
			{
				var uvs2Data:Array<Float> = [];
				
				byteArray.position = binaryInfo.uvs2AttrDesc.offset;
				for (i in 0...binaryInfo.uvs2AttrDesc.count)
				{
					uvs2Data[i] = byteArray.readFloat();
				}
				
                mesh.setVerticesData(VertexBuffer.UV2Kind, uvs2Data, false);
            }

            if (binaryInfo.colorsAttrDesc != null && binaryInfo.colorsAttrDesc.count > 0)
			{
				var colorsData:Array<Float> = [];
				
				byteArray.position = binaryInfo.colorsAttrDesc.offset;
				for (i in 0...binaryInfo.colorsAttrDesc.count)
				{
					colorsData[i] = byteArray.readFloat();
				}
				
                mesh.setVerticesData(VertexBuffer.ColorKind, colorsData, false);
            }

            if (binaryInfo.matricesIndicesAttrDesc != null && binaryInfo.matricesIndicesAttrDesc.count > 0)
			{
				var matricesIndicesData:Array<Float> = [];
				
				byteArray.position = binaryInfo.matricesIndicesAttrDesc.offset;
				for (i in 0...binaryInfo.matricesIndicesAttrDesc.count)
				{
					matricesIndicesData[i] = byteArray.readInt();
				}
				
                mesh.setVerticesData(VertexBuffer.MatricesIndicesKind, matricesIndicesData, false);
            }

            if (binaryInfo.matricesWeightsAttrDesc != null && binaryInfo.matricesWeightsAttrDesc.count > 0) 
			{
				var matricesWeightsData:Array<Float> = [];
				
				byteArray.position = binaryInfo.matricesWeightsAttrDesc.offset;
				for (i in 0...binaryInfo.matricesWeightsAttrDesc.count)
				{
					matricesWeightsData[i] = byteArray.readFloat();
				}
				
                mesh.setVerticesData(VertexBuffer.MatricesWeightsKind, matricesWeightsData, false);
            }

            if (binaryInfo.indicesAttrDesc != null && binaryInfo.indicesAttrDesc.count > 0)
			{
				var indicesData:Array<Int> = [];
				
				byteArray.position = binaryInfo.indicesAttrDesc.offset;
				for (i in 0...binaryInfo.indicesAttrDesc.count)
				{
					indicesData[i] = byteArray.readInt();
				}
                mesh.setIndices(indicesData);
            }

            if (binaryInfo.subMeshesAttrDesc != null && binaryInfo.subMeshesAttrDesc.count > 0) 
			{
				var subMeshesData:Array<Int> = [];
				
				byteArray.position = binaryInfo.subMeshesAttrDesc.offset;
				var size:Int = Std.int(binaryInfo.subMeshesAttrDesc.count * 5);
				for (i in 0...size)
				{
					subMeshesData[i] = byteArray.readInt();
				}

                mesh.subMeshes = [];
                for (i in 0...binaryInfo.subMeshesAttrDesc.count) 
				{
                    var materialIndex = subMeshesData[(i * 5) + 0];
                    var verticesStart = subMeshesData[(i * 5) + 1];
                    var verticesCount = subMeshesData[(i * 5) + 2];
                    var indexStart = subMeshesData[(i * 5) + 3];
                    var indexCount = subMeshesData[(i * 5) + 4];

                    var subMesh:SubMesh = new SubMesh(materialIndex, verticesStart, verticesCount, indexStart, indexCount, mesh);
                }
            }
		} 
		else if (parsedGeometry.geometryId != null)
		{
            var geometry = scene.getGeometryByID(parsedGeometry.geometryId);
            if (geometry != null)
			{
                geometry.applyToMesh(mesh);
            }
        }
		else if (parsedGeometry.positions != null && parsedGeometry.normals != null && parsedGeometry.indices != null) 
		{
			mesh.setVerticesData(VertexBuffer.PositionKind, parsedGeometry.positions,  false);
			mesh.setVerticesData(VertexBuffer.NormalKind, parsedGeometry.normals,  false);

			if (parsedGeometry.uvs != null) 
			{
				mesh.setVerticesData(VertexBuffer.UVKind, parsedGeometry.uvs , false);
			}

			if (parsedGeometry.uvs2 != null) 
			{
				mesh.setVerticesData(VertexBuffer.UV2Kind, parsedGeometry.uvs2, false);
			}

			if (parsedGeometry.colors != null) 
			{
				mesh.setVerticesData(VertexBuffer.ColorKind, checkColors4(parsedGeometry.colors,Std.int(parsedGeometry.positions.length/3)), false);
			}

			if (parsedGeometry.matricesIndices != null) 
			{
				if (parsedGeometry.matricesIndices._isExpanded == null ||
					!parsedGeometry.matricesIndices._isExpanded) 
				{
                    var floatIndices:Array<Float> = [];

					for (i in 0...parsedGeometry.matricesIndices.length) 
					{
						var matricesIndex = parsedGeometry.matricesIndices[i];

						floatIndices.push(matricesIndex & 0x000000FF);
						floatIndices.push((matricesIndex & 0x0000FF00) >> 8);
						floatIndices.push((matricesIndex & 0x00FF0000) >> 16);
						floatIndices.push(matricesIndex >> 24);
					}

					mesh.setVerticesData(VertexBuffer.MatricesIndicesKind, floatIndices, false);
                } 
				else 
				{
					mesh.setVerticesData(VertexBuffer.MatricesIndicesKind, parsedGeometry.matricesIndices, false);
				}
				
			}

			if (parsedGeometry.matricesWeights != null) 
			{
				mesh.setVerticesData(VertexBuffer.MatricesWeightsKind, parsedGeometry.matricesWeights,  false);
			}

			mesh.setIndices(parsedGeometry.indices);
		}

		// SubMeshes
		if (parsedGeometry.subMeshes != null)
		{
			mesh.subMeshes = [];
			for (subIndex in 0...parsedGeometry.subMeshes.length) 
			{
				var parsedSubMesh = parsedGeometry.subMeshes[subIndex];

				var subMesh:SubMesh = new SubMesh(parsedSubMesh.materialIndex, 
											parsedSubMesh.verticesStart, 
											parsedSubMesh.verticesCount, 
											parsedSubMesh.indexStart, 
											parsedSubMesh.indexCount, 
											mesh);
			}
		}
		
		// Flat shading
	    if (mesh._shouldGenerateFlatShading)
		{
		    mesh.convertToFlatShadedMesh();
		    mesh._shouldGenerateFlatShading = false;
	    }

		// Update
		mesh.computeWorldMatrix(true);

		if (scene._selectionOctree != null)
		{
			scene._selectionOctree.addMesh(mesh);
		}
	}
	
	/* INTERFACE babylon.load.ISceneLoaderPlugin */
	
	public function getExtensions():String 
	{
		return "babylon";
	}
	
	public function importMesh(meshesNames:Dynamic, scene:Scene, data:String, rootUrl:String, meshes:Array<AbstractMesh>, particleSystems:Array<ParticleSystem>, skeletons:Array<Skeleton>):Bool 
	{
		var parsedData:Dynamic = Json.parse(data);

		var loadedSkeletonsIds:Array<String> = [];
		var loadedMaterialsIds:Array<String> = [];
		var hierarchyIds:Array<String> = [];
		
		var parsedMeshes:Array<Dynamic> = parsedData.meshes;
		for (index in 0...parsedMeshes.length) 
		{
			var parsedMesh:Dynamic = parsedMeshes[index];

			if (meshesNames != null || 
				isDescendantOf(parsedMesh, meshesNames, hierarchyIds))
			{
				if (Std.is(meshesNames, Array))
				{
					// Remove found mesh name from list.
					Std.instance(meshesNames, Array).remove(parsedMesh.name);
				}
				
				// Material ?
				if (StringUtil.isValid(parsedMesh.materialId))
				{
					var materialFound:Bool = loadedMaterialsIds.indexOf(parsedMesh.materialId) != -1;

					if (!materialFound) 
					{
						var parsedMultiMaterials:Array<Dynamic> = parsedData.multiMaterials;
						for (multimatIndex in 0...parsedMultiMaterials.length) 
						{
							var parsedMultiMaterial = parsedMultiMaterials[multimatIndex];
							if (parsedMultiMaterial.id == parsedMesh.materialId) 
							{
								var parsedMaterials:Array<Dynamic> = parsedMultiMaterial.materials;
								for (matIndex in 0...parsedMaterials.length)
								{
									var subMatId:String = parsedMaterials[matIndex];
									loadedMaterialsIds.push(subMatId);
									parseMaterialById(subMatId, parsedData, scene, rootUrl);
								}

								loadedMaterialsIds.push(parsedMultiMaterial.id);
								parseMultiMaterial(parsedMultiMaterial, scene);
								materialFound = true;
								break;
							}
						}
					}

					if (!materialFound)
					{
						loadedMaterialsIds.push(parsedMesh.materialId);
						parseMaterialById(parsedMesh.materialId, parsedData, scene, rootUrl);
					}
				}

				// Skeleton ?
				if (parsedMesh.skeletonId > -1 && scene.skeletons != null) 
				{
					var skeletonAlreadyLoaded:Bool = loadedSkeletonsIds.indexOf(parsedMesh.skeletonId) > -1;

					if (!skeletonAlreadyLoaded) 
					{
						var parsedSkeletons:Array<Dynamic> = parsedData.skeletons;
						for (skeletonIndex in 0...parsedSkeletons.length) 
						{
							var parsedSkeleton = parsedSkeletons[skeletonIndex];

							if (parsedSkeleton.id == parsedMesh.skeletonId) 
							{
								skeletons.push(parseSkeleton(parsedSkeleton, scene));
								loadedSkeletonsIds.push(parsedSkeleton.id);
							}
						}
					}
				}

				var mesh = parseMesh(parsedMesh, scene, rootUrl);
				meshes.push(mesh);
			}
		}
		
		// Connecting parents
		for (index in 0...scene.meshes.length) 
		{
			var currentMesh:AbstractMesh = scene.meshes[index];
			if (currentMesh._waitingParentId.isValid()) 
			{
				currentMesh.parent = scene.getLastEntryByID(currentMesh._waitingParentId);
				currentMesh._waitingParentId = null;
			}
		}

		// Particles
		if (parsedData.particleSystems != null) 
		{
			var ps:Array<ParticleSystem> = cast parsedData.particleSystems;
			for (index in 0...ps.length) 
			{
				var parsedParticleSystem:ParticleSystem = ps[index];

				if (hierarchyIds.indexOf(parsedParticleSystem.emitterId) != -1) {
					particleSystems.push(parseParticleSystem(parsedParticleSystem, scene, rootUrl));
				}
			}
		}

		return true;
	}
	
	public function load(scene:Scene, data:String, rootUrl:String):Bool 
	{
		#if debug
		var time:Int = Lib.getTimer();
		#end
		
		var parsedData = Json.parse(data);		
		
		#if debug
		Logger.log("parse Scene Time : " + (Lib.getTimer() - time));
		#end
					
		// Scene
		scene.useDelayedTextureLoading = parsedData.useDelayedTextureLoading && !SceneLoader.ForceFullSceneLoadingForIncremental;
		scene.autoClear = parsedData.autoClear;
		scene.clearColor = Color3.FromArray(parsedData.clearColor);
		scene.ambientColor = Color3.FromArray(parsedData.ambientColor);
		scene.gravity = Vector3.FromArray(parsedData.gravity);
		
		// Fog
		var fogMode : Null<Int> = parsedData.fogMode;
		if (fogMode != null && fogMode != 0) 
		{
			scene.fogInfo.fogMode = fogMode;
			scene.fogInfo.fogColor = Color3.FromArray(parsedData.fogColor);
			scene.fogInfo.fogStart = parsedData.fogStart;
			scene.fogInfo.fogEnd = parsedData.fogEnd;
			scene.fogInfo.fogDensity = parsedData.fogDensity;
		}

		
		// Lights
		var lights:Array<Dynamic> = parsedData.lights;
		for (index in 0...lights.length) 
		{			
			parseLight(lights[index], scene);				
		}

		// Materials
		if (parsedData.materials != null)
		{
			var materials:Array<Dynamic> = parsedData.materials;
			for (index in 0...materials.length) 
			{
				parseMaterial(materials[index], scene, rootUrl);
			}
		}

		if (parsedData.multiMaterials != null) 
		{
			var multiMaterials:Array<Dynamic> = cast parsedData.multiMaterials;
			for (index in 0...multiMaterials.length) 
			{
				parseMultiMaterial(multiMaterials[index], scene);
			}
		}

		// Skeletons
		if (parsedData.skeletons != null) 
		{
			var skeletons:Array<Dynamic> = cast parsedData.skeletons;
			for (index in 0...skeletons.length) 
			{
				parseSkeleton(skeletons[index], scene);
			}
		}
		
		// Geometries
		var geometries = parsedData.geometries;
		if (geometries != null) 
		{
			// Boxes
			var boxes:Array<Dynamic> = geometries.boxes;
			if (boxes != null)
			{
				for (index in 0...boxes.length) 
				{
					var parsedBox = boxes[index];
					parseBox(parsedBox, scene);
				}
			}

			// Spheres
			var spheres:Array<Dynamic> = geometries.spheres;
			if (spheres != null) 
			{
				for (index in 0...spheres.length) 
				{
					var parsedSphere = spheres[index];
					parseSphere(parsedSphere, scene);
				}
			}

			// Cylinders
			var cylinders:Array<Dynamic> = geometries.cylinders;
			if (cylinders != null)
			{
				for (index in 0...cylinders.length) 
				{
					var parsedCylinder = cylinders[index];
					parseCylinder(parsedCylinder, scene);
				}
			}

			// Toruses
			var toruses:Array<Dynamic> = geometries.toruses;
			if (toruses != null)
			{
				for (index in 0...toruses.length) 
				{
					var parsedTorus = toruses[index];
					parseTorus(parsedTorus, scene);
				}
			}

			// Grounds
			var grounds:Array<Dynamic> = geometries.grounds;
			if (grounds != null)
			{
				for (index in 0...grounds.length) 
				{
					var parsedGround = grounds[index];
					parseGround(parsedGround, scene);
				}
			}

			// Planes
			var planes:Array<Dynamic> = geometries.planes;
			if (planes != null) 
			{
				for (index in 0...planes.length) 
				{
					var parsedPlane = planes[index];
					parsePlane(parsedPlane, scene);
				}
			}

			// TorusKnots
			var torusKnots:Array<Dynamic> = geometries.torusKnots;
			if (torusKnots != null)
			{
				for (index in 0...torusKnots.length) 
				{
					var parsedTorusKnot = torusKnots[index];
					parseTorusKnot(parsedTorusKnot, scene);
				}
			}

			// VertexData
			var vertexData:Array<Dynamic> = geometries.vertexData;
			if (vertexData != null) 
			{
				for (index in 0...vertexData.length) 
				{
					var parsedVertexData = vertexData[index];
					parseVertexData(parsedVertexData, scene, rootUrl);
				}
			}
		}

		// Meshes
		var parsedMeshes:Array<Dynamic> = parsedData.meshes;
		for (index in 0...parsedMeshes.length) 
		{
			parseMesh(parsedMeshes[index], scene, rootUrl);
		}
		
		// Cameras
		var parsedCameras:Array<Dynamic> = parsedData.cameras;
		for (index in 0...parsedCameras.length)
		{
			var parsedCamera = parsedCameras[index];
			parseCamera(parsedCamera, scene);
		}

		if (parsedData.activeCameraID != null)
		{
			scene.activeCameraByID(parsedData.activeCameraID);
		}

		// Connecting parents
		for (index in 0...scene.cameras.length)
		{
			var camera:Camera = scene.cameras[index];
			if (camera._waitingParentId.isValid()) 
			{
				camera.parent = scene.getLastEntryByID(camera._waitingParentId);
				camera._waitingParentId = null;
			}
		}

		for (index in 0...scene.meshes.length) 
		{
			var mesh:AbstractMesh = scene.meshes[index];
			if (mesh._waitingParentId.isValid()) 
			{
				mesh.parent = scene.getLastEntryByID(mesh._waitingParentId);
				mesh._waitingParentId = null;
			}
			
			if (mesh._waitingActions != null)
			{
				parseActions(mesh._waitingActions, mesh, scene);
				mesh._waitingActions = null;
			}
		}
		
		for (index in 0...scene.lights.length) 
		{
			var light:Light = scene.lights[index];
			if (light._waitingParentId.isValid())
			{
				light.parent = scene.getLastEntryByID(light._waitingParentId);
				light._waitingParentId = null;
			}
		}

		// Particles Systems
		if (parsedData.particleSystems != null)
		{
			var particleSystems:Array<Dynamic> = parsedData.particleSystems;
			for (index in 0...particleSystems.length) 
			{
				parseParticleSystem(particleSystems[index], scene, rootUrl);
			}
		}

		// Lens flares
		if (parsedData.lensFlareSystems != null) 
		{
			var lensFlareSystems:Array<Dynamic> = parsedData.lensFlareSystems;
			for (index in 0...lensFlareSystems.length) 
			{
				parseLensFlareSystem(lensFlareSystems[index], scene, rootUrl);
			}
		}

		// Shadows
		if (parsedData.shadowGenerators != null) 
		{
			var shadowGenerators:Array<Dynamic> = parsedData.shadowGenerators;
			for (index in 0...shadowGenerators.length) 
			{
				parseShadowGenerator(shadowGenerators[index], scene);
			}
		}
		
		return true;
	}
	
}