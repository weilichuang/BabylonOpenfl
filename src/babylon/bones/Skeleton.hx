package babylon.bones;

import babylon.animations.Animation;
import babylon.animations.IAnimatable;
import babylon.Scene;
import babylon.math.Matrix;
import openfl.utils.Float32Array;

class Skeleton 
{
	public var id:String;
	public var name:String;
	public var bones:Array<Bone>;
	
	private var _scene:Scene;
	private var _isDirty:Bool;
	
	private var _transformMatrices: #if html5 Float32Array #else Array<Float> #end ;
	
	private var _animatables:Array<IAnimatable>;

	public function new(name:String, id:String, scene:Scene) 
	{
		this.id = id;
        this.name = name;
        this.bones = [];

        this._scene = scene;

        scene.skeletons.push(this);

        this._isDirty = true;
	}
	
	public function _markAsDirty():Void
	{
        this._isDirty = true;
    }

	public function getTransformMatrices(): #if html5 Float32Array #else Array<Float> #end
	{
		return this._transformMatrices;
	}
	
	public function prepare():Void 
	{		
		if (!this._isDirty) 
		{
            return;
        }

        if (this._transformMatrices == null #if html5 || this._transformMatrices.length != 16 * this.bones.length #end ) 
		{
            this._transformMatrices = #if html5 new Float32Array(16 * this.bones.length) #else [] #end ;
        }

        for (index in 0...this.bones.length) 
		{
            var bone:Bone = this.bones[index];
            var parentBone:Bone = bone.getParent();

            if (parentBone != null) 
			{
                bone.getLocalMatrix().multiplyToRef(parentBone.getWorldMatrix(), bone.getWorldMatrix());
            } 
			else 
			{
                bone.getWorldMatrix().copyFrom(bone.getLocalMatrix());
            }

            bone.getInvertedAbsoluteTransform().multiplyToArray(bone.getWorldMatrix(), this._transformMatrices, index * 16);
        }
		
        this._isDirty = false;
	}
	
	public function getAnimatables():Array<IAnimatable>
	{ 
		if (this._animatables == null || this._animatables.length != this.bones.length)
		{
            this._animatables = [];
            
            for (index in 0...this.bones.length)
			{
                this._animatables.push(this.bones[index]);
            }
        }

        return this._animatables;
	}
	
	public function clone(name:String, id:String):Skeleton
	{
		var result:Skeleton = new Skeleton(name, id, this._scene);

        for (index in 0...this.bones.length)
		{
            var source:Bone = this.bones[index];
            var parentBone:Bone = null;
            
            if (source.getParent() != null)
			{
                var parentIndex = this.bones.indexOf(source.getParent());
                parentBone = result.bones[parentIndex];
            }

            var bone = new Bone(source.name, result, parentBone, source.getBaseMatrix());
			
			var newAnimations:Array<Animation> = [];
			var sAnimations:Array<Animation> = source.animations;
			for (i in 0...sAnimations.length)
			{
				newAnimations[i] = sAnimations[i].clone();
			}
			bone.animations = newAnimations;
        }

        return result;
	}
	
}
