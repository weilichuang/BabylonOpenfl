package babylon.collisions;

import babylon.math.FastMath;
import babylon.mesh.AbstractMesh;
import babylon.mesh.Mesh;
import babylon.mesh.SubMesh;
import babylon.math.Plane;
import babylon.math.Vector3;

typedef LowestRootResult = {
	root: Float,
	found: Bool
}

class Collider
{
	public var radius:Vector3;
	public var retry:Int;
	public var velocity:Vector3;
	public var basePoint:Vector3;
	public var epsilon:Float;
	public var collisionFound:Bool;
	public var velocityWorldLength:Float;
	
	public var basePointWorld:Vector3;
	public var velocityWorld:Vector3;
	public var normalizedVelocity:Vector3;
	
	public var initialVelocity:Vector3;
	public var initialPosition:Vector3;
	
	public var nearestDistance:Float;
	public var intersectionPoint:Vector3;
	public var collidedMesh:AbstractMesh;
	
	private var _collisionPoint:Vector3;
	private var _planeIntersectionPoint:Vector3;
	private var _tempVector:Vector3;
	private var _tempVector2:Vector3;
	private var _tempVector3:Vector3;
	private var _tempVector4:Vector3;
	private var _edge:Vector3;
	private var _baseToVertex:Vector3;
	private var _destinationPoint:Vector3;
	private var _slidePlaneNormal:Vector3;
	private var _displacementVector:Vector3;

	public function new()
	{
		this.radius = new Vector3(1, 1, 1);
        this.retry = 0;

		this.basePoint = new Vector3();
		this.velocity = new Vector3();
		
		this.initialVelocity = new Vector3();
		this.initialPosition = new Vector3();
		
        this.basePointWorld = new Vector3();
        this.velocityWorld = new Vector3();
        this.normalizedVelocity = new Vector3();
        
        // Internals
        this._collisionPoint = new Vector3();
        this._planeIntersectionPoint = new Vector3();
        this._tempVector = new Vector3();
        this._tempVector2 = new Vector3();
        this._tempVector3 = new Vector3();
        this._tempVector4 = new Vector3();
		
        this._edge = new Vector3();
        this._baseToVertex = new Vector3();
        this._destinationPoint = new Vector3();
        this._slidePlaneNormal = new Vector3();
        this._displacementVector = new Vector3();
	}
	
	public function initialize(source:Vector3, dir:Vector3, epsilon:Float):Void 
	{
        this.velocity.copyFrom(dir);
		
		//Vector3.NormalizeToRef(dir, this.normalizedVelocity);
		this.normalizedVelocity.copyFrom(dir);
		this.normalizedVelocity.normalize();
		
        this.basePoint.copyFrom(source);

        source.multiplyToRef(this.radius, this.basePointWorld);
        dir.multiplyToRef(this.radius, this.velocityWorld);

        this.velocityWorldLength = this.velocityWorld.length();

        this.epsilon = epsilon;
        this.collisionFound = false;
    }
	
	public function _checkPointInTriangle(point:Vector3, pa:Vector3, pb:Vector3, pc:Vector3, n:Vector3):Bool
	{
        pa.subtractToRef(point, this._tempVector);
        pb.subtractToRef(point, this._tempVector2);

        Vector3.CrossToRef(this._tempVector, this._tempVector2, this._tempVector4);
        var d:Float = this._tempVector4.dot(n);
        if (d < 0)
            return false;

        pc.subtractToRef(point, this._tempVector3);
        Vector3.CrossToRef(this._tempVector2, this._tempVector3, this._tempVector4);
        d = this._tempVector4.dot(n);
        if (d < 0)
            return false;

        Vector3.CrossToRef(this._tempVector3, this._tempVector, this._tempVector4);
        d = this._tempVector4.dot(n);
        return d >= 0;
    }
	
	public function intersectBoxAASphere(boxMin:Vector3, boxMax:Vector3, sphereCenter:Vector3, sphereRadius:Float):Bool
	{
        if (boxMin.x > sphereCenter.x + sphereRadius)
            return false;

        if (sphereCenter.x - sphereRadius > boxMax.x)
            return false;

        if (boxMin.y > sphereCenter.y + sphereRadius)
            return false;

        if (sphereCenter.y - sphereRadius > boxMax.y)
            return false;

        if (boxMin.z > sphereCenter.z + sphereRadius)
            return false;

        if (sphereCenter.z - sphereRadius > boxMax.z)
            return false;

        return true;
    }
	
	public function getLowestRoot(a:Float, b:Float, c:Float, maxR:Float):LowestRootResult 
	{
        var determinant = b * b - 4.0 * a * c;
		
        var result:LowestRootResult = { root: 0, found: false };

        if (determinant < 0)
            return result;

		var a2:Float = 2.0 * a;
        var sqrtD:Float = Math.sqrt(determinant);
        var r1:Float = (-b - sqrtD) / a2;
        var r2:Float = (-b + sqrtD) / a2;

        if (r1 > r2)
		{
            var temp = r2;
            r2 = r1;
            r1 = temp;
        }

        if (r1 > 0 && r1 < maxR)
		{
            result.root = r1;
            result.found = true;
            return result;
        }

        if (r2 > 0 && r2 < maxR)
		{
            result.root = r2;
            result.found = true;
            return result;
        }

        return result;
    }
	
