package babylon.particles;

import babylon.Engine;
import babylon.IDispose;
import babylon.materials.Effect;
import babylon.materials.textures.Texture;
import babylon.math.Color4;
import babylon.math.Matrix;
import babylon.math.Vector3;
import babylon.mesh.BabylonGLBuffer;
import babylon.Scene;
import babylon.tools.Tools;
import babylon.utils.MathUtils;
import openfl.utils.Float32Array;


class ParticleSystem implements IDispose
{
	// Statics
    public static inline var BLENDMODE_ONEONE:Int = 0;
    public static inline var BLENDMODE_STANDARD:Int = 1;
	
	public var name:String;
	public var id:String;
	public var renderingGroupId:Int = 0;
	public var emitter:Dynamic = null;// Vector3- TODO
    public var emitRate:Int = 10;
	public var manualEmitCount:Int = -1;
    public var updateSpeed:Float = 0.01;
    public var targetStopDuration:Float = 0;
    public var disposeOnStop:Bool = false;
	
	public var minEmitPower:Float = 1;
    public var maxEmitPower:Float = 1;

    public var minLifeTime:Float = 1;
    public var maxLifeTime:Float = 1;
	
	public var minSize:Float = 1;
    public var maxSize:Float = 1;
    public var minAngularSpeed:Float = 0;
    public var maxAngularSpeed:Float = 0;
	
	public var particleTexture:Texture;
    
    public var onDispose:Void->Void;

    public var blendMode:Int = 0;
	
	public var forceDepthWrite:Bool = false;
	
	public var gravity:Vector3;
	public var direction1:Vector3;
	public var direction2:Vector3;
	public var minEmitBox:Vector3;
	public var maxEmitBox:Vector3;
	public var color1:Color4;
	public var color2:Color4;
	public var colorDead:Color4;
	public var textureMask:Color4;
	public var startDirectionFunction:Float->Matrix->Vector3->Void;
	public var startPositionFunction:Matrix->Vector3->Void;
	
	private var particles:Array<Particle>;
	
	private var _capacity:Int;
	private var _scene:Scene;
	private var _vertexDeclaration:Array<Int>;
	private var _vertexStrideSize:Int;
	private var _stockParticles:Array<Particle>;
	private var _newPartsExcess:Float;
	
	private var _vertexBuffer:BabylonGLBuffer;
	private var _indexBuffer:BabylonGLBuffer;
	
	#if html5
	private var _vertices:Float32Array;
	#else
	private var _vertices:Array<Float>;				
	#end
	
	private var _effect:Effect;
	
	private var _customEffect: Effect;
	
	private var _cachedDefines:String;
	
	private var _scaledColorStep:Color4;
	private var _colorDiff:Color4;
	private var _scaledDirection:Vector3;
	private var _scaledGravity:Vector3;
	private var _currentRenderId:Int;
	
	private var _alive:Bool;
	private var _started:Bool;
	private var _stopped:Bool;
	private var _actualFrame:Float;
	private var _scaledUpdateSpeed:Float;

	public var emitterId(get, null):Dynamic;
	private function get_emitterId():Dynamic 
	{
		if (Reflect.getProperty(this.emitter, "id") != null) {
			return Reflect.getProperty(this.emitter, "id");
		} 
		return null;
	}


