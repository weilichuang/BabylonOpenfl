package babylon.layer;

import babylon.materials.textures.Texture;
import babylon.materials.Effect;
import babylon.math.Color4;
import babylon.mesh.BabylonGLBuffer;
import babylon.mesh.Mesh;

class Layer
{
	public var name:String;
	public var texture:Texture;
	public var isBackground:Bool;
	public var color:Color4;
	public var _scene:Scene;
	public var vertices:Array<Float>;
	public var indicies:Array<Int>;
	public var _indexBuffer:Dynamic;
	public var _effect:Effect;
	
	private var _vertexDeclaration:Array<Int>;  
	private var _vertexStrideSize:Int;
	private var _vertexBuffer:BabylonGLBuffer;				
	
	private var onDispose:Void->Void;				

	public function new(name:String, imgUrl:String, scene:Scene, isBackground:Bool = true, color:Color4 = null)
	{
		this.name = name;
        this.texture = imgUrl != "" ? new Texture(imgUrl, scene, true) : null;
        this.isBackground = isBackground;
        this.color = color == null ? new Color4(1, 1, 1, 1) : color;

        this._scene = scene;
        this._scene.layers.push(this);
        
        // VBO
        var vertices:Array<Float> = [1., 1, -1, 1, -1, -1, 1, -1];

        this._vertexDeclaration = [2];
        this._vertexStrideSize = 2 * 4;
        this._vertexBuffer = scene.getEngine().createVertexBuffer(vertices);

        // Indices
        var indices:Array<Int> = [0, 1, 2, 0, 2, 3];
        this._indexBuffer = scene.getEngine().createIndexBuffer(indices);
        
        // Effects
        this._effect = this._scene.getEngine().createEffect("layer",
                    ["position"],
                    ["textureMatrix", "color"],
                    ["textureSampler"], "");
	}
 
	public function render():Void
	{
		// Check
        if (!this._effect.isReady() || this.texture == null || !this.texture.isReady())
            return;

        var engine = this._scene.getEngine();
       
        // Render
        engine.enableEffect(this._effect);
        engine.setCullState(false);

        // Texture
        this._effect.setTexture("textureSampler", this.texture);
        this._effect.setMatrix("textureMatrix", this.texture.getTextureMatrix());

        // Color
        this._effect.setFloat4("color", this.color.r, this.color.g, this.color.b, this.color.a);

        // VBOs
        engine.bindBuffers(_vertexBuffer, _indexBuffer, _vertexDeclaration, _vertexStrideSize, _effect);

        // Draw order
        engine.setAlphaMode(Engine.ALPHA_COMBINE);
        engine.draw(true, 0, 6);
        engine.setAlphaMode(Engine.ALPHA_DISABLE);
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

        if (this.texture != null)
		{
            this.texture.dispose();
            this.texture = null;
        }

        // Remove from scene
        _scene.layers.remove(this);
        
        // Callback
        if (this.onDispose != null)
		{
            this.onDispose();
        }
	}	
		
}
