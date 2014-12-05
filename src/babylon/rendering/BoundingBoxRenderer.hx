package babylon.rendering;
import babylon.culling.BoundingBox;
import babylon.materials.ShaderMaterial;
import babylon.math.Color3;
import babylon.math.Color4;
import babylon.math.Matrix;
import babylon.mesh.BabylonGLBuffer;
import babylon.mesh.VertexBuffer;
import babylon.mesh.VertexData;
import babylon.Scene;
import babylon.tools.SmartArray;

class BoundingBoxRenderer
{
	public var frontColor:Color4;
	public var backColor:Color4;
	public var showBackLines:Bool = true;
	public var renderList:SmartArray<BoundingBox>;

	private var _scene: Scene;
	private var _colorShader: ShaderMaterial;
	private var _vb: VertexBuffer;
	private var _ib: BabylonGLBuffer;
	private var _vertexDeclaration:Array<Int>;
		
	public function new(scene:Scene) 
	{
		_scene = scene;
		
		frontColor = new Color4(1, 1, 1, 1);
		backColor = new Color4(0.1, 0.1, 0.1, 1);
		
		renderList = new SmartArray<BoundingBox>();
		
		_colorShader = new ShaderMaterial("colorShader", scene, "color",
										{
											attributes: ["position"],
											uniforms: ["worldViewProjection", "color"]
										});
				
		var engine = this._scene.getEngine();
		var boxdata = VertexData.CreateBox(1.0);
		_vb = new VertexBuffer(engine, boxdata.positions, VertexBuffer.PositionKind, false);
		_ib = engine.createIndexBuffer([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 7, 1, 6, 2, 5, 3, 4]);
		_vertexDeclaration = [3];
	}
	
	public function reset():Void
	{
		renderList.reset();
	}
	
	private var tmpMatrix:Matrix;
	private var worldMatrix:Matrix;
	public function render():Void
	{
		if (renderList.length == 0 || !_colorShader.isReady())
		{
			return;
		}
		
		if (tmpMatrix == null)
		{
			tmpMatrix = new Matrix();
			worldMatrix = new Matrix();
		}
		
		var engine = _scene.getEngine();
		
		engine.setDepthWrite(false);
		this._colorShader._preBind();
		for (i in 0...renderList.length) 
		{
			var boundingBox = this.renderList.data[i];
			var min = boundingBox.minimum;
			var max = boundingBox.maximum;
			
			//var diff = max.subtract(min);
			//var median = min.add(diff.scale(0.5));
			//var worldMatrix = Matrix.Scaling(diff.x, diff.y, diff.z)
				//.multiply(Matrix.Translation(median.x, median.y, median.z))
				//.multiply(boundingBox.getWorldMatrix());
			
			var sx:Float = max.x - min.x;
			var sy:Float = max.y - min.y;
			var sz:Float = max.z - min.z;
			
			var tx:Float = min.x + sx * 0.5;
			var ty:Float = min.y + sy * 0.5;
			var tz:Float = min.z + sz * 0.5;
			
			tmpMatrix.m[0] = sx;
			tmpMatrix.m[5] = sy;
			tmpMatrix.m[10] = sz;
			tmpMatrix.m[12] = tx;
			tmpMatrix.m[13] = ty;
			tmpMatrix.m[14] = tz;
			tmpMatrix.multiplyToRef(boundingBox.getWorldMatrix(), worldMatrix);

			// VBOs
			engine.bindBuffers(this._vb.getBuffer(), this._ib, _vertexDeclaration, 3 * 4, this._colorShader.getEffect());

			if (this.showBackLines)
			{
				// Back
				engine.setDepthFunctionToGreaterOrEqual();
				this._colorShader.setColor4("color", this.backColor);
				this._colorShader.bind(worldMatrix, null);

				// Draw order
				engine.draw(false, 0, 24);
			}

			// Front
			engine.setDepthFunctionToLess();
			this._colorShader.setColor4("color", this.frontColor);
			this._colorShader.bind(worldMatrix, null);

			// Draw order
			engine.draw(false, 0, 24);
		}
		this._colorShader.unbind();
		engine.setDepthFunctionToLessOrEqual();
		engine.setDepthWrite(true);
		
	}
	
	public function dispose():Void
	{
		_colorShader.dispose();
		_colorShader = null;
		
		_vb.dispose();
		_vb = null;
		
		_scene.getEngine().releaseBuffer(_ib);
	}
	
}