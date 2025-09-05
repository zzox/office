package game.util;

class TimeUtil {
    // steps for one hour
    public static inline final ONE_HOUR:Int = 60 * 60;
    // 5am-9pm is one day
    public static inline final ONE_DAY:Int = ONE_HOUR * 16;
    
    // 12 hours after 5am
    public static inline final FIVE_PM:Int = ONE_HOUR * 12;
    public static inline final NOON:Int = ONE_HOUR * 7;

    public static function hours (hours:Int) {
        return hours * ONE_HOUR;
    }
}
