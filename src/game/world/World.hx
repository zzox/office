package game.world;

import game.util.TimeUtil as Time;
import game.util.TimeUtil;
import game.world.Grid;

enum ActorState {
  Sell;
  Break;
  Talk;
  Think;
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

class Actor {
    public static var curId:Int = 0;
    // static vals
    public final id:Int;
    public final name:String;

    // dynamic vals
    public var state:Null<ActorState>;

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

    public function new () {
        grid = makeGrid(25, 25, 0);
        for (_ in 0...3) {
            actors.push(new Actor('test${Actor.curId}'));
        }
        newDay();
    }

    public function step () {
        time++;

        for (a in actors) {
            if (a.arriveTime == this.time) {
                trace('arrive');
            }
        }
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
}
