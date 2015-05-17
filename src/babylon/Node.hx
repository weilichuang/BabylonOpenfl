package babylon;

import babylon.animations.Animation;
import babylon.math.Matrix;
import babylon.math.Vector3;

/**
 * Node is the basic class for all scene objects (Mesh, Light Camera).
 */
class Node 
{
	public var position:Vector3;
	
	public var parent:Node = null;
	public var name:String;
	public var id:String;
	public var uniqueId:Int;
	public var state:String = "";
	
	public var animations:Array<Animation>;
	
	public var onReady:Node->Void = null;
	
	private var _childrenFlag:Int = -1;
	private var _isEnabled:Bool = true;
    private var _isReady:Bool = true;
	
	public var _currentRenderId:Int = -1;
	private var _parentRenderId:Int = -1;
	
	private var _scene:Scene;
	private var _cache:Dynamic;
	
	private var _worldMatrix:Matrix;
	
	@:dox(hide)
	public var _waitingParentId: String;
	
	/**
	 * @constructor
	 * @param {string} name - the name and id to be given to this node
	 * @param {BABYLON.Scene} the scene this node will be added to
	 */
	public function new(name:String, scene:Scene) 
	{
		this.name = name;
		this.id = name;
		
		this._scene = scene;
		
		this.animations = [];
		
		this.position = new Vector3();
		this._worldMatrix = new Matrix();
		
		this._initCache();
	}
	
	public inline function getScene(): Scene 
	{
		return _scene;
	}

	public inline function getEngine(): Engine 
	{
		return _scene.getEngine();
	}

	public function getWorldMatrix():Matrix 
	{
		return _worldMatrix;
	}
	
	/*
	  override it in derived class if you add new variables to the cache
      and call the parent class method
	 */
	private function _initCache():Void
	{
		this._cache = {};
		this._cache.parent = null;
	}
	
	public function updateCache(force:Bool = true):Void
	{
        if (!force && this.isSynchronized())
            return;

        this._cache.parent = this.parent;

        this.internalUpdateCache();
    }
	
	/*
	 * override it in derived class if you add new variables to the cache
     * and call the parent class method if !ignoreParentClass
	 */
	public function internalUpdateCache(ignoreParentClass:Bool = false):Void
	{
		
    }
	
	/*
	 * override it in derived class if you add new variables to the cache
	 */
	public function _isSynchronized():Bool
	{
        return true;
    }
	
	public function isSynchronizedWithParent():Bool 
	{
        if (this.parent == null) 
		{
			return true;
		}

		if (this._parentRenderId != this.parent._currentRenderId)
		{
			return false;
		}

		return this.parent.isSynchronized();
    }
	
	public function _markSyncedWithParent():Void
	{
		this._parentRenderId = this.parent._currentRenderId;
	}
	
	public function isSynchronized(updateCache:Bool = false):Bool
	{		
        var check:Bool = this.hasNewParent();
		
        check = check || !this.isSynchronizedWithParent();
        check = check || !this._isSynchronized();
		
        if (updateCache) 
		{
            this.updateCache(true);
		}

        return !check;
    }
	
	public function hasNewParent(update:Bool = false):Bool
	{
        if (this._cache.parent == this.parent)
            return false;

        if (update)
            this._cache.parent = this.parent;

        return true;
    }
	
	public function isReady():Bool
	{
		return this._isReady;
	}
	
	public function isEnabled():Bool
	{
		if (!this._isEnabled)
		{
			return false;
		}

        if (this.parent != null)
		{
            return this.parent.isEnabled();
        }

        return true;
	}
	
	public function setEnabled(value:Bool):Void
	{
		this._isEnabled = value;
	}
	
	/**
	 * Is this node a descendant of the given node.
	 * The function will iterate up the hierarchy until the ancestor was found or no more parents defined.
	 * @param {BABYLON.Node} ancestor - The parent node to inspect
	 * @see parent
	 */
	public function isDescendantOf(ancestor:Node):Bool 
	{
		if (this.parent != null) 
		{
            if (this.parent == ancestor)
			{
                return true;
            }

            return this.parent.isDescendantOf(ancestor);
        }
        return false;
	}
	
	public function _getDescendants(list:Array<Node>, results:Array<Node>):Void
	{
		for (index in 0...list.length)
		{
            var item:Node = list[index];
            if (item.isDescendantOf(this)) 
			{
                results.push(item);
            }
        }
	}
	
	/**
	 * Will return all nodes that have this node as parent.
	 * @return Array<Node>  all children nodes of all types.
	 */
	public function getDescendants():Array<Node> 
	{
		var results:Array<Node> = [];
        this._getDescendants(cast this._scene.meshes, results);
        this._getDescendants(cast this._scene.lights, results);
        this._getDescendants(cast this._scene.cameras, results);

        return results;
	}
	
	public function _setReady(state: Bool): Void
	{
		if (state == this._isReady)
		{
			return;
		}
		
		this._isReady = state;
		if (!this._isReady) 
		{
			return;
		}

		if (this.onReady != null) 
		{
			this.onReady(this);
		}
	}
	
}
