package game.sprites;

import core.gameobjects.BitmapText;
import game.ui.UiText;
import game.world.Grid;
import kha.Assets;

class Particle extends BitmapText {
    static inline final MAX_TIME:Float = 3.0;
    var time:Float;
    var worldX:Float;
    var worldY:Float;
    public var rotation:RotationDir;

    public function new () {
        super(-16, -16, Assets.images.cards_text_outline, UiText.smallFont, '');
    }

    public function show (x:Float, y:Float) {
        time = 0.0;
        this.worldX = x;
        this.worldY = y;
        visible = true;
        color = 0x6cd947;
    }

    override function update (delta:Float) {
        time += delta;
        if (time > MAX_TIME) {
            visible = false;
        }

        x = Math.floor(translateWorldX(worldX, worldY, rotation));
        y = Math.floor(translateWorldY(worldX, worldY, rotation) - time * 15);
    }
}
