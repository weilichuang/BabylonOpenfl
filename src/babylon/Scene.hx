package babylon;

import babylon.actions.ActionEvent;
import babylon.actions.ActionManager;
import babylon.animations.Animatable;
import babylon.animations.Animation;
import babylon.audio.AudioEngine;
import babylon.bones.Skeleton;
import babylon.cameras.Camera;
import babylon.collisions.Collider;
import babylon.collisions.PickingInfo;
import babylon.culling.BoundingBox;
import babylon.culling.octrees.Octree;
import babylon.layer.Layer;
import babylon.lensflare.LensFlareSystem;
import babylon.lights.Light;
import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.Material;
import babylon.materials.MultiMaterial;
import babylon.materials.StandardMaterial;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.procedurals.ProceduralTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.math.Color3;
import babylon.math.Frustum;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.math.Ray;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Geometry;
import babylon.mesh.Mesh;
import babylon.mesh.SubMesh;
import babylon.particles.ParticleSystem;
import babylon.physics.IPhysicsEnginePlugin;
import babylon.physics.PhysicsBodyCreationOptions;
import babylon.physics.PhysicsCompoundBodyPart;
import babylon.physics.PhysicsEngine;
import babylon.postprocess.PostProcessManager;
import babylon.postprocess.renderpipeline.PostProcessRenderPipelineManager;
import babylon.rendering.BoundingBoxRenderer;
import babylon.rendering.OutlineRenderer;
import babylon.rendering.RenderingManager;
import babylon.sprites.SpriteManager;
import babylon.tools.SmartArray;
import babylon.tools.Tools;
import babylon.utils.MathUtils;
import haxe.Timer;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.Lib;

class Scene
{
	public static var MinDeltaTime:Float = 1.0;
	public static var MaxDeltaTime:Float = 1000.0;
	
	public var autoClear:Bool = true;
	public var clearColor:Color3;
	public var ambientColor:Color3;
	public var beforeRender:Void->Void;
	public var afterRender:Void->Void;
	public var onDispose:Void->Void;
	
	public var beforeCameraRender:Camera->Void;
	public var afterCameraRender:Camera->Void;
	
	public var forceWireframe:Bool = false;
	public var forceShowBoundingBoxes:Bool = false;
	
	public var clipPlane:Plane;
	
	public var animationsEnabled:Bool = true;
	
	// Keyboard
	private var _onKeyDown: KeyboardEvent->Void;
	private var _onKeyUp: KeyboardEvent->Void;
	
	// Pointers
	private var _onPointerMove: MouseEvent->Void;
	private var _onPointerDown: MouseEvent->Void;
	public var onPointerDown: MouseEvent->PickingInfo->Void;
	// Define this parameter if you are using multiple cameras and you want to specify which one should be used for pointer position
	public var cameraToUseForPointers: Camera = null; 
	
	private var _pointerX: Float = 0;
	private var _pointerY: Float = 0;
	private var _meshUnderPointer: AbstractMesh;
	private var _pointerOverMesh: AbstractMesh;
	
	public var fogEnabled:Bool = true;
	public var fogInfo:FogInfo;
	
	//---------Lights begin-------//
	public var lightsEnabled:Bool = true;
	public var lights:Array<Light>;
	//---------Lights end---------//
	
	//---------Cameras begin-------//
	public var cameras:Array<Camera>;
	public var activeCamera:Camera;
	public var activeCameras:Array<Camera>;
	//---------Cameras end-------//
	
	// Meshes
	public var meshes:Array<AbstractMesh>;
	
	 // Geometries
	private var _geometries:Array<Geometry>;
	
	public var materials:Array<Material>;
	public var multiMaterials:Array<MultiMaterial>;
	public var defaultMaterial:StandardMaterial;
	
	// Textures
	public var texturesEnabled:Bool = true;
	public var textures:Array<BaseTexture>;
	
	// Particles
	public var particlesEnabled:Bool = true;
	public var particleSystems:Array<ParticleSystem>;
	
	// Sprites
	public var spriteManagers:Array<SpriteManager>;
	
	// Layers
	public var layers:Array<Layer>;
	
	// Skeletons
	public var skeletonsEnabled:Bool = true;
	public var skeletons:Array<Skeleton>;
	
	// Lens flares
	public var lensFlaresEnabled:Bool = true;
	public var lensFlareSystems:Array<LensFlareSystem>;
	
	// Collisions
	public var collisionsEnabled:Bool = true;
	public var gravity:Vector3;
	
	private var _physicsEngine:PhysicsEngine;
	private var _physicsEnable:Bool = true;
	
	// Postprocesses
	public var postProcessesEnabled:Bool = true;
	public var postProcessManager:PostProcessManager;
	public var postProcessRenderPipelineManager: PostProcessRenderPipelineManager;
	
	// Customs render targets
	public var renderTargetsEnabled:Bool = true;
	public var customRenderTargets:Array<RenderTargetTexture>;
	
	// Delay loading
	public var useDelayedTextureLoading:Bool = false;
	
	// Imported meshes
	public var importedMeshesFiles:Array<String> = new Array<String>();
	
	// Database
	//public var database:Dynamic;
	
	// Actions
	public var actionManager:ActionManager;
	public var _actionManagers:Array<ActionManager>;
	private var _meshesForIntersections:SmartArray<AbstractMesh>;
	
	public var engine:Engine;
	
	public var statistics:Statistics;
	
	private var _animationRatio:Float = 0;
	private var _animationStartDate:Int = -1;
	
	private var _renderId:Int = 0;

	public var _toBeDisposed:SmartArray<IDispose>;
	
	public var _onReadyCallbacks:Array<Dynamic>;
	public var _pendingData:Array<Dynamic>;
	
	public var _onBeforeRenderCallbacks:Array<Void->Void> ;
	public var _onAfterRenderCallbacks:Array<Void->Void>;
	
	private var _activeMeshes:SmartArray<AbstractMesh>; 	
	private var _processedMaterials:SmartArray<Material>; 		
	private var _renderTargets:SmartArray<RenderTargetTexture>; 
	private var _activeParticleSystems:SmartArray<ParticleSystem>; 
	private var _activeSkeletons:SmartArray<Skeleton>; 
	
	private var _renderingManager:RenderingManager;
	
	public var _activeAnimatables:Array<Animatable>;
	
	private var _transformMatrix:Matrix;
	private var _pickWithRayInverseMatrix:Matrix;
	