	public function _canDoCollision(sphereCenter:Vector3, sphereRadius:Float, vecMin:Vector3, vecMax:Vector3):Bool
	{
        var distance:Float = this.basePointWorld.distanceTo(sphereCenter);

        var max:Float = Math.max(Math.max(this.radius.x, this.radius.y), this.radius.z);

        if (distance > this.velocityWorldLength + max + sphereRadius)
		{
            return false;
        }

        if (!intersectBoxAASphere(vecMin, vecMax, this.basePointWorld, this.velocityWorldLength + max))
            return false;

        return true;
    }
	
	public function _testTriangle(faceIndex:Int, subMesh:SubMesh, p1:Vector3, p2:Vector3, p3:Vector3):Void
	{
        var t0:Float = 0;
        var embeddedInPlane:Bool = false;

        if (subMesh._trianglePlanes == null)
		{
            subMesh._trianglePlanes = [];
        }
        
		var trianglePlane:Plane = subMesh._trianglePlanes[faceIndex];
        if (trianglePlane == null) 
		{
            trianglePlane = new Plane(0, 0, 0, 0);
            trianglePlane.copyFromPoints(p1, p2, p3);
			subMesh._trianglePlanes[faceIndex] = trianglePlane;
        }

        if (subMesh.getMaterial() == null && 
			!trianglePlane.isFrontFacingTo(this.normalizedVelocity, 0))
            return;

        var signedDistToTrianglePlane:Float = trianglePlane.signedDistanceTo(this.basePoint);
        var normalDotVelocity:Float = trianglePlane.normal.dot(this.velocity);

        if (normalDotVelocity == 0)
		{
            if (FastMath.fabs(signedDistToTrianglePlane) >= 1.0)
                return;
				
            embeddedInPlane = true;
            t0 = 0;
        }
        else
		{
            t0 = (-1.0 - signedDistToTrianglePlane) / normalDotVelocity;
            var t1:Float = (1.0 - signedDistToTrianglePlane) / normalDotVelocity;

            if (t0 > t1) 
			{
                var temp:Float = t1;
                t1 = t0;
                t0 = temp;
            }

            if (t0 > 1.0 || t1 < 0.0)
                return;

            if (t0 < 0)
                t0 = 0;
            if (t0 > 1.0)
                t0 = 1.0;
        }

        this._collisionPoint.setTo(0, 0, 0);

        var found:Bool = false;
        var t:Float = 1.0;

        if (!embeddedInPlane) 
		{
            this.basePoint.subtractToRef(trianglePlane.normal, this._planeIntersectionPoint);
            this.velocity.scaleToRef(t0, this._tempVector);
            this._planeIntersectionPoint.addInPlace(this._tempVector);

            if (this._checkPointInTriangle(this._planeIntersectionPoint, p1, p2, p3, trianglePlane.normal))
			{
                found = true;
                t = t0;
                this._collisionPoint.copyFrom(this._planeIntersectionPoint);
            }
        }

        if (!found)
		{
            var velocitySquaredLength:Float = this.velocity.lengthSquared();

            var a:Float = velocitySquaredLength;

            this.basePoint.subtractToRef(p1, this._tempVector);
            var b:Float = 2.0 * (this.velocity.dot( this._tempVector));
            var c:Float = this._tempVector.lengthSquared() - 1.0;

            var lowestRoot:LowestRootResult = getLowestRoot(a, b, c, t);
            if (lowestRoot.found)
			{
                t = lowestRoot.root;
                found = true;
                this._collisionPoint.copyFrom(p1);
            }

            this.basePoint.subtractToRef(p2, this._tempVector);
            b = 2.0 * this.velocity.dot(this._tempVector);
            c = this._tempVector.lengthSquared() - 1.0;

            lowestRoot = getLowestRoot(a, b, c, t);
            if (lowestRoot.found)
			{
                t = lowestRoot.root;
                found = true;
                this._collisionPoint.copyFrom(p2);
            }

            this.basePoint.subtractToRef(p3, this._tempVector);
            b = 2.0 * this.velocity.dot(this._tempVector);
            c = this._tempVector.lengthSquared() - 1.0;

            lowestRoot = getLowestRoot(a, b, c, t);
            if (lowestRoot.found)
			{
                t = lowestRoot.root;
                found = true;
                this._collisionPoint.copyFrom(p3);
            }

            p2.subtractToRef(p1, this._edge);
            p1.subtractToRef(this.basePoint, this._baseToVertex);
            var edgeSquaredLength:Float = this._edge.lengthSquared();
            var edgeDotVelocity:Float = this._edge.dot(this.velocity);
            var edgeDotBaseToVertex:Float = this._edge.dot(this._baseToVertex);

            a = edgeSquaredLength * (-velocitySquaredLength) + edgeDotVelocity * edgeDotVelocity;
            b = edgeSquaredLength * (2.0 * this.velocity.dot(this._baseToVertex)) - 2.0 * edgeDotVelocity * edgeDotBaseToVertex;
            c = edgeSquaredLength * (1.0 - this._baseToVertex.lengthSquared()) + edgeDotBaseToVertex * edgeDotBaseToVertex;

            lowestRoot = getLowestRoot(a, b, c, t);
            if (lowestRoot.found)
			{
                var f:Float = (edgeDotVelocity * lowestRoot.root - edgeDotBaseToVertex) / edgeSquaredLength;

                if (f >= 0.0 && f <= 1.0)
				{
                    t = lowestRoot.root;
                    found = true;
                    this._edge.scaleInPlace(f);
                    p1.addToRef(this._edge, this._collisionPoint);
                }
            }

            p3.subtractToRef(p2, this._edge);
            p2.subtractToRef(this.basePoint, this._baseToVertex);
            edgeSquaredLength = this._edge.lengthSquared();
            edgeDotVelocity = this._edge.dot(this.velocity);
            edgeDotBaseToVertex = this._edge.dot(this._baseToVertex);

            a = edgeSquaredLength * (-velocitySquaredLength) + edgeDotVelocity * edgeDotVelocity;
            b = edgeSquaredLength * (2.0 * this.velocity.dot(this._baseToVertex)) - 2.0 * edgeDotVelocity * edgeDotBaseToVertex;
            c = edgeSquaredLength * (1.0 - this._baseToVertex.lengthSquared()) + edgeDotBaseToVertex * edgeDotBaseToVertex;
            lowestRoot = getLowestRoot(a, b, c, t);
            if (lowestRoot.found) 
			{
                var f:Float = (edgeDotVelocity * lowestRoot.root - edgeDotBaseToVertex) / edgeSquaredLength;

                if (f >= 0.0 && f <= 1.0) 
				{
                    t = lowestRoot.root;
                    found = true;
                    this._edge.scaleInPlace(f);
                    p2.addToRef(this._edge, this._collisionPoint);
                }
            }

            p1.subtractToRef(p3, this._edge);
            p3.subtractToRef(this.basePoint, this._baseToVertex);
            edgeSquaredLength = this._edge.lengthSquared();
            edgeDotVelocity = this._edge.dot(this.velocity);
            edgeDotBaseToVertex = this._edge.dot(this._baseToVertex);

            a = edgeSquaredLength * (-velocitySquaredLength) + edgeDotVelocity * edgeDotVelocity;
            b = edgeSquaredLength * (2.0 * this.velocity.dot(this._baseToVertex)) - 2.0 * edgeDotVelocity * edgeDotBaseToVertex;
            c = edgeSquaredLength * (1.0 - this._baseToVertex.lengthSquared()) + edgeDotBaseToVertex * edgeDotBaseToVertex;

            lowestRoot = getLowestRoot(a, b, c, t);
            if (lowestRoot.found) 
			{
                var f:Float = (edgeDotVelocity * lowestRoot.root - edgeDotBaseToVertex) / edgeSquaredLength;

                if (f >= 0.0 && f <= 1.0)
				{
                    t = lowestRoot.root;
                    found = true;
                    this._edge.scaleInPlace(f);
                    p3.addToRef(this._edge, this._collisionPoint);
                }
            }
        }

        if (found)
		{
            var distToCollision:Float = t * this.velocity.length();

            if (!this.collisionFound || distToCollision < this.nearestDistance)
			{
                if (this.intersectionPoint == null)
				{
                    this.intersectionPoint = this._collisionPoint.clone();
                } 
				else 
				{
                    this.intersectionPoint.copyFrom(this._collisionPoint);
                }
                this.nearestDistance = distToCollision;                
                this.collisionFound = true;
                this.collidedMesh = subMesh.getMesh();
            }
        }
    }
	
