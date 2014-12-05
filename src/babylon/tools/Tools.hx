package babylon.tools;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import assets.manager.misc.LoaderStatus;
import babylon.math.Vector3;
import babylon.utils.Logger;
import openfl.display.BitmapData;
import openfl.Lib;
import openfl.utils.ByteArray;
import openfl.utils.Timer;

typedef BabylonMinMax = {
	minimum: Vector3,
	maximum: Vector3
}
 
class Tools 
{
	
	public static var timer:Timer;
	
	// World limits
	public static function checkExtends(v:Vector3, min:Vector3, max:Vector3):Void
	{
		if (v.x < min.x)
			min.x = v.x;
		if (v.y < min.y)
			min.y = v.y;
		if (v.z < min.z)
			min.z = v.z;

		if (v.x > max.x)
			max.x = v.x;
		if (v.y > max.y)
			max.y = v.y;
		if (v.z > max.z)
			max.z = v.z;
	}
	
	public static function ExtractMinAndMaxIndexed(positions: Array<Float>, 
													indices: Array<Int>, 
													indexStart:Int, 
													indexCount: Int): BabylonMinMax
	{
		var minimum:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var maximum:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

		for (index in indexStart...(indexStart + indexCount))
		{
			var current = new Vector3(positions[indices[index] * 3], 
									positions[indices[index] * 3 + 1], 
									positions[indices[index] * 3 + 2]);

			minimum = Vector3.Minimize(current, minimum);
			maximum = Vector3.Maximize(current, maximum);
		}

		return {
			minimum: minimum,
			maximum: maximum
		};
	}

	public static function ExtractMinAndMax(positions:Array<Float>, start:Int, count:Int):BabylonMinMax
	{
        var minimum:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var maximum:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

        for (index in start...start + count)
		{
            var current = new Vector3(positions[index * 3], positions[index * 3 + 1], positions[index * 3 + 2]);

            minimum = Vector3.Minimize(current, minimum);
            maximum = Vector3.Maximize(current, maximum);
        }

        return {
            minimum: minimum,
            maximum: maximum
        };
    }
	
	public static inline function WithinEpsilon(a:Float, b:Float):Bool 
	{
        var num:Float = a - b;
        return -1.401298E-45 <= num && num <= 1.401298E-45;
    }
	
	public static function LoadFile(url:String, loadComplete:String->Void, loadError:String->Void = null):Void 
	{
		var loader = new FileLoader();
		loader.onFileLoaded.add(function(file:FileInfo):Void 
		{
			if (file.id == url) 
			{
				if (file.status == LoaderStatus.LOADED)
				{
					Logger.log("load File Complete:"+file.id);
					loadComplete(file.data);
				} 
				else if (file.status == LoaderStatus.ERROR)
				{
					Logger.log("load File Error:" + file.id);
					if(loadError != null)
						loadError(file.id);
				}
			}
		});
		Logger.log("loading File:"+url);
		loader.loadFile(url, FileType.TEXT); 
    }
	
	public static function LoadBinary(url:String, loadComplete:ByteArray->Void, loadError:Void->Void = null):Void 
	{
		var loader = new FileLoader();
		loader.onFileLoaded.add(function(file:FileInfo):Void 
		{
			if (file.id == url) 
			{
				if (file.status == LoaderStatus.LOADED)
				{
					Logger.log("load File Complete:"+file.id);
					loadComplete(file.data);
				} 
				else if (file.status == LoaderStatus.ERROR)
				{
					Logger.log("load File Error:" + file.id);
					if(loadError != null)
						loadError();
				}
			}
		});
		Logger.log("loading Binary File:" + url);
		loader.loadFile(url, FileType.BINARY); 
    }
	
