package game.scenes;

import core.Game;
import core.scene.Scene;
import game.ui.UiText;
import game.world.Grid;
import game.world.World;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.Image;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final TILE_WIDTH = 16;
final TILE_HEIGHT = 8;

class GameScene extends Scene {
    var world:World;
    var uiScene:UiScene;
    var zoom:Int = 1;
    var tilemap:Image;

    var minX:Int = 0;
    var minY:Int = 0;

    override function create () {
        super.create();

        // WARN: should go in first scene in the game to initialize these items
        new UiText();

        world = new World();

        uiScene = new UiScene(world);

        game.addScene(uiScene);

        makeTilemap();
    }

    override function update (delta:Float) {
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

        if (Game.keys.justPressed(KeyCode.HyphenMinus)) {
            zoomOut();
        }

        if (Game.keys.justPressed(KeyCode.Equals)) {
            zoomIn();
        }

        for (_ in 0...steps) {
            world.step();
        }

        super.update(delta);
    }

    function makeTilemap () {
        final items = mapGIItems(world.grid, (x, y, item) -> { return { item: item, x: x, y: y } });
        ArraySort.sort(items, (a, b) -> Std.int(translateWorldY(a.x, a.y, SouthEast)) - Std.int(translateWorldY(b.x, b.y, SouthEast)));

        // there's a more mathematical way to do this, but looping through all works
        minX = 0;
        minY = 0;
        var maxX = 0;
        var maxY = 0;
        for (i in items) {
            minX = Std.int(Math.min(minX, translateWorldX(i.x, i.y, SouthEast)));
            minY = Std.int(Math.min(minY, translateWorldY(i.x, i.y, SouthEast)));
            maxX = Std.int(Math.max(translateWorldX(i.x, i.y, SouthEast) + TILE_WIDTH, maxX));
            maxY = Std.int(Math.max(translateWorldY(i.x, i.y, SouthEast) + TILE_WIDTH, maxY));
        }

        tilemap = Image.createRenderTarget(maxX - minX, maxY - minY);

        tilemap.g2.begin(true, 0x00000000);

        for (i in 0...items.length) {
            tilemap.g2.drawSubImage(Assets.images.tiles,
                translateWorldX(items[i].x, items[i].y, SouthEast) - minX,
                translateWorldY(items[i].x, items[i].y, SouthEast) - minY,
                0, 0, 16, 16
            );
        }

        tilemap.g2.end();
    }

    override function render (g2:Graphics, clears:Bool) {
        // PERF: only do this on rotation instead of on every frame, preferably
        // rendering to a single image
        g2.begin(true, camera.bgColor);

        // g2.color = Math.floor(alpha * 256) * 0x1000000 + color;
        g2.color = 256 * 0x1000000 + 0xffffffff;

        g2.pushTranslation(-camera.scrollX, -camera.scrollY);
        g2.pushScale(camera.scale, camera.scale);

        g2.drawImage(tilemap, 0, 0);

        for (i in 0...world.actors.length) {
            g2.drawImage(Assets.images.char_test, translateWorldX(world.actors[i].x, world.actors[i].y, SouthEast) - minX, translateWorldY(world.actors[i].x, world.actors[i].y, SouthEast) - minY);
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
