package game.scenes;

import core.Game;
import core.gameobjects.BitmapText;
import core.scene.Scene;
import game.ui.UiText;
import game.util.TextUtil;
import game.world.Grid;
import game.world.World;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

class GameScene extends Scene {
    var world:World;

    var timeText:BitmapText;

    var zoom:Int = 0;

    override function create () {
        super.create();

        world = new World();

        new UiText();

        entities.push(timeText = makeBitmapText(4, 4, ''));
    }

    override function update (delta:Float) {
        if (Game.keys.justPressed(KeyCode.HyphenMinus)) {
            zoomOut();
        }

        if (Game.keys.justPressed(KeyCode.Equals)) {
            zoomIn();
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

        var steps = 1;
        if (Game.keys.pressed(KeyCode.H)) {
            steps += 15;
        } else if (Game.keys.pressed(KeyCode.G)) {
            steps += 7;
        } else if (Game.keys.pressed(KeyCode.F)) {
            steps += 3;
        }

        for (_ in 0...steps) {
            world.step();
        }

        timeText.setText(TextUtil.formatTime(world.time));

        super.update(delta);
    }

    override function render (g2:Graphics, clears:Bool) {
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

        for (i in 0...world.actors.length) {
            g2.drawImage(Assets.images.char_test, translateWorldX(world.actors[i].x, world.actors[i].y, SouthEast), translateWorldY(world.actors[i].x, world.actors[i].y, SouthEast));
        }

        g2.popTransformation();
        g2.popTransformation();

        g2.end();

        super.render(g2, false);
    }

    public function zoomIn () {
        zoom++;
        if (zoom > 3) {
            zoom = 3;
            return;
        }

        final scale = Math.pow(2, zoom);

        camera.scale = scale;
        camera.scrollX += (1 / camera.scale) * (camera.width / 2);
        camera.scrollY += (1 / camera.scale) * (camera.height / 2);
    }

    public function zoomOut () {
        zoom--;
        if (zoom < 0) {
            zoom = 0;
            return;
        }

        final scale = Math.pow(2, zoom);

        camera.scrollX -= (1 / camera.scale) * (camera.width / 2);
        camera.scrollY -= (1 / camera.scale) * (camera.height / 2);
        camera.scale = scale;
    }
}
