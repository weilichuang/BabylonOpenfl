package babylon.materials;

import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.Scene;

class MultiMaterial extends Material
{
	public var subMaterials:Array<Material>;

	public function new(name:String, scene:Scene) 
	{
		super(name, scene, true);
		
        scene.multiMaterials.push(this);

        this.subMaterials = [];
	}
	
	public function getSubMaterial(index:Int):Material
	{
        if (index < 0 || index >= this.subMaterials.length)
		{
            return this.getScene().defaultMaterial;
        }

        return this.subMaterials[index];
    }
	
	override public function isReady(mesh:AbstractMesh = null, useInstances:Bool = false):Bool 
	{
        for (index in 0...this.subMaterials.length)
		{
            var subMaterial:Material = this.subMaterials[index];
            if (subMaterial != null)
			{
                if (!subMaterial.isReady(mesh)) 
				{
					return false;
				}
            }
        }

        return true;
    }
	
}
