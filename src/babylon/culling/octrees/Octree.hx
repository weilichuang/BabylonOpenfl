package babylon.culling.octrees;

import babylon.math.Ray;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.math.Plane;
import babylon.math.Vector3;
import babylon.mesh.SubMesh;
import babylon.tools.SmartArray;

class Octree<T>
{
	public var blocks:Array<OctreeBlock<T>>;
	public var dynamicContent:Array<T>;
	public var maxDepth:Int;
	
	private var _maxBlockCapacity:Int;
	private var _selectionContent:SmartArray<T>;
	private var _creationFunc:T->OctreeBlock<T>->Void;

	public function new(creationFunc:T->OctreeBlock<T>->Void = null, maxBlockCapacity:Int = 64, maxDepth:Int = 2)
	{
		this.blocks = [];
		this.dynamicContent = [];
		
		this._creationFunc = creationFunc;
        this._maxBlockCapacity = maxBlockCapacity;
		this.maxDepth = maxDepth;
		
        this._selectionContent = new SmartArray<T>();
	}
	
	public function update(worldMin:Vector3, worldMax:Vector3, entries:Array<T>):Void 
	{
        _CreateBlocks(worldMin, worldMax, entries, this._maxBlockCapacity, 0, this.maxDepth, this, this._creationFunc);
    }
	
	public function addMesh(entry:T) 
	{
        for (index in 0...this.blocks.length) 
		{
            var block:OctreeBlock<T> = this.blocks[index];
            block.addEntry(entry);
        }
    }
	
	public function select(frustumPlanes:Array<Plane>, allowDuplicate:Bool = false):SmartArray<T>
	{ 
		this._selectionContent.reset();

        for (index in 0...this.blocks.length) 
		{
            var block:OctreeBlock<T> = this.blocks[index];
            block.select(frustumPlanes, this._selectionContent, allowDuplicate);
        }
		
		if (allowDuplicate)
		{
			_selectionContent.concat(this.dynamicContent);
		}
		else
		{
			_selectionContent.concatWithNoDuplicate(this.dynamicContent);
		}

        return this._selectionContent;
    }
	
	public function intersects(sphereCenter: Vector3, sphereRadius: Float, allowDuplicate: Bool = false): SmartArray<T> 
	{
		this._selectionContent.reset();

		for (i in 0...this.blocks.length)
		{
			var block:OctreeBlock<T> = this.blocks[i];
			block.intersects(sphereCenter, sphereRadius, this._selectionContent, allowDuplicate);
		}

		if (allowDuplicate) 
		{
			this._selectionContent.concat(this.dynamicContent);
		} 
		else 
		{
			this._selectionContent.concatWithNoDuplicate(this.dynamicContent);
		}

		return this._selectionContent;
	}

	public function intersectsRay(ray: Ray): SmartArray<T>
	{
		this._selectionContent.reset();

		for (i in 0...this.blocks.length)
		{
			var block:OctreeBlock<T> = this.blocks[i];
			block.intersectsRay(ray, this._selectionContent);
		}

		this._selectionContent.concatWithNoDuplicate(this.dynamicContent);

		return this._selectionContent;
	}
	
	public static function _CreateBlocks<T>(worldMin:Vector3, worldMax:Vector3,
										entries:Array<T>, maxBlockCapacity:Int, 
										currentDepth:Int, maxDepth:Int,
										target:IOctreeContainer<T>,
										creationFunc:T->OctreeBlock<T>->Void):Void
	{
        target.blocks = [];
		
        var blockSize = new Vector3((worldMax.x - worldMin.x) / 2, (worldMax.y - worldMin.y) / 2, (worldMax.z - worldMin.z) / 2);

        // Segmenting space
        for (x in 0...2) 
		{
            for (y in 0...2)
			{
                for (z in 0...2)
				{
                    var localMin:Vector3 = worldMin.add(blockSize.multiplyByFloats(x, y, z));
                    var localMax:Vector3 = worldMin.add(blockSize.multiplyByFloats(x + 1, y + 1, z + 1));

                    var block:OctreeBlock<T> = new OctreeBlock<T>(localMin, localMax, maxBlockCapacity, currentDepth + 1, maxDepth, creationFunc);
                    block.addEntries(entries);
                    target.blocks.push(block);
                }
            }
        }
    }
	
	public static function CreationFuncForMeshes(entry: AbstractMesh, block: OctreeBlock<AbstractMesh>):Void
	{
		//TODO 天空体等不应该剔除
		if (!entry.isBlocked && entry.getBoundingInfo().boundingBox.intersectsMinMax(block.minPoint, block.maxPoint))
		{
			block.entries.push(entry);
		}
	}

	public static function CreationFuncForSubMeshes(entry: SubMesh, block: OctreeBlock<SubMesh>): Void 
	{
		if (entry.getBoundingInfo().boundingBox.intersectsMinMax(block.minPoint, block.maxPoint))
		{
			block.entries.push(entry);
		}
	}
	
}
