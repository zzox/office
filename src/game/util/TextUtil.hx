package game.util;

import core.util.BitmapFont;

class TextUtil {
    // format the text into correct line widths
    public static inline function formatText (string:String, width:Int, font:BitmapFont):Array<String> {
        final words = string.split(' ');

        var result = [];
        var current = '';
        for (w in words) {
            if (font.getTextWidth('$current $w') > width) {
                result.push(current);
                current = '';
            }

            if (current == '') {
                current = w;
            } else {
                current += ' $w';
            }
        }

        if (current != '') {
            result.push(current);
        }

        return result;
    }

    public static inline function formatMoney (amount:Int) {
        final amountString = amount + '';
        var result = '';
        var index = -1;
        while (++index < amountString.length) {
            result += amountString.charAt(index);
            if ((amountString.length - index - 1) % 3 == 0 && index != amountString.length - 1) {
                result += ',';
            }
        }

        return '$' + result;
    }

    public static inline function padInt (int:Int):String {
        if (int < 10) {
            return '0${int}';
        }

        return '' + int; 
    }

    public static inline function formatTime (time:Int) {
        final minutes = Math.floor(time / 20) % 60;
        var hours = Math.floor(time / TimeUtil.ONE_HOUR);

        final roundedMinutes = Math.floor(minutes / 5) * 5;

        // start time is 5am, `time` val of zero equals 5 am
        hours += 5;

        var ampm = 'AM';
        if (hours >= 12) {
            ampm = 'PM';
        }

        if (hours >= 13) {
            hours -= 12;
        }

        return '${padInt(hours)}:${padInt(roundedMinutes)} ${ampm}';
    }
}
