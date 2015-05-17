package babylon;

import babylon.actions.Action;
import babylon.actions.ActionEvent;
import babylon.actions.ActionManager;
import babylon.animations.Animatable;
import babylon.animations.Animation;
import babylon.audio.AudioEngine;
import babylon.bones.Skeleton;
import babylon.cameras.Camera;
import babylon.collisions.Collider;
import babylon.collisions.CollisionCoordinatorLegacy;
import babylon.collisions.CollisionCoordinatorWorker;
import babylon.collisions.ICollisionCoordinator;
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
import babylon.math.FastMath;
import babylon.math.Frustum;
import babylon.math.Matrix;
import babylon.math.Plane;
import babylon.math.Ray;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Geometry;
import babylon.mesh.Mesh;
import babylon.mesh.simplify.SimplificationQueue;
import babylon.mesh.SubMesh;
import babylon.particles.ParticleSystem;
import babylon.physics.IPhysicsEnginePlugin;
import babylon.physics.PhysicsBodyCreationOptions;
import babylon.physics.PhysicsCompoundBodyPart;
import babylon.physics.PhysicsEngine;
import babylon.postprocess.PostProcessManager;
import babylon.postprocess.renderpipeline.PostProcessRenderPipelineManager;
import babylon.rendering.BoundingBoxRenderer;
import babylon.rendering.DepthRenderer;
import babylon.rendering.OutlineRenderer;
import babylon.rendering.RenderingManager;
import babylon.sprites.SpriteManager;
import babylon.tools.SmartArray;
import babylon.tools.Tools;
import haxe.Timer;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.Lib;

/**
 * Represents a scene to be rendered by the engine.
 */
class Scene
{
	public static var MinDeltaTime:Float = 1.0;
	public static var MaxDeltaTime:Float = 1000.0;
	
	public var meshUnderPointer(get, null):AbstractMesh;
	public var pointerX(get, null):Float;
	public var pointerY(get, null):Float;
	
	public var autoClear:Bool = true;
	public var clearColor:Color3;
	public var ambientColor:Color3;
	
	/**
	 * A function to be executed before rendering this scene
	 */
	public var beforeRender:Void->Void;
	
	/**
	* A function to be executed after rendering this scene
	*/
	public var afterRender:Void->Void;
	
	/**
	 * A function to be executed when this scene is disposed.
	 */
	public var onDispose:Void->Void;
	
	public var beforeCameraRender:Camera->Void;
	public var afterCameraRender:Camera->Void;
	
	public var forceWireframe:Bool = false;
	public var forcePointsCloud:Bool = false;
	public var forceShowBoundingBoxes:Bool = false;
	
	public var clipPlane:Plane;
	
	public var animationsEnabled:Bool = true;
	
	// Keyboard
	private var _onKeyDown: KeyboardEvent->Void;
	private var _onKeyUp: KeyboardEvent->Void;
	
	// Pointers
	private var _onPointerMove: MouseEvent->Void;
	private var _onPointerDown: MouseEvent->Void;
	private var _onPointerUp: MouseEvent->Void;
	
	public var onPointerDown: MouseEvent->PickingInfo->Void;
	public var onPointerUp: MouseEvent->PickingInfo->Void;
	
	// Define this parameter if you are using multiple cameras and 
	// you want to specify which one should be used for pointer position
	public var cameraToUseForPointers: Camera = null; 
	
	private var _pointerX: Float = 0;
	private var _pointerY: Float = 0;
	private var _meshUnderPointer: AbstractMesh;
	private var _pointerOverMesh: AbstractMesh;
	
	// Fog
	public var fogEnabled:Bool = true;
	public var fogInfo:FogInfo;
	
	//---------Lights begin-------//
	public var shadowsEnabled:Bool = true;
	
	public var lightsEnabled:Bool = true;
	public var lights:Array<Light>;
	
	public var onNewLightAdded:Light->Int->Scene-> Void;
	public var onLightRemoved:Light->Void;
	
	//---------Lights end---------//
	
	//---------Cameras begin-------//
	public var cameras:Array<Camera>;
	public var activeCamera:Camera;
	public var activeCameras:Array<Camera>;
	
	public var onNewCameraAdded:Camera->Int->Scene-> Void;
	public var onCameraRemoved:Camera->Void;
	//---------Cameras end-------//
	
	//---------Meshes begin-------//
	public var meshes:Array<AbstractMesh>;
	public var onNewMeshAdded:AbstractMesh->Int->Scene-> Void;
	public var onMeshRemoved:AbstractMesh->Void;
	//---------Meshes end-------//
	
