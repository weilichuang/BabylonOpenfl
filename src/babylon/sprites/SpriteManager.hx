package babylon.sprites;

import babylon.Engine;
import babylon.materials.Effect;
import babylon.materials.textures.Texture;
import babylon.mesh.BabylonGLBuffer;
import babylon.Scene;
import babylon.tools.Tools;

class SpriteManager 
{
	public var cellSize:Int;
	public var name:String;
	public var sprites:Array<Sprite>;
	
	public var renderingGroupId:Int = 0;
	
	public var onDispose:Void->Void;
	
	public var fogEnabled:Bool = true;
	
	private var _capacity:Int;
	private var _spriteTexture:Texture;
	private var _epsilon:Float;
	
	private var _scene:Scene;
	
	private var _vertexDeclaration:Array<Int>;	
	// 15 floats per sprite (x, y, z, angle, size, offsetX, offsetY, invertU, invertV, cellIndexX, cellIndexY, color)
	private var _vertexStrideSize:Int;
	
	private var _vertexBuffer:BabylonGLBuffer;	
	private var _indexBuffer:BabylonGLBuffer;
	
	private var _vertices:Array<Float>;
	private var _effectBase:Effect;				
	private var _effectFog:Effect;
	
	public var index:Int;

	public function new(name:String, imgUrl:String, capacity:Int, cellSize:Int, scene:Scene, epsilon:Float = 0.01)
	{
		this.name = name;
        this._capacity = capacity;
        this.cellSize = cellSize;
        this._spriteTexture = new Texture(imgUrl, scene, true, true);
        this._spriteTexture.wrapU = Texture.CLAMP_ADDRESSMODE;
        this._spriteTexture.wrapV = Texture.CLAMP_ADDRESSMODE;
        this._epsilon = epsilon;

        this._scene = scene;
        this._scene.spriteManagers.push(this);
        
        // VBO
        this._vertexDeclaration = [3, 4, 4, 4];
        this._vertexStrideSize = 15 * 4; // 15 floats per sprite (x, y, z, angle, size, offsetX, offsetY, invertU, invertV, cellIndexX, cellIndexY, color)
        this._vertexBuffer = scene.getEngine().createDynamicVertexBuffer(capacity * this._vertexStrideSize * 4);

        var indices:Array<Int> = [];
        var index:Int = 0;
        for (count in 0...capacity)
		{
            indices.push(index);
            indices.push(index + 1);
            indices.push(index + 2);
            indices.push(index);
            indices.push(index + 2);
            indices.push(index + 3);
            index += 4;
        }

        this._indexBuffer = scene.getEngine().createIndexBuffer(indices);
        this._vertices = [];
        
        // Sprites
        this.sprites = [];
        
        // Effects
        this._effectBase = this._scene.getEngine().createEffect("sprites",
                    ["position", "options", "cellInfo", "color"],
                    ["view", "projection", "textureInfos", "alphaTest"],
                    ["diffuseSampler"], "");
        
        this._effectFog = this._scene.getEngine().createEffect("sprites",
                    ["position", "options", "cellInfo", "color"],
                    ["view", "projection", "textureInfos", "alphaTest", "vFogInfos", "vFogColor"],
                    ["diffuseSampler"], "#define FOG");
	}

