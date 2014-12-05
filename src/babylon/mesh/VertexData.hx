package babylon.mesh;
import babylon.math.Matrix;
import babylon.math.Vector2;
import babylon.math.Vector3;
import babylon.utils.TempVars;
import openfl.display.BitmapData;

class VertexData
{
	public var positions: Array<Float>;
	public var normals: Array<Float>;
	public var uvs: Array<Float>;
	public var uv2s: Array<Float>;
	public var colors: Array<Float>;
	public var matricesIndices: Array<Float>;
	public var matricesWeights: Array<Float>;
	public var indices: Array<Int>;

	public function new() 
	{
		
	}
	
	public function set(data:Array<Float>, kind:String):Void
	{
		switch(kind)
		{
			case VertexBuffer.PositionKind:
				this.positions = data;
			case VertexBuffer.NormalKind:
				this.normals = data;
			case VertexBuffer.UVKind:
				this.uvs = data;
			case VertexBuffer.UV2Kind:
				this.uv2s = data;
			case VertexBuffer.ColorKind:
				this.colors = data;
			case VertexBuffer.MatricesIndicesKind:
				this.matricesIndices = data;
			case VertexBuffer.MatricesWeightsKind:
				this.matricesWeights = data;
		}
	}
	
	public function applyToMesh(mesh:Mesh, updatable:Bool = false):Void
	{
		_applyTo(mesh, updatable);
	}
	
	public function applyToGeometry(geometry: Geometry, updatable:Bool = false): Void 
	{
		this._applyTo(geometry, updatable);
	}
	
	private function _applyTo(meshOrGeometry: IGetSetVerticesData, updatable:Bool = false):Void
	{
		if (this.positions != null)
		{
			meshOrGeometry.setVerticesData(VertexBuffer.PositionKind, this.positions, updatable);
		}

		if (this.normals != null)
		{
			meshOrGeometry.setVerticesData(VertexBuffer.NormalKind, this.normals, updatable);
		}

		if (this.uvs != null) 
		{
			meshOrGeometry.setVerticesData(VertexBuffer.UVKind, this.uvs, updatable);
		}

		if (this.uv2s != null)
		{
			meshOrGeometry.setVerticesData(VertexBuffer.UV2Kind, this.uv2s, updatable);
		}

		if (this.colors != null) 
		{
			meshOrGeometry.setVerticesData(VertexBuffer.ColorKind, this.colors, updatable);
		}

		if (this.matricesIndices != null) 
		{
			meshOrGeometry.setVerticesData(VertexBuffer.MatricesIndicesKind, this.matricesIndices, updatable);
		}

		if (this.matricesWeights != null)
		{
			meshOrGeometry.setVerticesData(VertexBuffer.MatricesWeightsKind, this.matricesWeights, updatable);
		}

		if (this.indices != null) 
		{
			meshOrGeometry.setIndices(this.indices);
		}
	}
	
	public function updateMesh(mesh:Mesh, updateExtends:Bool = true, makeItUnique:Bool = true):Void
	{
		this._update(mesh);
	}
	
