package game.world;

import core.Types;
import game.util.TimeUtil as Time;

enum ActorState {
    None;
    Wait;
    Move;
    Sell;
    Break;
    Talk;
    Think;
}

// what the actor wants to do
enum ActorGoal {
    Work;
    Break;
    Leave;
}

// TODO: better naming?
enum ActorLocation {
    PreWork;
    AtWork;
    PostWork;
}

typedef Move = {
    var fromX:Int;
    var fromY:Int;
    var toX:Int;
    var toY:Int;
    var time:Int;
    var elapsed:Int;
}

class Actor {
    public static var curId:Int = 0;
    // static vals
    public final id:Int;
    public final name:String;

    // 0-10000 stats
    public final speed:Int = 5000; // 20 frames a square

    // dynamic vals
    public var x:Float = -16.0;
    public var y:Float = -16.0;
    public var state:ActorState = Wait;
    public var stateTime:Int = 0;
    public var move:Null<Move>;
    public var path:Array<IntVec2> = [];

    public var goal:ActorGoal = Work;
    public var location:ActorLocation = PreWork;

    public var arriveTime:Int;
    
    public function new (name:String) {
        this.name = name;
        id = curId++;
        speed = 4000 + Math.floor(Math.random() * 6000);
    }

    public function startDay () {
        // reset daily values
        state = Wait;
        arriveTime = Math.floor(Time.hours(3) + Math.random() * Time.hours(2));
    }

    public inline function getX ():Int {
        if (move == null) return Std.int(x);
        return move.toX;
    }
    public inline function getY ():Int {
        if (move == null) return Std.int(y);
        return move.toY;
    }
    public inline function isAt (x:Int, y:Int):Bool {
        return this.x == x && this.y == y;
    }
}
