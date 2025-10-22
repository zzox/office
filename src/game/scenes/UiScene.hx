package game.scenes;

import core.gameobjects.BitmapText;
import core.scene.Scene;
import game.ui.UiText;
import game.util.TextUtil;
import game.world.World;

class UiScene extends Scene {
    var world:World;
    var dayText:BitmapText;
    var timeText:BitmapText;
    public var dollarText:BitmapText;

    var middleTextTime:Float = 0.0;
    var middleText:BitmapText;
    var middleSubtext:BitmapText;

    public var devTexts:Array<BitmapText> = [];

    public function new (world:World) {
        super();
        this.world = world;
    }

    override function create () {
        super.create();
        camera.scale = 2;
        entities.push(dayText = makeBitmapText(4, 4, ''));
        entities.push(timeText = makeBitmapText(4, 14, ''));
        entities.push(dollarText = makeBitmapText(camera.width, 9, ''));
        entities.push(middleText = makeBitmapText(0, 64, ''));
        entities.push(middleSubtext = makeBitmapText(0, 80, ''));

        for (i in 0...8) {
            final text = makeBitmapText(4, 100 + i * 10, '');
            entities.push(text);
            devTexts.push(text);
        }
    }

    override function update (delta:Float) {
        super.update(delta);

        dayText.setText('Day ${world.day + 1}');
        timeText.setText(TextUtil.formatTime(world.time));
        dollarText.setText('$' + world.money);
        dollarText.setPosition(Math.floor(camera.width / camera.scale - dollarText.textWidth - 8), dollarText.y);

        middleTextTime -= delta;
        middleText.setPosition(Math.floor((camera.width / camera.scale - middleText.textWidth) / 2), middleText.y);
        middleText.visible = middleTextTime > 0;
    }

    public function setMiddleText (text:String, time:Float) {
        middleText.setText(text);
        middleTextTime = time;
    }
}
