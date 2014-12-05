package babylon.lensflare;

import babylon.collisions.PickingInfo;
import babylon.Engine;
import babylon.materials.Effect;
import babylon.math.Matrix;
import babylon.math.Ray;
import babylon.math.Vector3;
import babylon.math.Viewport;
import babylon.mesh.AbstractMesh;
import babylon.mesh.BabylonGLBuffer;
import babylon.Scene;
import babylon.utils.TempVars;

class LensFlareSystem
{
	public var name:String;
	public var borderLimit:Float = 300;
	public var lensFlares:Array<LensFlare>;
	public var meshesSelectionPredicate:AbstractMesh->Bool;
	
	/** Emitter of the lens flare system : it can be a camera, a light or a mesh. */
	private var _emitter:Dynamic;	
	private var _scene:Scene;
	
	private var _vertexDeclaration:Array<Int>;
	private var _vertexStrideSize:Int;
	private var _vertexBuffer:BabylonGLBuffer;		
	private var _indexBuffer:BabylonGLBuffer;		
	private var _effect:Effect;				
	private var _positionX:Float;
	private var _positionY:Float;
	private var _isEnabled:Bool = true;
	
	public var isEnabled(get, set):Bool;
	
	public function new(name:String, emitter:Dynamic, scene:Scene)
	{
        this.name = name;
		this._emitter = emitter;
		this._scene = scene;
        scene.lensFlareSystems.push(this);
        
		this.lensFlares = [];
		
		this.meshesSelectionPredicate = function(m:AbstractMesh):Bool 
		{
			return m.material != null && m.isVisible && 
				m.isEnabled() && m.isBlocker && 
				((m.layerMask & scene.activeCamera.layerMask) != 0);
		};
		
		var engine:Engine = _scene.engine;
		
        // VBO
        var vertices:Array<Float> = [1, 1, -1, 1, -1, -1, 1, -1];
        this._vertexDeclaration = [2];
        this._vertexStrideSize = 2 * 4;
        this._vertexBuffer = engine.createVertexBuffer(vertices);

        // Indices
        var indices:Array<Int> = [0, 1, 2, 0, 2, 3];
        this._indexBuffer = engine.createIndexBuffer(indices);       

        // Effects
        this._effect = engine.createEffect("lensFlare",
                    ["position"],
                    ["color", "viewportMatrix"],
                    ["textureSampler"], "");
	}
	
	private inline function get_isEnabled():Bool
	{
		return _isEnabled;
	}
	
	private inline function set_isEnabled(value:Bool):Bool
	{
		return _isEnabled = value;
	}
	
	public function getScene():Scene
	{
		return this._scene;
	}
	
	public function getEmitterPosition():Vector3
	{
		return Reflect.field(this._emitter, "getAbsolutePosition") != null ? _emitter.getAbsolutePosition() : _emitter.position;
	}
	
	public function computeEffectivePosition(globalViewport:Viewport):Bool
	{
		var position:Vector3 = this.getEmitterPosition();

        position = Vector3.Project(position, new Matrix(), this._scene.getTransformMatrix(), globalViewport);

        this._positionX = position.x;
        this._positionY = position.y;

        position = Vector3.TransformCoordinates(this.getEmitterPosition(), this._scene.getViewMatrix());

        if (position.z > 0) 
		{
            if ((this._positionX > globalViewport.x) && (this._positionX < globalViewport.x + globalViewport.width))
			{
                if ((this._positionY > globalViewport.y) && (this._positionY < globalViewport.y + globalViewport.height))
                    return true;
            }
        }

        return false;
	}
	
	public function _isVisible():Bool 
	{
		if (!_isEnabled)
			return false;
			
		var emitterPosition:Vector3 = this.getEmitterPosition();
        var direction:Vector3 = emitterPosition.subtract(_scene.activeCamera.position);
        var distance:Float = direction.length();
        direction.normalize();
        
        var ray:Ray = new Ray(this._scene.activeCamera.position, direction);
        var pickInfo:PickingInfo = this._scene.pickWithRay(ray, this.meshesSelectionPredicate, true);

        return !pickInfo.hit || pickInfo.distance > distance;
	}
	