	public function updateGeometry(geometry:Geometry, updateExtends:Bool = true, makeItUnique:Bool = true):Void
	{
		this._update(geometry);
	}
	
	
	private function _update(meshOrGeometry: IGetSetVerticesData, updateExtends:Bool = true, makeItUnique:Bool = true):Void
	{
		if (this.positions != null)
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.PositionKind, this.positions, updateExtends, makeItUnique);
		}

		if (this.normals != null)
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.NormalKind, this.normals, updateExtends, makeItUnique);
		}

		if (this.uvs != null) 
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.UVKind, this.uvs, updateExtends, makeItUnique);
		}

		if (this.uv2s != null) 
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.UV2Kind, this.uv2s, updateExtends, makeItUnique);
		}

		if (this.colors != null) 
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.ColorKind, this.colors, updateExtends, makeItUnique);
		}

		if (this.matricesIndices != null)
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.MatricesIndicesKind, this.matricesIndices, updateExtends, makeItUnique);
		}

		if (this.matricesWeights != null)
		{
			meshOrGeometry.updateVerticesData(VertexBuffer.MatricesWeightsKind, this.matricesWeights, updateExtends, makeItUnique);
		}

		if (this.indices != null) 
		{
			meshOrGeometry.setIndices(this.indices);
		}
	}
	
	public function transform(matrix: Matrix): Void 
	{
		var transformed = Vector3.Zero();

		if (this.positions != null)
		{
			var position = Vector3.Zero();

			var index:Int = 0;
			while(index < this.positions.length)
			{
				Vector3.FromArrayToRef(this.positions, index, position);

				Vector3.TransformCoordinatesToRef(position, matrix, transformed);
				this.positions[index] = transformed.x;
				this.positions[index + 1] = transformed.y;
				this.positions[index + 2] = transformed.z;
				
				index += 3;
			}
		}

		if (this.normals != null) 
		{
			var normal = Vector3.Zero();

			var index:Int = 0;
			while(index < this.normals.length)
			{
				Vector3.FromArrayToRef(this.normals, index, normal);

				Vector3.TransformNormalToRef(normal, matrix, transformed);
				this.normals[index] = transformed.x;
				this.normals[index + 1] = transformed.y;
				this.normals[index + 2] = transformed.z;
				
				index += 3;
			}
		}
	}

	public function merge(other: VertexData): Void 
	{
		if (other.indices != null) 
		{
			if (this.indices == null)
			{
				this.indices = [];
			}

			var offset:Int = this.positions != null ? Std.int(this.positions.length / 3) : 0;
			for (index in 0...other.indices.length)
			{
				this.indices.push(other.indices[index] + offset);
			}
		}

		if (other.positions != null) 
		{
			if (this.positions == null) 
			{
				this.positions = [];
			}

			for (index in 0...other.positions.length)
			{
				this.positions.push(other.positions[index]);
			}
		}

		if (other.normals != null)
		{
			if (this.normals == null)
			{
				this.normals = [];
			}
			
			for (index in 0...other.normals.length) 
			{
				this.normals.push(other.normals[index]);
			}
		}

		if (other.uvs != null) 
		{
			if (this.uvs == null)
			{
				this.uvs = [];
			}
			
			for (index in 0...other.uvs.length) 
			{
				this.uvs.push(other.uvs[index]);
			}
		}

		if (other.uv2s != null)
		{
			if (this.uv2s == null)
			{
				this.uv2s = [];
			}
			
			for (index in 0...other.uv2s.length)
			{
				this.uv2s.push(other.uv2s[index]);
			}
		}

		if (other.matricesIndices != null) 
		{
			if (this.matricesIndices == null)
			{
				this.matricesIndices = [];
			}
			
			for (index in 0...other.matricesIndices.length)
			{
				this.matricesIndices.push(other.matricesIndices[index]);
			}
		}

		if (other.matricesWeights != null) 
		{
			if (this.matricesWeights == null)
			{
				this.matricesWeights = [];
			}
			
			for (index in 0...other.matricesWeights.length) 
			{
				this.matricesWeights.push(other.matricesWeights[index]);
			}
		}

		if (other.colors != null)
		{
			if (this.colors == null) 
			{
				this.colors = [];
			}
			
			for (index in 0...other.colors.length) 
			{
				this.colors.push(other.colors[index]);
			}
		}
	}
	
	public static function ExtractFromMesh(mesh: Mesh): VertexData 
	{
		return _ExtractFrom(mesh);
	}

	public static function ExtractFromGeometry(geometry: Geometry): VertexData 
	{
		return _ExtractFrom(geometry);
	}

	private static function _ExtractFrom(meshOrGeometry: IGetSetVerticesData): VertexData 
	{
		var result:VertexData = new VertexData();

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.PositionKind))
		{
			result.positions = meshOrGeometry.getVerticesData(VertexBuffer.PositionKind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.NormalKind))
		{
			result.normals = meshOrGeometry.getVerticesData(VertexBuffer.NormalKind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.UVKind))
		{
			result.uvs = meshOrGeometry.getVerticesData(VertexBuffer.UVKind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.UV2Kind)) 
		{
			result.uv2s = meshOrGeometry.getVerticesData(VertexBuffer.UV2Kind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.ColorKind)) 
		{
			result.colors = meshOrGeometry.getVerticesData(VertexBuffer.ColorKind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind))
		{
			result.matricesIndices = meshOrGeometry.getVerticesData(VertexBuffer.MatricesIndicesKind);
		}

		if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind))
		{
			result.matricesWeights = meshOrGeometry.getVerticesData(VertexBuffer.MatricesWeightsKind);
		}

		result.indices = meshOrGeometry.getIndices();

		return result;
	}
	
	// Statics
	public static function CreateBox(size:Float = 1):VertexData 
	{
        var normalsSource:Array<Vector3> = [
            new Vector3(0, 0, 1),
            new Vector3(0, 0, -1),
            new Vector3(1, 0, 0),
            new Vector3(-1, 0, 0),
            new Vector3(0, 1, 0),
            new Vector3(0, -1, 0)
        ];

        var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // Create each face in turn.
		var side1:Vector3 = new Vector3();
		var side2:Vector3 = new Vector3();
        for (index in 0...normalsSource.length)
		{
            var normal:Vector3 = normalsSource[index];

            // Get two vectors perpendicular to the face normal and to each other.
			side1.setTo(normal.y, normal.z, normal.x);
			side2 = Vector3.CrossToRef(normal, side1, side2);

            // Six indices (two triangles) per face.
            var verticesLength:Int = Std.int(positions.length / 3);
            indices.push(verticesLength);
            indices.push(verticesLength + 1);
            indices.push(verticesLength + 2);

            indices.push(verticesLength);
            indices.push(verticesLength + 2);
            indices.push(verticesLength + 3);

            // Four vertices per face.
			var halfSize:Float = size * 0.5;
			var vx:Float = (normal.x - side1.x - side2.x ) * halfSize;
			var vy:Float = (normal.y - side1.y - side2.y ) * halfSize;
			var vz:Float = (normal.z - side1.z - side2.z ) * halfSize;
            //var vertex:Vector3 = normal.subtract(side1).subtract(side2).scale(size / 2);
			
            positions.push(vx);
			positions.push(vy);
			positions.push(vz);
            normals.push(normal.x);
			normals.push(normal.y);
			normals.push(normal.z);
            uvs.push(1.0);
			uvs.push(1.0);

			vx = (normal.x - side1.x + side2.x ) * halfSize;
			vy = (normal.y - side1.y + side2.y ) * halfSize;
			vz = (normal.z - side1.z + side2.z ) * halfSize;
            //vertex = normal.subtract(side1).add(side2).scale(size / 2);
            positions.push(vx);
			positions.push(vy);
			positions.push(vz);
            normals.push(normal.x);
			normals.push(normal.y);
			normals.push(normal.z);
            uvs.push(0.0);
			uvs.push(1.0);

			vx = (normal.x + side1.x + side2.x ) * halfSize;
			vy = (normal.y + side1.y + side2.y ) * halfSize;
			vz = (normal.z + side1.z + side2.z ) * halfSize;
            //vertex = normal.add(side1).add(side2).scale(size / 2);
            positions.push(vx);
			positions.push(vy);
			positions.push(vz);
            normals.push(normal.x);
			normals.push(normal.y);
			normals.push(normal.z);
            uvs.push(0.0);
			uvs.push(0.0);

			vx = (normal.x + side1.x - side2.x ) * halfSize;
			vy = (normal.y + side1.y - side2.y ) * halfSize;
			vz = (normal.z + side1.z - side2.z ) * halfSize;
            //vertex = normal.add(side1).subtract(side2).scale(size / 2);
            positions.push(vx);
			positions.push(vy);
			positions.push(vz);
            normals.push(normal.x);
			normals.push(normal.y);
			normals.push(normal.z);
            uvs.push(1.0);
			uvs.push(0.0);
        }
		
		// Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;
		
		return vertexData;
	}
	
	public static function CreateCylinder(height:Float = 1, diameterTop:Float = 0.5, 
										diameterBottom:Float = 1, tessellation:Int = 16,
										subdivisions:Int = 1):VertexData
	{
		var radiusTop:Float = diameterTop / 2;
        var radiusBottom:Float = diameterBottom / 2;
        
		var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
		
        function getCircleVector(i:Int):Vector3
		{
            var angle = (i * 2 * Math.PI / tessellation);
            var dx = Math.cos(angle);
            var dz = Math.sin(angle);

            return new Vector3(dx, 0, dz);
        }

        function createCylinderCap(isTop:Bool):Void
		{
            var radius:Float = isTop ? radiusTop : radiusBottom;
            
            if (radius == 0)
			{
                return;
            }

			var vbase:Int = Std.int(positions.length / 3);

			var offset = new Vector3(0, height / 2, 0);
			var textureScale = new Vector2(0.5, 0.5);

			if (!isTop)
			{
				offset.scaleInPlace(-1);
				textureScale.x = -textureScale.x;
			}

			// Positions, normals & uvs
			for (i in 0...tessellation) 
			{
				var circleVector = getCircleVector(i);
				var position = circleVector.scale(radius).add(offset);
				var textureCoordinate = new Vector2(
					circleVector.x * textureScale.x + 0.5,
					circleVector.z * textureScale.y + 0.5
				);

				positions.push(position.x);
				positions.push(position.y);
				positions.push(position.z);
				uvs.push(textureCoordinate.x);
				uvs.push(textureCoordinate.y);
			}

			// Indices
			for (i in 0...tessellation - 2) 
			{
				if (!isTop) 
				{
					indices.push(vbase);
					indices.push(vbase + (i + 2) % tessellation);
					indices.push(vbase + (i + 1) % tessellation);
				} else
				{
					indices.push(vbase);
					indices.push(vbase + (i + 1) % tessellation);
					indices.push(vbase + (i + 2) % tessellation);
				}
			}
		};

		var base:Vector3    = new Vector3(0, -1, 0).scale(height / 2);
		var offset:Vector3  = new Vector3(0, 1, 0).scale(height / subdivisions);
		var stride:Int  = tessellation + 1;

		// Positions, normals & uvs
		for (i in 0...tessellation+1) 
		{
			var circleVector = getCircleVector(i);
			var textureCoordinate = new Vector2(i / tessellation, 0);
			var position:Vector3; 
			var radius:Float = radiusBottom;

			for (s in 0...subdivisions + 1)
			{
				// Update variables
				position = circleVector.scale(radius);
				position.addInPlace(base.add(offset.scale(s)));
				textureCoordinate.y += 1 / subdivisions;
				radius += (radiusTop - radiusBottom)/subdivisions;

				// Push in arrays
				positions.push(position.x);
				positions.push(position.y);
				positions.push(position.z);
				uvs.push(textureCoordinate.x);
				uvs.push(textureCoordinate.y);
			}
		}

		subdivisions += 1;
		// Indices
		for (s in 0...subdivisions - 1) 
		{
			for (i in 0...tessellation + 1)
			{
				indices.push( i * subdivisions + s);
				indices.push((i * subdivisions + (s + subdivisions)) % (stride * subdivisions));
				indices.push( i * subdivisions + (s + 1));

				indices.push( i * subdivisions + (s + 1));
				indices.push((i * subdivisions + (s + subdivisions)) % (stride * subdivisions));
				indices.push((i * subdivisions + (s + subdivisions + 1)) % (stride * subdivisions));
			}
		}

        // Create flat triangle fan caps to seal the top and bottom.
        createCylinderCap(true);
        createCylinderCap(false);
		
		// Normals
		ComputeNormals(positions, normals, indices);
		
		// Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;

        return vertexData;
	}
	
	public static function CreateTorus(diameter:Float = 1, thickness:Float = 0.5, tessellation:Int = 16):VertexData
	{
        var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var stride = tessellation + 1;

        for (i in 0...tessellation + 1) 
		{
            var u:Float = i / tessellation;

            var outerAngle:Float = i * Math.PI * 2.0 / tessellation - Math.PI / 2.0;

            var transform = Matrix.Translation(diameter / 2.0, 0, 0).multiply(Matrix.RotationY(outerAngle));

            for (j in 0...tessellation + 1)
			{
                var v = 1 - j / tessellation;

                var innerAngle = j * Math.PI * 2.0 / tessellation + Math.PI;
                var dx = Math.cos(innerAngle);
                var dy = Math.sin(innerAngle);

                // Create a vertex.
                var normal = new Vector3(dx, dy, 0);
                var position:Vector3 = normal.scale(thickness / 2);
                var textureCoordinate = new Vector2(u, v);

                position = Vector3.TransformCoordinates(position, transform);
                normal = Vector3.TransformNormal(normal, transform);

                positions.push(position.x);
				positions.push(position.y);
				positions.push(position.z);
				
                normals.push(normal.x);
				normals.push(normal.y);
				normals.push(normal.z);
				
                uvs.push(textureCoordinate.x);
				uvs.push(textureCoordinate.y);

                // And create indices for two triangles.
                var nextI = (i + 1) % stride;
                var nextJ = (j + 1) % stride;

                indices.push(i * stride + j);
                indices.push(i * stride + nextJ);
                indices.push(nextI * stride + j);

                indices.push(i * stride + nextJ);
                indices.push(nextI * stride + nextJ);
                indices.push(nextI * stride + j);
            }
        }
		
		// Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;
		
        return vertexData;
	}
	
	public static function CreateSphere(segments:Int = 32, diameter:Float = 1):VertexData
	{
        var radius:Float = diameter / 2;

        var totalZRotationSteps:Int = 2 + segments;
        var totalYRotationSteps:Int = 2 * totalZRotationSteps;

        var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

		var vertex:Vector3 = new Vector3();
		var normal:Vector3 = new Vector3();
        for (zRotationStep in 0...totalZRotationSteps + 1) 
		{
            var normalizedZ:Float = zRotationStep / totalZRotationSteps;
            var angleZ:Float = (normalizedZ * Math.PI);

            for (yRotationStep in 0...totalYRotationSteps + 1)
			{
                var normalizedY:Float = yRotationStep / totalYRotationSteps;

                var angleY:Float = normalizedY * Math.PI * 2;

                var rotationZ = Matrix.RotationZ(-angleZ);
                var rotationY = Matrix.RotationY(angleY);
                var afterRotZ = Vector3.TransformCoordinates(Vector3.Up(), rotationZ);
                var complete = Vector3.TransformCoordinates(afterRotZ, rotationY);

                complete.scaleToRef(radius, vertex);
				normal.copyFrom(vertex);
				normal.normalize();
                //var normal = Vector3.Normalize(vertex);

                positions.push(vertex.x);
				positions.push(vertex.y);
				positions.push(vertex.z);
                normals.push(normal.x);
				normals.push(normal.y);
				normals.push(normal.z);
                uvs.push(normalizedZ);
				uvs.push(normalizedY);
            }

            if (zRotationStep > 0)
			{
                var verticesCount:Int = Std.int(positions.length / 3);
				
				var firstIndex:Int = Std.int(verticesCount - 2 * (totalYRotationSteps + 1));
				while ((firstIndex + totalYRotationSteps + 2) < verticesCount)
				{                
                    indices.push((firstIndex));
                    indices.push((firstIndex + 1));
                    indices.push(firstIndex + totalYRotationSteps + 1);

                    indices.push((firstIndex + totalYRotationSteps + 1));
                    indices.push((firstIndex + 1));
                    indices.push((firstIndex + totalYRotationSteps + 2));
					
					firstIndex++;
                }
            }
        }
		
		// Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;

        return vertexData;
	}
	
	public static function CreatePlane(size:Float):VertexData
	{
        var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // Vertices
        var halfSize:Float = size / 2.0;
        positions.push( -halfSize);
		positions.push( -halfSize);
		positions.push(0);
        normals.push(0);
		normals.push(0);
		normals.push(-1.0);
        uvs.push(0.0);
		uvs.push(0.0);

        positions.push(halfSize);
		positions.push( -halfSize);
		positions.push(0);
        normals.push(0);
		normals.push(0);
		normals.push( -1.0);
        uvs.push(1.0);
		uvs.push(0.0);

        positions.push(halfSize);
		positions.push(halfSize);
		positions.push(0);
        normals.push(0);
		normals.push(0);
		normals.push(-1.0);
        uvs.push(1.0);
		uvs.push(1.0);

        positions.push( -halfSize);
		positions.push(halfSize);
		positions.push(0);
        normals.push(0);
		normals.push(0);
		normals.push(-1.0);
        uvs.push(0.0);
		uvs.push(1.0);

        // Indices
        indices.push(0);
        indices.push(1);
        indices.push(2);

        indices.push(0);
        indices.push(2);
        indices.push(3);

        // Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;
		
        return vertexData;
	}
	
	public static function CreateLines(points: Array<Vector3>): VertexData
	{
		var indices:Array<Int> = [];
        var positions:Array<Float> = [];

		for (index in 0...points.length)
		{
			positions.push(points[index].x);
			positions.push(points[index].y);
			positions.push(points[index].z);

			if (index > 0)
			{
				indices.push(index - 1);
				indices.push(index);
			}
		}

		// Result
		var vertexData = new VertexData();

		vertexData.indices = indices;
		vertexData.positions = positions;

		return vertexData;
	}
	
	public static function CreateGround(width:Float, height:Float, subdivisions:Int):VertexData 
	{
        var indices:Array<Int> = [];
        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        for (row in 0...(subdivisions + 1))
		{
            for (col in 0...(subdivisions + 1))
			{
                var position = new Vector3((col * width) / subdivisions - (width / 2.0),
											0, 
											((subdivisions - row) * height) / subdivisions - (height / 2.0));
                var normal = new Vector3(0, 1.0, 0);

                positions.push(position.x);
				positions.push(position.y);
				positions.push(position.z);
				
                normals.push(normal.x);
				normals.push(normal.y);
				normals.push(normal.z);
				
                uvs.push(col / subdivisions);
				uvs.push(1.0 - row / subdivisions);
            }
        }

        for (row in 0...subdivisions)
		{
            for (col in 0...subdivisions)
			{
                indices.push(col + 1 + (row + 1) * (subdivisions + 1));
                indices.push(col + 1 + row * (subdivisions + 1));
                indices.push(col + row * (subdivisions + 1));

                indices.push(col + (row + 1) * (subdivisions + 1));
                indices.push(col + 1 + (row + 1) * (subdivisions + 1));
                indices.push(col + row * (subdivisions + 1));
            }
        }

        // Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;
		
        return vertexData;
	}
	
	public static function CreateTiledGround (xmin: Float, zmin: Float, xmax: Float, zmax: Float, 
											subdivisions: { w: Int, h: Int }, 
											precision: { w: Int, h: Int } ): VertexData
	{
		var indices:Array<Int> = [];
		var positions = [];
		var normals = [];
		var uvs = [];

		subdivisions.h = (subdivisions.w < 1) ? 1 : subdivisions.h;
		subdivisions.w = (subdivisions.w < 1) ? 1 : subdivisions.w;
		precision.w    = (precision.w < 1) ? 1 : precision.w;
		precision.h    = (precision.h < 1) ? 1 : precision.h;

		var tileSize = {
			w : (xmax - xmin) / subdivisions.w,
			h : (zmax - zmin) / subdivisions.h
		};
		
		function applyTile(xTileMin: Float, zTileMin: Float, xTileMax: Float, zTileMax: Float):Void
		{
			// Indices
			var base = positions.length / 3;
			var rowLength:Int = precision.w + 1;
			for (row in 0...precision.h) 
			{
				for (col in 0...precision.w)
				{
					var square:Array<Int> = [
						Std.int(base +  col + row * rowLength),
						Std.int(base + (col + 1) + row * rowLength),
						Std.int(base + (col + 1) + (row + 1) * rowLength),
						Std.int(base +  col + (row + 1) * rowLength)
					];

					indices.push(square[1]);
					indices.push(square[2]);
					indices.push(square[3]);
					indices.push(square[0]);
					indices.push(square[1]);
					indices.push(square[3]);
				}
			}

			// Position, normals and uvs
			var position = Vector3.Zero();
			var normal = new Vector3(0, 1.0, 0);
			for (row in 0...precision.h + 1)
			{
				position.z = (row * (zTileMax - zTileMin)) / precision.h + zTileMin;
				for (col in 0...precision.w + 1)
				{
					position.x = (col * (xTileMax - xTileMin)) / precision.w + xTileMin;
					position.y = 0;

					positions.push(position.x);
					positions.push(position.y);
					positions.push(position.z);
					normals.push(normal.x);
					normals.push(normal.y);
					normals.push(normal.z);
					uvs.push(col / precision.w);
					uvs.push(row / precision.h);
				}
			}
		}

		for (tileRow in 0...subdivisions.h) 
		{
			for (tileCol in 0...subdivisions.w) 
			{
				applyTile(xmin + tileCol * tileSize.w,
						zmin + tileRow * tileSize.h,
						xmin + (tileCol + 1) * tileSize.w,
						zmin + (tileRow + 1) * tileSize.h
					);
			}
		}
		// Result
		var vertexData:VertexData = new VertexData();

		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;

		return vertexData;
	}
	
	public static function CreateGroundFromHeightMap(width:Float, height:Float,subdivisions:Int, 
													minHeight:Float, maxHeight:Float,img:BitmapData):VertexData
	{
		var indices:Array<Int> = [];
		var positions:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];
		
		// Getting height map data
		var heightMapWidth = img.width;
		var heightMapHeight = img.height;
		
		var position:Vector3 = new Vector3();
					
		// Vertices
		var subdivisions1:Int = subdivisions + 1;
		for (row in 0...subdivisions1) 
		{
			for (col in 0...subdivisions1)
			{
				position.x = (col * width) / subdivisions - (width / 2.0); 
				position.y = 0; 
				position.z = ((subdivisions - row) * height) / subdivisions - (height / 2.0);

				// Compute height
				var heightMapX:Int = Std.int(((position.x + width / 2) / width) * (heightMapWidth - 1));
				var heightMapY:Int = Std.int((1.0 - (position.z + height / 2) / height) * (heightMapHeight - 1));

				var color:UInt = img.getPixel(heightMapX, heightMapY);
				var r:Float = (color >> 16 & 0xFF) / 255;
				var g:Float = (color >> 8 & 0xFF) / 255;
				var b:Float = (color & 0xFF) / 255;
				
				var gradient = r * 0.3 + g * 0.59 + b * 0.11;

				position.y = minHeight + (maxHeight - minHeight) * gradient;

				// Add  vertex
				positions.push(position.x);
				positions.push(position.y);
				positions.push(position.z);
				normals.push(0);
				normals.push(0);
				normals.push(0);
				uvs.push(col / subdivisions);
				uvs.push(1.0 - row / subdivisions);
			}
		}

		// Indices
		for (row in 0...subdivisions)
		{
			for (col in 0...subdivisions)
			{
				var row1:Int = row + 1;
				indices.push(col + 1 + row1 * subdivisions1);
				indices.push(col + 1 + row * subdivisions1);
				indices.push(col + row * subdivisions1);

				indices.push(col + row1 * subdivisions1);
				indices.push(col + 1 + row1 * subdivisions1);
				indices.push(col + row * subdivisions1);
			}
		}

		// Normals
		VertexData.ComputeNormals(positions, normals, indices);
		
		// Result
		var vertexData:VertexData = new VertexData();
		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;
		
        return vertexData;
	}
	
	// based on http://code.google.com/p/away3d/source/browse/trunk/fp10/Away3D/src/away3d/primitives/TorusKnot.as?spec=svn2473&r=2473
    public static function CreateTorusKnot(radius: Float = 2, tube: Float = 0.5, 
								radialSegments: Int = 32, tubularSegments: Int = 32, 
								p: Float = 2, q: Float = 3): VertexData 
	{
		var indices:Array<Int> = [];
		var positions:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		// Helper
		function getPos(angle:Float):Vector3
		{
			var cu = Math.cos(angle);
			var su = Math.sin(angle);
			var quOverP = q / p * angle;
			var cs = Math.cos(quOverP);

			var tx = radius * (2 + cs) * 0.5 * cu;
			var ty = radius * (2 + cs) * su * 0.5;
			var tz = radius * Math.sin(quOverP) * 0.5;

			return new Vector3(tx, ty, tz);
		}

		// Vertices
		for (i in 0...(radialSegments+1))
		{
			var modI:Int = i % radialSegments;
			var u:Float = modI / radialSegments * 2 * p * Math.PI;
			var p1:Vector3 = getPos(u);
			var p2:Vector3 = getPos(u + 0.01);
			var tang:Vector3 = p2.subtract(p1);
			var n:Vector3 = p2.add(p1);

			var bitan:Vector3 = Vector3.Cross(tang, n);
			n = Vector3.Cross(bitan, tang);

			bitan.normalize();
			n.normalize();

			for (j in 0...tubularSegments)
			{
				var modJ = j % tubularSegments;
				var v = modJ / tubularSegments * 2 * Math.PI;
				var cx = -tube * Math.cos(v);
				var cy = tube * Math.sin(v);

				positions.push(p1.x + cx * n.x + cy * bitan.x);
				positions.push(p1.y + cx * n.y + cy * bitan.y);
				positions.push(p1.z + cx * n.z + cy * bitan.z);

				uvs.push(i / radialSegments);
				uvs.push(j / tubularSegments);
			}
		}

		for (i in 0...radialSegments)
		{
			for (j in 0...tubularSegments)
			{
				var jNext = (j + 1) % tubularSegments;
				var a:Int = i * tubularSegments + j;
				var b:Int = (i + 1) * tubularSegments + j;
				var c:Int = (i + 1) * tubularSegments + jNext;
				var d:Int = i * tubularSegments + jNext;

				indices.push(d); indices.push(b); indices.push(a);
				indices.push(d); indices.push(c); indices.push(b);
			}
		}

		// Normals
		VertexData.ComputeNormals(positions, normals, indices);

		// Result
		var vertexData:VertexData = new VertexData();

		vertexData.indices = indices;
		vertexData.positions = positions;
		vertexData.normals = normals;
		vertexData.uvs = uvs;

		return vertexData;
	}
	
	public static function ComputeNormals(positions:Array<Float>, normals:Array<Float>, indices:Array<Int>):Void
	{
		var positionVectors:Array<Vector3> = [];
        var facesOfVertices:Array<Array<Int>> = [];
		
        var index:Int = 0;

		while (index < positions.length) 
		{
            var vector3 = new Vector3(positions[index], positions[index + 1], positions[index + 2]);
            positionVectors.push(vector3);
            facesOfVertices.push([]);
			index += 3;
        }
		
        // Compute normals
        var facesNormals:Array<Vector3> = [];
        for (index in 0...Std.int(indices.length / 3))
		{
            var i1 = indices[index * 3];
            var i2 = indices[index * 3 + 1];
            var i3 = indices[index * 3 + 2];

            var p1 = positionVectors[i1];
            var p2 = positionVectors[i2];
            var p3 = positionVectors[i3];

            var p1p2 = p1.subtract(p2);
            var p3p2 = p3.subtract(p2);
			
			var faceNormal:Vector3 = Vector3.Cross(p1p2, p3p2);
			faceNormal.normalize();

            facesNormals[index] = faceNormal;
            facesOfVertices[i1].push(index);
            facesOfVertices[i2].push(index);
            facesOfVertices[i3].push(index);
        }

		var normal:Vector3 = Vector3.Zero();
        for (index in 0...positionVectors.length)
		{
            var faces:Array<Int> = facesOfVertices[index];

            normal.setTo(0, 0, 0);
            for (faceIndex in 0...faces.length) 
			{
                normal.addInPlace(facesNormals[faces[faceIndex]]);
            }
			
			normal.scaleToRef(1.0 / faces.length, normal);
			normal.normalize();

            //normal = Vector3.Normalize(normal.scale(1.0 / faces.length));

            normals[index * 3] = normal.x;
            normals[index * 3 + 1] = normal.y;
            normals[index * 3 + 2] = normal.z;
        }
	}
}