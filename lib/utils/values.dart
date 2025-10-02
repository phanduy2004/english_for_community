// Common Setting
import 'simple_settings.dart';

const modelPath = 'assets/models/facenet_david.tflite';

// Getters dùng khắp app
int get widthImage    => SimpleSettings.widthImage;
int get heightImage   => SimpleSettings.heightImage;

double get threshold  => SimpleSettings.threshold;
double get bboxMargin => SimpleSettings.bboxMargin;
double get maxAbsYaw  => SimpleSettings.maxAbsYaw;
double get maxAbsRoll => SimpleSettings.maxAbsRoll;
double get minBox     => SimpleSettings.minBox;

int get targetShots           => SimpleSettings.targetShots;
int get needOkFramesEnroll    => SimpleSettings.needOkFramesEnroll;
int get tickMsEnroll          => SimpleSettings.tickMsEnroll;

int get tickMsRecognition         => SimpleSettings.tickMsRecognition;
int get needOkFramesRecognition   => SimpleSettings.needOkFramesRecognition;

double get livenessThreshold => SimpleSettings.livenessThreshold;
