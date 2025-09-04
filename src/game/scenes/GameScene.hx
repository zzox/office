package game.scenes;

import core.Game;
import core.scene.Scene;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.Window;
import kha.input.KeyCode;

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
    for (x in 0...grid.width) {
        for (y in 0...grid.height) {
            items.push(callback(x, y, grid.items[x + y * grid.width]));
        }
    }
    return items;
}

class GameScene extends Scene {
    var grid:Grid<Int>;
    override function create () {
        super.create();

        grid = makeGrid(25, 25, 0);
    }

    override function update (delta:Float) {
        if (Game.keys.justPressed(KeyCode.HyphenMinus)) {
            camera.scale /= 2.0;
        }

        if (Game.keys.justPressed(KeyCode.Equals)) {
            camera.scale *= 2.0;
        }

        final num = Game.keys.pressed(KeyCode.Shift) ? 4.0 : 1.0;
        if (Game.keys.pressed(KeyCode.Left)) {
            camera.scrollX -= num;
        }
        if (Game.keys.pressed(KeyCode.Right)) {
            camera.scrollX += num;
        }
        if (Game.keys.pressed(KeyCode.Up)) {
            camera.scrollY -= num;
        }
        if (Game.keys.pressed(KeyCode.Down)) {
            camera.scrollY += num;
        }

        super.update(delta);
    }

    override function render (g2, cam) {
        super.render(g2, cam);

        // PERF: only do this on rotation
        final items = mapGIItems(grid, (x, y, item) -> { return { item: item, x: x, y: y } });
        ArraySort.sort(items, (a, b) -> Std.int(translateWorldY(a.x, a.y, SouthEast)) - Std.int(translateWorldY(b.x, b.y, SouthEast)));

        g2.begin(true, camera.bgColor);

        // g2.color = Math.floor(alpha * 256) * 0x1000000 + color;
        g2.color = 256 * 0x1000000 + 0xffffffff;

        g2.pushTranslation(-camera.scrollX, -camera.scrollY);
        g2.pushScale(camera.scale, camera.scale);

        for (i in 0...items.length) {
            g2.drawSubImage(Assets.images.tiles, translateWorldX(items[i].x, items[i].y, SouthEast), translateWorldY(items[i].x, items[i].y, SouthEast),
                0, 0, 16, 16
            );
        }

        g2.popTransformation();
        g2.popTransformation();

        g2.end();
    }
}
