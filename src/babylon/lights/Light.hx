package babylon.lights;

import babylon.lights.shadows.ShadowGenerator;
import babylon.materials.Effect;
import babylon.math.FastMath;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.Node;
import babylon.Scene;
import babylon.math.Color3;
import babylon.math.Matrix;
import babylon.animations.Animation;
import babylon.mesh.Mesh;

class Light extends Node
{
	public var diffuse:Color3;
	public var specular:Color3;
			
	public var intensity:Float = 1.0;
	public var range:Float;
	
	public var excludedMeshes:Array<AbstractMesh>;		
	public var includedOnlyMeshes:Array<AbstractMesh>;
	
	public var shadowGenerator:ShadowGenerator;
	
	private var _parentedWorldMatrix:Matrix;
	
	@:dox(hide)
	public var _excludedMeshesIds:Array<String>;
	
	@:dox(hide)
	public var _includedOnlyMeshesIds:Array<String>;
	
	public function new(name:String, scene:Scene)
	{
		super(name, scene);

        scene.addLight(this);
		
		this.diffuse = new Color3(1, 1, 1);
		this.specular = new Color3(1, 1, 1);
		this.range = FastMath.FLOAT_MAX;
		this._excludedMeshesIds = [];
		this._includedOnlyMeshesIds = [];
        this.excludedMeshes = [];
		this.includedOnlyMeshes = [];
	}
	
	public function getShadowGenerator():ShadowGenerator
	{
		return shadowGenerator;
	}
	
	public function getAbsolutePosition(): Vector3
	{
		return Vector3.Zero();
	}
	
	public function canAffectMesh(mesh: AbstractMesh): Bool 
	{
		if (mesh == null)
		{
			return true;
		}

		if (this.includedOnlyMeshes.length > 0 && this.includedOnlyMeshes.indexOf(mesh) == -1)
		{
			return false;
		}

		if (this.excludedMeshes.length > 0 && this.excludedMeshes.indexOf(mesh) != -1) 
		{
			return false;
		}

		return true;
	}
	
	public function transferToEffect(effect:Effect, uniformName0:String = "", uniformName1:String = ""):Void
	{
		
    }
	
	@:dox(hide)
	public function _getWorldMatrix():Matrix
	{
		return _worldMatrix;
	}
	
	override public function getWorldMatrix():Matrix
	{
		this._currentRenderId = this.getScene().getRenderId();
		
		var worldMatrix:Matrix = this._getWorldMatrix();

        if (this.parent != null)
		{
            if (this._parentedWorldMatrix == null)
			{
                this._parentedWorldMatrix = new Matrix();
            }

            worldMatrix.multiplyToRef(this.parent.getWorldMatrix(), this._parentedWorldMatrix);

            return this._parentedWorldMatrix;
        }

        return worldMatrix;
	}
	
	public function dispose():Void
	{
        if (shadowGenerator != null) 
		{
            shadowGenerator.dispose();
            shadowGenerator = null;
        }
        
        // Remove from scene
        _scene.removeLight(this);
    }
	
}
