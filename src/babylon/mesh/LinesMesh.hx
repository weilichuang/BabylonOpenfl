package babylon.mesh;

import babylon.materials.Effect;
import babylon.materials.ShaderMaterial;
import babylon.math.Color4;
import babylon.Scene;

class LinesMesh extends Mesh
{
	public var color:Color4;

	private var _ib: BabylonGLBuffer;

	private var _indicesLength: Int;
	private var _indices:Array<Int>;
	
	private var _colorMaterial:ShaderMaterial;

	public function new(name:String, scene:Scene, updatable:Bool = false)
	{
		super(name, scene);
		
		this._colorMaterial = new ShaderMaterial("colorShader", scene, "color",
                {
                    attributes: ["position"],
                    uniforms: ["worldViewProjection", "color"],
					needAlphaBlending: true
                });
		
		this.material = this._colorMaterial;
		
					
		this.color = new Color4(1, 1, 1, 1);
		_indices = new Array<Int>();
	}
	
	override private function get_isPickable():Bool
	{
		return false;
	}
	
	override private function get_checkCollisions():Bool
	{
		return false;
	}
	
	override public function intersectsMesh(mesh: AbstractMesh, precise: Bool = false): Bool
	{
		return false;
	}
	
	override public function _bind(subMesh: SubMesh, effect: Effect, fillMode: Int = 0): Void 
	{
		var engine = this.getScene().getEngine();

		var indexToBind = _geometry.getIndexBuffer();

		// VBOs
		var buffer = _geometry.getVertexBuffer(VertexBuffer.PositionKind).getBuffer();
		engine.bindBuffers(buffer, indexToBind, [3], 3 * 4, _material.getEffect());

		// Color
		_colorMaterial.setColor4("color", this.color);
	}

	override public function _draw(subMesh: SubMesh, fillMode: Int, instancesCount: Int = 0): Void
	{
		if (_geometry == null || 
			_geometry.getVertexBuffers() == null || 
			_geometry.getIndexBuffer() == null)
		{
			return;
		}

		var engine = getScene().getEngine();

		// Draw order
		engine.draw(false, subMesh.indexStart, subMesh.indexCount, instancesCount);
	}

	override public function dispose(doNotRecurse: Bool = false): Void
	{
		this._colorMaterial.dispose();
		this._colorMaterial = null;

		super.dispose(doNotRecurse);
	}
	
}