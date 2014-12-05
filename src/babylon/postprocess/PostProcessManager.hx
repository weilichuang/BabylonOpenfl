package babylon.postprocess;

import babylon.materials.Effect;
import babylon.materials.textures.BabylonGLTexture;
import babylon.mesh.BabylonGLBuffer;
import babylon.Scene;

class PostProcessManager 
{
	private var _scene:Scene;
	private var _vertexDeclaration:Array<Int>;
	private var _vertexStrideSize:Int;
	private var _vertexBuffer:BabylonGLBuffer;
	private var _indexBuffer:BabylonGLBuffer;

	public function new(scene:Scene) 
	{
		this._scene = scene;
        
        // VBO
        var vertices:Array<Float> = [1, 1, -1, 1, -1, -1, 1, -1];
        this._vertexDeclaration = [2];
        this._vertexStrideSize = 2 * 4;
        this._vertexBuffer = scene.getEngine().createVertexBuffer(vertices);

        // Indices
        var indices = [0, 1, 2, 0, 2, 3];
        this._indexBuffer = scene.getEngine().createIndexBuffer(indices);
	}
	
	public function _prepareFrame(sourceTexture:BabylonGLTexture = null):Bool
	{
        var postProcesses:Array<PostProcess> = _scene.activeCamera._postProcesses;
        var postProcessesTakenIndices:Array<Int> = _scene.activeCamera._postProcessesTakenIndices;
    
        if (postProcessesTakenIndices.length == 0 || !_scene.postProcessesEnabled)
		{
            return false;
        }

        postProcesses[_scene.activeCamera._postProcessesTakenIndices[0]].activate(_scene.activeCamera, sourceTexture);
		
		return true;
    }
	
	public function _finalizeFrame(doNotPresent:Bool = false, targetTexture:BabylonGLTexture = null):Void
	{
        var postProcesses:Array<PostProcess> = this._scene.activeCamera._postProcesses;
        var postProcessesTakenIndices:Array<Int> = this._scene.activeCamera._postProcessesTakenIndices;
        if (postProcessesTakenIndices.length == 0 || !this._scene.postProcessesEnabled) 
		{
            return;
        }

        var engine = this._scene.getEngine();
        
        for (index in 0...postProcessesTakenIndices.length)
		{            
            if (index < postProcessesTakenIndices.length - 1)
			{
                postProcesses[postProcessesTakenIndices[index + 1]].activate(_scene.activeCamera);
            } 
			else
			{
				if (targetTexture != null)
				{
					engine.bindFramebuffer(targetTexture);
				}
				else
				{
					engine.restoreDefaultFramebuffer();
				}
            }
			
			if (doNotPresent)
			{
				break;
			}

			var pp:PostProcess = postProcesses[postProcessesTakenIndices[index]];
            var effect:Effect = pp.apply();

            if (effect != null) 
			{
				if (pp.onBeforeRender != null)
				{
					pp.onBeforeRender(effect);
				}
				
                // VBOs
                engine.bindBuffers(this._vertexBuffer, this._indexBuffer, this._vertexDeclaration, this._vertexStrideSize, effect);
                
                // Draw order
                engine.draw(true, 0, 6);
            }
        }
        
        // Restore depth buffer
        engine.setDepthTest(true);
        engine.setDepthWrite(true);
    }
	
	public function dispose():Void
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
    }
	
}
