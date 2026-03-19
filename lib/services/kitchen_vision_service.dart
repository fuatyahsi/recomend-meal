import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/kitchen_intelligence.dart';
import '../models/smart_actueller.dart';

class KitchenVisionService {
  Future<ReceiptVisionCapture> analyzeReceiptImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.55),
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final labels = await imageLabeler.processImage(inputImage);
      final labelTexts = labels
          .where((label) => label.confidence >= 0.55)
          .map((label) => label.label)
          .toSet()
          .toList();

      return ReceiptVisionCapture(
        imagePath: imagePath,
        rawText: recognizedText.text.trim(),
        labels: labelTexts,
        detectedStore: _detectStore(recognizedText.text),
        confidence: _receiptConfidence(
          rawText: recognizedText.text,
          labels: labelTexts,
        ),
      );
    } finally {
      await textRecognizer.close();
      await imageLabeler.close();
    }
  }

  Future<PlateVisionCapture> analyzePlateImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.45),
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final labels = await imageLabeler.processImage(inputImage);
      final labelTexts = labels
          .where((label) => label.confidence >= 0.45)
          .map((label) => label.label)
          .toSet()
          .toList();
      final prompt = _buildPlatePrompt(
        labelTexts: labelTexts,
        recognizedText: recognizedText.text,
      );

      return PlateVisionCapture(
        imagePath: imagePath,
        labels: labelTexts,
        prompt: prompt,
        estimatedCalories: _estimateCalories(labelTexts, recognizedText.text),
        confidence: _plateConfidence(labelTexts, recognizedText.text),
      );
    } finally {
      await textRecognizer.close();
      await imageLabeler.close();
    }
  }

  Future<ActuellerVisionCapture> analyzeActuellerImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final labels = await imageLabeler.processImage(inputImage);
      final labelTexts = labels
          .where((label) => label.confidence >= 0.5)
          .map((label) => label.label)
          .toSet()
          .toList();
      final blocks = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((block) => block.isNotEmpty)
          .toList();

      return ActuellerVisionCapture(
        imagePath: imagePath,
        rawText: recognizedText.text.trim(),
        blocks: blocks,
        labels: labelTexts,
        detectedStore: _detectStore(recognizedText.text),
        confidence: _receiptConfidence(
          rawText: recognizedText.text,
          labels: labelTexts,
        ),
      );
    } finally {
      await textRecognizer.close();
      await imageLabeler.close();
    }
  }

  String _buildPlatePrompt({
    required List<String> labelTexts,
    required String recognizedText,
  }) {
    final cleanedText = recognizedText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanedText.isNotEmpty && labelTexts.isNotEmpty) {
      return '$cleanedText, ${labelTexts.take(6).join(', ')}';
    }
    if (cleanedText.isNotEmpty) {
      return cleanedText;
    }
    if (labelTexts.isNotEmpty) {
      return labelTexts.take(6).join(', ');
    }
    return 'plate';
  }

  double _receiptConfidence({
    required String rawText,
    required List<String> labels,
  }) {
    final textScore =
        rawText.isEmpty ? 0.0 : (rawText.length / 120).clamp(0, 1);
    final labelScore = (labels.length / 4).clamp(0, 1).toDouble();
    return ((textScore * 0.8) + (labelScore * 0.2)).clamp(0, 1).toDouble();
  }

  double _plateConfidence(List<String> labels, String rawText) {
    final labelScore = (labels.length / 5).clamp(0, 1).toDouble();
    final textScore = rawText.isEmpty ? 0.0 : 0.35;
    return (labelScore * 0.75 + textScore).clamp(0, 1).toDouble();
  }

  String? _detectStore(String rawText) {
    final normalized = rawText.toLowerCase();
    const stores = ['migros', 'carrefoursa', 'a101', 'bim', 'sok', 'şok'];
    for (final store in stores) {
      if (normalized.contains(store)) {
        if (store == 'şok') return 'SOK';
        return store.toUpperCase() == 'MIGROS'
            ? 'Migros'
            : store.toUpperCase() == 'CARREFOURSA'
                ? 'CarrefourSA'
                : store.toUpperCase();
      }
    }
    return null;
  }

  int _estimateCalories(List<String> labels, String rawText) {
    final source = '${labels.join(' ')} ${rawText.toLowerCase()}';
    if (source.contains('salad') || source.contains('salata')) return 220;
    if (source.contains('soup') || source.contains('corba')) return 190;
    if (source.contains('fish') || source.contains('salmon')) return 340;
    if (source.contains('pasta') || source.contains('makarna')) return 560;
    if (source.contains('pizza') || source.contains('burger')) return 720;
    if (source.contains('dessert') || source.contains('cake')) return 430;
    if (source.contains('rice') || source.contains('pilaf')) return 410;
    return 360;
  }
}