	public function new(name:String, capacity:Int, scene:Scene, customEffect:Effect = null)
	{
		this.name = name;
        this.id = name;
		
        this._capacity = capacity;

        this._scene = scene;

        scene.particleSystems.push(this);
		
		this._customEffect = customEffect;
		
		// Vectors and colors
        this.gravity = Vector3.Zero();
        this.direction1 = new Vector3(0, 1.0, 0);
        this.direction2 = new Vector3(0, 1.0, 0);
        this.minEmitBox = new Vector3(-0.5, -0.5, -0.5);
        this.maxEmitBox = new Vector3(0.5, 0.5, 0.5);
        this.color1 = new Color4(1.0, 1.0, 1.0, 1.0);
        this.color2 = new Color4(1.0, 1.0, 1.0, 1.0);
        this.colorDead = new Color4(0, 0, 0, 1.0);
        this.textureMask = new Color4(1.0, 1.0, 1.0, 1.0);

        // Particles
        this.particles = [];
        this._stockParticles = [];
        this._newPartsExcess = 0;
		
		// VBO
        this._vertexDeclaration = [3, 4, 4];
        this._vertexStrideSize = 11 * 4; // 11 floats per particle (x, y, z, r, g, b, a, angle, size, offsetX, offsetY)
        this._vertexBuffer = scene.getEngine().createDynamicVertexBuffer(capacity * this._vertexStrideSize * 4);

        var indices:Array<Int> = [];
        var index = 0;
        for (count in 0...capacity)
		{
            indices.push(index);
            indices.push(index + 1);
            indices.push(index + 2);
            indices.push(index);
            indices.push(index + 2);
            indices.push(index + 3);
            index += 4;
        }
		
        this._indexBuffer = scene.getEngine().createIndexBuffer(indices);

		#if html5
		this._vertices = new Float32Array(capacity * this._vertexStrideSize);
		#else
        this._vertices = [];
		#end
        
        // Internals
        this._scaledColorStep = new Color4(0, 0, 0, 0);
        this._colorDiff = new Color4(0, 0, 0, 0);
        this._scaledDirection = Vector3.Zero();
        this._scaledGravity = Vector3.Zero();
        this._currentRenderId = -1;
		
		this.renderingGroupId = 0;
		this.emitter = null;
		this.emitRate = 10;
		this.manualEmitCount = -1;
		this.updateSpeed = 0.01;
		this.targetStopDuration = 0;
		this.disposeOnStop = false;

		this.minEmitPower = 1;
		this.maxEmitPower = 1;

		this.minLifeTime = 1;
		this.maxLifeTime = 1;

		this.minSize = 1;
		this.maxSize = 1;
		this.minAngularSpeed = 0;
		this.maxAngularSpeed = 0;

		this.particleTexture = null;
		
		this.onDispose = null;

		this.blendMode = ParticleSystem.BLENDMODE_ONEONE;
		
		// Default behaviors
		this.startDirectionFunction = function(emitPower: Float, worldMatrix: Matrix, directionToUpdate: Vector3): Void 
		{
			var randX = MathUtils.randomNumber(this.direction1.x, this.direction2.x);
			var randY = MathUtils.randomNumber(this.direction1.y, this.direction2.y);
			var randZ = MathUtils.randomNumber(this.direction1.z, this.direction2.z);

			Vector3.TransformNormalFromFloatsToRef(randX * emitPower, randY * emitPower, randZ * emitPower, worldMatrix, directionToUpdate);
		};

		this.startPositionFunction = function(worldMatrix: Matrix, positionToUpdate: Vector3): Void
		{
			var randX = MathUtils.randomNumber(this.minEmitBox.x, this.maxEmitBox.x);
			var randY = MathUtils.randomNumber(this.minEmitBox.y, this.maxEmitBox.y);
			var randZ = MathUtils.randomNumber(this.minEmitBox.z, this.maxEmitBox.z);

			Vector3.TransformCoordinatesFromFloatsToRef(randX, randY, randZ, worldMatrix, positionToUpdate);
		};
	}
	
	public function getCapacity():Int
	{
        return this._capacity;
    }
	
	public function isAlive():Bool
	{
        return this._alive;
    }
	
	public function isStarted():Bool
	{
        return this._started;
    }
	
	public function start():Void
	{
        this._started = true;
        this._stopped = false;
        this._actualFrame = 0;
    }
	
	public function stop():Void
	{
        this._stopped = true;
    }
	
	public function _appendParticleVertex(index:Int, particle:Particle, offsetX:Float, offsetY:Float):Void
	{
        var offset = index * 11;
        this._vertices[offset]     = particle.position.x;
        this._vertices[offset + 1] = particle.position.y;
        this._vertices[offset + 2] = particle.position.z;
        this._vertices[offset + 3] = particle.color.r;
        this._vertices[offset + 4] = particle.color.g;
        this._vertices[offset + 5] = particle.color.b;
        this._vertices[offset + 6] = particle.color.a;
        this._vertices[offset + 7] = particle.angle;
        this._vertices[offset + 8] = particle.size;
        this._vertices[offset + 9] = offsetX;
        this._vertices[offset + 10] = offsetY;		
    }
	
