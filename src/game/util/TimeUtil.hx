package game.util;

class TimeUtil {
    // steps in a minute
    public static inline final MINUTE:Int = 20;
    // steps for one hour
    public static inline final ONE_HOUR:Int = 60 * MINUTE;
    // 5am-9pm is one day
    public static inline final ONE_DAY:Int = ONE_HOUR * 16;
    
    // 12 hours after 5am
    public static inline final FIVE_PM:Int = ONE_HOUR * 12;
    public static inline final NOON:Int = ONE_HOUR * 7;

    // other hour stuff
    public static inline final HALF_HOUR:Int = MINUTE * 30;
    public static inline final QTR_HOUR:Int = MINUTE * 15;

    public static function hours (hours:Int) {
        return hours * ONE_HOUR;
    }
}
