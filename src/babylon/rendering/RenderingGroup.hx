package babylon.rendering;

import babylon.Engine;
import babylon.math.Vector3;
import babylon.mesh.AbstractMesh;
import babylon.mesh.SubMesh;
import babylon.Scene;

class RenderingGroup 
{
	public var index:Int;
	
	private var _scene:Scene;
	
	private var _opaqueSubMeshes:Array<SubMesh>;
	private var _transparentSubMeshes:Array<SubMesh>;
	private var _alphaTestSubMeshes:Array<SubMesh>;
	
	private var _activeVertices:Int;

	public function new(index:Int, scene:Scene)
	{
		this.index = index;
        this._scene = scene;
		
		this._activeVertices = 0;

        this._opaqueSubMeshes = new Array<SubMesh>();
        this._transparentSubMeshes = new Array<SubMesh>();
        this._alphaTestSubMeshes = new Array<SubMesh>();
	}
	
	public function render(customRenderFunction:Dynamic = null, 
							beforeTransparents:Dynamic = null):Bool 
	{
        if (customRenderFunction != null) 
		{
            customRenderFunction(_opaqueSubMeshes, _alphaTestSubMeshes, _transparentSubMeshes, beforeTransparents);
            return true;
        }

		var opaqueSize:Int = _opaqueSubMeshes.length;
		var alphaTestSize:Int = _alphaTestSubMeshes.length;
		var transparentSize:Int = _transparentSubMeshes.length;
        if (opaqueSize == 0 && 
			alphaTestSize == 0 && 
			transparentSize == 0)
		{
            return false;
        }
		
        var engine:Engine = _scene.getEngine();
        
        var submesh:SubMesh = null;
		
		// Opaque
        for (subIndex in 0...opaqueSize) 
		{
            submesh = _opaqueSubMeshes[subIndex];
			
            _activeVertices += submesh.verticesCount;

            submesh.render();
        }

        // Alpha test
        engine.setAlphaTesting(true);
        for (subIndex in 0...alphaTestSize)
		{
            submesh = _alphaTestSubMeshes[subIndex];
			
            _activeVertices += submesh.verticesCount;

            submesh.render();
        }
        engine.setAlphaTesting(false);

        if (beforeTransparents != null)
		{
            beforeTransparents();
        }

        // Transparent
        if (transparentSize > 0)
		{
            // Sorting			
            for (subIndex in 0...transparentSize)
			{
                submesh = _transparentSubMeshes[subIndex];
				
				var center:Vector3 = submesh.getBoundingInfo().boundingSphere.centerWorld;
				
				submesh._alphaIndex = submesh.getMesh().alphaIndex;
                submesh._distanceToCamera = center.subtract(_scene.activeCamera.position).lengthSquared();
            }

            _transparentSubMeshes.sort(function (a:SubMesh, b:SubMesh):Int 
			{
				// Alpha index first
                if (a._alphaIndex > b._alphaIndex) 
				{
					return 1;
				}
				if (a._alphaIndex < b._alphaIndex) 
				{
					return -1;
				}
				
				// Then distance to camera
				if (a._distanceToCamera < b._distanceToCamera)
				{
					return 1;
				}
				if (a._distanceToCamera > b._distanceToCamera) 
				{
					return -1;
				}
					
                return 0;
            });

            // Rendering
            engine.setAlphaMode(Engine.ALPHA_COMBINE);
            for (subIndex in 0..._transparentSubMeshes.length)
			{
                submesh = _transparentSubMeshes[subIndex];
				
                _activeVertices += submesh.verticesCount;

                submesh.render();
            }
            engine.setAlphaMode(Engine.ALPHA_DISABLE);
        }
		
        return true;
    }
	
	public function prepare():Void
	{
        _opaqueSubMeshes = [];
        _transparentSubMeshes = [];
        _alphaTestSubMeshes = [];
    }
	
	public function dispatch(subMesh:SubMesh):Void
	{
        var material = subMesh.getMaterial();
        var mesh:AbstractMesh = subMesh.getMesh();
		
        if (material.needAlphaBlending() || mesh.visibility < 1.0 || mesh.hasVertexAlpha)  // Transparent
		{
            _transparentSubMeshes.push(subMesh);
        } 
		else if (material.needAlphaTesting()) // Alpha test
		{ 
            _alphaTestSubMeshes.push(subMesh);
        } 
		else
		{
            _opaqueSubMeshes.push(subMesh); // Opaque
        }
    }
	
}
