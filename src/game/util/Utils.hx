package game.util;

import core.Types.IntVec2;
import game.world.Grid.RotationDir;

// NOTE: quite brittle, took way too long, collision detection may be
// better in the future for rotations, especially with elevations.
inline function getTilePosAt (xPos:Float, yPos:Float, rot:RotationDir, worldSizeX:Int, worldSizeY:Int) {
    var x:Float, y:Float;
    switch (rot) {
        case SouthEast:
            x = (xPos - 8) / 16;
            y = (yPos - 4) / 8;
        case SouthWest:
            x = (xPos + (worldSizeX * 16) - 8) / 16;
            y = (yPos - 4) / 8;
        case NorthWest:
            x = (xPos + (worldSizeX * 16) - 8) / 16;
            y = (yPos + (worldSizeY * 8) - 4) / 8;
        case NorthEast:
            x = (xPos - 8) / 16;
            y = (yPos + (worldSizeY * 8) - 4) / 8;
    }

    var tileX:Int, tileY:Int;
    switch (rot) {
        case SouthEast:
            tileX = Math.round(x - y);
            tileY = Math.round(x + y);
        case SouthWest:
            tileX = Math.round(x - (worldSizeY - y));
            tileY = Math.round((worldSizeX - x) + y);
        case NorthWest:
            tileX = Math.round((worldSizeX - x) - (worldSizeY - y));
            tileY = Math.round((worldSizeX - x) + (worldSizeY - y));
        case NorthEast:
            tileX = Math.round((worldSizeX - x) - y);
            tileY = Math.round(x + (worldSizeY - y));
    }

    return new IntVec2(tileX, tileY);
}