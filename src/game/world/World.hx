package game.world;

import core.Types.IntVec2;
import core.util.Util;
import game.util.Pathfind;
import game.util.TimeUtil as Time;
import game.world.Grid;
import game.world.Thing;

enum TileItem {
    Entrance;
    Exit;
    Tile;
}

enum EventType {
    Arrive;
    Leave;
    Temp;
}

typedef Event = {
    var type:EventType;
    var actor:Actor;
}

function calcPosition (moveFrom:Int, moveTo:Int, percentMoved:Float):Float {
    return moveFrom + (moveTo - moveFrom) * percentMoved;
}

class World {
    public var grid:Grid<TileItem>;
    public var actors:Array<Actor> = [];
    public var thingPieces:Array<Piece> = [];
    public var things:Array<Thing> = [];
    // public var tiles:Grid<TileItem>;

    public var entrance:IntVec2;
    public var exit:IntVec2;
    var collision:Grid<Int>;

    public var time:Int;
    public var day:Int = -1;
    public var money:Int = 0;

    public var events:Array<Event> = [];

    public function new () {
        final size = new IntVec2(12, 12);
        entrance = new IntVec2(5, 0);
        exit = new IntVec2(7, 0);

        grid = mapGI(makeGrid(size.x, size.y, Tile), (x, y, item) -> {
            if (entrance.x == x && entrance.y == y) return Entrance;
            if (exit.x == x && exit.y == y) return Exit;
            return item;
        });

        for (_ in 0...10) {
            actors.push(new Actor('test${Actor.curId}'));
        }

        collision = makeGrid(size.x, size.y, 1);

        placeThing(PhoneDesk, 0, 1, SouthEast);
        placeThing(PhoneDesk, 2, 1, SouthEast);
        placeThing(PhoneDesk, 4, 1, SouthEast);
        placeThing(PhoneDesk, 7, 1, SouthEast);
        placeThing(PhoneDesk, 9, 1, SouthEast);

        placeThing(PhoneDesk, 1, 8, SouthEast);
        placeThing(PhoneDesk, 3, 8, SouthEast);
        placeThing(PhoneDesk, 5, 8, SouthEast);
        placeThing(PhoneDesk, 7, 8, SouthEast);
        placeThing(PhoneDesk, 9, 8, SouthEast);
    }

    public function step ():Bool {
        time++;

        // update collision array
        collision.items = collision.items.map(_ -> 1);
        for (a in actors) collision.items[a.getX() + a.getY() * grid.width] = 0;
        for (p in thingPieces) collision.items[p.x + p.y * grid.width] = 0;

        // TEMP:
        if (Math.random() < 0.01) {
            money += Math.floor(Math.random() * 20);
        }

        // check to see if an actor has arrived
        for (a in actors) {
            if (a.locale == PreWork) {
                if (a.arriveTime == this.time) {
                    arrive(a);
                    tryMoveActor(a, randomInt(grid.width), randomInt(grid.height));
                }
            }
        }

        // handle actor movement
        for (a in actors) {
            if (a.state == Move) {
                handleCurrentMove(a);
            }
        }

        for (a in actors) {
            // if we're moving or not at work, don't do anything
            if (a.locale != AtWork || a.state == Move) continue;
            a.stateTime--;

            if (a.stateTime == 0) {
                if (time > a.arriveTime + Time.hours(8) && time > Time.FIVE_PM) {
                    goHome(a);
                }

                // what do we do when we're done with our task?
                if (a.state == None) {
                    if (a.goal == Leave) {
                        if (a.isAt(exit.x, exit.y)) {
                            leave(a);
                            continue;
                        }

                        tryMoveActor(a, exit.x, exit.y);
                    } else {
                        tryMoveActor(a, randomInt(grid.width), randomInt(grid.height));
                    }
                } else if (a.state == Wait) {
                    // TODO: DRY
                    if (a.goal == Leave) {
                        tryMoveActor(a, exit.x, exit.y);
                    } else {
                        tryMoveActor(a, randomInt(grid.width), randomInt(grid.height));
                    }
                }
            }

#if world_debug
            if (a.stateTime < 0) {
                trace(a.name, a.state, a.stateTime, a.goal);
                throw 'Illegal `stateTime`';
            }

            if (a.state == None) {
                trace(a.name, a.state, a.stateTime, a.goal);
                throw 'Illegal `state`';
            }
#end
        }

        // decide next action/state if we are done with a state
        // do the action

        final actorsPresent = Lambda.fold(actors, (actor:Actor, res:Int) -> {
            return res + (actor.locale == AtWork ? 1 : 0);
        }, 0);

        return !(time > Time.FIVE_PM && actorsPresent == 0);
    }

