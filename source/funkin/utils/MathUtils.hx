package funkin.utils;

class MathUtils
{
  public static final E:Float = 2.71828182845904523536;

  /**
   * Perform linear interpolation between the base and the target, based on the current framerate.
   * @deprecated Use smoothLerp instead
   */
  @:deprecated('Use smoothLerp instead')
  public static function coolLerp(base:Float, target:Float, ratio:Float):Float
  {
    return base + cameraLerp(ratio) * (target - base);
  }

  /**
   * Perform linear interpolation based on the current framerate.
   * @deprecated Use smoothLerp instead
   */
  @:deprecated('Use smoothLerp instead')
  public static function cameraLerp(lerp:Float):Float
  {
    return lerp * (FlxG.elapsed / (1 / 60));
  }

  /**
   * Get the logarithm of a value with a given base.
   */
  public static function logBase(base:Float, value:Float):Float
  {
    if (base <= 0 || value <= 0) return 0;
    return Math.log(value) / Math.log(base);
  }

  public static function easeInOutCirc(x:Float):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
    return Math.isNaN(result) ? 1.0 : result;
  }

  public static function easeInOutBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    var result:Float = (x < 0.5) ? (2 * x * x * ((c + 1) * 2 * x - c)) / 2 : (1 - 2 * (1 - x) * (1 - x) * ((c + 1) * 2 * (1 - x) - c)) / 2;
    return Math.isNaN(result) ? 1.0 : result;
  }

  public static function easeInBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return (1 + c) * x * x * x - c * x * x;
  }

  public static function easeOutBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
  }

  /**
   * Get the base-2 exponential of a value.
   */
  public static function exp2(x:Float):Float
  {
    return Math.pow(2, x);
  }

  /**
   * Linearly interpolate between two values.
   */
  public static function lerp(base:Float, target:Float, progress:Float):Float
  {
    return base + progress * (target - base);
  }

  /**
   * Perform a framerate-independent linear interpolation between the base value and the target.
   * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
   */
  public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
  {
    if (current == target) return target;
    if (duration <= 0 || elapsed <= 0) return target;

    var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

    var threshold:Float = precision * Math.max(Math.abs(target), 1);
    if (Math.abs(result - target) < threshold) result = target;

    return result;
  }
}
