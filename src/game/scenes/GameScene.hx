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
    var zoom:Int = 0;
    var tilemap:Image;
    var worldActive:Bool = false;

    var minX:Int = 0;
    var minY:Int = 0;
    var maxX:Int = 0;
    var maxY:Int = 0;

    override function create () {
        super.create();

        // WARN: should go in first scene in the game to initialize these items
        new UiText();

        world = new World();

        uiScene = new UiScene(world);

        game.addScene(uiScene);

        makeTilemap();
        // making tilemap gives us the max and min positions of the tilemap,
        // we can use the center to start in the center of the map.
        // TODO: figure out why this puts the map a little too far down
        camera.scrollX = (minX + maxX) / 2 - camera.width / 2;
        camera.scrollY = (minY + maxY) / 2 - camera.height / 2;

        // we start all the way zoomed out, so zoom in once
        zoomIn();

        startDay();
    }

    override function update (delta:Float) {
        final num = Game.keys.pressed(KeyCode.Shift) ? 4.0 : 1.0;
        if (Game.keys.pressed(KeyCode.Left) && camCenterX() > minX) {
            camera.scrollX -= num;
        }
        if (Game.keys.pressed(KeyCode.Right) && camCenterX() < maxX) {
            camera.scrollX += num;
        }
        if (Game.keys.pressed(KeyCode.Up) && camCenterY() > minY) {
            camera.scrollY -= num;
        }
        if (Game.keys.pressed(KeyCode.Down) && camCenterY() < maxY) {
            camera.scrollY += num;
        }

        var steps = 1;
        if (Game.keys.pressed(KeyCode.J)) {
            steps += 64;
        } else if (Game.keys.pressed(KeyCode.H)) {
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

        if (worldActive) {
            for (_ in 0...steps) {
                worldActive = world.step();
                // break needed?
                // if (!worldActive) break;
            }

            if (!worldActive) {
                dayOver();
            }
        }

        super.update(delta);
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

        final charXDiff = 0;
        final charYDiff = 24;

        for (i in 0...world.actors.length) {
            g2.color = 128 * 0x1000000 + 0xffffffff;
            final tileIndex = 6;
            g2.drawSubImage(
                Assets.images.char,
                translateWorldX(world.actors[i].x, world.actors[i].y, SouthEast) - minX - charXDiff,
                translateWorldY(world.actors[i].x, world.actors[i].y, SouthEast) - minY - charYDiff,
                tileIndex * 16, 0, 16, 32
            );
            g2.color = 256 * 0x1000000 + 0xffffffff;
            g2.drawSubImage(
                Assets.images.char,
                translateWorldX(world.actors[i].x, world.actors[i].y, SouthEast) - minX - charXDiff,
                translateWorldY(world.actors[i].x, world.actors[i].y, SouthEast) - minY - charYDiff,
                0, 0, 16, 32
            );
        }

        g2.popTransformation();
        g2.popTransformation();

        g2.end();

        super.render(g2, false);
    }

    function startDay () {
        worldActive = true;
        world.newDay();
        uiScene.setMiddleText('Day ${world.day + 1}', 3.0);
    }

    function dayOver () {
        startDay();
    }

    function makeTilemap () {
        final items = mapGIItems(world.grid, (x, y, item) -> { return { item: item, x: x, y: y } });
        ArraySort.sort(items, (a, b) -> Std.int(translateWorldY(a.x, a.y, SouthEast)) - Std.int(translateWorldY(b.x, b.y, SouthEast)));

        // there's a more mathematical way to do this, but looping through all works
        minX = 0;
        minY = 0;
        maxX = 0;
        maxY = 0;
        for (i in items) {
            minX = Std.int(Math.min(minX, translateWorldX(i.x, i.y, SouthEast)));
            minY = Std.int(Math.min(minY, translateWorldY(i.x, i.y, SouthEast)));
            maxX = Std.int(Math.max(maxX, translateWorldX(i.x, i.y, SouthEast) + TILE_WIDTH));
            maxY = Std.int(Math.max(maxY, translateWorldY(i.x, i.y, SouthEast) + TILE_WIDTH));
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

    inline function camCenterY () return camera.scrollY + camera.height / camera.scale / 2;
    inline function camCenterX () return camera.scrollX + camera.width / camera.scale / 2;
}
