package;

import openfl.Assets;
import haxe.io.Path;
import haxe.xml.Parser;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectGroup;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.FlxCamera;

/**
 * ...
 * @author Samuel Batista
 */
class TiledLevel extends TiledMap
{
  // For each "Tile Layer" in the map, you must define a "tileset" property which contains the name of a tile sheet image
  // used to draw tiles in that layer (without file extension). The image file must be located in the directory specified bellow.
  private inline static var c_PATH_LEVEL_TILESHEETS = "assets/images/";

  // Array of tilemaps used for collision
  public var foregroundTiles:FlxGroup;
  public var backgroundTiles:FlxGroup;
  private var collidableTileLayers:Array<FlxTilemap>;

  public function new(tiledLevel:Dynamic)
  {
    super(tiledLevel);

    foregroundTiles = new FlxGroup();
    backgroundTiles = new FlxGroup();

    FlxG.camera.setBounds(0, 0, fullWidth, fullHeight, true);

    // Load Tile Maps
    for (tileLayer in layers)
    {
      var tileSheetName:String = tileLayer.properties.get("tileset");

      if (tileSheetName == null)
        throw "'tileset' property not defined for the '" + tileLayer.name + "' layer. Please add the property to the layer.";

      var tileSet:TiledTileSet = null;
      for (ts in tilesets)
      {
        if (ts.name == tileSheetName)
        {
          tileSet = ts;
          break;
        }
      }

      if (tileSet == null)
        throw "Tileset '" + tileSheetName + " not found. Did you mispell the 'tilesheet' property in " + tileLayer.name + "' layer?";

      var imagePath     = new Path(tileSet.imageSource);
      var processedPath   = c_PATH_LEVEL_TILESHEETS + imagePath.file + "." + imagePath.ext;

      var tilemap:FlxTilemap = new FlxTilemap();
      tilemap.widthInTiles = width;
      tilemap.heightInTiles = height;
      tilemap.loadMap(tileLayer.tileArray, processedPath, tileSet.tileWidth, tileSet.tileHeight, 0, 1, 1, 1);

      if (tileLayer.properties.contains("nocollide"))
      {
        backgroundTiles.add(tilemap);
      }
      else
      {
        if (collidableTileLayers == null)
          collidableTileLayers = new Array<FlxTilemap>();

        foregroundTiles.add(tilemap);
        collidableTileLayers.push(tilemap);
      }
    }
  }

  public function loadObjects(state:PlayState)
  {
    for (group in objectGroups)
    {
      for (o in group.objects)
      {
        loadObject(o, group, state);
      }
    }
  }

  private function loadObject(o:TiledObject, g:TiledObjectGroup, state:PlayState)
  {
    var x:Int = o.x;
    var y:Int = o.y;

    // objects in tiled are aligned bottom-left (top-left in flixel)
    if (o.gid != -1)
      y -= g.map.getGidOwner(o.gid).tileHeight;

    switch (o.type.toLowerCase())
    {
      case "player":
        var player = new Player(x, y, state.jumpText);
        FlxG.camera.follow(player, FlxCamera.STYLE_LOCKON, 10);

        state.player = player;
        state.add(player);

      case "gem":
        var gem = new Gem(x, y);

        state.gem = gem;
        state.add(gem);

    }
  }

  public function collideWithLevel(obj:FlxObject, ?notifyCallback:FlxObject->FlxObject->Void, ?processCallback:FlxObject->FlxObject->Bool):Bool
  {
    if (collidableTileLayers != null)
    {
      for (map in collidableTileLayers)
      {
        // IMPORTANT: Always collide the map with objects, not the other way around.
        //        This prevents odd collision errors (collision separation code off by 1 px).
        return FlxG.overlap(map, obj, notifyCallback, processCallback != null ? processCallback : FlxObject.separate);
      }
    }
    return false;
  }

  public function checkTile(x,y, width, height){

    if (collidableTileLayers != null)
    {
      for (map in collidableTileLayers)
      {
//        trace(Math.floor(Std.int(x) / 16));
//        trace(Math.floor(Std.int(y) / 16));
//        trace(map.getTile(Math.floor(Std.int(x) / 16), Math.floor(Std.int(y) / 16)));

        if(map.getTile(Math.floor(Std.int(x) / 16), Math.floor(Std.int(y) / 16)) != 0
        || map.getTile(Math.floor(Std.int(x + width) / 16), Math.floor(Std.int(y + height) / 16)) != 0
        || map.getTile(Math.floor(Std.int(x + width) / 16), Math.floor(Std.int(y) / 16)) != 0
        || map.getTile(Math.floor(Std.int(x) / 16), Math.floor(Std.int(y + height) / 16)) != 0)
        {
          return true;
        }

      }
    }

    return false;

  }

}
