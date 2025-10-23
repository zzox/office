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

        for (_ in 0...10) {
            final actor = new Actor('test${Actor.curId}');
            actor.assignDesk(things[actors.length]);
            actors.push(actor);
        }
    }

    public function step ():Bool {
        time++;

        // update collision array
        collision.items = collision.items.map(_ -> 1);
        for (a in actors) collision.items[a.getX() + a.getY() * grid.width] = 0;
        for (p in thingPieces) collision.items[p.x + p.y * grid.width] = 0;

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

            // if time doing our state ran out, actor does something
            if (a.stateTime == 0) {
                // if we've been here 8 hours, leave
                if (time > a.arriveTime + Time.hours(8) && time > Time.FIVE_PM) {
                    a.goal = Leave;
                }

                // if goal is to leave, head towards the exit
                if (a.goal == Leave) {
                    if (a.isAt(exit.x, exit.y)) {
                        leave(a);
                        continue;
                    } else {
                        tryMoveActor(a, exit.x, exit.y);
                    }
                } else if (a.goal == Work) {
                    if (a.placement != Desk && a.desk != null) {
                        // if at desk, get on, otherwise go to it
                        if (atEntranceSpot(a, a.desk)) {
                            getOnDesk(a);
                        } else {
                            tryGoDesk(a);
                        }
                    }

                    if (a.placement == Desk) {
                        sell(a);
                    }

                    // } else {
                    //     tryMoveActor(a, randomInt(grid.width), randomInt(grid.height));
                    // }
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

    function tryGoDesk (actor:Actor) {
        final pos = getEntranceSpots(actor.desk)[0];
        tryMoveActor(actor, pos.x, pos.y);
    }

    function getOnDesk (actor:Actor) {
        actor.x = actor.desk.useItem.x;
        actor.y = actor.desk.useItem.y;
        actor.facing = actor.desk.useItem.rotation;
        actor.placement = Desk;
    }

    function atEntranceSpot (actor:Actor, thing:Thing):Bool {
        final spots = getEntranceSpots(thing);
        for (s in spots) {
            if (actor.isAt(s.x, s.y)) {
                return true;
            }
        }
        return false;
    }

    function sell (actor:Actor) {
        actor.state = Sell;
        actor.stateTime = Time.QTR_HOUR;
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
            actor.placement = None; // unsets the actor from a desk
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

    // TODO: move parts of this to makeThing method?
    function placeThing (type:ThingType, x:Int, y:Int, rotation:RotationDir) {
        final items = makePiecesGrid(type);

        final parent = new Thing(type);

        things.push(parent);

        // TODO: rotate grid
        forEachGI(items, (xx, yy, item) -> {
            if (item != null && !checkCollision(x + xx, y + yy)) {
                final piece = new Piece(x + xx, y + yy, item, parent, rotation);
                if (item != EntranceSpot) {
                    thingPieces.push(piece);
                }
                parent.pieces.push(piece);

                // assign the usable piece to the parent
                if (item == Chair) {
                    parent.useItem = piece;
                }
            } else {
                // throw 'Cant place!';
            }
        });
    }

    inline function wait (actor:Actor, time:Int) {
        actor.state = Wait;
        actor.stateTime = time;
    }

    // single line functions make more sense to just write out
    // inline function goHome (actor:Actor) {
    //     actor.goal = Leave;
    // }

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