	//---------Geometries begin-------//
	private var _geometries:Array<Geometry>;
	public var onGeometryAdded:Geometry->Void;
	public var onGeometryRemoved:Geometry->Void;
	//---------Geometries begin-------//
	
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
	public var spritesEnabled:Bool = true;
	public var spriteManagers:Array<SpriteManager>;
	
	// Layers
	public var layers:Array<Layer>;
	
	// Skeletons
	public var skeletonsEnabled:Bool = true;
	public var skeletons:Array<Skeleton>;
	
	// Lens flares
	public var lensFlaresEnabled:Bool = true;
	public var lensFlareSystems:Array<LensFlareSystem>;
	
	//--------- Collisions begin--------------//
	public var collisionsEnabled:Bool = true;
	public var gravity:Vector3;
	private var _workerCollisions:Bool = false;
	public var collisionCoordinator:ICollisionCoordinator;
	
	public var workerCollisions(get, set):Bool;
	//--------- Collisions end--------------//
	
	private var _physicsEngine:PhysicsEngine;
	private var _physicsEnable:Bool = true;
	
	// Postprocesses
	public var postProcessesEnabled:Bool = true;
	public var postProcessManager:PostProcessManager;
	public var postProcessRenderPipelineManager: PostProcessRenderPipelineManager;
	
	// Customs render targets
	public var renderTargetsEnabled:Bool = true;
	public var dumpNextRenderTargets:Bool = false;
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
	
	// Procedural textures
	public var proceduralTexturesEnabled:Bool = true;
	public var _proceduralTextures:Array<ProceduralTexture> = [];
	
	// Sound Tracks
	//public mainSoundTrack: SoundTrack;
	//public soundTracks = new Array<SoundTrack>();
	//private _audioEnabled = true;
	//private _headphone = false;
	
	//Simplification Queue
	public var simplificationQueue: SimplificationQueue;
	
	public var engine:Engine;
	
	public var statistics:Statistics;
	
	private var _animationRatio:Float = 0;
	private var _animationStartDate:Int = -1;
	
	private var _renderId:Int = 0;
	private var _executeWhenReadyTimeoutId:Int = -1;

	public var _toBeDisposed:SmartArray<IDispose>;
	
	public var _onReadyCallbacks:Array<Void->Void>;
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
	private var _depthRenderer: DepthRenderer;
	
	private var _scaledVelocity:Vector3;
	private var _scaledPosition:Vector3;
	
	public var _viewMatrix:Matrix;
	public var _projectionMatrix:Matrix;
	public var _frustumPlanes:Array<Plane>;
	
	public var _selectionOctree:Octree<AbstractMesh>;

	public var _cachedMaterial: Material;
	
	private var _uniqueIdCounter:Int = 0;

	public function new(engine:Engine) 
	{
		this.engine = engine;
		
		engine.scenes.push(this);

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
		
		//simplification queue
		this.simplificationQueue = new SimplificationQueue();
		
		this.workerCollisions = false;

		this.attachControl();
	}
	
	private function set_workerCollisions(value:Bool):Bool
	{
		this._workerCollisions = value;
		if (this.collisionCoordinator != null) 
		{
			this.collisionCoordinator.destroy();
		}

		this.collisionCoordinator = value ? new CollisionCoordinatorWorker() : new CollisionCoordinatorLegacy();

		this.collisionCoordinator.init(this);
		
		return value;
	}
	
	private function get_workerCollisions():Bool
	{
		return this._workerCollisions;
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
	
	
	private function get_meshUnderPointer(): AbstractMesh 
	{
		return this._meshUnderPointer;
	}

	
	private function get_pointerX(): Float
	{
		return this._pointerX;
	}

	
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
			
			var pickResult = this.pick(this._pointerX, this._pointerY, predicateDown, false, this.cameraToUseForPointers);

			if (pickResult.hit)
			{
				if (pickResult.pickedMesh.actionManager != null)
				{
					switch (evt.type) 
					{
						case MouseEvent.MOUSE_DOWN:
							pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnLeftPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
						case MouseEvent.RIGHT_MOUSE_DOWN:
							pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnRightPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
						case MouseEvent.MIDDLE_MOUSE_DOWN:
							pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnCenterPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
					}
					
					pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
				}
			}

			if(this.onPointerDown != null)
				this.onPointerDown(evt, pickResult);
		};
		
