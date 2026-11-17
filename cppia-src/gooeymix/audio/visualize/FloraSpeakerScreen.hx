package gooeymix.audio.visualize;

import animate.internal.RenderTexture;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.sound.FlxSound;
import funkin.assets.Paths;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import funkin.graphics.FunkinSprite;
import funkin.vis.dsp.Bar;
import funkin.vis.dsp.SpectralAnalyzer;
import openfl.Vector;

class FloraSpeakerScreen extends FunkinSprite
{
  private static var FLORA_VIS_COLOR:Int = 0xFF6CFFFA;
  private static var FLORA_VIS_WIDTH:Int = 115;
  private static var FLORA_VIS_HEIGHT:Int = 74;
  private static var FLORA_VIS_OFFSETS:Map<String, Array<Float>> = [
    "lightBop0000" => [132, 18],
    "lightBop0001" => [132, 18],
    "lightBop0002" => [129, 13],
    "lightBop0003" => [129, 13],
    "lightBop0004" => [127, 11],
    "lightBop0005" => [127, 11],
    "lightLoop0000" => [127, 11],
    "lightLoop0001" => [127, 11],
    "lightLoop0002" => [127, 11]
  ];
  private static var FLORA_VIS_BAR_COUNT:Int = 7;
  private static var FLORA_VIS_FLAT_LEVEL:Float = 0.5;

  var vizEnabled:Bool;
  var shouldUpdateViz:Bool;
  var vizSquare:FlxGraphic;
  var vizIndices:Vector<Int>;
  var vizVertices:Vector<Float>;
  var vizUvtData:Vector<Float>;
  var analyzer:SpectralAnalyzer;
  var vizLevels:Array<Bar> = [];
  var vizTimeoutTime:Float = 0;

  public function new(enableViz:Bool)
  {
    super();
    vizEnabled = enableViz;

    loadSparrow('gameplay/characters/flora/FloraLights');
    animation.addByPrefix('lightBop', 'lightBop', 24, false);
    animation.addByPrefix('lightLoop', 'lightLoop', 24, true);
    animation.addByPrefix('50combo', '50combo', 24, false);
    animation.addByPrefix('200combo', '200combo', 24, false);
    animation.addByPrefix('lossCombo', 'lossCombo', 24, false);
    animation.play('lightBop');

    if (vizEnabled)
    {
      vizSquare = FlxG.bitmap.add(Paths.image('gameplay/characters/flora/floraVis').toFlxGraphicAsset());

      vizVertices = new Vector();
      vizIndices = new Vector();
      vizUvtData = new Vector();
      trace('hello???');
    }
    trace(enableViz);
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

    shouldUpdateViz = false;
  }

  public function dumpSound():Void
  {
    analyzer = null;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (vizEnabled) {
      vizTimeoutTime -= elapsed;
      while (vizTimeoutTime < 0)
      {
        updateViz();
        vizTimeoutTime += 1 / 24;
      }
    }
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    if (!['lightBop', 'lightLoop'].contains(getCurrentAnimation()) || vizSquare == null)
    {
      super.drawFrameComplex(frame, camera);
      return;
    }

    final matrix = this._matrix;
    final point = this._point;

    frame.prepareMatrix(matrix, 0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    final bounds:Array<Int> = [Math.ceil(frame.frame.width), Math.ceil(frame.frame.height)];
    if (_renderTexture == null) _renderTexture = new RenderTexture(bounds[0], bounds[1]);

    if (_renderTextureDirty)
    {
      final visOffset:Array<Float> = FLORA_VIS_OFFSETS.get(_frame.name) ?? [];
      point.set(visOffset[0] ?? 0, visOffset[1] ?? 0);

      _renderTexture.init(bounds[0], bounds[1]);
      _renderTexture.drawToCamera((camera, mat) ->
      {
        camera.drawPixels(frame, framePixels, mat, null, null, false, null);
        camera.drawTriangles(vizSquare, vizVertices, vizIndices, vizUvtData, null, point, null, false, true);
      });

      _renderTexture.render();
    }

    camera.drawPixels(_renderTexture.graphic.imageFrame.frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
  }

  function updateViz():Void
  {
    vizLevels = analyzer?.getLevels(vizLevels) ?? getDefaultLevels();

    vizVertices.length = 0;
    vizIndices.length = 0;
    vizUvtData.length = 0;

    final pointsLength:Int = FLORA_VIS_BAR_COUNT + 1;
    final stepWidth:Float = FLORA_VIS_WIDTH / pointsLength;

    var oldPointX:Float = 0;
    var oldPointY:Float = FLORA_VIS_HEIGHT * 0.6;

    for (i in 0...pointsLength)
    {
      var levelValue:Float = 0.5;
      if (i < FLORA_VIS_BAR_COUNT)
      {
        levelValue = (vizLevels[i].value * 0.5) + 0.5;
      }

      final x:Float = (i / (pointsLength - 1)) * FLORA_VIS_WIDTH;
      final y:Float = FLORA_VIS_HEIGHT * (1 - levelValue + 0.1);

      // Your original used curveTo, creating a midpoint path:
      final midX:Float = (oldPointX + x) * 0.5;
      final midY:Float = (oldPointY + y) * 0.5;

      final progress:Float = i / pointsLength;

      // Vert Top
      vizVertices.push(midX);
      vizVertices.push(midY);

      // Vert Bottom
      vizVertices.push(midX);
      vizVertices.push(FLORA_VIS_HEIGHT);

      // UVT mapping for the fill
      vizUvtData.push(progress);
      vizUvtData.push(0.0);
      vizUvtData.push(progress);
      vizUvtData.push(1.0);

      // Standard index pairing to construct the solid fill mesh blocks
      if (i > 0)
      {
        final prevTop:Int = (i - 1) * 2;
        final prevBottom:Int = prevTop + 1;
        final curTop:Int = i * 2;
        final curBottom:Int = curTop + 1;

        vizIndices.push(prevTop);
        vizIndices.push(curTop);
        vizIndices.push(prevBottom);

        vizIndices.push(curTop);
        vizIndices.push(curBottom);
        vizIndices.push(prevBottom);
      }

      if (i == (pointsLength - 1))
      {
        vizVertices.push(FLORA_VIS_WIDTH);
        vizVertices.push(y);

        vizVertices.push(FLORA_VIS_WIDTH);
        vizVertices.push(FLORA_VIS_HEIGHT);

        vizUvtData.push(1.0);
        vizUvtData.push(0.0);

        vizUvtData.push(1.0);
        vizUvtData.push(1.0);

        final prevTop:Int = i * 2;
        final prevBottom:Int = prevTop + 1;
        final curTop:Int = (i + 1) * 2;
        final curBottom:Int = curTop + 1;

        vizIndices.push(prevTop);
        vizIndices.push(curTop);
        vizIndices.push(prevBottom);

        vizIndices.push(curTop);
        vizIndices.push(curBottom);
        vizIndices.push(prevBottom);
      }

      oldPointX = x;
      oldPointY = y;
    }
  }

  function getDefaultLevels():Array<Bar>
  {
    vizLevels.resize(0);
    for (i in 0...FLORA_VIS_BAR_COUNT) vizLevels.push({value: 0, peak: 0.0});
    return vizLevels;
  }
}