	private var _boundingBoxRenderer: BoundingBoxRenderer;
	private var _outlineRenderer: OutlineRenderer;
	
	private var _scaledVelocity:Vector3;
	private var _scaledPosition:Vector3;
	
	public var _viewMatrix:Matrix;
	public var _projectionMatrix:Matrix;
	public var _frustumPlanes:Array<Plane>;
	
	public var _selectionOctree:Octree<AbstractMesh>;
	
	public var shadowsEnabled:Bool = true;

	// Procedural textures
	public var proceduralTexturesEnabled:Bool = true;
	public var _proceduralTextures:Array<ProceduralTexture> = [];
	
	public var forcePointsCloud:Bool = false;
	
	public var _cachedMaterial: Material;

	public function new(engine:Engine) 
	{
		this.engine = engine;

		_oldViewPort = new Rectangle();
		
		this.autoClear = true;
        this.clearColor = new Color3(0.2, 0.2, 0.3);
        this.ambientColor = new Color3(0, 0, 0);

		// Fog
		this.fogInfo = new FogInfo();
		
		// Lights
        this.lights = [];

        // Cameras
        this.cameras = [];
        // Multi-cameras
        this.activeCameras = [];
		
		// Meshes
        this.meshes = [];
		
		// Geometries
        _geometries = new Array<Geometry>();
		
		// Materials
        this.materials = [];
        this.multiMaterials = [];
        this.defaultMaterial = new StandardMaterial("default material", this);
		
		// Textures
        this.textures = [];
		
		// Particles
        this.particleSystems = [];

        // Sprites
        this.spriteManagers = [];

        // Layers
        this.layers = [];

        // Skeletons
        this.skeletons = [];
        
        // Lens flares
        this.lensFlareSystems = [];

        // Collisions
        this.collisionsEnabled = true;
        this.gravity = new Vector3(0, -9.0, 0);
		
		// Customs render targets
        this.renderTargetsEnabled = true;
        this.customRenderTargets = [];

		this.statistics = new Statistics();

        this._toBeDisposed = new SmartArray<IDispose>();

        this._onReadyCallbacks = [];
        this._pendingData = [];

        this._onBeforeRenderCallbacks = [];
		this._onAfterRenderCallbacks = [];
		
		// Internal smart arrays
        this._activeMeshes = new SmartArray<AbstractMesh>();
        this._processedMaterials = new SmartArray<Material>();
        this._renderTargets = new SmartArray<RenderTargetTexture>();
        this._activeParticleSystems = new SmartArray<ParticleSystem>();
        this._activeSkeletons = new SmartArray<Skeleton>();
        
		// Animations
        this._activeAnimatables = [];

        // Matrices
        this._transformMatrix = Matrix.Zero();

        // Internals
        this._scaledPosition = Vector3.Zero();
        this._scaledVelocity = Vector3.Zero();
        
		this._actionManagers = new Array<ActionManager>();
		this._meshesForIntersections = new SmartArray<AbstractMesh>();
		
		// Rendering groups
        this._renderingManager = new RenderingManager(this);
		
		// Postprocesses
        this.postProcessesEnabled = true;
        this.postProcessManager = new PostProcessManager(this);
		this.postProcessRenderPipelineManager = new PostProcessRenderPipelineManager();

		this._boundingBoxRenderer = new BoundingBoxRenderer(this);
		this._outlineRenderer = new OutlineRenderer(this);

		this.attachControl();
	}
	
	public function getCachedMaterial(): Material
	{
		return this._cachedMaterial;
	}
	
	public function resetCachedMaterial(): Void 
	{
		this._cachedMaterial = null;
	}

	public function getStageWidth():Int
	{
		return engine.getStage().stageWidth;
	}
	
	public function getStageHeight():Int 
	{
		return engine.getStage().stageHeight;
	}
	
	public function getActiveParticleSystems():SmartArray<ParticleSystem>
	{
		return this._activeParticleSystems;
	}
	
	public var meshUnderPointer(get, null):AbstractMesh;
	private function get_meshUnderPointer(): AbstractMesh 
	{
		return this._meshUnderPointer;
	}

	public var pointerX(get, null):Float;
	private function get_pointerX(): Float
	{
		return this._pointerX;
	}

	public var pointerY(get, null):Float;
	private function get_pointerY(): Float
	{
		return this._pointerY;
	}

	public function getBoundingBoxRenderer(): BoundingBoxRenderer 
	{
		return this._boundingBoxRenderer;
	}
	
	public function getOutlineRenderer(): OutlineRenderer
	{
		return this._outlineRenderer;
	}
	
	public function addLight(light:Light):Void
	{
		if (lights.indexOf(light) == -1)
			lights.push(light);
	}
	
	public function removeLight(light:Light):Bool
	{
		return lights.remove(light);
	}
	
	public function addMesh(mesh:AbstractMesh):Void
	{
		if (meshes.indexOf(mesh) == -1)
			meshes.push(mesh);
	}
	
	public function removeMesh(mesh:AbstractMesh):Bool
	{
		return meshes.remove(mesh);
	}

	public inline function getEngine():Engine 
	{
		return engine;
	}

	public function getActiveMeshes():SmartArray<AbstractMesh> 
	{
		return this._activeMeshes;
	}

	public function getAnimationRatio():Float 
	{
		return this._animationRatio;
	}
	
	public inline function getRenderId():Int 
	{
		return this._renderId;
	}
	
