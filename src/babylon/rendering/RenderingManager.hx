package babylon.rendering;

import babylon.math.Color3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.SubMesh;
import babylon.particles.ParticleSystem;
import babylon.Scene;
import babylon.mesh.Mesh;
import babylon.sprites.SpriteManager;
import babylon.math.Color4;
import babylon.tools.SmartArray;
import openfl.Lib;

class RenderingManager 
{
	public static var MAX_RENDERINGGROUPS:Int = 4;
	
	public var _scene:Scene;
	public var _renderingGroups:Array<RenderingGroup>;
	public var _depthBufferAlreadyCleaned:Bool;

	public function new(scene:Scene) 
	{
		this._scene = scene;
        this._renderingGroups = [];
		
		_depthBufferAlreadyCleaned = false;
	}
	
	public function _renderParticles(index:Int, activeMeshes:Array<AbstractMesh>):Void 
	{
		var particles = _scene.getActiveParticleSystems();
        if (particles.length == 0) 
		{
			return;
		}
		
		// Particles
		var beforeParticlesDate = Lib.getTimer();
		for (particleIndex in 0...particles.length) 
		{
			var particleSystem:ParticleSystem = particles.data[particleIndex];

			if (particleSystem.renderingGroupId != index) 
			{
				continue;
			}
			
			_clearDepthBuffer();

			if (particleSystem.emitter.position == null || 
				activeMeshes == null || 
				activeMeshes.indexOf(particleSystem.emitter) != -1)
			{
				_scene.statistics.activeParticles += particleSystem.render();
			}			
		}
		_scene.statistics.particlesDuration += (Lib.getTimer() - beforeParticlesDate);      
    }
	
	public function _renderSprites(index:Int):Void
	{
        if (this._scene.spriteManagers.length == 0)
		{
            return;
        }

        // Sprites       
        var beforeSpritessDate = Lib.getTimer();
        for (id in 0...this._scene.spriteManagers.length)
		{
            var spriteManager:SpriteManager = _scene.spriteManagers[id];

            if (spriteManager.renderingGroupId == index)
			{
                _clearDepthBuffer();
                spriteManager.render();
            }
        }
        _scene.statistics.spritesDuration += (Lib.getTimer() - beforeSpritessDate);
    }
	
	public function _clearDepthBuffer():Void
	{
        if (_depthBufferAlreadyCleaned)
		{
            return;
        }

        _scene.getEngine().clear(new Color3(0, 0, 0), false, true);
        _depthBufferAlreadyCleaned = true;
    }
	
	public function render(customRenderFunction:Dynamic, 
							activeMeshes:Array<AbstractMesh>, 
							renderParticles:Bool, 
							renderSprites:Bool):Void 
	{    
        for (index in 0...RenderingManager.MAX_RENDERINGGROUPS)
		{
            this._depthBufferAlreadyCleaned = false;
			
            var renderingGroup:RenderingGroup = this._renderingGroups[index];
            if (renderingGroup != null) 
			{
                this._clearDepthBuffer();
                if (!renderingGroup.render(customRenderFunction, function():Void {
                    if (renderSprites)
					{
                        this._renderSprites(index);
					}
                }))
				{
                    this._renderingGroups.splice(index, 1);
                }
            } 
			else if (renderSprites)
			{
                this._renderSprites(index);
            }

            if (renderParticles)
			{
                this._renderParticles(index, activeMeshes);
            }
        }
    }
	
	public function reset():Void 
	{
        for (renderingGroup in this._renderingGroups)
		{
            renderingGroup.prepare();
        }
    }
	
	public function dispatch(subMesh:SubMesh):Void
	{
        var mesh:AbstractMesh = subMesh.getMesh();
		
        var renderingGroupId:Int = mesh.renderingGroupId;

        if (this._renderingGroups.length <= renderingGroupId) 
		{
            this._renderingGroups[renderingGroupId] = new RenderingGroup(renderingGroupId, this._scene);
        }

        this._renderingGroups[renderingGroupId].dispatch(subMesh);
    }
	
}
