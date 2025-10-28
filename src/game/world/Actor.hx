package game.world;

import core.Types;
import game.data.Leads.LeadTier;
import game.util.TimeUtil as Time;
import game.world.Grid.RotationDir;

enum ActorState {
    None; // ready for our task.
    Wait; // waiting, usually when a path is blocked
    Move;
    Sell;
    // Break;
    // Talk;
    // Think;
}

// what the actor wants to do
enum ActorGoal {
    Work;
    Break;
    Leave;
}

// whether the actor is at work or not, also if they've been in that day
enum ActorLocale {
    PreWork;
    AtWork;
    PostWork;
}

enum ActorPlacement {
    None;
    Desk;
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
    public var skill:Float;

    // dynamic vals
    public var x:Float = -16.0;
    public var y:Float = -16.0;
    public var facing:RotationDir = SouthEast;
    public var state:ActorState = None;
    public var stateTime:Int = 0;
    public var move:Null<Move>;
    public var path:Array<IntVec2> = [];
    public var goal:ActorGoal = Work;
    public var locale:ActorLocale = PreWork;
    public var placement:ActorPlacement = None;

    public var salary:Int;

    public var desk:Null<Thing>;
    // sales stuff
    public var lead:Null<LeadTier>;
    public var salesAttempts:Int = 0;
    public var salesSuccess:Int = 0;

    public var arriveTime:Int;

    public function new (name:String) {
        this.name = name;
        id = curId++;
        // max is 10000?
        speed = 2000 + Math.floor(Math.random() * 4000);
        skill = 0.2 + Math.random() * 0.8;
        salary = 100 + Math.floor(Math.random() * 25);
    }

    public function startDay () {
        // reset daily values
        state = None;
        locale = PreWork;
        goal = Work;
        placement = None;
        arriveTime = Math.floor(Time.hours(3) + Math.random() * Time.hours(2));
    }

    public function assignDesk (desk:Thing) {
        if (desk.type != PhoneDesk) {
            throw 'Not a desk!';
        }
        this.desk = desk;
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