	// Pointers handling
	public function attachControl():Void
	{
		this._onPointerMove = function(evt: MouseEvent):Void
		{
			this._updatePointerPosition(evt);
			
			var predicateMove = function(mesh:AbstractMesh):Bool
			{
				return mesh.isPickable && mesh.isVisible && mesh.isReady() && 
						mesh.actionManager != null && mesh.actionManager.hasPointerTriggers;
			}
			
			var pickResult = this.pick(this._pointerX, this._pointerY, predicateMove, false, this.cameraToUseForPointers);
			
			if (pickResult.hit)
			{
				this._meshUnderPointer = pickResult.pickedMesh;
				
				this.setPointerOverMesh(pickResult.pickedMesh);
				//canvas.style.cursor = "pointer";
			} 
			else 
			{
				this.setPointerOverMesh(null);
				//canvas.style.cursor = "";
				this._meshUnderPointer = null;
			}
		};

		this._onPointerDown = function(evt: MouseEvent):Void
		{
			var predicateDown:AbstractMesh->Bool = null;
			
			if (this.onPointerDown == null)
			{
				predicateDown = function(mesh:AbstractMesh):Bool
				{
					return mesh.isPickable && mesh.isVisible && mesh.isReady() &&
						mesh.actionManager != null && mesh.actionManager.hasPickTriggers;
				}
			}
			
			this._updatePointerPosition(evt);
			
			//trace("x:"+this._pointerX + ",y:" + this._pointerY);
			//return;
			
			var pickResult = this.pick(this._pointerX, this._pointerY, predicateDown, false, this.cameraToUseForPointers);

			if (pickResult.hit)
			{
				if (pickResult.pickedMesh.actionManager != null)
				{
					pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnLeftPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh));
					
					//switch (evt.buttons) 
					//{
						//case 1:
							//pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnLeftPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh));
						//case 2:
							//pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnRightPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh));
						//case 3:
							//pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnCenterPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh));
					//}
					pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh));
				}
			}

			if(this.onPointerDown != null)
				this.onPointerDown(evt, pickResult);
		};
		
		engine.getStage().addEventListener(MouseEvent.MOUSE_MOVE, _onPointerMove, false);
		engine.getStage().addEventListener(MouseEvent.MOUSE_DOWN, _onPointerDown, false);
		
		#if !mobile
		this._onKeyDown = function(event:KeyboardEvent):Void
		{
			//trace("onKeyDown:" + event.keyCode);
			if (this.actionManager != null)
			{
				this.actionManager.processTrigger(ActionManager.OnKeyDownTrigger, ActionEvent.CreateNewFromScene(this, event));
			}
		}
		
		this._onKeyUp = function(event:KeyboardEvent):Void
		{
			if (this.actionManager != null)
			{
				this.actionManager.processTrigger(ActionManager.OnKeyUpTrigger, ActionEvent.CreateNewFromScene(this, event));
			}
		}
		
		engine.getStage().addEventListener(KeyboardEvent.KEY_UP, _onKeyUp, false);
		engine.getStage().addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown, false);
		#end
	}
	
	public function detachControl():Void
	{
		engine.getStage().removeEventListener(MouseEvent.MOUSE_MOVE, _onPointerMove);
		engine.getStage().removeEventListener(MouseEvent.MOUSE_DOWN, _onPointerDown);
		
		#if !mobile
		engine.getStage().removeEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
		engine.getStage().removeEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
		#end
	}
	
	private function _updatePointerPosition(evt: MouseEvent): Void
	{
		this._pointerX = evt.localX;
		this._pointerY = evt.localY;
		
		if (this.cameraToUseForPointers != null)
		{
			this._pointerX = this._pointerX - this.cameraToUseForPointers.viewport.x * this.engine.getRenderWidth();
			this._pointerY = this._pointerY - this.cameraToUseForPointers.viewport.y * this.engine.getRenderHeight();
		}
	}

	public function isReady():Bool 
	{
		if (this._pendingData.length > 0)
		{
            return false;
        }
		
		for (index in 0...this._geometries.length)
		{
			var geometry = this._geometries[index];

			if (geometry.delayLoadState == Engine.DELAYLOADSTATE_LOADING)
			{
				//trace("geometry.id:"+geometry.id);
				return false;
			}
		}

        for (index in 0...this.meshes.length)
		{
            var mesh = this.meshes[index];
			if (!mesh.isReady())
			{
				//trace("mesh.id:"+mesh.id);
				return false;
			}
			
            var mat:Material = mesh.material;
            if (mat != null) 
			{
                if (!mat.isReady(mesh))
				{
					//trace("mat.id:"+mat.name);
                    return false;
                }
            }
        }

        return true;
	}
	
	public function registerBeforeRender(func:Void->Void):Void
	{
		this._onBeforeRenderCallbacks.push(func);
	}
	
	public function unregisterBeforeRender(func:Void->Void):Void
	{
		var index = this._onBeforeRenderCallbacks.indexOf(func);

        if (index > -1) 
		{
            this._onBeforeRenderCallbacks.splice(index, 1);
        }
	}
	
	public function registerAfterRender(func:Void->Void):Void
	{
		this._onAfterRenderCallbacks.push(func);
	}

	public function unregisterAfterRender(func:Void->Void):Void
	{
		var index = this._onAfterRenderCallbacks.indexOf(func);

		if (index > -1)
		{
			this._onAfterRenderCallbacks.splice(index, 1);
		}
	}
	
	public function _addPendingData(data:Dynamic):Void
	{
        this._pendingData.push(data);
    }

	public function _removePendingData(data:Dynamic):Void
	{
        var index = this._pendingData.indexOf(data);

        if (index != -1) {
            this._pendingData.splice(index, 1);
        }
    }

    public function getWaitingItemsCount():Int
	{
        return this._pendingData.length;
    }
	
	private var executeTimer:Timer;
	public function executeWhenReady(func:Dynamic):Void
	{
		this._onReadyCallbacks.push(func);
		
		if (executeTimer != null)
		{
			return;
		}
		
		executeTimer = new Timer(150);
		executeTimer.run = function():Void
		{
			this._checkIsReady();
		}
		
		this._checkIsReady();
	}
	
	private function _checkIsReady():Void 
	{
		if (this.isReady()) 
		{
            for (func in this._onReadyCallbacks) 
			{
                func();
            }

            this._onReadyCallbacks = [];

			if (executeTimer != null)
			{
				executeTimer.stop();
				executeTimer = null;
			}
            return;
        }
	}
	
	public function beginAnimation(target:Dynamic, from:Float, to:Float, 
									loop:Bool = false, 
									speedRatio:Float = 1.0, 
									onAnimationEnd:Void->Void = null,
									animatable:Animatable = null):Animatable
	{
		this.stopAnimation(target);
		
        if (animatable == null)
		{
            animatable = new Animatable(this, target, from, to, loop, speedRatio, onAnimationEnd);
        }
		
		if (Reflect.getProperty(target, "animations") != null)
		{
			animatable.appendAnimations(target, target.animations);
		}

        // Children animations		
        if (Reflect.getProperty(target, "getAnimatables") != null)
		{
            var animatables:Array<Dynamic> = target.getAnimatables();
			for (index in 0...animatables.length) 
			{
				this.beginAnimation(animatables[index], from, to, loop, speedRatio, onAnimationEnd, animatable);
			}
        }
		
		return animatable;
	}
	
	public function beginDirectAnimation(target: Dynamic, 
								animations: Array<Animation>, 
								from: Float, to: Float, 
								loop: Bool = false, speedRatio: Float = 1.0, 
								onAnimationEnd:Void->Void = null): Animatable
	{
		var animatable = new Animatable(this, target, from, to, loop, speedRatio, onAnimationEnd, animations);

		return animatable;
	}
	
	public function getAnimatableByTarget(target: Dynamic): Animatable
	{
		for (index in 0...this._activeAnimatables.length)
		{
			if (this._activeAnimatables[index].target == target) 
			{
				return this._activeAnimatables[index];
			}
		}

		return null;
	}
	
	public function stopAnimation(target:Dynamic):Void 
	{
		var animatable = this.getAnimatableByTarget(target);
		
		if (animatable != null)
		{
			animatable.stop();
		}
	}
	
	public function _animate():Void 
	{
		if (!animationsEnabled)
			return;
		
		// Getting time
		var delay:Int;
        if (_animationStartDate == -1)
		{
            _animationStartDate = Lib.getTimer();
			delay = 0;
        }
		else
		{
			delay = Lib.getTimer() - _animationStartDate;
		}

		var index:Int = 0;
		while (index < _activeAnimatables.length)
		{
            if (!_activeAnimatables[index]._animate(delay)) 
			{
                _activeAnimatables.splice(index, 1);
                index--;
            }
			index++;
        }
    }

	public inline function getViewMatrix():Matrix 
	{
		return this._viewMatrix;
	}
	
	public inline function getProjectionMatrix():Matrix 
	{
		return this._projectionMatrix;
	}
	
	public inline function getTransformMatrix():Matrix 
	{
		return this._transformMatrix;
	}	
	
	public inline function setTransformMatrix(view:Matrix, projection:Matrix) 
	{
		this._viewMatrix = view;
        this._projectionMatrix = projection;

        this._viewMatrix.multiplyToRef(this._projectionMatrix, this._transformMatrix);
	}
	
	public function getCameraByID(id: String): Camera
	{
		for (index in  0...cameras.length) 
		{
			if (cameras[index].id == id) 
			{
				return cameras[index];
			}
		}

		return null;
	}
	
	public function getCameraByName(name: String): Camera
	{
		for (index in  0...cameras.length) 
		{
			if (cameras[index].name == name) 
			{
				return cameras[index];
			}
		}

		return null;
	}
	
	public function activeCameraByID(id:String):Camera 
	{
		var camera = getCameraByID(id);
		if (camera != null)
		{
			activeCamera = camera;
			return camera;
		}
		
		return null;
	}
	
	public function setActiveCameraByName(name: String): Camera 
	{
		var camera = getCameraByName(name);

		if (camera != null)
		{
			activeCamera = camera;
			return camera;
		}

		return null;
	}
	
	public function getMaterialByID(id:String):Material
	{
		for (index in 0...materials.length)
		{
            if (materials[index].id == id)
			{
                return materials[index];
            }
        }

        return null;
	}
	
	public function getMaterialByName(name:String):Material
	{
		for (index in 0...materials.length)
		{
            if (materials[index].name == name) 
			{
                return materials[index];
            }
        }

        return null;
	}
	
	public function getLightByID(id:String):Light 
	{
		for (index in 0...lights.length)
		{
            if (lights[index].id == id) 
			{
                return lights[index];
            }
        }

        return null;
	}
	
	public function getLightByName(name:String):Light 
	{
		for (index in 0...lights.length)
		{
            if (lights[index].name == name) 
			{
                return lights[index];
            }
        }

        return null;
	}
	
	public function getGeometryByID(id:String):Geometry
	{
		for (index in 0..._geometries.length)
		{
            if (_geometries[index].id == id)
			{
                return _geometries[index];
            }
        }

        return null;
	}
	
	public function pushGeometry(geometry: Geometry, force: Bool = false): Bool
	{
		if (!force && getGeometryByID(geometry.id) != null) 
		{
			return false;
		}

		_geometries.push(geometry);

		return true;
	}

	public function getGeometries(): Array<Geometry> 
	{
		return _geometries;
	}

	public function getMeshByID(id:String):AbstractMesh
	{
		for (index in 0...meshes.length)
		{
            if (meshes[index].id == id)
			{
                return meshes[index];
            }
        }

        return null;
	}
	
	public function getLastMeshByID(id:String):AbstractMesh
	{
		var index:Int = meshes.length - 1;
		while (index >= 0) 
		{
            if (meshes[index].id == id) 
			{
                return meshes[index];
            }
			index--;
        }

        return null;
	}
	
	public function getLastEntryByID(id:String):Dynamic 
	{
		var index:Int = meshes.length - 1;
		while (index >= 0) 
		{
            if (meshes[index].id == id) 
			{
                return meshes[index];
            }
			index--;
        }

		index = cameras.length - 1;
		while (index >= 0)
		{
            if (cameras[index].id == id) 
			{
                return cameras[index];
            }
			index--;
        }
        
		index = lights.length - 1;
		while (index >= 0)
		{
            if (lights[index].id == id)
			{
                return lights[index];
            }
			index--;
        }

        return null;
    }
	
	public function getMeshByName(name:String):AbstractMesh
	{
		for (index in 0...meshes.length) 
		{
            if (meshes[index].name == name)
			{
                return meshes[index];
            }
        }

        return null;
	}
	
	public function isActiveMesh(mesh:Mesh):Bool
	{
		return (_activeMeshes.indexOf(mesh) != -1);
	}
	
	public function getLastSkeletonByID(id:String):Skeleton
	{
		var index:Int = skeletons.length - 1;
		while (index >= 0)
		{
            if (skeletons[index].id == id)
			{
                return skeletons[index];
            }
			index--;
        }

        return null;
	}
	
	public function getSkeletonByID(id:String):Skeleton
	{
		for (index in 0...skeletons.length)
		{
            if (skeletons[index].id == id) 
			{
                return skeletons[index];
            }
        }

        return null;
	}
	
	public function getSkeletonByName(name:String):Skeleton 
	{
		for (index in 0...skeletons.length)
		{
            if (skeletons[index].name == name) 
			{
                return skeletons[index];
            }
        }

        return null;
	}

	public function _evaluateSubMesh(subMesh:SubMesh, mesh:AbstractMesh):Void
	{
		if (mesh.subMeshes.length == 1 || subMesh.isInFrustrum(_frustumPlanes)) 
		{
            var material:Material = subMesh.getMaterial();
			
			if (mesh.showSubMeshesBoundingBox) 
			{
				this._boundingBoxRenderer.renderList.push(subMesh.getBoundingInfo().boundingBox);
			}

            if (material != null)
			{
                // Render targets
                if (material.getRenderTargetTextures().length > 0)
				{
                    if (this._processedMaterials.indexOf(material) == -1)
					{
                        this._processedMaterials.push(material);

						this._renderTargets.concat(material.getRenderTargetTextures());
                    }
                }

                // Dispatch
                statistics.activeVertices += subMesh.indexCount;
                _renderingManager.dispatch(subMesh);
            }
        }
	}
	
	private function _evaluateActiveMeshes():Void 
	{
		this._activeMeshes.reset();
        this._renderingManager.reset(); 
        this._processedMaterials.reset();
        this._activeParticleSystems.reset();
        this._activeSkeletons.reset();
		this._boundingBoxRenderer.reset();

        if (_frustumPlanes == null) 
		{
            _frustumPlanes = Frustum.GetPlanes(_transformMatrix);
        } 
		else
		{
            _frustumPlanes = Frustum.GetPlanesToRef(_transformMatrix, _frustumPlanes);
        }

        // Meshes
		var meshes: Array<AbstractMesh>;
		var len: Int;
        if (_selectionOctree != null)  // Octree
		{
            var selection:SmartArray<AbstractMesh> = _selectionOctree.select(_frustumPlanes);
			meshes = selection.data;
			len = selection.length;
        } 
		else // Full scene traversal
		{
			len = this.meshes.length;
			meshes = this.meshes;
		}

		for (meshIndex in 0...len)
		{
			var mesh:AbstractMesh = meshes[meshIndex];

			if (mesh.isBlocked)
			{
				continue;
			}
			
			statistics.totalVertices += mesh.getTotalVertices();
			
			if (!mesh.isReady())
			{
				continue;
			}
			
			mesh.computeWorldMatrix();
			
			// Intersections
			if (mesh.actionManager != null && 
				mesh.actionManager.hasSpecificTriggers([ActionManager.OnIntersectionEnterTrigger, ActionManager.OnIntersectionExitTrigger]))
			{
				this._meshesForIntersections.pushNoDuplicate(mesh);
			}
			
			// Switch to current LOD
			var meshLOD:AbstractMesh = mesh.getLOD(this.activeCamera);
			if (meshLOD == null)
			{
				continue;
			}
			
			mesh.preActivate();

			if (mesh.isEnabled() && 
				mesh.isVisible && 
				mesh.visibility > 0 && 
				((mesh.layerMask & this.activeCamera.layerMask) != 0) &&
				mesh.isInFrustrum(this._frustumPlanes))
			{
				this._activeMeshes.push(mesh);
				
				mesh.activate(this._renderId);
				
				this._activeMesh(meshLOD);
			}
		}

		//TODO 粒子应该也有个包围盒
        // Particle systems
        var beforeParticlesDate:Int = Lib.getTimer();
        if (this.particlesEnabled)
		{
            for (particleIndex in 0...this.particleSystems.length) 
			{
                var particleSystem:ParticleSystem = this.particleSystems[particleIndex];
				
				if (!particleSystem.isStarted())
				{
					continue;
				}

                if (particleSystem.emitter.position == null || 
					(particleSystem.emitter != null && particleSystem.emitter.isEnabled()))
				{
                    this._activeParticleSystems.push(particleSystem);
                    particleSystem.animate();
                }
            }
        }
        statistics.particlesDuration += Lib.getTimer() - beforeParticlesDate;
	}
	
	private function _activeMesh(mesh: AbstractMesh): Void 
	{
		if (mesh.skeleton != null && this.skeletonsEnabled)
		{
			this._activeSkeletons.pushNoDuplicate(mesh.skeleton);
		}

		if (mesh.showBoundingBox || this.forceShowBoundingBoxes) 
		{
			this._boundingBoxRenderer.renderList.push(mesh.getBoundingInfo().boundingBox);
		}
		
		if (mesh != null && mesh.subMeshes != null)
		{
			// Submeshes Octrees
			var len: Int;
			var subMeshes: Array<SubMesh>;

			if (mesh._submeshesOctree != null && mesh.useOctreeForRenderingSelection)
			{
				var intersections = mesh._submeshesOctree.select(this._frustumPlanes);

				len = intersections.length;
				subMeshes = intersections.data;
			} 
			else 
			{
				subMeshes = mesh.subMeshes;
				len = subMeshes.length;
			}

			for (subIndex in 0...len)
			{
				var subMesh = subMeshes[subIndex];

				this._evaluateSubMesh(subMesh, mesh);
			}
		}
	}
	
	public function updateTransformMatrix(force: Bool = false): Void
	{
		this.setTransformMatrix(this.activeCamera.getViewMatrix(), this.activeCamera.getProjectionMatrix(force));
	}
		
	public function _renderForCamera(camera:Camera = null, mustClearDepth:Bool = false) 
	{
        this.activeCamera = camera;

        if (this.activeCamera == null)
            throw ("Active camera not set");

        // Viewport
        engine.setViewport(activeCamera.viewport);

        // Camera
        this._renderId++;
		this.updateTransformMatrix();
		
        if (this.beforeCameraRender != null)
		{
			this.beforeCameraRender(this.activeCamera);
		}
		
        // Meshes
        var beforeEvaluateActiveMeshesDate = Lib.getTimer();
		
        _evaluateActiveMeshes();
		
        statistics.evaluateActiveMeshesDuration += Lib.getTimer() - beforeEvaluateActiveMeshesDate;

        // Skeletons
        for (skeletonIndex in 0..._activeSkeletons.length) 
		{
            var skeleton:Skeleton = _activeSkeletons.data[skeletonIndex];
            skeleton.prepare();
			
			statistics.activeBones++;
        }

        // Render targets
        var beforeRenderTargetDate = Lib.getTimer();
        if (this.renderTargetsEnabled)
		{
            for (renderIndex in 0..._renderTargets.length)
			{
                var renderTarget:RenderTargetTexture = _renderTargets.data[renderIndex];
				if (renderTarget != null && renderTarget._shouldRender())
				{
					this._renderId++;
					renderTarget.render();
				}
            }
			this._renderId++;
        }

        if (_renderTargets.length > 0)
		{ 
			// Restore back buffer
            engine.restoreDefaultFramebuffer();
        }
		
        statistics.renderTargetsDuration += Lib.getTimer() - beforeRenderTargetDate;

        // Prepare Frame
        postProcessManager._prepareFrame();

        var beforeRenderDate = Lib.getTimer();        
        // Backgrounds
        if (layers.length > 0) 
		{
            engine.setDepthTest(false);
			
            var layer:Layer = null;
            for (layerIndex in 0...layers.length)
			{
                layer = layers[layerIndex];
                if (layer.isBackground)
				{
                    layer.render();
                }
            }
            engine.setDepthTest(true);
        }

        // Render
        _renderingManager.render(null, null, true, true);
		
		// Bounding boxes
		this._boundingBoxRenderer.render();
        
        // Lens flares
		if (lensFlaresEnabled)
		{
			for (lensFlareSystemIndex in 0...lensFlareSystems.length)
			{
				lensFlareSystems[lensFlareSystemIndex].render();
			}
		}

        // Foregrounds
        if (layers.length > 0) 
		{
            engine.setDepthTest(false);
            for (layerIndex in 0...layers.length) 
			{
                var layer = layers[layerIndex];
                if (!layer.isBackground) 
				{
                    layer.render();
                }
            }
            engine.setDepthTest(true);
        }

        statistics.renderDuration += Lib.getTimer() - beforeRenderDate;

        // Finalize frame
        postProcessManager._finalizeFrame(camera.isIntermediate);

        // Update camera
        activeCamera._updateFromScene();
        
        // Reset some special arrays
        _renderTargets.reset();
		
		if (this.afterCameraRender != null)
		{
			this.afterCameraRender(this.activeCamera);
		}
	}
		
	private function _processSubCameras(camera: Camera): Void 
	{
		if (camera.subCameras.length == 0) 
		{
			this._renderForCamera(camera);
			return;
		}

		// Sub-cameras
		for (index in 0...camera.subCameras.length)
		{
			this._renderForCamera(camera.subCameras[index]);
		}

		this.activeCamera = camera;
		this.setTransformMatrix(this.activeCamera.getViewMatrix(), this.activeCamera.getProjectionMatrix());

		// Update camera
		this.activeCamera._updateFromScene();
	}
	
	private function _checkIntersections(): Void 
	{
		for (index in 0...this._meshesForIntersections.length)
		{
			var sourceMesh:AbstractMesh = this._meshesForIntersections.data[index];

			for (actionIndex in 0...sourceMesh.actionManager.actions.length)
			{
				var action = sourceMesh.actionManager.actions[actionIndex];
				var actionManager:ActionManager = sourceMesh.actionManager;

				if (action.trigger == ActionManager.OnIntersectionEnterTrigger || 
					action.trigger == ActionManager.OnIntersectionExitTrigger)
				{
					var otherMesh:AbstractMesh = action.getTriggerParameter();

					var areIntersecting:Bool = otherMesh.intersectsMesh(sourceMesh, false);
					var currentIntersectionInProgress = sourceMesh._intersectionsInProgress.indexOf(otherMesh);

					if (areIntersecting && currentIntersectionInProgress == -1 && 
						action.trigger == ActionManager.OnIntersectionEnterTrigger )
					{
						action._executeCurrent(ActionEvent.CreateNew(sourceMesh));
						sourceMesh._intersectionsInProgress.push(otherMesh);

					} 
					else if (!areIntersecting && currentIntersectionInProgress > -1 && 
							action.trigger == ActionManager.OnIntersectionExitTrigger )
					{
						action._executeCurrent(ActionEvent.CreateNew(sourceMesh));

						var indexOfOther = sourceMesh._intersectionsInProgress.indexOf(otherMesh);

						if (indexOfOther > -1) 
						{
							sourceMesh._intersectionsInProgress.splice(indexOfOther, 1);
						}
					}
				}
			}                
		}
	}
	
	private var _oldViewPort:Rectangle;
	public function render(rect:Rectangle):Void
	{
		var startDate = Lib.getTimer();
		
		this.statistics.reset();
		engine.resetDrawCalls();
		this.resetCachedMaterial();
		this._meshesForIntersections.reset();
		
		// Actions
		if (this.actionManager != null)
		{
			this.actionManager.processTrigger(ActionManager.OnEveryFrameTrigger, null);
		}
		
		//#if desktop
		//GL.enable (GL.TEXTURE_2D);
		//#end

        // Before render
        if (beforeRender != null)
		{
            beforeRender();
        }

        for (i in 0..._onBeforeRenderCallbacks.length) 
		{
            _onBeforeRenderCallbacks[i]();
        }
        
        // Animations
		var deltaTime:Float = MathUtils.fclamp(Tools.deltaTime, MinDeltaTime, MaxDeltaTime);
        _animationRatio = deltaTime * (60.0 / 1000.0);
		
        _animate();
        
        // Physics
        if (_physicsEngine != null && _physicsEnable) 
		{
            _physicsEngine.runOneStep(deltaTime / 1000.0);
        }
		
		// Customs render targets
		var beforeRenderTargetDate:Int = Lib.getTimer();
		if (this.renderTargetsEnabled) 
		{
			for (customIndex in 0...this.customRenderTargets.length)
			{
				var renderTarget:RenderTargetTexture = this.customRenderTargets[customIndex];
				if (renderTarget._shouldRender())
				{
					this._renderId++;

					this.activeCamera = renderTarget.activeCamera != null ? renderTarget.activeCamera : this.activeCamera;

					if (this.activeCamera == null)
						throw ("Active camera not set");

					// Viewport
					engine.setViewport(this.activeCamera.viewport);

					// Camera
					this.updateTransformMatrix();

					renderTarget.render();
				}
			}
			this._renderId++;
		}

		if (this.customRenderTargets.length > 0)
		{ 
			// Restore back buffer
			engine.restoreDefaultFramebuffer();
		}
		statistics.renderTargetsDuration += Lib.getTimer() - beforeRenderTargetDate;
		
		// Procedural textures
		if (this.proceduralTexturesEnabled)
		{
			for (proceduralIndex in 0..._proceduralTextures.length)
			{
				var proceduralTexture:ProceduralTexture = this._proceduralTextures[proceduralIndex];
				if (proceduralTexture._shouldRender()) 
				{
					proceduralTexture.render();
				}
			}
		}
        
        // Clear
        engine.clear(this.clearColor, this.autoClear || this.forceWireframe || this.forcePointsCloud, true);
        
        // Shadows
		if (shadowsEnabled)
		{
			for (lightIndex in 0...lights.length)
			{
				var light:Light = lights[lightIndex];
				
				var shadowGenerator:ShadowGenerator = light.shadowGenerator;

				if (light.isEnabled() && 
					shadowGenerator != null &&
					shadowGenerator.getShadowMap().getScene().textures.indexOf(shadowGenerator.getShadowMap()) != -1) 
				{
					_renderTargets.push(shadowGenerator.getShadowMap());
				}
			}
		}
        
		// RenderPipeline
		this.postProcessRenderPipelineManager.update();

        // Multi-cameras?
        if (activeCameras.length > 0) 
		{
            var currentRenderId:Int = _renderId;
            for (cameraIndex in 0...activeCameras.length) 
			{
                _renderId = currentRenderId;
                _processSubCameras(activeCameras[cameraIndex]);
            }
        } 
		else 
		{
            _processSubCameras(activeCamera);
        }
		
		// Intersection checks
		this._checkIntersections();
		
		// Update the audio listener attached to the camera
		this._updateAudioParameters();

        // After render
        if (afterRender != null) 
		{
            afterRender();
        }
		
		for (callbackIndex in 0..._onAfterRenderCallbacks.length) 
		{
			this._onAfterRenderCallbacks[callbackIndex]();
		}

        // Cleaning
        for (index in 0..._toBeDisposed.length)
		{
            _toBeDisposed.data[index].dispose();            
        }		
		_toBeDisposed.reset();
		
		statistics.lastFrameDuration = Lib.getTimer() - startDate;
	}
	
	private function _updateAudioParameters():Void
	{
		var listeningCamera:Camera;
		var audioEngine:AudioEngine = this.getEngine().getAudioEngine();

		if (this.activeCameras.length > 0)
		{
			listeningCamera = this.activeCameras[0];
		} 
		else
		{
			listeningCamera = this.activeCamera;
		}

		//if (listeningCamera != null && audioEngine.canUseWebAudio)
		//{
			//audioEngine.audioContext.listener.setPosition(listeningCamera.position.x, listeningCamera.position.y, listeningCamera.position.z);
			//
			//var mat = Matrix.Invert(listeningCamera.getViewMatrix());
			//var cameraDirection = Vector3.TransformNormal(new Vector3(0, 0, -1), mat);
			//cameraDirection.normalize();
			//audioEngine.audioContext.listener.setOrientation(cameraDirection.x, cameraDirection.y, cameraDirection.z, 0, 1, 0);
		//}
	}
	
	public function activePhysics(active:Bool):Void
	{
		_physicsEnable = active;
	}
	
	public function isPhysicsActive():Bool
	{
		return _physicsEnable;
	}
	
	public function dispose():Void
	{
		this.beforeRender = null;
        this.afterRender = null;

        this.skeletons = [];
		
		this._boundingBoxRenderer.dispose();
		
		// Debug layer
		//this.debugLayer.enabled = false;
		
		if (this.onDispose != null)
			this.onDispose();
			
		this._onBeforeRenderCallbacks = [];
		this._onAfterRenderCallbacks = [];

        // Detach cameras
        for (index in 0...this.cameras.length) 
		{
            this.cameras[index].detachControl();
        }

        // Release lights
        while (this.lights.length > 0)
		{
            this.lights[0].dispose();
        }

        // Release meshes
        while (this.meshes.length > 0)
		{
            this.meshes[0].dispose(true);
        }

        // Release cameras
        while (this.cameras.length > 0) 
		{
            this.cameras[0].dispose();
        }

        // Release materials
        while (this.materials.length > 0)
		{
            this.materials[0].dispose();
        }

        // Release particles
        while (this.particleSystems.length > 0)
		{
            this.particleSystems[0].dispose();
        }

        // Release sprites
        while (this.spriteManagers.length > 0)
		{
            this.spriteManagers[0].dispose();
        }

        // Release layers
        while (this.layers.length > 0)
		{
            this.layers[0].dispose();
        }

        // Release textures
        while (this.textures.length > 0)
		{
            this.textures[0].dispose();
        }

        // Post-processes
        this.postProcessManager.dispose();
        
        // Physics
        if (this._physicsEngine != null) 
		{
            this.disablePhysicsEngine();
        }

        engine.wipeCaches();
	}
	
	public function _getNewPosition(position:Vector3, velocity:Vector3, 
									collider:Collider, maximumRetry:Int, 
									finalPosition:Vector3, excludedMesh: AbstractMesh = null):Void
	{
		position.divideToRef(collider.radius, this._scaledPosition);
        velocity.divideToRef(collider.radius, this._scaledVelocity);

        collider.retry = 0;
        collider.initialVelocity.copyFrom(this._scaledVelocity);
        collider.initialPosition.copyFrom(this._scaledPosition);
		
        this._collideWithWorld(this._scaledPosition, this._scaledVelocity, collider, maximumRetry, finalPosition, excludedMesh);

        finalPosition.multiplyInPlace(collider.radius);
	}
	
	public function _collideWithWorld(position:Vector3, velocity:Vector3, 
									collider:Collider, maximumRetry:Int, 
									finalPosition:Vector3, excludedMesh: AbstractMesh = null):Void 
	{
		var closeDistance = Engine.CollisionsEpsilon * 10.0;

        if (collider.retry >= maximumRetry)
		{
            finalPosition.copyFrom(position);
            return;
        } 
		else 
		{
			collider.initialize(position, velocity, closeDistance);

			// Check all meshes
			for (index in 0...this.meshes.length)
			{
				var mesh:AbstractMesh = this.meshes[index];
				if (mesh.isEnabled() && mesh.checkCollisions && mesh != excludedMesh)
				{
					mesh._checkCollision(collider);
				}
			}

			if (!collider.collisionFound)
			{
				position.addToRef(velocity, finalPosition);
				return;
			}
			
			if (velocity.x != 0 || velocity.y != 0 || velocity.z != 0)
			{
				collider._getResponse(position, velocity);
			}

			if (velocity.length() <= closeDistance)
			{
				finalPosition.copyFrom(position);
				return;
			}
			
			collider.retry++;
			this._collideWithWorld(position, velocity, collider, maximumRetry, finalPosition, excludedMesh);
		}
	}

	public function createOrUpdateSelectionOctree(maxCapacity:Int = 64, maxDepth:Int = 2):Octree<AbstractMesh> 
	{
		if (this._selectionOctree == null)
		{
            this._selectionOctree = new Octree<AbstractMesh>(Octree.CreationFuncForMeshes, maxCapacity, maxDepth);
        }

        var min:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var max:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
        for (index in 0...this.meshes.length) 
		{
            var mesh:AbstractMesh = this.meshes[index];

            mesh.computeWorldMatrix(true);
			
			var boundingBox:BoundingBox = mesh.getBoundingInfo().boundingBox;
            var minBox = boundingBox.minimumWorld;
            var maxBox = boundingBox.maximumWorld;

            Tools.checkExtends(minBox, min, max);
            Tools.checkExtends(maxBox, min, max);
        }

        // Update octree
        this._selectionOctree.update(min, max, this.meshes);
		
		return this._selectionOctree;
	}
	
	public function createPickingRay(x:Float, y:Float, world:Matrix = null, camera:Camera = null):Ray
	{
        if (camera == null)
		{
            if (this.activeCamera == null)
                throw ("Active camera not set");

			camera = this.activeCamera;
        }
		
		var cameraViewport = camera.viewport;
        var viewport = this.activeCamera.viewport.toGlobal(engine);

        // Moving coordinates to local viewport world
		x = x / engine.getHardwareScalingLevel() - viewport.x;
		y = y / engine.getHardwareScalingLevel() - (engine.getRenderHeight() - viewport.y - viewport.height);

        return Ray.CreateNew(x, y, viewport.width, viewport.height, 
							world != null ? world : new Matrix(), 
							camera.getViewMatrix(), 
							camera.getProjectionMatrix());
	}
	
	public function _internalPick(rayFunction:Matrix->Ray, 
								predicate:AbstractMesh->Bool, 
								fastCheck:Bool = false):PickingInfo
	{
		var pickingInfo:PickingInfo = null;

        for (meshIndex in 0...this.meshes.length)
		{
            var mesh:AbstractMesh = this.meshes[meshIndex];

            if (predicate != null)
			{
                if (!predicate(mesh)) 
				{
                    continue;
                }
            } 
			else if (!mesh.isEnabled() || !mesh.isVisible || !mesh.isPickable)
			{
                continue;
            }

            var world:Matrix = mesh.getWorldMatrix();
            var ray:Ray = rayFunction(world);

            var result:PickingInfo = mesh.intersects(ray, fastCheck);
            if (result == null || !result.hit)
                continue;

            if (!fastCheck && pickingInfo != null && result.distance >= pickingInfo.distance)
                continue;

            pickingInfo = result;

            if (fastCheck) 
			{
                break;
            }
        }
        
        return pickingInfo == null ? new PickingInfo() : pickingInfo;
	}
	
	public function pick(x:Float, y:Float, predicate:AbstractMesh->Bool = null, 
						fastCheck:Bool = false, camera:Camera = null):PickingInfo 
	{
		var pickRay = function(world:Matrix):Ray 
		{
            return this.createPickingRay(x, y, world, camera);
        }
        return this._internalPick(pickRay, predicate, fastCheck);
    }
	
	public function pickWithRay(ray:Ray, predicate:AbstractMesh->Bool, fastCheck:Bool = false):PickingInfo 
	{
		function param(world:Matrix):Ray 
		{
            if (this._pickWithRayInverseMatrix == null) 
			{
                this._pickWithRayInverseMatrix = new Matrix();
            }
            world.invertToRef(this._pickWithRayInverseMatrix);
            return Ray.Transform(ray, this._pickWithRayInverseMatrix);
        }
		
        return this._internalPick(param, predicate, fastCheck);
    }
	
	public function setPointerOverMesh(mesh: AbstractMesh): Void 
	{
		if (_pointerOverMesh == mesh)
		{
			return;
		}

		if (_pointerOverMesh != null && this._pointerOverMesh.actionManager != null)
		{
			_pointerOverMesh.actionManager.processTrigger(ActionManager.OnPointerOutTrigger, ActionEvent.CreateNew(_pointerOverMesh));
		}

		_pointerOverMesh = mesh;
		if(_pointerOverMesh != null && _pointerOverMesh.actionManager != null)
		{
			_pointerOverMesh.actionManager.processTrigger(ActionManager.OnPointerOverTrigger, ActionEvent.CreateNew(_pointerOverMesh));
		}
	}

	public function getPointerOverMesh(): AbstractMesh
	{
		return this._pointerOverMesh;
	}
	
	// Physics
	public function getPhysicsEngine(): PhysicsEngine
	{
		return this._physicsEngine;
	}
		
	// Physics
    public function enablePhysics(gravity:Vector3 = null, plugin:IPhysicsEnginePlugin = null):Bool
	{
        if (this._physicsEngine != null)
		{
            return true;
        }
        
		this._physicsEngine = new PhysicsEngine(plugin);
		
        if (!_physicsEngine.isSupported()) 
		{
			this._physicsEngine = null;
            return false;
        }

        this._physicsEngine.initialize(gravity);

        return true;
    }

	public function disablePhysicsEngine(): Void 
	{
		if (this._physicsEngine == null)
		{
			return;
		}

		this._physicsEngine.dispose();
		this._physicsEngine = null;
	}

	public function isPhysicsEnabled(): Bool 
	{
		return this._physicsEngine != null;
	}

	public function setGravity(gravity: Vector3): Void {
		if (this._physicsEngine == null)
		{
			return;
		}

		this._physicsEngine.setGravity(gravity);
	}

	public function createCompoundImpostor(parts: Array<PhysicsCompoundBodyPart>, options: PhysicsBodyCreationOptions): Dynamic
	{
		if (this._physicsEngine == null)
		{
			return null;
		}

		for (index in 0...parts.length) 
		{
			var mesh:Mesh = parts[index].mesh;

			mesh._physicImpostor = parts[index].impostor;
			mesh._physicsMass = options.mass / parts.length;
			mesh._physicsFriction = options.friction;
			mesh._physicRestitution = options.restitution;
		}

		return this._physicsEngine.registerMeshesAsCompound(parts, options);
	}

	//ANY
	public function deleteCompoundImpostor(compound: Dynamic): Void 
	{
		for (index in 0...compound.parts.length) 
		{
			var mesh:AbstractMesh = compound.parts[index].mesh;
			mesh._physicImpostor = PhysicsEngine.NoImpostor;
			this._physicsEngine.unregisterMesh(mesh);
		}
	}
	
}