	public function _collide(subMesh:SubMesh, pts:Array<Vector3>, indices:Array<Int>, indexStart:Int, indexEnd:Int, decal:Int):Void 
	{
		var i:Int = indexStart;
        while (i < indexEnd) 
		{
            var p1:Vector3 = pts[indices[i] - decal];
            var p2:Vector3 = pts[indices[i + 1] - decal];
            var p3:Vector3 = pts[indices[i + 2] - decal];

			this._testTriangle(i, subMesh, p3, p2, p1);

			i += 3;
        }
    }
	
	public function _getResponse(pos:Vector3, vel:Vector3):Void
	{
        pos.addToRef(vel, _destinationPoint);
        vel.scaleInPlace((nearestDistance / vel.length()));

        basePoint.addToRef(vel, pos);
        pos.subtractToRef(intersectionPoint, _slidePlaneNormal);
        _slidePlaneNormal.normalize();
        _slidePlaneNormal.scaleToRef(epsilon, _displacementVector);

        pos.addInPlace(_displacementVector);
        intersectionPoint.addInPlace(_displacementVector);

        _slidePlaneNormal.scaleInPlace(Plane.SignedDistanceToPlaneFromPositionAndNormal(intersectionPoint, _slidePlaneNormal, _destinationPoint));
        _destinationPoint.subtractInPlace(_slidePlaneNormal);

        _destinationPoint.subtractToRef(intersectionPoint, vel);
    }
	
}