	private function _update(newParticles:Int):Void
	{
		var particle:Particle = null;
		
        // Update current
        _alive = particles.length > 0;
		
		var index:Int = -1;
		while (++index < particles.length)
		{
			particle = particles[index];						
			particle.age += _scaledUpdateSpeed;

			if (particle.age >= particle.lifeTime) 
			{
				_stockParticles.push(particles.splice(index, 1)[0]);
				index--;
				continue;
			}
			else 
			{
				particle.colorStep.scaleToRef(this._scaledUpdateSpeed, this._scaledColorStep);
				particle.color.addInPlace(this._scaledColorStep);

				if (particle.color.a < 0)
					particle.color.a = 0;

				particle.angle += particle.angularSpeed * this._scaledUpdateSpeed;
					
				particle.direction.scaleToRef(this._scaledUpdateSpeed, this._scaledDirection);
				particle.position.addInPlace(this._scaledDirection);

				this.gravity.scaleToRef(this._scaledUpdateSpeed, this._scaledGravity);
				particle.direction.addInPlace(this._scaledGravity);
			}
		}
        
        // Add new ones
        var worldMatrix:Matrix = null;
		
		//if(Reflect.getProperty(this.emitter,"x") != null)
			//worldMatrix = Matrix.Translation(this.emitter.x, this.emitter.y, this.emitter.z);
		
		//Logger.log("this.emitter.x=" + this.emitter.x);
		//Logger.log("this.emitter.position=" + this.emitter.position);
		if(Reflect.getProperty(this.emitter,"position") != null)
		{
            worldMatrix = this.emitter.getWorldMatrix();
        } 
		
		if (worldMatrix == null)
			worldMatrix = new Matrix();

        for (index in 0...newParticles) 
		{
            if (this.particles.length == this._capacity)
			{
                break;
            }

            if (this._stockParticles.length != 0) 
			{
                particle = this._stockParticles.pop();
                particle.age = 0;
            } 
			else 
			{
                particle = new Particle();
            }
			this.particles.push(particle);

            var emitPower:Float = MathUtils.randomNumber(this.minEmitPower, this.maxEmitPower);
			
			this.startDirectionFunction(emitPower, worldMatrix, particle.direction);

            particle.lifeTime = MathUtils.randomNumber(this.minLifeTime, this.maxLifeTime);

            particle.size = MathUtils.randomNumber(this.minSize, this.maxSize);
            particle.angularSpeed = MathUtils.randomNumber(this.minAngularSpeed, this.maxAngularSpeed);

            this.startPositionFunction(worldMatrix, particle.position);
			
            var step = MathUtils.randomNumber(0, 1.0);

            Color4.LerpToRef(this.color1, this.color2, step, particle.color);

            this.colorDead.subtractToRef(particle.color, this._colorDiff);
            this._colorDiff.scaleToRef(1.0 / particle.lifeTime, particle.colorStep);
        }		
    }
	
	public function _getEffect():Effect
	{
		if (this._customEffect != null) 
		{
			return this._customEffect;
		}
			
        var defines:Array<String> = [];
        
        if (_scene.clipPlane != null) 
		{
            defines.push("#define CLIPPLANE");
        }
        
        // Effect
        var join = defines.join("\n");
        if (this._cachedDefines != join)
		{
            this._cachedDefines = join;
            this._effect = _scene.getEngine().createEffect("particles",
                ["position", "color", "options"],
                ["invView", "view", "projection", "vClipPlane", "textureMask"],
                ["diffuseSampler"], join);
        }

        return this._effect;
    }
	
