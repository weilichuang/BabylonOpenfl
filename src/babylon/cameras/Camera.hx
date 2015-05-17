package babylon.cameras;

import babylon.Engine;
import babylon.mesh.AbstractMesh;
import babylon.Node;
import babylon.Scene;
import babylon.math.Vector3;
import babylon.math.Matrix;
import babylon.animations.Animation;
import babylon.postprocess.PostProcess;
import babylon.math.Viewport;
import babylon.tools.SmartArray;
import babylon.utils.Logger;
import openfl.display.DisplayObject;
import openfl.display.Sprite;

class Camera extends Node
{
	public static inline var PERSPECTIVE_CAMERA:Int = 0;
	public static inline var ORTHOGRAPHIC_CAMERA:Int = 1;

	public var upVector:Vector3;
	
	public var orthoLeft:Null<Float> = null;
	public var orthoRight:Null<Float> = null;
	public var orthoBottom:Null<Float> = null;
	public var orthoTop:Null<Float> = null;
	
	public var fov:Float = 0.8;
	public var minZ:Float = 1.0;
	public var maxZ:Float = 10000.0;
	public var inertia:Float = 0.9;
	
	public var mode:Int;
	
	public var isIntermediate:Bool = false;
	
	public var viewport:Viewport;
	
	public var subCameras:Array<Camera>;
	
	public var layerMask: UInt = 0xFFFFFFFF;
		
	public var _postProcesses:Array<PostProcess>;	
	public var _postProcessesTakenIndices:Array<Int>;
	
	private var _computedViewMatrix:Matrix;
	private var _projectionMatrix:Matrix;
	
	public var _activeMeshes:SmartArray<AbstractMesh>;

	public function new(name:String, position:Vector3, scene:Scene)
	{
		super(name, scene);

        this.position = position;
        
        scene.addCamera(this);
        if (scene.activeCamera == null)
		{
            scene.activeCamera = this;
        }
		
		this._activeMeshes = new SmartArray<AbstractMesh>();
		
		this.upVector = Vector3.Up();
        
		this.subCameras = [];
				
		this.mode = Camera.PERSPECTIVE_CAMERA;

        this._computedViewMatrix = new Matrix();
		this._projectionMatrix = new Matrix();

        // _postProcesses
        this._postProcesses = [];
		this._postProcessesTakenIndices = [];
        
        // Viewport
        this.viewport = new Viewport(0, 0, 1, 1);	
	}
	
	override private function _initCache():Void
	{
		super._initCache();
		
		this._cache.parent = null;
		this._cache.position = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		this._cache.upVector = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

		this._cache.mode = null;
		this._cache.minZ = null;
		this._cache.maxZ = null;

		this._cache.fov = null;
		this._cache.aspectRatio = null;

		this._cache.orthoLeft = null;
		this._cache.orthoRight = null;
		this._cache.orthoBottom = null;
		this._cache.orthoTop = null;
		this._cache.renderWidth = null;
		this._cache.renderHeight = null;
    }
	
	override public function internalUpdateCache(ignoreParentClass:Bool = true) 
	{
        if (!ignoreParentClass)
		{
			super.internalUpdateCache(ignoreParentClass);
        }

        var engine:Engine = this.getEngine();

        this._cache.position.copyFrom(this.position);
        this._cache.upVector.copyFrom(this.upVector);

        this._cache.mode = this.mode;
        this._cache.minZ = this.minZ;
        this._cache.maxZ = this.maxZ;

        this._cache.fov = this.fov;
        this._cache.aspectRatio = engine.getAspectRatio(this);

        this._cache.orthoLeft = this.orthoLeft;
        this._cache.orthoRight = this.orthoRight;
        this._cache.orthoBottom = this.orthoBottom;
        this._cache.orthoTop = this.orthoTop;
        this._cache.renderWidth = engine.getRenderWidth();
        this._cache.renderHeight = engine.getRenderHeight();
    }
	
	public function _updateFromScene():Void
	{
        this.updateCache();
        this._update();
    }
	
	override public function _isSynchronized():Bool
	{
        return this._isSynchronizedViewMatrix() && this._isSynchronizedProjectionMatrix();
    }
	
	public function _isSynchronizedViewMatrix():Bool
	{
        if (!super._isSynchronized())
            return false;			
		
        return this._cache.position.equals(this.position)
            && this._cache.upVector.equals(this.upVector)
            && this.isSynchronizedWithParent();
    }
	
	public function _isSynchronizedProjectionMatrix():Bool
	{
        var check = _cache.mode == mode
             && _cache.minZ == minZ
             && _cache.maxZ == maxZ;

        if (!check) 
		{
            return false;
        }

        var engine = getEngine();

        if (mode == Camera.PERSPECTIVE_CAMERA) 
		{
            check = _cache.fov == fov
                 && _cache.aspectRatio == engine.getAspectRatio(this);
        }
        else 
		{
            check = _cache.orthoLeft == orthoLeft
                 && _cache.orthoRight == orthoRight
                 && _cache.orthoBottom == orthoBottom
                 && _cache.orthoTop == orthoTop
                 && _cache.renderWidth == engine.getRenderWidth()
                 && _cache.renderHeight == engine.getRenderHeight();
        }

        return check;
    }

