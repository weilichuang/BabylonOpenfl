package babylon.lights;
import babylon.lights.shadows.ShadowGenerator;
import babylon.math.Vector3;
import babylon.Scene;

interface IShadowLight 
{
	var position:Vector3;
	var direction:Vector3;
	var transformedPosition:Vector3;
	var shadowGenerator: ShadowGenerator;
	var name:String;
	
	function computeTransformedPosition():Bool;
	function getScene():Scene;
}