package game.world;

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

enum PieceType {
    Phone;
    Chair;
    EntranceSpot;
}

// one or more pieces. an inanimate object.
class Thing {
    var actor:Null<Actor>;
    var pieces:Array<Piece>;

    public function new (type:ThingType) {}
}

// part of a thing
class Piece {
    public var x:Int;
    public var y:Int;

    public var parent:Thing;
    public var type:PieceType;

    public function new (x:Int, y:Int, type:PieceType, parent:Thing) {
        this.x = x;
        this.y = y;

        this.type = type;
        this.parent = parent;
    }
}
