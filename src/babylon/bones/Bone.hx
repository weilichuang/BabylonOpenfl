package babylon.bones;

import babylon.math.Matrix;
import babylon.animations.Animation;

class Bone 
{
	public var name:String;
	public var children:Array<Bone>;
	public var animations:Array<Animation>;
	
	private var _skeleton:Skeleton;
	public var _matrix:Matrix;
	private var _baseMatrix:Matrix;
	private var _worldTransform:Matrix;
	private var _absoluteTransform:Matrix;
	private var _invertedAbsoluteTransform:Matrix;
	
	private var _parent:Bone;
	
	public function new(name:String, skeleton:Skeleton, parentBone:Bone, matrix:Matrix)
	{
		this.name = name;
        this._skeleton = skeleton;
        this._matrix = matrix;
        this._baseMatrix = matrix;
		
        this._worldTransform = new Matrix();
        this._absoluteTransform = new Matrix();
        this._invertedAbsoluteTransform = new Matrix();
        this.children = [];
        this.animations = [];

        skeleton.bones.push(this);
        
        if (parentBone != null)
		{
            this._parent = parentBone;
            parentBone.children.push(this);
        } 
		else 
		{
            this._parent = null;
        }
        
        this._updateDifferenceMatrix();
	}

	public inline function getParent():Bone
	{
		return this._parent;
	}
	
	public function getLocalMatrix():Matrix 
	{
		return this._matrix;
	}
	
	public function getBaseMatrix():Matrix 
	{
		return this._baseMatrix;
	}
	
	public function getWorldMatrix():Matrix 
	{
		return this._worldTransform;
	}
	
	public function getInvertedAbsoluteTransform():Matrix 
	{
		return this._invertedAbsoluteTransform;
	}
	
	public function getAbsoluteMatrix():Matrix 
	{
		var matrix:Matrix = this._matrix.clone();
        var parent:Bone = this._parent;

        while (parent != null)
		{
            matrix = matrix.multiply(parent.getLocalMatrix());
            parent = parent.getParent();
        }

        return matrix;
	}
	
	public function _updateDifferenceMatrix():Void
	{
		if (this._parent != null)
		{
            this._matrix.multiplyToRef(this._parent._absoluteTransform, this._absoluteTransform);
        }
		else
		{
            this._absoluteTransform.copyFrom(this._matrix);
        }

        this._absoluteTransform.invertToRef(this._invertedAbsoluteTransform);

        for (index in 0...this.children.length)
		{
            this.children[index]._updateDifferenceMatrix();
        }
	}
	
	public function updateMatrix(matrix:Matrix):Void
	{
		this._matrix = matrix;
        this._skeleton._markAsDirty();

        this._updateDifferenceMatrix();
	}
	
	public function markAsDirty():Void
	{
		this._skeleton._markAsDirty();
	}
	
}
