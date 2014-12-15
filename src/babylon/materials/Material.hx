package babylon.materials;

import babylon.Engine;
import babylon.materials.textures.BaseTexture;
import babylon.materials.textures.RenderTargetTexture;
import babylon.math.Matrix;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.Scene;
import babylon.tools.SmartArray;

class Material
{
	public static inline var TriangleFillMode:Int = 0;
	public static inline var WireFrameFillMode:Int = 1;
	public static inline var PointFillMode:Int = 2;
		
	public var name:String;
	public var id:String;
	
	public var checkReadyOnEveryCall:Bool = true;
    public var checkReadyOnlyOnce:Bool = false;
	
    public var alpha:Float = 1.0;
    public var backFaceCulling:Bool = true;
	
	@:dox(hide)
    public var _effect:Effect;
	@:dox(hide)
    public var _wasPreviouslyReady:Bool;
	
	private var _scene:Scene;
	private var _fillMode:Int = TriangleFillMode;
	
	public var pointSize:Float = 1.0;

    public var onDispose:Void->Void;
	public var onCompiled:Effect->Void;
	public var onError:Effect->String->Void;

	@:dox(hide)
	public var _renderId:Int;
	
	public var wireframe(get, set):Bool;
	public var pointsCloud(get, set):Bool;
	public var fillMode(get, set):Int;

	public function new(name:String, scene:Scene, doNotAdd:Bool = false)
	{
		this.name = name;
        this.id = name;
        
        this._scene = scene;

		if (!doNotAdd)
			scene.materials.push(this);
	}
	
	private function get_wireframe():Bool
	{
		return _fillMode == WireFrameFillMode;
	}
	
	private function set_wireframe(value:Bool):Bool
	{
		_fillMode = value ? WireFrameFillMode : TriangleFillMode;
		return value;
	}
	
	private function get_pointsCloud():Bool
	{
		return _fillMode == PointFillMode;
	}
	
	private function set_pointsCloud(value:Bool):Bool
	{
		_fillMode = value ? PointFillMode : TriangleFillMode;
		return value;
	}
	
	private function get_fillMode():Int
	{
		return _fillMode;
	}
	
	private function set_fillMode(value:Int):Int
	{
		return _fillMode = value;
	}
	
	
	public function getRenderTargetTextures():Array<RenderTargetTexture>
	{
		return [];
	}
	
	public function isReady(mesh:AbstractMesh = null, useInstances:Bool = false):Bool
	{
        return true;
    }
	
	public function getEffect():Effect
	{
        return this._effect;
    }
	
	public function getScene(): Scene
	{
		return this._scene;
	}
	
	public function needAlphaBlending():Bool
	{
        return (this.alpha < 1.0);
    }
	
	public function needAlphaTesting():Bool 
	{
        return false;
    }
	
	public function getAlphaTestTexture():BaseTexture
	{
		return null;
	}
	
	public function trackCreation(onCompiled:Effect->Void, onError:Effect->String->Void):Void
	{
		
	}
	
	public function _preBind():Void
	{
        var engine:Engine = _scene.getEngine();
        
        engine.enableEffect(_effect);
        engine.setCullState(backFaceCulling);
    }
	
	public function bind(world:Matrix, mesh:Mesh):Void
	{ 		
		
    }
	
	public function bindOnlyWorldMatrix(world:Matrix):Void
	{ 		
		
    }
	
	public function unbind():Void
	{								
		
	}

	public function dispose(forceDisposeEffect:Bool = false):Void
	{
        // Remove from scene
		this._scene.materials.remove(this);
		
		// Shader are kept in cache for further use but we can get rid of this by using forceDisposeEffect
		if (forceDisposeEffect && _effect != null)
		{
			_scene.getEngine().releaseEffect(_effect);
			_effect = null;
		}

        // Callback
        if (this.onDispose != null)
		{
            this.onDispose();
        }
    }
	
}
