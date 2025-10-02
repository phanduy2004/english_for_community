import 'package:shared_preferences/shared_preferences.dart';

class SimpleSettings {
  // Khóa lưu
  static const _k = 'simple_settings_v1';

  // ===== Defaults =====
  static int widthImage = 160;
  static int heightImage = 160;
  static double bboxMargin = .10;
  static double maxAbsYaw = 30;
  static double maxAbsRoll = 30;
  static double minBox = 120;
  static double threshold = 0.7;

  static int targetShots = 10;
  static int needOkFramesEnroll = 5;
  static int tickMsEnroll = 120;

  static int tickMsRecognition = 120;
  static int needOkFramesRecognition = 3;

  // ✅ THÊM FIELD NÀY
  static double livenessThreshold = 0.6;

  static SharedPreferences? _prefs;

  static Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    widthImage   = _prefs!.getInt('widthImage')   ?? widthImage;
    heightImage  = _prefs!.getInt('heightImage')  ?? heightImage;
    bboxMargin   = _prefs!.getDouble('bboxMargin')?? bboxMargin;
    maxAbsYaw    = _prefs!.getDouble('maxAbsYaw') ?? maxAbsYaw;
    maxAbsRoll   = _prefs!.getDouble('maxAbsRoll')?? maxAbsRoll;
    minBox       = _prefs!.getDouble('minBox')    ?? minBox;
    threshold    = _prefs!.getDouble('threshold') ?? threshold;

    targetShots  = _prefs!.getInt('targetShots')  ?? targetShots;
    needOkFramesEnroll = _prefs!.getInt('needOkFramesEnroll') ?? needOkFramesEnroll;
    tickMsEnroll = _prefs!.getInt('tickMsEnroll') ?? tickMsEnroll;

    tickMsRecognition = _prefs!.getInt('tickMsRecognition') ?? tickMsRecognition;
    needOkFramesRecognition = _prefs!.getInt('needOkFramesRecognition') ?? needOkFramesRecognition;

    // ✅ NẠP GIÁ TRỊ LIVENESS
    livenessThreshold = _prefs!.getDouble('livenessThreshold') ?? livenessThreshold;
  }

  static Future<void> save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('widthImage', widthImage);
    await _prefs!.setInt('heightImage', heightImage);
    await _prefs!.setDouble('bboxMargin', bboxMargin);
    await _prefs!.setDouble('maxAbsYaw', maxAbsYaw);
    await _prefs!.setDouble('maxAbsRoll', maxAbsRoll);
    await _prefs!.setDouble('minBox', minBox);
    await _prefs!.setDouble('threshold', threshold);

    await _prefs!.setInt('targetShots', targetShots);
    await _prefs!.setInt('needOkFramesEnroll', needOkFramesEnroll);
    await _prefs!.setInt('tickMsEnroll', tickMsEnroll);

    await _prefs!.setInt('tickMsRecognition', tickMsRecognition);
    await _prefs!.setInt('needOkFramesRecognition', needOkFramesRecognition);

    // ✅ LƯU LIVENESS
    await _prefs!.setDouble('livenessThreshold', livenessThreshold);
  }

  static Future<void> reset() async {
    // Gán về default
    widthImage = 160;
    heightImage = 160;
    bboxMargin = .10;
    maxAbsYaw = 30;
    maxAbsRoll = 30;
    minBox = 120;
    threshold = 0.7;

    targetShots = 10;
    needOkFramesEnroll = 5;
    tickMsEnroll = 120;

    tickMsRecognition = 120;
    needOkFramesRecognition = 3;

    // ✅ RESET LIVENESS
    livenessThreshold = 0.6;

    await save();
  }
}
