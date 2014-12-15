BabylonOpenfl
=============

Generate Doc
=============
You need install Dox first:

haxelib install dox
haxelib install hxparse
haxelib install hxtemplo 
haxelib install hxargs
haxelib install markdown

than run command:

openfl build html5 -xml
haxelib run dox -i bin/html5/ -o Documentation/ -in babylon -in com