	public static function LoadImage(url:String, onload:BitmapData->Void, onError:Void->Void = null):Void
	{  
		var loader = new FileLoader();
		loader.onFileLoaded.add(function(file:FileInfo):Void 
		{
			if (file.id == url) 
			{
				if (file.status == LoaderStatus.LOADED)
				{
					Logger.log("load Image Complete:"+file.id);
					onload(file.data);
				} 
				else if (file.status == LoaderStatus.ERROR)
				{
					Logger.log("load Image Error:" + file.id);
					//if(onload != null)
						//onload(new BitmapData(16,16,false,0xFFFFFF));
					if (onError != null)
					{
						onError();
					}
				}
			}
		});
		Logger.log("loading Image:"+url);
		loader.loadFile(url, FileType.IMAGE);  
    }
	
	private static var extensions = ["_px.jpg", "_py.jpg", "_pz.jpg", "_nx.jpg", "_ny.jpg", "_nz.jpg"];
	public static function LoadCubeImages(url:String, onLoad:Array<BitmapData>->Void):Void
	{  
		var bitmapDatas:Array<BitmapData> = [];
		var files:Array<String> = [];
		for (i in 0...extensions.length)
		{
			files[i] = url + extensions[i];
		}
		
		var loader = new FileLoader();
		loader.onFileLoaded.add(function(file:FileInfo):Void 
		{
			if (file.status == LoaderStatus.LOADED)
			{
				var index:Int = files.indexOf(file.id);
				Logger.log("load Cube Image " + index + " Complete:" + file.id);
				
				bitmapDatas[index] = file.data;
			}
			else if (file.status == LoaderStatus.ERROR)
			{
				var index:Int = files.indexOf(file.id);
				Logger.log("load Cube Image " + index + " Error:" + file.id);
				bitmapDatas[index] = new BitmapData(16, 16, false, 0xff0000);
			}	
		});
		loader.onFilesLoaded.addOnce(function(files:Array<FileInfo>):Void {
			Logger.log("load Cube Images Complete:" + url);
			if (onLoad != null)
			{
				onLoad(bitmapDatas);
			}
		});
		Logger.log("loading Cube Images:" + url);
		for (i in 0...files.length)
		{
			loader.queueFile(files[i], FileType.IMAGE);
		}
		loader.loadQueuedFiles();
    }
	
	public static function DeepCopy(source:Dynamic, destination:Dynamic, doNotCopyList:Array<String> = null, mustCopyList:Array<String> = null)
	{
		var fields:Array<String> = Reflect.fields(source);
        for (prop in fields) 
		{
            if (prop.charAt(0) == "_" && (mustCopyList == null || mustCopyList.indexOf(prop) == -1)) 
			{
                continue;
            }

            if (doNotCopyList != null && doNotCopyList.indexOf(prop) != -1) 
			{
                continue;
            }
			
            var sourceValue = Reflect.field(source, prop);

            if (Reflect.isFunction(sourceValue)) 
			{
                continue;
            }
			
			Reflect.setField(destination, prop, Reflect.copy(sourceValue));			
        }
    }
	
	// FPS
    public static var fpsRange:Float = 60.0;
    public static var previousFramesDuration:Array<Float> = [];
    public static var fps:Float = 60.0;
    public static var deltaTime:Float = 0.0;

    public static function GetFps():Float
	{
        return fps;
    }

    public static function GetDeltaTime():Float 
	{
        return deltaTime;
    }

    public static function _MeasureFps():Void
	{
        previousFramesDuration.push(Lib.getTimer());
		
        var length = previousFramesDuration.length;

        if (length >= 2)
		{
            deltaTime = previousFramesDuration[length - 1] - previousFramesDuration[length - 2];
        }

        if (length >= fpsRange)
		{
            if (length > fpsRange)
			{
                previousFramesDuration.splice(0, 1);
                length--;
            }

            var sum:Float = 0;
			var count:Int = length - 1;
            for (i in 0...count)
			{
                sum += previousFramesDuration[i + 1] - previousFramesDuration[i];
            }

            fps = 1000.0 / (sum / count);
        }
    }
	
	public static function MakeArray(obj:Dynamic):Array<Dynamic>
	{
		if (obj == null)
			return null;
			
		return Std.is(obj, Array) ? obj : [obj];
	}
}