	public function animate():Void
	{
        if (!this._started)
            return;

        var effect:Effect = this._getEffect();

        // Check
        if (this.emitter == null || 
			!effect.isReady() || 
			this.particleTexture == null || 
			!this.particleTexture.isReady())
            return;
        
        if (this._currentRenderId == this._scene.getRenderId())
		{
            return;
        }

        this._currentRenderId = this._scene.getRenderId();

        this._scaledUpdateSpeed = this.updateSpeed * this._scene.getAnimationRatio();

        // determine the number of particles we need to create   
        var emitCout:Int;
        if (this.manualEmitCount > -1)
		{
            emitCout = this.manualEmitCount;
            this.manualEmitCount = 0;
        } 
		else
		{
			emitCout = this.emitRate;
		}

        var newParticles:Int = Std.int(emitCout * this._scaledUpdateSpeed);
        this._newPartsExcess += emitCout * this._scaledUpdateSpeed - newParticles;

        if (this._newPartsExcess > 1.0)
		{
            newParticles += Std.int(this._newPartsExcess);
            this._newPartsExcess -= Std.int(this._newPartsExcess);
        }

        this._alive = false;

        if (!this._stopped)
		{
            this._actualFrame += this._scaledUpdateSpeed;

            if (this.targetStopDuration != 0 && this._actualFrame >= this.targetStopDuration)
                this.stop();
        } 
		else 
		{
            newParticles = 0;
        }

        this._update(newParticles);

        // Stopped?
        if (this._stopped)
		{
            if (!this._alive)
			{
                this._started = false;
                if (this.disposeOnStop) 
				{
                    _scene._toBeDisposed.push(this);
                }
            }
        }

        // Update VBO
        var offset:Int = 0;
        for (index in 0...this.particles.length)
		{
            var particle = this.particles[index];

            this._appendParticleVertex(offset++, particle, 0, 0);
            this._appendParticleVertex(offset++, particle, 1, 0);
            this._appendParticleVertex(offset++, particle, 1, 1);
            this._appendParticleVertex(offset++, particle, 0, 1);
        }
		
        _scene.getEngine().updateDynamicVertexBuffer(_vertexBuffer, _vertices, particles.length * _vertexStrideSize);
	}
	
	public function render():Int
	{
        var effect:Effect = this._getEffect();

        // Check
        if (this.emitter == null || 
			!effect.isReady() || 
			this.particleTexture == null || 
			!this.particleTexture.isReady() || 
			this.particles.length == 0)
		{
			return 0;
		}
            
		var engine:Engine = this._scene.getEngine();

        // Render
        engine.enableEffect(effect);
		engine.setCullState(false);

        var viewMatrix:Matrix = this._scene.getViewMatrix();
        effect.setTexture("diffuseSampler", this.particleTexture);
        effect.setMatrix("view", viewMatrix);
        effect.setMatrix("projection", this._scene.getProjectionMatrix());
        effect.setFloat4("textureMask", this.textureMask.r, this.textureMask.g, this.textureMask.b, this.textureMask.a);

        if (_scene.clipPlane != null) 
		{
			var normal:Vector3 = _scene.clipPlane.normal;
			
            var invView = viewMatrix.clone();
            invView.invert();
            effect.setMatrix("invView", invView);
            effect.setFloat4("vClipPlane", normal.x, normal.y, normal.z, _scene.clipPlane.d);
        }        

        // VBOs
        engine.bindBuffers(_vertexBuffer, _indexBuffer, _vertexDeclaration, _vertexStrideSize, effect);

        // Draw order
        if (this.blendMode == ParticleSystem.BLENDMODE_ONEONE)
		{
            engine.setAlphaMode(Engine.ALPHA_ADD);
        } 
		else 
		{
            engine.setAlphaMode(Engine.ALPHA_COMBINE);
        }
		
		if (forceDepthWrite)
		{
			engine.setDepthWrite(true);
		}
		
        engine.draw(true, 0, this.particles.length * 6);
        engine.setAlphaMode(Engine.ALPHA_DISABLE);

        return this.particles.length;
    }
	
	public function dispose(doNotRecurse: Bool = false):Void
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

        if (this.particleTexture != null) 
		{
            this.particleTexture.dispose();
            this.particleTexture = null;
        }

        // Remove from scene
		_scene.particleSystems.remove(this);
        
        // Callback
        if (this.onDispose != null)
		{
            this.onDispose();
        }
    }
	
	public function clone(name:String, newEmitter:Dynamic):ParticleSystem 
	{
        var result:ParticleSystem = new ParticleSystem(name, this._capacity, this._scene);

        Tools.DeepCopy(this, result, ["particles"], ["_vertexDeclaration", "_vertexStrideSize"]);

        if (newEmitter == null) 
		{
            newEmitter = this.emitter;
        }

        result.emitter = newEmitter;
        if (this.particleTexture != null)
		{
            result.particleTexture = new Texture(this.particleTexture.name, this._scene);
        }

        result.start();

        return result;
    }
	
}
