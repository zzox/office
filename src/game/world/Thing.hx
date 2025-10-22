package game.world;

enum ThingType {
    Desk;
}

typedef ThingData = {
    var pieces:Array<Array<Null<PieceType>>>;
}

final thingData:Map<ThingType, ThingData> = [];

enum PieceType {
    DeskPhone;
    Chair;
}

// one or more pieces. an inanimate objects.
class Thing {
    var actor:Null<Actor>;
    var pieces:Array<Piece>;
}

// part of a thing
class Piece {
    var parent:Thing;
}
