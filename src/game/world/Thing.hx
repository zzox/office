package game.world;

import game.world.Grid.RotationDir;

enum ThingType {
    PhoneDesk;
}

typedef ThingData = {
    var pieces:Array<Null<PieceType>>;
}

final thingData:Map<ThingType, ThingData> = [
    PhoneDesk => {
        pieces: [null, null, null, EntranceSpot, Chair, EntranceSpot, null, Phone, null]
    }
];

function makePiecesGrid(type:ThingType):Grid<Null<PieceType>> {
    final pieces = thingData.get(type).pieces;
    return {
        height: Std.int(Math.sqrt(pieces.length)),
        width: Std.int(Math.sqrt(pieces.length)),
        items: pieces.copy()
    }
}

function getEntranceSpots (thing:Thing):Array<Piece> {
    return thing.pieces.filter(p -> p.type == EntranceSpot);
}

enum PieceType {
    Phone;
    Chair;
    EntranceSpot;
}

// one or more pieces. an inanimate object.
class Thing {
    public var actor:Null<Actor>;
    public var pieces:Array<Piece> = [];
    public var type:ThingType;
    public var useItem:Piece;

    public function new (type:ThingType) {
        this.type = type;
    }
}

// part of a thing
class Piece {
    public var x:Int;
    public var y:Int;

    public var parent:Thing;
    public var type:PieceType;
    public var rotation:RotationDir;

    public function new (x:Int, y:Int, type:PieceType, parent:Thing, rotation:RotationDir) {
        this.x = x;
        this.y = y;

        this.type = type;
        this.parent = parent;
        this.rotation = rotation;
    }
}
