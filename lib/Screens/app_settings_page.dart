import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/simple_settings.dart';
import '../utils/values.dart'; // sửa đường dẫn: từ lib/pages -> lib/utils là ../

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});
  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  // COMMON (width/height chỉ hiển thị)
  late final int _widthImage = widthImage;
  late final int _heightImage = heightImage;

  // local state (edit rồi save vào SimpleSettings)
  late double _bboxMargin = bboxMargin;
  late double _maxAbsYaw = maxAbsYaw;
  late double _maxAbsRoll = maxAbsRoll;
  late double _minBox = minBox;
  late double _threshold = threshold;

  // ENROLLMENT
  late int _targetShots = targetShots;
  late int _tickMsEnroll = tickMsEnroll;
  late int _needOkFramesEnroll = needOkFramesEnroll;

  // RECOGNITION
  late int _tickMsRecognition = tickMsRecognition;
  late int _needOkFramesRecognition = needOkFramesRecognition;

  // LIVENESS
  late double _livenessThreshold = SimpleSettings.livenessThreshold;

  Future<void> _saveNow() => SimpleSettings.save();

  int _ci(int v, int a, int b) => v.clamp(a, b);
  double _cd(double v, double a, double b) {
    final n = v.clamp(a, b);
    return n is int ? n.toDouble() : n as double;
  }

  Future<void> _confirmReset() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Reset to Defaults'),
        message: const Text('Khôi phục tất cả thông số về mặc định?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SimpleSettings.reset();
              setState(() {
                // sync lại từ SimpleSettings
                _threshold = threshold;
                _bboxMargin = bboxMargin;
                _maxAbsYaw = maxAbsYaw;
                _maxAbsRoll = maxAbsRoll;
                _minBox = minBox;

                _targetShots = targetShots;
                _tickMsEnroll = tickMsEnroll;
                _needOkFramesEnroll = needOkFramesEnroll;

                _tickMsRecognition = tickMsRecognition;
                _needOkFramesRecognition = needOkFramesRecognition;

                _livenessThreshold = SimpleSettings.livenessThreshold;
              });
            },
            child: const Text('Reset'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // Hiển thị read-only
  Widget _infoRow({required String label, required String value, String? suffix}) {
    return CupertinoFormRow(
      prefix: Text(label),
      child: Text(
        suffix == null ? value : '$value $suffix',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.black,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  // Số nguyên có thể sửa
  Widget _intField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 9999,
    String? suffix,
  }) {
    return CupertinoFormRow(
      prefix: Text(label),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextFormFieldRow(
              key: ValueKey('$label-$value'),
              padding: EdgeInsets.zero,
              initialValue: value.toString(),
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
              onChanged: (t) {
                final v = _ci(int.tryParse(t) ?? value, min, max);
                onChanged(v);
                setState(() {});
                _saveNow();
              },
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(suffix, style: const TextStyle(color: CupertinoColors.systemGrey)),
            ),
        ],
      ),
    );
  }

  // Số thực có thể sửa
  Widget _doubleField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 9999,
    String? suffix,
  }) {
    return CupertinoFormRow(
      prefix: Text(label),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextFormFieldRow(
              key: ValueKey('$label-$value'),
              padding: EdgeInsets.zero,
              initialValue: value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (t) {
                final v = _cd(double.tryParse(t) ?? value, min, max);
                onChanged(v);
                setState(() {});
                _saveNow();
              },
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(suffix, style: const TextStyle(color: CupertinoColors.systemGrey)),
            ),
        ],
      ),
    );
  }

  // Slider double
  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return CupertinoFormRow(
      prefix: Text(label),
      helper: Text(value.toStringAsFixed(2)),
      child: CupertinoSlider(
        value: value.clamp(min, max).toDouble(),
        min: min,
        max: max,
        onChanged: (v) {
          onChanged(v);
          setState(() {});
          _saveNow();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            // Common (width/height chỉ hiển thị), threshold chỉnh slider
            CupertinoFormSection.insetGrouped(
              header: const Text('COMMON'),
              children: [
                _infoRow(label: 'Image width',  value: _widthImage.toString(), suffix: 'px'),
                _infoRow(label: 'Image height', value: _heightImage.toString(), suffix: 'px'),
                _sliderRow(
                  label: 'Threshold',
                  value: _threshold,
                  min: 0.10,
                  max: 1.50,
                  onChanged: (v) {
                    _threshold = v;
                    SimpleSettings.threshold = v;
                  },
                ),
              ],
            ),

            // Enrollment
            CupertinoFormSection.insetGrouped(
              header: const Text('ENROLLMENT'),
              children: [
                _intField(
                  label: 'Target shots',
                  value: _targetShots,
                  min: 1,
                  max: 100,
                  onChanged: (v) {
                    _targetShots = v;
                    SimpleSettings.targetShots = v;
                  },
                ),
                _doubleField(
                  label: 'BBox margin',
                  value: _bboxMargin,
                  min: 0,
                  max: .5,
                  onChanged: (v) {
                    _bboxMargin = v;
                    SimpleSettings.bboxMargin = v;
                  },
                ),
                _doubleField(
                  label: 'Max yaw',
                  value: _maxAbsYaw,
                  min: 0,
                  max: 60,
                  onChanged: (v) {
                    _maxAbsYaw = v;
                    SimpleSettings.maxAbsYaw = v;
                  },
                ),
                _doubleField(
                  label: 'Max roll',
                  value: _maxAbsRoll,
                  min: 0,
                  max: 60,
                  onChanged: (v) {
                    _maxAbsRoll = v;
                    SimpleSettings.maxAbsRoll = v;
                  },
                ),
                _doubleField(
                  label: 'Min box',
                  value: _minBox,
                  min: 50,
                  max: 400,
                  suffix: 'px',
                  onChanged: (v) {
                    _minBox = v;
                    SimpleSettings.minBox = v;
                  },
                ),
                _intField(
                  label: 'Tick (ms)',
                  value: _tickMsEnroll,
                  min: 16,
                  max: 1000,
                  suffix: 'ms',
                  onChanged: (v) {
                    _tickMsEnroll = v;
                    SimpleSettings.tickMsEnroll = v;
                  },
                ),
                _intField(
                  label: 'OK frames',
                  value: _needOkFramesEnroll,
                  min: 1,
                  max: 10,
                  onChanged: (v) {
                    _needOkFramesEnroll = v;
                    SimpleSettings.needOkFramesEnroll = v;
                  },
                ),
              ],
            ),

            // Recognition
            CupertinoFormSection.insetGrouped(
              header: const Text('RECOGNITION'),
              children: [
                _intField(
                  label: 'Tick (ms)',
                  value: _tickMsRecognition,
                  min: 16,
                  max: 1000,
                  suffix: 'ms',
                  onChanged: (v) {
                    _tickMsRecognition = v;
                    SimpleSettings.tickMsRecognition = v;
                  },
                ),
                _intField(
                  label: 'OK frames',
                  value: _needOkFramesRecognition,
                  min: 1,
                  max: 10,
                  onChanged: (v) {
                    _needOkFramesRecognition = v;
                    SimpleSettings.needOkFramesRecognition = v;
                  },
                ),
              ],
            ),

            // Passive Liveness
            CupertinoFormSection.insetGrouped(
              header: const Text('PASSIVE LIVENESS'),
              children: [
                _sliderRow(
                  label: 'Liveness threshold',
                  value: _livenessThreshold,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) {
                    _livenessThreshold = v;
                    SimpleSettings.livenessThreshold = v;
                  },
                ),
              ],
            ),

            // Reset
            CupertinoFormSection.insetGrouped(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _confirmReset,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Reset to Defaults',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
