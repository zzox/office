package game.scenes;

import core.Game;
import core.scene.Scene;
import game.world.Grid;
import game.world.World;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.input.KeyCode;

class GameScene extends Scene {
    var world:World;

    override function create () {
        super.create();

        world = new World();
    }

    override function update (delta:Float) {
        world.step();

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

        // PERF: only do this on rotation instead of on every frame, preferably
        // rendering to a single image
        final items = mapGIItems(world.grid, (x, y, item) -> { return { item: item, x: x, y: y } });
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
