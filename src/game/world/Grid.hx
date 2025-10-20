package game.world;

typedef Grid<T> = {
    var width:Int;
    var height:Int;
    var items:Array<T>;
}

/**
 * Methods for making and handling grids.
 */
enum abstract RotationDir(Int) to Int {
    // North;
    // South;
    // East;
    // West;
    var SouthEast = 0;
    var SouthWest = 1;
    var NorthWest = 2;
    var NorthEast = 3;
}

function translateWorldX (x:Float, y:Float, rotation:RotationDir):Float {
    return switch (rotation) {
        case SouthEast: (x * 8) + (y * 8);
        case SouthWest: (x * 8) + (y * -8);
        case NorthWest: (x * -8) + (y * -8);
        case NorthEast: (x * -8) + (y * 8);
    }
}

function translateWorldY (x:Float, y:Float, rotation:RotationDir):Float {
    return switch (rotation) {
        case SouthEast: (y * 4) + (x * -4);
        case SouthWest: (y * 4) + (x * 4);
        case NorthWest: (y * -4) + (x * 4);
        case NorthEast: (y * -4) + (x * -4);
    }
}

function makeGrid<T> (width:Int, height:Int, initialValue:T):Grid<T> {
    return {
        width: width,
        height: height,
        items: [for (i in 0...(width * height)) initialValue],
    }
}

function forEachGI<T> (grid:Grid<T>, callback:(x:Int, y:Int, item:T) -> Void) {
    for (x in 0...grid.width) {
        for (y in 0...grid.height) {
            callback(x, y, grid.items[x + y * grid.width]);
        }
    }
}

function mapGIItems<T, TT> (grid:Grid<T>, callback:(x:Int, y:Int, item:T) -> TT):Array<TT> {
    // don't know about this as it requires a cast
    // if (callback == null) {
    //     callback = (x:Int, y:Int, item:T) -> { return cast(item); };
    // }

    final items = [];
    // TODO: flip
    for (x in 0...grid.width) {
        for (y in 0...grid.height) {
            items.push(callback(x, y, grid.items[x + y * grid.width]));
        }
    }
    return items;
}

function getGridItem<T> (grid:Grid<T>, x:Int, y:Int):Null<T> {
    if (x < 0 || y < 0 || x >= grid.width || y >= grid.height) {
        return null;
    }

    return grid.items[x + y * grid.width];
}

function getDirFromDiff (diffX:Int, diffY:Int):RotationDir {
    if (diffX == 1 && diffY == 0) return NorthEast;
    if (diffX == 0 && diffY == -1) return NorthWest;
    if (diffX == 0 && diffY == 1) return SouthEast;
    if (diffX == -1 && diffY == 0) return SouthWest;
    throw 'Dir not found';
}
