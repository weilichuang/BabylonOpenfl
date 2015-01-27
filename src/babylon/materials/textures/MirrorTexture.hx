package babylon.materials.textures;

import babylon.Scene;
import babylon.Engine;
import babylon.math.Matrix;
import babylon.math.Plane;

class MirrorTexture extends RenderTargetTexture
{
	private var _transformMatrix:Matrix;
	private var _savedViewMatrix:Matrix;
	private var _mirrorMatrix:Matrix;
	
	public var mirrorPlane:Plane;

	public function new(name:String, width:Int, height:Int, scene:Scene, generateMipMaps:Bool = false)
	{
		super(name, width, height, scene, generateMipMaps);
		
		this._transformMatrix = Matrix.Zero();
        this._mirrorMatrix = Matrix.Zero();	
		this.mirrorPlane = new Plane(0, 1, 0, 1);
		
		this.onBeforeRender = function():Void
		{
			Matrix.ReflectionToRef(this.mirrorPlane, this._mirrorMatrix);
			this._savedViewMatrix = scene.getViewMatrix();

			this._mirrorMatrix.multiplyToRef(this._savedViewMatrix, this._transformMatrix);

			scene.setTransformMatrix(this._transformMatrix, scene.getProjectionMatrix());

			scene.clipPlane = this.mirrorPlane;

			scene.getEngine().cullBackFaces = false;
		}
		
		this.onAfterRender = function():Void 
		{
			scene.setTransformMatrix(this._savedViewMatrix, scene.getProjectionMatrix());
			scene.getEngine().cullBackFaces = true;

			scene.clipPlane = null;
		}
	}
	
	override public function clone():BaseTexture 
	{
        var textureSize = this.getSize();
        var newTexture:MirrorTexture = new MirrorTexture(this.name, Std.int(textureSize.width),Std.int(textureSize.height), getScene(), _generateMipMaps);

        // Base texture
        newTexture.hasAlpha = this.hasAlpha;
        newTexture.level = this.level;

        // Mirror Texture
        newTexture.mirrorPlane = this.mirrorPlane.clone();
        newTexture.renderList = this.renderList.slice(0);

        return newTexture;
    }
	
}