    function arrive (actor:Actor) {
        actor.locale = AtWork;
        actor.x = entrance.x;
        actor.y = entrance.y;
    }

    function leave (actor:Actor) {
        actor.locale = PostWork;
        actor.state = None;
        actor.x = -16;
        actor.y = -16;
    }

    function tryMoveActor (actor:Actor, x:Int, y:Int) {
#if world_debug
        if (actor.getX() % 1.0 != 0.0 || actor.getY() % 1.0 != 0.0) {
            throw 'Should not move from uneven spots';
        }
#end

        final path = pathfind(collision, new IntVec2(actor.getX(), actor.getY()), new IntVec2(x, y), Manhattan);
        // final path = pathfind(makeGrid(grid.width, grid.height, 1), new IntVec2(actor.getX(), actor.getY()), new IntVec2(x, y), Manhattan);
        if (path != null) {
            actor.path = clonePath(path);
            actor.state = Move;
            addEvent(Temp, actor);
        } else {
            // TODO: remove
            trace('could not find path');
        }
    }

    inline function clonePath (path:Array<IntVec2>) {
        return [for (p in path) new IntVec2(p.x, p.y)];
    }

    inline function handleCurrentMove (actor:Actor) {
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

        // TODO: check queue here, if anything urgent, we leave
        // checkQueue();

        if (actor.path[0] != null) {
            if (!checkCollision(actor.path[0].x, actor.path[0].y)) {
                final item = actor.path.shift();
                actor.facing = getDirFromDiff(item.x - actor.getX(), item.y - actor.getY());
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
            ready(actor);
        }
    }

    // returns true if there is a collision at this position
    function checkCollision (x:Int, y:Int):Bool {
        // TODO: consider making a grid that we populate with all possible collisions, then checking
        // against that. would be built once per frame.
        // for (i in 0...actors.length) {
        //     if (actors[i].getX() == x && actors[i].getY() == y) {
        //         return true;
        //     }
        // }

        // for (i in 0...thingPieces.length) {
        //     if (thingPieces[i].x == x && thingPieces[i].y == y) {
        //         return true;
        //     }
        // }

        final item = getGridItem(collision, x, y);

        return item == null || item == 0;

        // return false;
    }

    function placeThing (type:ThingType, x:Int, y:Int, rotation:RotationDir) {
        final items = makePiecesGrid(type);

        final parent = new Thing(type);

        things.push(parent);

        // TODO: rotate grid
        forEachGI(items, (xx, yy, item) -> {
            trace(checkCollision(x + xx, y + yy), x + xx, y + yy, item);
            if (item != null && item != EntranceSpot && !checkCollision(x + xx, y + yy)) {
                thingPieces.push(new Piece(x + xx, y + yy, item, parent));
            } else {
                // throw 'Cant place!';
            }
        });
    }

    inline function wait (actor:Actor, time:Int) {
        actor.state = Wait;
        actor.stateTime = time;
    }

    inline function goHome (actor:Actor) {
        actor.goal = Leave;
    }

    inline function addEvent (type:EventType, actor:Actor) {
        events.push({ type: type, actor: actor });
    }

    // actor is ready for a new state
    inline function ready (actor:Actor) {
        actor.state = None;
        actor.stateTime = 1;
    }

    public function getEvents () {
        final rEvents = events.copy();
        events.resize(0);
        return rEvents;
    }

    public function newDay () {
        day++;

        time = Time.hours(3) + Time.HALF_HOUR;

        // reset daily values
        for (a in actors) {
            a.startDay();
            if (a.arriveTime < time) {
                time = a.arriveTime - Time.QTR_HOUR;
            }
        }
    }
}
