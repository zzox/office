package game.scenes;

import core.gameobjects.BitmapText;
import core.scene.Scene;
import game.ui.UiText;
import game.util.TextUtil;
import game.world.World;

class UiScene extends Scene {
    var world:World;
    var timeText:BitmapText;

    public function new (world:World) {
        super();
        this.world = world;
    }

    override function create () {
        super.create();
        entities.push(timeText = makeBitmapText(4, 4, ''));
        camera.scale = 2;
    }

    override function update (delta:Float) {
        super.update(delta);
        timeText.setText(TextUtil.formatTime(world.time));
    }
}
