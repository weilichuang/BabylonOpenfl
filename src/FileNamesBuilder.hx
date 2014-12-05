/**
 * @author Mark Knol [blog.stroep.nl]
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
class FileNamesBuilder
{
	/** do not read sub directory */
    public static function build(directorys:Array<String>):Array<Field>
    {
        var fileReferences:Array<FileRef> = [];
		for (directory in directorys)
		{
			var fileNames = FileSystem.readDirectory(directory);
			for (fileName in fileNames)
			{
				if (!FileSystem.isDirectory(directory + fileName))
				{
					// push filenames in list. 
					fileReferences.push(new FileRef(directory + fileName));
				}
			}
		}
        
        var fields:Array<Field> = Context.getBuildFields();
        for (fileRef in fileReferences)
        {
            // create new fields based on file references!
            fields.push({
                    name: fileRef.name,
                    doc: fileRef.documentation,
                    access: [Access.APublic, Access.AStatic, Access.AInline],
                    kind: FieldType.FVar(macro:String, macro $v{fileRef.value}),
                    pos: Context.currentPos()
                });
        }
        
        return fields;
    }
}

// internal class
class FileRef
{
    public var name:String;
    public var value:String;
    public var documentation:String;
    
    public function new(value:String)
    {
        this.value = value;

        // replace forbidden characters to underscores, since variables cannot use these symbols.
        this.name = value.split("/").join("_").split("-").join("_").split(".").join("__");
        
        // generate documentation
        this.documentation = "Reference to file on disk \"" + value + "\". (auto generated)";
    }
}