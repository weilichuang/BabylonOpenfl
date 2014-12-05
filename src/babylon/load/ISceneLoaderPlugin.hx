package babylon.load;
import babylon.bones.Skeleton;
import babylon.mesh.AbstractMesh;
import babylon.particles.ParticleSystem;

/**
 * @author weilichuang
 */

interface ISceneLoaderPlugin 
{
	function getExtensions():String;
	
	function importMesh(meshesNames:Dynamic, scene:Scene, data:String,
									rootUrl:String,
									meshes:Array<AbstractMesh>, particleSystems:Array<ParticleSystem>, skeletons:Array<Skeleton>):Bool;
									
	function load(scene:Scene, data:String, rootUrl:String):Bool;
}