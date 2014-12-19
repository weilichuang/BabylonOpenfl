package babylon.mesh;

import babylon.Engine;
import babylon.mesh.BabylonGLBuffer;

class VertexBuffer 
{
	public static inline var PositionKind:String           = "position";
    public static inline var NormalKind:String             = "normal";
    public static inline var UVKind:String                 = "uv";
    public static inline var UV2Kind:String                = "uv2";
    public static inline var ColorKind:String              = "color";
    public static inline var MatricesIndicesKind:String    = "matricesIndices";
    public static inline var MatricesWeightsKind:String    = "matricesWeights";
	
	private var _mesh:Mesh;
	private var _engine:Engine;
	private var _buffer:BabylonGLBuffer;	
	private var _data:Array<Float>;	
	private var _updatable:Bool;
	private var _kind:String;
	private var _strideSize:Int = 0;
	
	public function new(engine:Engine, data:Array<Float>, kind:String, updatable:Bool, postponeInternalCreation:Bool = false, stride:Int = 0)
	{
        this._engine = engine;
		
        this._updatable = updatable;
		
		this._data = data;
		
		if (!postponeInternalCreation) // by default
		{ 
			this.create();
		}
  
        this._kind = kind;
		
		if (stride > 0)
		{
			this._strideSize = stride;
			return;
		}
		
		// Deduce stride from kind
        switch (kind)
		{
            case VertexBuffer.PositionKind:
                this._strideSize = 3;
            case VertexBuffer.NormalKind:
                this._strideSize = 3;
            case VertexBuffer.UVKind:
                this._strideSize = 2;
            case VertexBuffer.UV2Kind:
                this._strideSize = 2;
            case VertexBuffer.ColorKind:
                this._strideSize = 4;
            case VertexBuffer.MatricesIndicesKind:
                this._strideSize = 4;
            case VertexBuffer.MatricesWeightsKind:
                this._strideSize = 4;
        }
	}
	
	public function create(data:Array<Float> = null):Void
	{
		if (data == null && _buffer != null)
			return;
			
		if (data == null)
			data = _data;
			
		if (_buffer == null)
		{
			if (_updatable)
				_buffer = _engine.createDynamicVertexBuffer(data.length * 4);
			else
				_buffer = _engine.createVertexBuffer(data);
		}
		
		if (_updatable)
		{
			_engine.updateDynamicVertexBuffer(_buffer, data);
			_data = data;
		}
	}
	
	public function getBuffer():BabylonGLBuffer
	{
		return _buffer;
	}
	
	public function isUpdatable():Bool
	{
        return this._updatable;
    }

    public function getData():Array<Float> 
	{
        return this._data;
    }
    
    public function getStrideSize():Int 
	{
        return this._strideSize;
    }
    
    public function update(data:Array<Float>)
	{
       this.create(data);
    }
	
	public function updateDirectly(data:Array<Float>, offset:Int = 0):Void
	{
		if (this._buffer == null) 
		{
			return;
		}

		if (this._updatable) // update buffer
		{ 
			this._engine.updateDynamicVertexBuffer(this._buffer, data, offset);
			this._data = null;
		}
	}

    public function dispose() 
	{
		if (_buffer != null)
		{
			this._engine.releaseBuffer(this._buffer);
			_buffer = null;
		}
    }
}
