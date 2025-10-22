package game.scenes;

import core.Game;
import core.gameobjects.BitmapText;
import core.scene.Scene;
import game.ui.UiText;
import game.util.Utils;
import game.world.Grid;
import game.world.World;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.Image;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.math.FastMatrix2;
import kha.math.FastVector2;

final TILE_WIDTH = 16;
final TILE_HEIGHT = 8;

typedef RenderItem = {
    var x:Float;
    var y:Float;
    var tileIndex:Int;
    var shadow:Bool;
    var flipX:Bool;
}

class GameScene extends Scene {
    var world:World;
    var uiScene:UiScene;
    var zoom:Int = 0;
    var tilemap:Image;
    var worldActive:Bool = false;
    var worldRotation:RotationDir = SouthEast;

    var numbers:Array<BitmapText> = [];

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

        for (_ in 0...20) {
            final number = makeSmallText(-16, -16, '');
            number.color = 0x6cd947;
            numbers.push(number);
        }
    }

    override function update (delta:Float) {
        handleCamera();

        // TODO: move into method
        final screenPosX = camera.scrollX + Game.mouse.position.x / camera.scale;
        final screenPosY = camera.scrollY + Game.mouse.position.y / camera.scale;
        uiScene.devTexts[0].setText('${Game.mouse.position.x},${Game.mouse.position.y}, ${screenPosX},${screenPosY}');

        final tilePosAt = getTilePosAt(screenPosX, screenPosY, worldRotation, world.grid.width, world.grid.height);
        uiScene.devTexts[1].setText('${tilePosAt.x},${tilePosAt.y}');
        // uiScene.setMiddleText('${camCenterX()} ${camCenterY()} ${minX} ${minY} ${maxX} ${maxY}', 1.0);

        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
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

        for (n in numbers) {
            n.y--;
        }

        for (ev in world.getEvents()) {
            if (ev.type == Temp) {
                makeNumber(
                    Math.floor(translateWorldX(ev.actor.x, ev.actor.y, worldRotation) + 8),
                    Math.floor(translateWorldY(ev.actor.x, ev.actor.y, worldRotation) - 16),
                    Math.floor(Math.random() * 1000)
                );
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

        var renderItems:Array<RenderItem> = world.actors.map(actor -> {
            var tileIndex = 0;
            var flipX = false;

            // figure facing
            final facingDir = calculateFacing(actor.facing, worldRotation);

            if (actor.move != null) {
                // can the fifth index happen?                                                             vvv
                tileIndex = (facingDir == NorthEast || facingDir == NorthWest ? 3 : 0) + [1, 0, 2, 0, 0][Math.floor(actor.move.elapsed / actor.move.time * 4)];
                flipX = facingDir == NorthWest || facingDir == SouthWest;
            } else {
                tileIndex = 0;
            }
            return {
                x: translateWorldX(actor.x, actor.y, worldRotation) - charXDiff,
                y: translateWorldY(actor.x, actor.y, worldRotation) - charYDiff,
                tileIndex: tileIndex,
                flipX: flipX,
                shadow: true,
            }
        });

        renderItems = renderItems.concat(world.thingPieces.map(p -> {
            var tileIndex = 0;
            if (p.type == Phone) {
                tileIndex = 7 + worldRotation;
            } else if (p.type == Chair) {
                tileIndex = 11 + worldRotation;
            }

            return {
                x: translateWorldX(p.x, p.y, worldRotation) - charXDiff,
                y: translateWorldY(p.x, p.y, worldRotation) - charYDiff,
                tileIndex: tileIndex,
                flipX: false,
                shadow: false,
            }
        }));

        renderItems.sort((a, b) -> {
            return Std.int(a.y) - Std.int(b.y);
        });

        // tile size here
        final sizeX = 16;
        final sizeY = 32;

        final image = Assets.images.char;

        for (i in 0...renderItems.length) {
            final item = renderItems[i];

            final cols = Std.int(image.width / sizeX);
            // render shadow
            if (item.shadow) {
                g2.color = 0x80 * 0x1000000 + 0xffffff;
                var tileIndex = 6;
                g2.drawScaledSubImage(
                    image,
                    (tileIndex % cols) * sizeX, Math.floor(tileIndex / cols) * sizeY, sizeX, sizeY,
                    item.x, item.y,
                    // translateWorldX(item.x, item.y, worldRotation) - charXDiff,
                    // translateWorldY(item.x, item.y, worldRotation) - charYDiff,
                    sizeX, sizeY
                );
            }

            // render actor
            g2.color = 0xff * 0x1000000 + 0xffffff;
            g2.drawScaledSubImage(
                image,
                (item.tileIndex % cols) * sizeX, Math.floor(item.tileIndex / cols) * sizeY, sizeX, sizeY,
                item.x + (item.flipX ? sizeX : 0), item.y,
                // translateWorldX(item.x, item.y, worldRotation) - charXDiff + (flipX ? sizeX : 0),
                // translateWorldY(item.x, item.y, worldRotation) - charYDiff,
                sizeX * (item.flipX ? -1 : 1), sizeY
            );
        }

        // TODO: adjust this scale nonsenese
        // TODO: particle class that is tied to an x and z position, y position is tied to time
        // final scale = camera.scale;
        // camera.scale = 1;
        // for (n in numbers) if (n.visible) n.render(g2, camera);
        // camera.scale = scale;

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

    var numIndex = -1;
    function makeNumber (x:Int, y:Int, amount:Int) {
        final num = numbers[(++numIndex % numbers.length)];

        num.setText(amount + '');
        num.x = Math.floor(x - num.textWidth / 2);
        num.y = y;
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

        final sizeX = 16;
        final sizeY = 16;

        final image = Assets.images.tiles;
        final cols = Std.int(image.width / sizeX);
        for (i in 0...items.length) {
            var tileIndex = 0;
            if (items[i].item == Entrance) {
                tileIndex = 1;
            } else if (items[i].item == Exit) {
                tileIndex = 2;
            }

            tilemap.g2.drawSubImage(
                image,
                translateWorldX(items[i].x, items[i].y, worldRotation) - minX,
                translateWorldY(items[i].x, items[i].y, worldRotation) - minY,
                (tileIndex % cols) * sizeX, Math.floor(tileIndex / cols) * sizeY, sizeX, sizeY
            );
        }

        tilemap.g2.end();
    }

    inline function handleCamera () {
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

        if (Game.keys.justPressed(KeyCode.HyphenMinus)) {
            zoomOut();
        }

        if (Game.keys.justPressed(KeyCode.Equals)) {
            zoomIn();
        }
    }

    function rotateLeft () {
        var num = (worldRotation - 1) % 4;
        if (num < 0) num += 4;
        worldRotation = cast(num);
        makeTilemap();
        final matrix = FastMatrix2.rotation(-Math.PI / 2);
        final tilePos = getTilePosAt(camCenterX(), camCenterY(), worldRotation, world.grid.width, world.grid.height);
        final ans = matrix.multvec(new FastVector2(tilePos.x, tilePos.y));
        camera.scrollX = translateWorldX(ans.x, ans.y, worldRotation) - (camera.width / 2) / camera.scale;
        camera.scrollY = translateWorldY(ans.x, ans.y, worldRotation) - (camera.height / 2) / camera.scale;
    }

    function rotateRight () {
        worldRotation = cast((worldRotation + 1) % 4);
        makeTilemap();
        final matrix = FastMatrix2.rotation(Math.PI / 2);
        final tilePos = getTilePosAt(camCenterX(), camCenterY(), worldRotation, world.grid.width, world.grid.height);
        final ans = matrix.multvec(new FastVector2(tilePos.x, tilePos.y));
        camera.scrollX = translateWorldX(ans.x, ans.y, worldRotation) - (camera.width / 2) / camera.scale;
        camera.scrollY = translateWorldY(ans.x, ans.y, worldRotation) - (camera.height / 2) / camera.scale;
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