		this._onPointerUp = function(evt: MouseEvent):Void
		{
			var predicateUp:AbstractMesh->Bool = null;
			
			if (this.onPointerUp == null)
			{
				predicateUp = function(mesh:AbstractMesh):Bool
				{
					return mesh.isPickable && mesh.isVisible && mesh.isReady() &&
						mesh.actionManager != null && mesh.actionManager.hasSpecificTriggers([ActionManager.OnPickUpTrigger]);
				}
			}
			
			this._updatePointerPosition(evt);
			
			var pickResult = this.pick(this._pointerX, this._pointerY, predicateUp, false, this.cameraToUseForPointers);

			if (pickResult.hit)
			{
				if (pickResult.pickedMesh.actionManager != null)
				{
							pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickUpTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
				}
			}

			if(this.onPointerUp != null)
				this.onPointerUp(evt, pickResult);
		};
		
		engine.getStage().addEventListener(MouseEvent.MOUSE_MOVE, _onPointerMove);
		engine.getStage().addEventListener(MouseEvent.MOUSE_DOWN, _onPointerDown);
		engine.getStage().addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, _onPointerDown);
		engine.getStage().addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _onPointerDown);
		
		engine.getStage().addEventListener(MouseEvent.MOUSE_UP, _onPointerUp);
		engine.getStage().addEventListener(MouseEvent.MIDDLE_MOUSE_UP, _onPointerUp);
		engine.getStage().addEventListener(MouseEvent.RIGHT_MOUSE_UP, _onPointerUp);
		
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
		engine.getStage().removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, _onPointerDown);
		engine.getStage().removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _onPointerDown);
		
		engine.getStage().removeEventListener(MouseEvent.MOUSE_UP, _onPointerUp);
		engine.getStage().removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, _onPointerUp);
		engine.getStage().removeEventListener(MouseEvent.RIGHT_MOUSE_UP, _onPointerUp);
		
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
		
		for (index in 0..._geometries.length)
		{
			var geometry = _geometries[index];
			if (geometry.delayLoadState == Engine.DELAYLOADSTATE_LOADING)
			{
				return false;
			}
		}

        for (index in 0...meshes.length)
		{
            var mesh = meshes[index];
			if (!mesh.isReady())
			{
				return false;
			}
			
            var mat:Material = mesh.material;
            if (mat != null) 
			{
                if (!mat.isReady(mesh))
				{
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
        if (index != -1)
		{
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
			animatable.appendAnimations(target, Reflect.getProperty(target, "animations"));
		}

        // Children animations		
		//TODO 写法对不对？
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
            _activeAnimatables[index]._animate(delay); 
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
	
	public function addMesh(newMesh: AbstractMesh):Void
	{
		newMesh.uniqueId = this._uniqueIdCounter++;
		
		var position:Int = this.meshes.push(newMesh);

		//notify the collision coordinator
		this.collisionCoordinator.onMeshAdded(newMesh);

		if (this.onNewMeshAdded != null)
		{
			this.onNewMeshAdded(newMesh, position, this);
		}
	}

	public function removeMesh(toRemove: AbstractMesh): Int
	{
		var index: Int = this.meshes.indexOf(toRemove);
		if (index != -1)
		{
			// Remove from the scene if mesh found 
			this.meshes.splice(index, 1);
		}
		//notify the collision coordinator
		this.collisionCoordinator.onMeshRemoved(toRemove);

		if (this.onMeshRemoved != null)
		{
			this.onMeshRemoved(toRemove);
		}
		return index;
	}

	public function removeLight(toRemove: Light): Int 
	{
		var index: Int = this.lights.indexOf(toRemove);
		if (index != -1) 
		{
			// Remove from the scene if mesh found 
			this.lights.splice(index, 1);
		}
		if (this.onLightRemoved != null)
		{
			this.onLightRemoved(toRemove);
		}
		return index;
	}

	public function removeCamera(toRemove: Camera): Int
	{
		var index: Int = this.cameras.indexOf(toRemove);
		if (index != -1) 
		{
			// Remove from the scene if mesh found 
			this.cameras.splice(index, 1);
		}
		// Remove from activeCameras
		var index2: Int = this.activeCameras.indexOf(toRemove);
		if (index2 != -1)
		{
			// Remove from the scene if mesh found
			this.activeCameras.splice(index2, 1);
		}
		// Reset the activeCamera
		if (this.activeCamera == toRemove) 
		{
			if (this.cameras.length > 0)
			{
				this.activeCamera = this.cameras[0];
			} 
			else
			{
				this.activeCamera = null;
			}
		}
		if (this.onCameraRemoved != null) 
		{
			this.onCameraRemoved(toRemove);
		}
		return index;
	}

	public function addLight(newLight: Light):Void
	{
		newLight.uniqueId = this._uniqueIdCounter++;
		var position: Int = this.lights.push(newLight);
		if (this.onNewLightAdded != null)
		{
			this.onNewLightAdded(newLight, position, this);
		}
	}

	public function addCamera(newCamera: Camera):Void
	{
		newCamera.uniqueId = this._uniqueIdCounter++;
		var position: Int = this.cameras.push(newCamera);
		if (this.onNewCameraAdded != null)
		{
			this.onNewCameraAdded(newCamera, position, this);
		}
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
	
	public function getCameraByUniqueID(uniqueId: Int): Camera
	{
		for (index in  0...cameras.length) 
		{
			if (cameras[index].uniqueId == uniqueId) 
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
	
	/**
	 * sets the active camera of the scene using its ID
	 * @param {string} id - the camera's ID
	 * @return {BABYLON.Camera|null} the new active camera or null if none found.
	 * @see activeCamera
	 */
	public function setActiveCameraByID(id:String):Camera 
	{
		var camera = getCameraByID(id);
		if (camera != null)
		{
			activeCamera = camera;
			return camera;
		}
		
		return null;
	}
	
	/**
	 * sets the active camera of the scene using its name
	 * @param {string} name - the camera's name
	 * @return {BABYLON.Camera|null} the new active camera or null if none found.
	 * @see activeCamera
	 */
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
	
	/**
	 * get a material using its id
	 * @param {string} the material's ID
	 * @return {BABYLON.Material|null} the material or null if none found.
	 */
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
	
	public function getLightByUniqueID(uniqueId:Int):Light 
	{
		for (index in 0...lights.length)
		{
            if (lights[index].uniqueId == uniqueId) 
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
		
		//notify the collision coordinator
		this.collisionCoordinator.onGeometryAdded(geometry);

		if (this.onGeometryAdded != null)
		{
			this.onGeometryAdded(geometry);
		}

		return true;
	}
	
	/**
	 * Removes an existing geometry
	 * @param {BABYLON.Geometry} geometry - the geometry to be removed from the scene.
	 * @return {boolean} was the geometry removed or not
	 */
	public function removeGeometry(geometry: Geometry): Bool 
	{
		var index:Int = this._geometries.indexOf(geometry);

		if (index > -1) 
		{
			this._geometries.splice(index, 1);

			//notify the collision coordinator
			this.collisionCoordinator.onGeometryDeleted(geometry);

			if (this.onGeometryRemoved != null)
			{
				this.onGeometryRemoved(geometry);
			}
			return true;
		}
		return false;
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
	
	public function getMeshByUniqueID(uniqueId:Int):AbstractMesh
	{
		for (index in 0...meshes.length)
		{
            if (meshes[index].uniqueId == uniqueId)
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
	
	public function getNodeByName(name: String): Node 
	{
		var mesh = this.getMeshByName(name);
		if (mesh != null)
		{
			return mesh;
		}

		var light = this.getLightByName(name);
		if (light != null)
		{
			return light;
		}

		return this.getCameraByName(name);
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
		if (mesh.alwaysSelectAsActiveMesh || mesh.subMeshes.length == 1 || subMesh.isInFrustrum(_frustumPlanes)) 
		{
            var material:Material = subMesh.getMaterial();
			
			if (mesh.showSubMeshesBoundingBox) 
			{
				this._boundingBoxRenderer.addBoundingBox(subMesh.getBoundingInfo().boundingBox);
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
                statistics.activeIndices += subMesh.indexCount;
                _renderingManager.dispatch(subMesh);
            }
        }
	}
	
	private function _evaluateActiveMeshes():Void 
	{
		this.activeCamera._activeMeshes.reset();
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
			
			if (!mesh.isReady() || !mesh.isEnabled())
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

			if (mesh.alwaysSelectAsActiveMesh ||
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
					
					var hasSpecialRenderTargetCamera:Bool = renderTarget.activeCamera != null && renderTarget.activeCamera != this.activeCamera;
					
					renderTarget.render(hasSpecialRenderTargetCamera, dumpNextRenderTargets);
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
				var action:Action = sourceMesh.actionManager.actions[actionIndex];
				var actionManager:ActionManager = sourceMesh.actionManager;

				if (action.trigger == ActionManager.OnIntersectionEnterTrigger || 
					action.trigger == ActionManager.OnIntersectionExitTrigger)
				{
					var parameters:Dynamic = action.getTriggerParameter();
					var otherMesh:AbstractMesh = Std.is(parameters,AbstractMesh) ? parameters : parameters.mesh;

					var areIntersecting:Bool = otherMesh.intersectsMesh(sourceMesh, parameters.usePreciseIntersection);
					var currentIntersectionInProgress:Int = sourceMesh._intersectionsInProgress.indexOf(otherMesh);

					if (areIntersecting && currentIntersectionInProgress == -1)
					{
						if (action.trigger == ActionManager.OnIntersectionEnterTrigger)
						{
							action._executeCurrent(ActionEvent.CreateNew(sourceMesh));
							sourceMesh._intersectionsInProgress.push(otherMesh);
						} 
						else if (action.trigger == ActionManager.OnIntersectionExitTrigger)
						{
							sourceMesh._intersectionsInProgress.push(otherMesh);
						}
					} 
					else if (!areIntersecting && currentIntersectionInProgress > -1 && 
							action.trigger == ActionManager.OnIntersectionExitTrigger )
					{
						action._executeCurrent(ActionEvent.CreateNew(sourceMesh));

						var indexOfOther:Int = sourceMesh._intersectionsInProgress.indexOf(otherMesh);
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
		var deltaTime:Float = FastMath.clamp(engine.getDeltaTime(), MinDeltaTime, MaxDeltaTime);
        _animationRatio = deltaTime * (60.0 / 1000.0);
		
        _animate();
        
        // Physics
        if (_physicsEngine != null && _physicsEnable) 
		{
            _physicsEngine.runOneStep(deltaTime / 1000.0);
        }
		
		// Customs render targets
		var beforeRenderTargetDate:Int = Lib.getTimer();
		var currentActiveCamera:Camera = this.activeCamera;
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

					renderTarget.render(currentActiveCamera != this.activeCamera, this.dumpNextRenderTargets);
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
		
		this.activeCamera = currentActiveCamera;
		
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
		
		// Depth renderer
		if (this._depthRenderer != null)
		{
			this._renderTargets.push(this._depthRenderer.getDepthMap());
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
			if (this.activeCamera == null)
			{
				throw "No camera defined";
			}
				
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
		
		if (this.dumpNextRenderTargets)
		{
			this.dumpNextRenderTargets = false;
		}
		
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
	
	public function enableDepthRenderer(): DepthRenderer 
	{
		if (this._depthRenderer != null)
		{
			return this._depthRenderer;
		}

		this._depthRenderer = new DepthRenderer(this);

		return this._depthRenderer;
	}

	public function disableDepthRenderer(): Void 
	{
		if (this._depthRenderer == null)
		{
			return;
		}

		this._depthRenderer.dispose();
		this._depthRenderer = null;
	}
	
	public function dispose():Void
	{
		this.beforeRender = null;
        this.afterRender = null;

        this.skeletons = [];
		
		this._boundingBoxRenderer.dispose();
		this._boundingBoxRenderer = null;
		
		if (this._depthRenderer != null) 
		{
			this._depthRenderer.dispose();
			this._depthRenderer = null;
		}
		
		if (this.onDispose != null)
			this.onDispose();
			
		this._onBeforeRenderCallbacks = [];
		this._onAfterRenderCallbacks = [];
		
		this.detachControl();

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
		
		// Remove from engine
		engine.scenes.remove(this);

        engine.wipeCaches();
	}
	
	public function getWorldExtends(): { min: Vector3, max: Vector3 } 
	{
		var min:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var max:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
		for (index in 0...meshes.length)
		{
			var mesh:AbstractMesh = this.meshes[index];

			mesh.computeWorldMatrix(true);
			
			var minBox:Vector3 = mesh.getBoundingInfo().boundingBox.minimumWorld;
			var maxBox:Vector3 = mesh.getBoundingInfo().boundingBox.maximumWorld;

			Tools.checkExtends(minBox, min, max);
			Tools.checkExtends(maxBox, min, max);
		}

		return {
			min: min,
			max: max
		};
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

        var worldExtends = this.getWorldExtends();

        // Update octree
        this._selectionOctree.update(worldExtends.min, worldExtends.max, this.meshes);
		
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