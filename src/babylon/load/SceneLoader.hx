package babylon.load ;

import babylon.load.plugins.BabylonFileLoader;
import babylon.Scene;
import babylon.tools.Tools;

class SceneLoader
{
	public static var ShowLoadingScreen:Bool;
	public static var ForceFullSceneLoadingForIncremental:Bool;
	
	private static var _registeredPlugins:Array<ISceneLoaderPlugin>;
	
	static function __init__():Void
	{
		ShowLoadingScreen = false;
		ForceFullSceneLoadingForIncremental = false;
		
		_registeredPlugins = [];
		RegisterPlugin(new BabylonFileLoader());
	}
	
	public static function RegisterPlugin(plugin:ISceneLoaderPlugin):Void
	{
		if (_registeredPlugins.indexOf(plugin) == -1)
			_registeredPlugins.push(plugin);
	}
	
	public static function getPluginForFilename(sceneFilename:String):ISceneLoaderPlugin
	{
		var dotPosition:Int = sceneFilename.lastIndexOf(".");

		var extension:String;
		var queryStringPosition:Int = sceneFilename.indexOf("?");
		if (queryStringPosition != -1)
			extension = sceneFilename.substring(dotPosition, queryStringPosition).toLowerCase();
		else
			extension = sceneFilename.substring(dotPosition).toLowerCase();

		for (index in 0..._registeredPlugins.length)
		{
			var plugin:ISceneLoaderPlugin = _registeredPlugins[index];
			var pExtensions:String = plugin.getExtensions().toLowerCase();
			if (pExtensions.indexOf(extension) != -1)
			{
				return plugin;
			}
		}

		return _registeredPlugins[_registeredPlugins.length - 1];
	}
	
	public static function LoadMesh(meshesNames:Dynamic,
									rootUrl:String, meshFileName:String, 
									scene:Scene,
									onSuccess:Dynamic,
									onError:Scene->Void = null):Void
	{
		var plugin:ISceneLoaderPlugin = getPluginForFilename(meshFileName);
		
		function importMeshFromData(data:String):Void 
		{
			var meshes = [];
			var particleSystems = [];
			var skeletons = [];

			if (!plugin.importMesh(meshesNames, scene, data, rootUrl, meshes, particleSystems, skeletons))
			{
				if (onError != null)
				{
					onError(scene);
				}

				return;
			}

			if (onSuccess != null)
			{
				scene.importedMeshesFiles.push(rootUrl + meshFileName);
				onSuccess(meshes, particleSystems, skeletons);
			}
		}
		
		if (meshFileName.substr(0, 5) == "data:") 
		{
			// Direct load
			importMeshFromData(meshFileName.substr(5));
			return;
		}
		
		Tools.LoadFile(rootUrl + meshFileName, importMeshFromData);	//,progressCallBack);//
	}
	
	public static function Load(scene:Scene, rootUrl:String, sceneFilename:String, loadComplete:Void->Void = null, loadError:Void->Void = null):Void
	{
		var plugin:ISceneLoaderPlugin = getPluginForFilename(sceneFilename);
		
		if (ShowLoadingScreen)
		{
			scene.getEngine().displayLoadingUI();
		}
		
		function loadSceneFromData(data:String):Void 
		{
			var result:Bool = plugin.load(scene, data, rootUrl);
			trace("parse " + sceneFilename+" result:" + result);
			if (!result)
			{
				if (loadError != null)
					loadError();
					
				scene.getEngine().hideLoadingUI();
				return;
			}
			
			if (loadComplete != null)
			{
				loadComplete();
			}
			
			if (SceneLoader.ShowLoadingScreen)
			{
				scene.executeWhenReady(function ():Void {
					scene.getEngine().hideLoadingUI();
				});
			}
		}
		
		function loadSceneError(url:String):Void
		{
			if (loadError != null)
					loadError();
					
			scene.getEngine().hideLoadingUI();
		}
		
		if (sceneFilename.substr(0, 5) == "data:") 
		{
			// Direct load
			loadSceneFromData(sceneFilename.substr(5));
			return;
		}

		Tools.LoadFile(rootUrl + sceneFilename, loadSceneFromData, loadSceneError);		
	}
}