	public function render():Void 
	{
		// Check
        if (!this._effectBase.isReady() || 
			!this._effectFog.isReady() || 
			this._spriteTexture == null || 
			!this._spriteTexture.isReady())
		{
			return ;
		}
            

        var engine:Engine = this._scene.getEngine();
        var baseSize = this._spriteTexture.getBaseSize();

        // Sprites
        var deltaTime = Tools.deltaTime;
        var max = Std.int(Math.min(this._capacity, this.sprites.length));
        var rowSize = baseSize.width / this.cellSize;

        var offset = 0;
        for (index in 0...max) 
		{
            var sprite:Sprite = this.sprites[index];
            if (sprite == null)
			{
                 continue;
            }
            
            sprite.animate(deltaTime);

            this._appendSpriteVertex(offset++, sprite, 0, 0, rowSize);
            this._appendSpriteVertex(offset++, sprite, 1, 0, rowSize);
            this._appendSpriteVertex(offset++, sprite, 1, 1, rowSize);
            this._appendSpriteVertex(offset++, sprite, 0, 1, rowSize);
        }
        engine.updateDynamicVertexBuffer(this._vertexBuffer, this._vertices, max * this._vertexStrideSize);
       
        // Render
        var effect = this._effectBase;

        if (this._scene.fogInfo.fogMode != FogInfo.FOGMODE_NONE && fogEnabled) 
		{
            effect = this._effectFog;
        }
        
        engine.enableEffect(effect);

        var viewMatrix = this._scene.getViewMatrix();
        effect.setTexture("diffuseSampler", this._spriteTexture);
        effect.setMatrix("view", viewMatrix);
        effect.setMatrix("projection", this._scene.getProjectionMatrix());

        effect.setFloat2("textureInfos", this.cellSize / baseSize.width, this.cellSize / baseSize.height);
        
        // Fog
		var fogInfo = this._scene.fogInfo;
        if (fogInfo.fogMode != FogInfo.FOGMODE_NONE && fogEnabled)
		{
            effect.setFloat4("vFogInfos", fogInfo.fogMode, fogInfo.fogStart, fogInfo.fogEnd, fogInfo.fogDensity);
            effect.setColor3("vFogColor", fogInfo.fogColor);
        }

        // VBOs
        engine.bindBuffers(this._vertexBuffer, this._indexBuffer, this._vertexDeclaration, this._vertexStrideSize, effect);

        // Draw order
        effect.setBool("alphaTest", true);
        engine.setColorWrite(false);
        engine.draw(true, 0, max * 6);
		
        engine.setColorWrite(true);
        effect.setBool("alphaTest", false);
        engine.setAlphaMode(Engine.ALPHA_COMBINE);
        engine.draw(true, 0, max * 6);
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

        if (this._spriteTexture != null)
		{
            this._spriteTexture.dispose();
            this._spriteTexture = null;
        }

        // Remove from scene
		this._scene.spriteManagers.remove(this);
        
        // Callback
        if (this.onDispose != null)
		{
            this.onDispose();
        }
	}
	
	private function _appendSpriteVertex(index:Int, sprite:Sprite, offsetX:Float, offsetY:Float, rowSize:Float) :Void
	{
		var arrayOffset = index * 15;

        if (offsetX == 0)
            offsetX = this._epsilon;
        else if (offsetX == 1)
            offsetX = 1 - this._epsilon;

        if (offsetY == 0)
            offsetY = this._epsilon;
        else if (offsetY == 1)
            offsetY = 1 - this._epsilon;

        this._vertices[arrayOffset] = sprite.position.x;
        this._vertices[arrayOffset + 1] = sprite.position.y;
        this._vertices[arrayOffset + 2] = sprite.position.z;
        this._vertices[arrayOffset + 3] = sprite.angle;
        this._vertices[arrayOffset + 4] = sprite.size;
        this._vertices[arrayOffset + 5] = offsetX;
        this._vertices[arrayOffset + 6] = offsetY;
        this._vertices[arrayOffset + 7] = sprite.invertU ? 1 : 0;
        this._vertices[arrayOffset + 8] = sprite.invertV ? 1 : 0;
        var offset = Std.int(sprite.cellIndex / rowSize);
        this._vertices[arrayOffset + 9] = sprite.cellIndex - offset * rowSize;
        this._vertices[arrayOffset + 10] = offset;
        // Color
        this._vertices[arrayOffset + 11] = sprite.color.r;
        this._vertices[arrayOffset + 12] = sprite.color.g;
        this._vertices[arrayOffset + 13] = sprite.color.b;
        this._vertices[arrayOffset + 14] = sprite.color.a;
	}
	
}