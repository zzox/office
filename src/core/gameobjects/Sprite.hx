package core.gameobjects;

import core.components.FrameAnim;
import core.system.Camera;
import kha.Image;
import kha.graphics2.Graphics;

// a selection of an image. not rotatable or scalable (presently)
class Sprite extends GameObject {

    public var tileIndex:Int = 0;
    public var flipX:Bool = false;
    public var flipY:Bool = false;

    public var image:Image;

    public var anim:FrameAnim;

    var animIndex:Int = -1;

    public function new (x:Float = 0.0, y:Float = 0.0, image:Image, ?sizeX:Int, ?sizeY:Int) {
        this.x = x;
        this.y = y;
        this.sizeX = sizeX ?? image.width;
        this.sizeY = sizeY ?? image.height;
        this.image = image;
    }

    public function init (?anim:FrameAnim/*, ?physics:FrameAnim*/) {
        this.anim = anim;

        if (anim != null) {
            anim.sprite = this;
        }
    }

    override function update (delta:Float) {}

    override function render (g2:Graphics, camera:Camera) {
        g2.pushTranslation(-camera.scrollX * scrollFactorX, -camera.scrollY * scrollFactorY);

        // draw a cutout of the spritesheet based on the tileindex
        final cols = Std.int(image.width / sizeX);
        g2.drawScaledSubImage(
            image,
            (tileIndex % cols) * sizeX,
            Math.floor(tileIndex / cols) * sizeY,
            sizeX,
            sizeY,
            Math.floor(x + (flipX ? sizeX : 0)),
            Math.floor(y + (flipY ? sizeY : 0)),
            sizeX * (flipX ? -1 : 1),
            sizeY * (flipY ? -1 : 1)
        );

        g2.popTransformation();
    }
}
