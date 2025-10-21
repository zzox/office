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
    var worldRotation:RotationDir = SouthEast;

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

        // making tilemap gives us the max and min positions of the tilemap,
        // we can use the center to start in the center of the map.
        makeTilemap();
        camera.scrollX = (minX + maxX) / 2 - camera.width / 2;
        camera.scrollY = (minY + maxY) / 2 - camera.height / 2;
        trace(minX, minY, maxX, maxY);

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

        if (Game.keys.justPressed(KeyCode.OpenBracket)) {
            rotateLeft();
        }

        if (Game.keys.justPressed(KeyCode.CloseBracket)) {
            rotateRight();
        }

        var steps = 1;
        if (Game.keys.pressed(KeyCode.J)) {
            steps += 256;
        } else if (Game.keys.pressed(KeyCode.H)) {
            steps += 64;
        } else if (Game.keys.pressed(KeyCode.G)) {
            steps += 16;
        } else if (Game.keys.pressed(KeyCode.F)) {
            steps += 3;
        }

        uiScene.setMiddleText('${Game.mouse.position.x},${Game.mouse.position.y}', 1.0);
        // uiScene.setMiddleText('${camCenterX()} ${camCenterY()} ${minX} ${minY} ${maxX} ${maxY}', 1.0);

        if (Game.keys.justPressed(KeyCode.HyphenMinus)) {
            zoomOut();
        }

        if (Game.keys.justPressed(KeyCode.Equals)) {
            zoomIn();
        }

        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
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

        g2.drawImage(tilemap, minX, minY);

        final charXDiff = 0;
        final charYDiff = 24;

        final actors = world.actors.copy();

        actors.sort((a, b) -> {
            return Std.int(translateWorldY(a.x, a.y, SouthEast)) - Std.int(translateWorldY(b.x, b.y, SouthEast));
        });

        // tile size here
        final sizeX = 16;
        final sizeY = 32;

        final image = Assets.images.char;

        for (i in 0...actors.length) {
            final actor = actors[i];

            // render shadow
            g2.color = 0x80 * 0x1000000 + 0xffffff;
            var tileIndex = 6;
            final cols = Std.int(image.width / sizeX);
            g2.drawScaledSubImage(
                image,
                (tileIndex % cols) * sizeX, Math.floor(tileIndex / cols) * sizeY, sizeX, sizeY,
                translateWorldX(actor.x, actor.y, worldRotation) - charXDiff,
                translateWorldY(actor.x, actor.y, worldRotation) - charYDiff,
                sizeX, sizeY
            );

            // figure facing
            final facingDir = calculateFacing(actor.facing, worldRotation);

            // render actor
            g2.color = 0xff * 0x1000000 + 0xffffff;
            var flipX = false;
            if (actor.move != null) {
                // can the fifth index happen?                                                             vvv
                tileIndex = (facingDir == NorthEast || facingDir == NorthWest ? 3 : 0) + [1, 0, 2, 0, 0][Math.floor(actor.move.elapsed / actor.move.time * 4)];
                flipX = facingDir == NorthWest || facingDir == SouthWest;
            } else {
                tileIndex = 0;
            }
            g2.drawScaledSubImage(
                image,
                (tileIndex % cols) * sizeX, Math.floor(tileIndex / cols) * sizeY, sizeX, sizeY,
                translateWorldX(actor.x, actor.y, worldRotation) - charXDiff + (flipX ? sizeX : 0),
                translateWorldY(actor.x, actor.y, worldRotation) - charYDiff,
                sizeX * (flipX ? -1 : 1), sizeY
            );
        }

        g2.popTransformation();
        g2.popTransformation();

        g2.end();

        super.render(g2, false);
    }

    function rotateLeft () {
        var num = (worldRotation - 1) % 4;
        if (num < 0) num += 4;
        worldRotation = cast(num);
        makeTilemap();
    }

    function rotateRight () {
        worldRotation = cast((worldRotation + 1) % 4);
        makeTilemap();
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
        ArraySort.sort(items, (a, b) -> Std.int(translateWorldY(a.x, a.y, worldRotation)) - Std.int(translateWorldY(b.x, b.y, worldRotation)));

        // there's a more mathematical way to do this, but looping through all works
        minX = 0;
        minY = 0;
        maxX = 0;
        maxY = 0;
        for (i in items) {
            minX = Std.int(Math.min(minX, translateWorldX(i.x, i.y, worldRotation)));
            minY = Std.int(Math.min(minY, translateWorldY(i.x, i.y, worldRotation)));
            maxX = Std.int(Math.max(maxX, translateWorldX(i.x, i.y, worldRotation) + TILE_WIDTH));
            maxY = Std.int(Math.max(maxY, translateWorldY(i.x, i.y, worldRotation) + TILE_HEIGHT));
        }

        tilemap = Image.createRenderTarget(maxX - minX, maxY - minY);

        tilemap.g2.begin(true, 0x00000000);

        for (i in 0...items.length) {
            tilemap.g2.drawSubImage(Assets.images.tiles,
                translateWorldX(items[i].x, items[i].y, worldRotation) - minX,
                translateWorldY(items[i].x, items[i].y, worldRotation) - minY,
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

    inline function camCenterX () return camera.scrollX + (camera.width / 2) / camera.scale;
    inline function camCenterY () return camera.scrollY + (camera.height / 2) / camera.scale;
}
