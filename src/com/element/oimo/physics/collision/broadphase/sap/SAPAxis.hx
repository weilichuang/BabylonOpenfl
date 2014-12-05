/* Copyright (c) 2012-2013 EL-EMENT saharan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation  * files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,  * modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package com.element.oimo.physics.collision.broadphase.sap;
import haxe.ds.Vector;

	
/**
 * A projection axis for sweep and prune broad-phase.
 * @author saharan
 */
class SAPAxis
{
	public var elements:Vector<SAPElement>;
	private var numElements:Int = 0;
	private var bufferSize:Int = 256;
	private var stack:Vector<Int> = new Vector<Int>(64);
	
	public function new()
	{
		elements = new Vector<SAPElement>(bufferSize);
	}
	
	public function addElements(min:SAPElement, max:SAPElement):Void
	{
		if (numElements + 2 >= bufferSize)
		{
			bufferSize <<= 1;
			
			var newElements:Vector<SAPElement> = new Vector<SAPElement>(bufferSize);

			Vector.blit(elements, 0, newElements, 0, numElements);
			
			elements = newElements;
		}
		elements[numElements++] = min;
		elements[numElements++] = max;
	}
	
	public function removeElements(min:SAPElement, max:SAPElement):Void
	{
		var minIndex:Int = -1;
		var maxIndex:Int = -1;
		for (i in 0...numElements)
		{
			var e:SAPElement = elements[i];
			if (e == min || e == max)
			{
				if (minIndex == -1)
				{
					minIndex = i;
				}
				else
				{
					maxIndex = i;
					break;
				}
			}
		}
		
		for (i in (minIndex + 1)...maxIndex)
		{
			elements[i - 1] = elements[i];
		}
		
		for (i in (maxIndex + 1)...numElements)
		{
			elements[i - 2] = elements[i];
		}
		
		elements[--numElements] = null;
		elements[--numElements] = null;
	}
	
	public function sort():Void
	{
		if (numElements == 0)
			return;
			
		var count:Int = 0;
		
		var threshold:Int = 1;
		while ((numElements >> threshold) != 0)
			threshold++;
		threshold = threshold * numElements >> 2;
		
		count = 0;
		var tmp:SAPElement;
		var pivot:Float;
		var tmp2:SAPElement;
		var giveup:Bool = false;
		var elements:Vector<SAPElement> = this.elements;
		for (i in 1...numElements)
		{ 
			// try insertion sort
			tmp = elements[i];
			pivot = tmp.value;
			tmp2 = elements[i - 1];
			if (tmp2.value > pivot)
			{
				var j:Int = i;
				do
				{
					elements[j] = tmp2;
					if (--j == 0)
						break;
					tmp2 = elements[j - 1];
				} while (tmp2.value > pivot);
				
				elements[j] = tmp;
				count += i - j;
				if (count > threshold)
				{
					giveup = true; // stop and use quick sort
					break;
				}
			}
		}
		if (!giveup)
			return;
			
		count = 2;
		var stack:Vector<Int> = this.stack;
		stack[0] = 0;
		stack[1] = numElements - 1;
		while (count > 0)
		{
			var right:Int = stack[--count];
			var left:Int = stack[--count];
			var diff:Int = right - left;
			if (diff > 16)
			{ 
				// quick sort
				var mid:Int = left + (diff >> 1);
				tmp = elements[mid];
				elements[mid] = elements[right];
				elements[right] = tmp;
				pivot = tmp.value;
				var i:Int = left - 1;
				var j:Int = right;
				while (true)
				{
					var ei:SAPElement;
					var ej:SAPElement;
					do
					{
						ei = elements[++i];
					} 
					while (ei.value < pivot);
					
					do
					{
						ej = elements[--j];
					} 
					while (pivot < ej.value && j != left);
					
					if (i >= j)
						break;
					elements[i] = ej;
					elements[j] = ei;
				}
				
				elements[right] = elements[i];
				elements[i] = tmp;
				if (i - left > right - i)
				{
					stack[count++] = left;
					stack[count++] = i - 1;
					stack[count++] = i + 1;
					stack[count++] = right;
				}
				else
				{
					stack[count++] = i + 1;
					stack[count++] = right;
					stack[count++] = left;
					stack[count++] = i - 1;
				}
			}
			else
			{ 
				// insertion sort
				for (i in (left + 1)...(right + 1))
				{
					tmp = elements[i];
					pivot = tmp.value;
					tmp2 = elements[i - 1];
					if (tmp2.value > pivot)
					{
						var j:Int = i;
						do
						{
							elements[j] = tmp2;
							if (--j == 0)
								break;
							tmp2 = elements[j - 1];
						} 
						while (tmp2.value > pivot);
						
						elements[j] = tmp;
					}
				}
			}
		}
	}
	
	public function calculateTestCount():Int
	{
		var num:Int = 1;
		var sum:Int = 0;
		for (i in 1...numElements)
		{
			if (elements[i].max)
			{
				num--;
			}
			else
			{
				sum += num;
				num++;
			}
		}
		return sum;
	}

}