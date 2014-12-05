package com.element.oimo.physics.collision.shape;

import com.element.oimo.math.Mat33;

/**
 * This class holds mass information of a shape.
 * @author saharan
 */
class MassInfo
{
	/**
	 * Mass of the shape.
	 */
	public var mass:Float;
	
	/**
	 * The moment inertia of the shape.
	 */
	public var inertia:Mat33;
	
	public function new()
	{
		mass = 0;
		inertia = new Mat33();
	}

}