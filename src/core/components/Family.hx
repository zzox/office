package core.components;

import core.components.Component;

class Family<T:Component> {
    public var items:Array<T> = [];
    var index:Int = -1;

    public function new () {}

    public function update (delta:Float) {
        for (i in items) i.update(delta);
    }

    public function getNext ():T {
        return items[++index % items.length];
    }
}