	public function render():Bool
	{
		if (!this._effect.isReady())
            return false;

        var engine:Engine = this._scene.getEngine();
        var viewport:Viewport = this._scene.activeCamera.viewport;
        var globalViewport:Viewport = viewport.toGlobal(engine);
        
        // Position
        if (!this.computeEffectivePosition(globalViewport)) 
		{
            return false;
        }
        
        // Visibility
        if (!this._isVisible())
		{
            return false;
        }

        // Intensity
        var awayX:Float = 0;
        var awayY:Float = 0;

        if (this._positionX < this.borderLimit + globalViewport.x)
		{
            awayX = this.borderLimit + globalViewport.x - this._positionX;
        } 
		else if (this._positionX > globalViewport.x + globalViewport.width - this.borderLimit) 
		{
            awayX = this._positionX - globalViewport.x - globalViewport.width + this.borderLimit;
        } 
		else
		{
            awayX = 0;
        }

        if (this._positionY < this.borderLimit + globalViewport.y)
		{
            awayY = this.borderLimit + globalViewport.y - this._positionY;
        }
		else if (this._positionY > globalViewport.y + globalViewport.height - this.borderLimit) 
		{
            awayY = this._positionY - globalViewport.y - globalViewport.height + this.borderLimit;
        } 
		else
		{
            awayY = 0;
        }

        var away:Float = (awayX > awayY) ? awayX : awayY;
        if (away > this.borderLimit) 
		{
            away = this.borderLimit;
        }

        var intensity:Float = 1.0 - (away / this.borderLimit);
        if (intensity < 0) 
		{
            return false;
        }
        
        if (intensity > 1.0)
		{
            intensity = 1.0;
        }

        // Position
        var centerX:Float = globalViewport.x + globalViewport.width / 2;
        var centerY:Float = globalViewport.y + globalViewport.height / 2;
        var distX:Float = centerX - this._positionX;
        var distY:Float = centerY - this._positionY;

        // Effects
        engine.enableEffect(this._effect);
        engine.setCullState(false);
        engine.setDepthTest(false);
        engine.setAlphaMode(Engine.ALPHA_ADD);
        
        // VBOs
        engine.bindBuffers(this._vertexBuffer, this._indexBuffer, this._vertexDeclaration, this._vertexStrideSize, this._effect);

		var tempVar:TempVars = TempVars.getTempVars();
		var viewportMatrix:Matrix = tempVar.tempMat;
		
        // Flares
        for (index in 0...this.lensFlares.length) 
		{
            var flare:LensFlare = this.lensFlares[index];

            var x:Float = centerX - (distX * flare.position);
            var y:Float = centerY - (distY * flare.position);
            
            var cw:Float = flare.size;
            var ch:Float = flare.size * engine.getAspectRatio(this._scene.activeCamera);
            var cx:Float = 2 * (x / globalViewport.width) - 1.0;
            var cy:Float = 1.0 - 2 * (y / globalViewport.height);
			
            viewportMatrix = Matrix.FromValues(
                                    cw / 2, 0, 0, 0,
                                    0, ch / 2, 0, 0,
                                    0, 0, 1, 0,
                                    cx, cy, 0, 1,viewportMatrix);

            this._effect.setMatrix("viewportMatrix", viewportMatrix);
            
            // Texture
            this._effect.setTexture("textureSampler", flare.texture);

            // Color
            this._effect.setFloat4("color", flare.color.r * intensity, flare.color.g * intensity, flare.color.b * intensity, 1.0);

            // Draw order
            engine.draw(true, 0, 6);
        }
		
		tempVar.release();
        
        engine.setDepthTest(true);
        engine.setAlphaMode(Engine.ALPHA_DISABLE);
        return true;
	}
	
	public function dispose() 
	{
		if (this._vertexBuffer != null) 
		{
            this._scene.getEngine().releaseBuffer(this._vertexBuffer);
            this._vertexBuffer = null;
        }

        if (this._indexBuffer != null) 
		{
            this._scene.getEngine().releaseBuffer(this._indexBuffer);
            this._indexBuffer = null;
        }

        while (this.lensFlares.length > 0) 
		{
            this.lensFlares[0].dispose();
        }
		this.lensFlares = [];

        // Remove from scene
		this._scene.lensFlareSystems.remove(this);
	}
	
}
