package game.world;

import core.Types.IntVec2;
import game.util.Pathfind.Manhattan;
import game.util.Pathfind.pathfind;
import game.util.TimeUtil as Time;
import game.util.TimeUtil;
import game.world.Grid;

enum ActorState {
  Sell;
  Break;
  Talk;
  Think;
  Move;
}

enum ActorGoal {
    Work;
    Break;
    Home;
}

enum ActorLocation {
  PreWork;
  AtWork;
  PostWork;
}

enum TileItem {
    Entrance;
    Exit;
    Tile;
}

enum EventType {
    Arrive;
    Leave;
}

typedef Event = {
    var type:EventType;
    var actor:Actor;
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

    // dynamic vals
    public var state:Null<ActorState>;
    public var stateTime:Int = 0;
    public var move:Null<Move>;
    public var path:Array<IntVec2> = [];

    public var location:ActorLocation = PreWork;

    public var arriveTime:Int;
    
    public function new (name:String) {
        this.name = name;
        id = curId++;
    }

    public function startDay () {
        // reset daily values

        arriveTime = Math.floor(TimeUtil.hours(3) + Math.random() * TimeUtil.hours(2)); 
    }
}

class World {
    public var grid:Grid<Int>;

    public var actors:Array<Actor> = [];

    public var tiles:Grid<TileItem>;

    public var time:Int;
    public var day:Int = -1;

    public var events:Array<Event> = [];

    public function new () {
        grid = makeGrid(25, 25, 0);
        for (_ in 0...3) {
            actors.push(new Actor('test${Actor.curId}'));
        }
        newDay();
    }

    public function step () {
        time++;

        // check to see if an actor has arrived
        for (a in actors) {
            if (a.location == PreWork) {
                if (a.arriveTime == this.time) {
                    // trace('arrive');
                       a.location = AtWork;
                    // a.stateTime = 0;

                    a.path = pathfind(makeGrid(grid.width, grid.height, 1), new IntVec2(12, 0), new IntVec2(16, 18), Manhattan);
                    trace(a.path);
                }
            }

            // addEvent(Arrive, a);
        }

        // handle actor movement
        for (a in actors) {
            if (a.state == Move) {
                handleCurrentMove(a);
            }
        }

        for (a in actors) {
            if (a.location != AtWork || a.state == Move) continue;
            a.stateTime--;

            if (a.stateTime == 0) {
                if (a.arriveTime + Time.hours(8) > time && time > Time.FIVE_PM) {
                    goHome(a);
                }
            }

#if debug
            if (a.stateTime < 0) {
                throw 'Illegal `stateTime`';
            }
#end
        }




            // decide next action/state if we are done with a state
            // do the action
    }

    public function newDay () {
        day++;
        // TEMP: start at 8 AM (time starts at 5 am)
        time = Time.hours(4);

        // reset daily values
        for (a in actors) {
            a.startDay();
        }
    }

    function handleCurrentMove (actor:Actor) {

    }

    function goHome (actor:Actor) {
        trace('going home!');
    }

    function addEvent (type:EventType, actor:Actor) {
        events.push({ type: type, actor: actor });
    }

    public function getEvents () {
        final rEvents = events.copy();
        events.resize(0);
        return rEvents;
    }
}
