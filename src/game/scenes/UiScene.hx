package game.scenes;

import core.gameobjects.BitmapText;
import core.scene.Scene;
import game.ui.UiText;
import game.util.TextUtil;
import game.world.World;

class UiScene extends Scene {
    var world:World;
    var timeText:BitmapText;

    var middleTextTime:Float = 0.0;
    var middleText:BitmapText;
    var middleSubtext:BitmapText;

    public function new (world:World) {
        super();
        this.world = world;
    }

    override function create () {
        super.create();
        camera.scale = 2;
        entities.push(timeText = makeBitmapText(4, 4, ''));
        entities.push(middleText = makeBitmapText(0, 64, ''));
        entities.push(middleSubtext = makeBitmapText(0, 80, ''));
    }

    override function update (delta:Float) {
        super.update(delta);

        timeText.setText(TextUtil.formatTime(world.time));
        middleTextTime -= delta;
        middleText.setPosition(Math.floor(((camera.width - middleText.textWidth) / 2) / 2), middleText.y);
        middleText.visible = middleTextTime > 0;
    }

    public function setMiddleText (text:String, time:Float) {
        middleText.setText(text);
        middleTextTime = time;
    }
}
