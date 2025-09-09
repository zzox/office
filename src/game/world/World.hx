package game.world;

import core.Types.IntVec2;
import core.util.Util;
import game.util.Pathfind;
import game.util.TimeUtil as Time;
import game.world.Grid;

enum ActorState {
    Wait;
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

function calcPosition (moveFrom:Int, moveTo:Int, percentMoved:Float):Float {
    return moveFrom + (moveTo - moveFrom) * percentMoved;
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
    public var state:Null<ActorState>;
    public var stateTime:Int = 0;
    public var move:Null<Move>;
    public var path:Array<IntVec2> = [];

    public var location:ActorLocation = PreWork;

    public var arriveTime:Int;
    
    public function new (name:String) {
        this.name = name;
        id = curId++;
        speed = 4000 + Math.floor(Math.random() * 6000);
    }

    public function startDay () {
        // reset daily values

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
}

class World {
    public var grid:Grid<Int>;

    public var actors:Array<Actor> = [];

    public var tiles:Grid<TileItem>;

    var entrance:IntVec2;
    var exit:IntVec2;

    public var time:Int;
    public var day:Int = -1;

    public var events:Array<Event> = [];

    public function new () {
        entrance = new IntVec2(12, 0);
        exit = new IntVec2(14, 0);

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
                    arrive(a);
                    tryMoveActor(a);
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
                    break;
                }

                if (a.state == Wait) {
                    tryMoveActor(a);
                }
            }

#if world_debug
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
        time = Time.hours(3);

        // reset daily values
        for (a in actors) {
            a.startDay();
        }
    }

    function arrive (actor:Actor) {
        actor.location = AtWork;
        actor.x = entrance.x;
        actor.y = entrance.y;
    }

    function tryMoveActor (actor:Actor) {
#if world_debug
        if (actor.getX() % 1.0 != 0.0 || actor.getY() % 1.0 != 0.0) {
            throw 'Should not move from uneven spots';
        }
#end
        final path = pathfind(makeGrid(grid.width, grid.height, 1), new IntVec2(actor.getX(), actor.getY()), new IntVec2(randomInt(grid.width), randomInt(grid.height)), Manhattan);
        if (path != null) {
            actor.path = clonePath(path);
            actor.state = Move;
        }
    }

    inline function clonePath (path:Array<IntVec2>) {
        return [for (p in path) new IntVec2(p.x, p.y)];
    }

    function handleCurrentMove (actor:Actor) {
        if (actor.move != null) {
            actor.move.elapsed++;
            actor.x = calcPosition(actor.move.fromX, actor.move.toX, actor.move.elapsed / actor.move.time);
            actor.y = calcPosition(actor.move.fromY, actor.move.toY, actor.move.elapsed / actor.move.time);
            if (actor.move.elapsed == actor.move.time) {
                actor.move = null;
            }
        }

        // skip collision/state checks if the move is still going
        if (actor.move != null) return;

        if (actor.path[0] != null) {
            if (!checkCollision(actor.path[0].x, actor.path[0].y)) {
                final item = actor.path.shift();
                actor.move = {
                    fromX: actor.getX(),
                    fromY: actor.getY(),
                    toX: item.x,
                    toY: item.y,
                    elapsed: 0,
                    time: Math.round(100000 / actor.speed)
                }
            } else {
                wait(actor, Time.MINUTE);
            }
        } else {
            wait(actor, 1);
        }
    }

    // returns true if there is a collision at this position
    function checkCollision (x:Int, y:Int):Bool {
        for (i in 0...actors.length) {
            if (actors[i].getX() == x && actors[i].getY() == y) {
                return true;
            }
        }

        return false;
    }

    inline function wait (actor:Actor, time:Int) {
        actor.state = Wait;
        actor.stateTime = time;
    }

    inline function goHome (actor:Actor) {
        trace('going home!');
    }

    inline function addEvent (type:EventType, actor:Actor) {
        events.push({ type: type, actor: actor });
    }

    public function getEvents () {
        final rEvents = events.copy();
        events.resize(0);
        return rEvents;
    }
}
