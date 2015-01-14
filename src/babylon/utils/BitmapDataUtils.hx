package babylon.utils;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.utils.ArrayBufferView;
import openfl.utils.UInt8Array;

class BitmapDataUtils
{
	public static function flipBitmapData(bitmapData:BitmapData, flipX:Bool, flipY:Bool):BitmapData
	{
		var result:BitmapData = new BitmapData(bitmapData.width, bitmapData.height, bitmapData.transparent, 0x0);
		var matrix:Matrix = new Matrix();
		if (flipX) {
			matrix.a = -1;
			matrix.tx = bitmapData.width;
		}
		if (flipY) {
			matrix.d = -1;
			matrix.ty = bitmapData.height;
		}
		result.draw(bitmapData, matrix, null, null, null, true);
		return result;
	}
	
	public static inline function getPixelData(bitmapData:BitmapData):ArrayBufferView
	{
		#if html5
		return @:privateAccess (bitmapData.__image).data;
		#else
		return new UInt8Array(BitmapData.getRGBAPixels(bitmapData));
		#end
	}
}