	public function attachControl(canvas:Sprite, noPreventDefault:Bool = false)
	{
		
	}

	public function detachControl()
	{
		
	}

	public function _update():Void
	{
		
	}
	
	public function attachPostProcess(postProcess:PostProcess, insertAt:Int = -1):Int
	{
        if (!postProcess.isReusable() && _postProcesses.indexOf(postProcess) > -1) 
		{
			Logger.log("You're trying to reuse a post process not defined as reusable.");
            return -1;
        }

        if (insertAt < 0) 
		{
            _postProcesses.push(postProcess);
            _postProcessesTakenIndices.push(_postProcesses.length - 1);

            return _postProcesses.length - 1;
        }

        var add:Int = 0;
        if (_postProcesses[insertAt] != null)
		{
            var i = _postProcesses.length - 1;
			while (i >= insertAt + 1) 
			{
				_postProcesses[i + 1] = _postProcesses[i];
				--i;
			}
            add = 1;
        }

        for (i in 0..._postProcessesTakenIndices.length)
		{
            if (_postProcessesTakenIndices[i] < insertAt)
			{
                continue;
            }

            var j = _postProcessesTakenIndices.length - 1;
			while (j >= i)
			{
				_postProcessesTakenIndices[j + 1] = _postProcessesTakenIndices[j] + add;
				--j;
			}
            _postProcessesTakenIndices[i] = insertAt;
            break;
        }

        if (add == 0 && _postProcessesTakenIndices.indexOf(insertAt) == -1)
		{
            _postProcessesTakenIndices.push(insertAt);
        }

        var result = insertAt + add;

        _postProcesses[result] = postProcess;

        return result;
    }
	
	public function detachPostProcess(postProcess:PostProcess, atIndices:Dynamic = null):Array<Int>
	{
        var result:Array<Int> = [];

        if (atIndices == null) 
		{
            var length:Int = _postProcesses.length;

            for (i in 0...length)
			{
                if (_postProcesses[i] != postProcess)
				{
                    continue;
                }

                _postProcesses[i] = null;  // TODO: remove it from array ??

                var index:Int = _postProcessesTakenIndices.indexOf(i);
                _postProcessesTakenIndices.splice(index, 1);
            }
        }
        else 
		{
            var _atIndices:Array<PostProcess> = Std.is(atIndices, Array) ? atIndices : [atIndices];
            for (i in 0..._atIndices.length)
			{
                var foundPostProcess = _postProcesses[atIndices[i]];

                if (foundPostProcess != postProcess)
				{
                    result.push(i);
                    continue;
                }

                _postProcesses[atIndices[i]] = null;		// TODO: remove it from array ??

                var index = _postProcessesTakenIndices.indexOf(atIndices[i]);
                _postProcessesTakenIndices.splice(index, 1);
            }
        }
        return result;
    }
	
	override public function getWorldMatrix():Matrix 
	{
		var viewMatrix = getViewMatrix();
        viewMatrix.invertToRef(_worldMatrix);

        return _worldMatrix;
	}
	
	private function _getViewMatrix():Matrix 
	{
		return new Matrix();
	}

	public function getViewMatrix():Matrix 
	{
		_computedViewMatrix = _computeViewMatrix();

        if (parent == null || isSynchronized())
		{
			return _computedViewMatrix;
		}
            
		_computedViewMatrix.invertToRef(_worldMatrix);
		_worldMatrix.multiplyToRef(parent.getWorldMatrix(), _computedViewMatrix);
		_computedViewMatrix.invert();	
   
		_currentRenderId = getScene().getRenderId();
		
        return _computedViewMatrix;
	}
	
	public function _computeViewMatrix(force:Bool = false):Matrix 
	{
		if (!force && _isSynchronizedViewMatrix()) 
		{
			return _computedViewMatrix;
		}

		_computedViewMatrix = _getViewMatrix();
		if (parent == null) 
		{
			_currentRenderId = getScene().getRenderId();
		}
		return _computedViewMatrix;
    }

	public function getProjectionMatrix(force:Bool = false): Matrix 
	{
		if (!force && _isSynchronizedProjectionMatrix())
		{
			return _projectionMatrix;
		}
			
		var engine = getEngine();
		if (mode == Camera.PERSPECTIVE_CAMERA)
		{
			if (minZ <= 1)
			{
				minZ = 1;
			}

			Matrix.PerspectiveFovLHToRef(fov, engine.getAspectRatio(this), minZ, maxZ, _projectionMatrix);
		}
		else
		{
			var halfWidth:Float = engine.getRenderWidth() * 0.5;
			var halfHeight:Float = engine.getRenderHeight() * 0.5;
			Matrix.OrthoOffCenterLHToRef(orthoLeft != null ? orthoLeft : -halfWidth, 
										orthoRight != null ? orthoRight : halfWidth, 
										orthoBottom != null ? orthoBottom : -halfHeight, 
										orthoTop != null ? orthoTop : halfHeight, 
										minZ, maxZ, _projectionMatrix);
		}
							
		return _projectionMatrix;
	}
	
	public function dispose():Void
	{
		// Remove from scene
        _scene.removeCamera(this);
        
        // _postProcesses
        for (i in 0..._postProcessesTakenIndices.length)
		{
            _postProcesses[_postProcessesTakenIndices[i]].dispose(this);
        }
	}
	
}
