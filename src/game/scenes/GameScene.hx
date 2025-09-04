package game.scenes;

import core.Game;
import core.scene.Scene;
import kha.Assets;
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

        g2.begin(true, camera.bgColor);

        // g2.color = Math.floor(alpha * 256) * 0x1000000 + color;
        g2.color = 256 * 0x1000000 + 0xffffffff;

        g2.pushTranslation(-camera.scrollX, -camera.scrollY);
        g2.pushScale(camera.scale, camera.scale);

        forEachGI(grid, (x, y, item) -> {
            g2.drawSubImage(Assets.images.tiles, translateWorldX(x, y, SouthEast), translateWorldY(x, y, SouthEast),
                0, 0, 16, 16
            );
        });

        g2.popTransformation();
        g2.popTransformation();

        g2.end();
    }
}
