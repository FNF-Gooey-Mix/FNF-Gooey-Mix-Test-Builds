package gooeymix.audio.visualize;

import flixel.FlxStrip;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import funkin.vis.dsp.Bar;
import funkin.vis.dsp.SpectralAnalyzer;

class FloraSpeakerScreenPixel extends FlxStrip
{
  public function new(visColor:FlxColor, vizEnabled:Bool):Void
  {
    super();

    makeGraphic(1, 1, visColor);
    this.vizEnabled = vizEnabled;
  }

  private static var FLORA_VIS_WIDTH:Int = 102;
  private static var FLORA_VIS_HEIGHT:Int = 72;
  private static var FLORA_VIS_BAR_COUNT:Int = 7;
  private static var FLORA_VIS_FLAT_LEVEL:Float = 0.5;
  var vizEnabled:Bool;
  var vizTimeoutTime:Float = 0;
  var analyzer:SpectralAnalyzer;
  var vizLevels:Array<Bar> = [];

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (vizEnabled)
    {
      vizTimeoutTime -= elapsed;
      while (vizTimeoutTime < 0)
      {
       updateViz();
        vizTimeoutTime += 1 / 24;
      }
    }
  }

  public function initAnalyzer(snd:FlxSound):Void
  {
    @:privateAccess
    analyzer = new SpectralAnalyzer(snd._source, FLORA_VIS_BAR_COUNT, 0.1, 40);
    analyzer.fftN = 256;

    // A-Bot tuning...
    analyzer.minDb = -65;
    analyzer.maxDb = -25;
    analyzer.maxFreq = 22000;
    // we use a very low minFreq since some songs use low low subbass like a boss
    analyzer.minFreq = 10;
  }

  function updateViz():Void
  {
    vizLevels = analyzer?.getLevels(vizLevels) ?? getDefaultLevels();

    final scale:Float = 6.0;
    final lowResWidth:Float = Math.floor(FLORA_VIS_WIDTH / scale);
    final lowResHeight:Float = Math.floor(FLORA_VIS_HEIGHT / scale);
    final barWidth:Float = Math.floor(lowResWidth / FLORA_VIS_BAR_COUNT);

    this.vertices.length = 0;
    this.indices.length = 0;
    this.uvtData.length = 0;

    for (i in 0...FLORA_VIS_BAR_COUNT)
    {
      var level:Float = FLORA_VIS_FLAT_LEVEL + (vizLevels[i].value * (1 - FLORA_VIS_FLAT_LEVEL));

      var x1:Float = Math.floor((i / FLORA_VIS_BAR_COUNT) * lowResWidth);
      var x2:Float = Math.floor(((i + 1) / FLORA_VIS_BAR_COUNT) * lowResWidth);
      var y:Float = Math.floor(lowResHeight - (level * lowResHeight));

      var v:Array<Float> = [
        x1 * scale,            y * scale,
        x2 * scale,            y * scale,
        x1 * scale, lowResHeight * scale,
        x2 * scale, lowResHeight * scale
      ];
      for (val in v) this.vertices.push(val);

      var offset:Int = i * 4;
      this.indices.push(offset + 0);
      this.indices.push(offset + 1);
      this.indices.push(offset + 2);

      this.indices.push(offset + 1);
      this.indices.push(offset + 3);
      this.indices.push(offset + 2);

      this.uvtData.push(0);
      this.uvtData.push(0);
      this.uvtData.push(1);
      this.uvtData.push(0);
      this.uvtData.push(0);
      this.uvtData.push(1);
      this.uvtData.push(1);
      this.uvtData.push(1);
    }
  }

  function getDefaultLevels():Array<Bar>
  {
    vizLevels.resize(0);
    for (i in 0...FLORA_VIS_BAR_COUNT) vizLevels.push({value: 0, peak: 0.0});
    return vizLevels;
  }
}