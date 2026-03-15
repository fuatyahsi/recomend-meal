import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/app_provider.dart';

class CookingModeScreen extends StatefulWidget {
  final String recipeName;
  final String emoji;
  final List<String> steps;
  final List<String>? ingredients;

  const CookingModeScreen({
    super.key,
    required this.recipeName,
    required this.emoji,
    required this.steps,
    this.ingredients,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final PageController _pageController = PageController();
  final Set<int> _completedSteps = {};
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  int _currentStep = 0;
  bool _voiceEnabled = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastCommand = '';
  Timer? _timer;
  Duration _remaining = Duration.zero;

  bool get _hasTimer => _remaining > Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVoice();
  }

  Future<void> _initVoice() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _voiceEnabled && mounted) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (_voiceEnabled && mounted) _startListening();
          });
        }
      },
    );
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) return;
    setState(() => _voiceEnabled = !_voiceEnabled);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    await _tts.setLanguage(isTr ? 'tr-TR' : 'en-US');
    if (_voiceEnabled) {
      await _speakCurrentStep();
      _startListening();
    } else {
      _speech.stop();
      await _tts.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _startListening() async {
    if (!_voiceEnabled || _isListening) return;
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleCommand(result.recognizedWords.toLowerCase());
        }
      },
      localeId: isTr ? 'tr_TR' : 'en_US',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _handleCommand(String command) {
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    setState(() => _lastCommand = command);

    if (_matchAny(command, ['next', 'sonraki', 'ileri'])) {
      _nextStep();
      _speakCurrentStep();
      return;
    }
    if (_matchAny(command, ['previous', 'geri', 'onceki', 'önceki'])) {
      _prevStep();
      _speakCurrentStep();
      return;
    }
    if (_matchAny(command, ['repeat', 'tekrar'])) {
      _speakCurrentStep();
      return;
    }
    if (_matchAny(command, ['done', 'tamam', 'bitti'])) {
      _toggleStepComplete(_currentStep);
      _speak(isTr ? 'Adim tamamlandi.' : 'Step completed.');
      return;
    }
    if (_matchAny(command, ['help', 'yardim', 'yardım'])) {
      _showSousChefSheet();
      return;
    }
    if (_matchAny(command, ['tip', 'ipucu'])) {
      _speak(_tipFor(widget.steps[_currentStep], isTr));
      return;
    }
    if (_matchAny(command, ['ingredients', 'malzeme'])) {
      _showIngredients();
      _speakIngredients();
      return;
    }
    if (_matchAny(command, ['timer', 'zamanlayici', 'zamanlayıcı'])) {
      final minutes = _extractMinutes(command);
      if (minutes != null && minutes > 0) {
        _startTimer(minutes);
      }
      return;
    }
    if (_matchAny(command, ['cancel timer', 'timer iptal'])) {
      _cancelTimer();
      return;
    }
    if (_matchAny(command, ['time left', 'kalan sure', 'kalan süre'])) {
      _speak(
        _hasTimer
            ? (isTr
                ? '${_remaining.inMinutes} dakika ${_remaining.inSeconds % 60} saniye kaldi.'
                : '${_remaining.inMinutes} minutes left.')
            : (isTr ? 'Aktif zamanlayici yok.' : 'No active timer.'),
      );
    }
  }

  bool _matchAny(String command, List<String> words) =>
      words.any(command.contains);

  int? _extractMinutes(String command) {
    final match = RegExp(r'(\d{1,2})').firstMatch(command);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    await _tts.speak(text);
  }

  Future<void> _speakCurrentStep() async {
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    await _speak(
      isTr
          ? 'Adim ${_currentStep + 1}. ${widget.steps[_currentStep]}'
          : 'Step ${_currentStep + 1}. ${widget.steps[_currentStep]}',
    );
  }

  Future<void> _speakIngredients() async {
    if (!_voiceEnabled || widget.ingredients == null || widget.ingredients!.isEmpty) {
      return;
    }
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final shortList = widget.ingredients!.take(5).join(', ');
    await _speak(isTr ? 'Malzemeler: $shortList' : 'Ingredients: $shortList');
  }

  void _startTimer(int minutes) {
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    _timer?.cancel();
    setState(() => _remaining = Duration(minutes: minutes));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
        _speak(isTr ? 'Zamanlayici bitti.' : 'Timer finished.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Zamanlayici bitti.' : 'Timer finished.')),
        );
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
    _speak(isTr ? '$minutes dakikalik zamanlayici basladi.' : '$minutes minute timer started.');
  }

  void _cancelTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _remaining = Duration.zero);
  }

  String _tipFor(String step, bool isTr) {
    final lower = step.toLowerCase();
    if (_matchAny(lower, ['dogra', 'doğra', 'chop', 'slice'])) {
      return isTr
          ? 'Benzer boyutlarda dograma, daha dengeli pisirir.'
          : 'Cut evenly so everything cooks at the same pace.';
    }
    if (_matchAny(lower, ['kizart', 'kızart', 'fry', 'sear'])) {
      return isTr
          ? 'Tavayi once isit, sonra malzemeyi ekle.'
          : 'Heat the pan first, then add the ingredients.';
    }
    if (_matchAny(lower, ['kaynat', 'boil', 'simmer'])) {
      return isTr
          ? 'Tasmasini onlemek icin ara ara kontrol et.'
          : 'Check it often so it does not boil over.';
    }
    return isTr
        ? 'Ritmi sabit tut. Bu adim acele sevmiyor.'
        : 'Keep a steady pace. This step does not like rushing.';
  }

  void _nextStep() {
    if (_currentStep >= widget.steps.length - 1) return;
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep <= 0) return;
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _toggleStepComplete(int index) {
    setState(() {
      if (_completedSteps.contains(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps.add(index);
      }
    });
  }

  void _showSousChefSheet() {
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.grey.shade950,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTr ? 'Sesli Sous Chef' : 'Voice Sous Chef',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tipFor(widget.steps[_currentStep], isTr),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickChip(label: isTr ? '3 dk' : '3 min', onTap: () => _startTimer(3)),
                _QuickChip(label: isTr ? '5 dk' : '5 min', onTap: () => _startTimer(5)),
                _QuickChip(
                  label: isTr ? 'Adimi oku' : 'Read step',
                  onTap: () {
                    _speakCurrentStep();
                  },
                ),
                _QuickChip(label: isTr ? 'Malzemeler' : 'Ingredients', onTap: _showIngredients),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isTr
                  ? 'Komutlar: sonraki, onceki, tekrar, tamam, 5 dakika zamanlayici, timer iptal, ipucu'
                  : 'Commands: next, previous, repeat, done, 5 minute timer, cancel timer, tip',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngredients() {
    final ingredients = widget.ingredients;
    if (ingredients == null || ingredients.isEmpty) return;
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTr ? 'Malzemeler' : 'Ingredients'),
            const SizedBox(height: 12),
            ...ingredients.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $item'),
                )),
          ],
        ),
      ),
    );
  }

  void _finish() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    _pageController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final allDone = _completedSteps.length == widget.steps.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(widget.emoji),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.recipeName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.mic : Icons.mic_off),
            onPressed: _toggleVoice,
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: _showSousChefSheet,
          ),
          if (widget.ingredients != null && widget.ingredients!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: _showIngredients,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_voiceEnabled || _hasTimer)
            Container(
              width: double.infinity,
              color: Colors.white10,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_voiceEnabled)
                    Text(
                      _lastCommand.isEmpty
                          ? (isTr ? 'Sous Chef dinliyor...' : 'Sous Chef is listening...')
                          : _lastCommand,
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                  if (_hasTimer)
                    Text(
                      isTr
                          ? 'Timer: ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                          : 'Timer: ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(
                widget.steps.length,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    color: _completedSteps.contains(index)
                        ? Colors.green
                        : index == _currentStep
                            ? Colors.orange
                            : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
          Text(
            isTr
                ? 'Adim ${_currentStep + 1} / ${widget.steps.length}'
                : 'Step ${_currentStep + 1} / ${widget.steps.length}',
            style: const TextStyle(color: Colors.white70),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.steps.length,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) {
                final step = widget.steps[index];
                final isDone = _completedSteps.contains(index);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isDone ? Colors.green : Colors.orange,
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white)
                            : Text('${index + 1}'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDone ? Colors.white38 : Colors.white,
                          fontSize: 22,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTr ? 'Sous Chef ipucu' : 'Sous Chef tip',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _tipFor(step, isTr),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickChip(label: isTr ? '3 dk' : '3 min', onTap: () => _startTimer(3)),
                                _QuickChip(label: isTr ? '5 dk' : '5 min', onTap: () => _startTimer(5)),
                                _QuickChip(
                                  label: isTr ? 'Oku' : 'Read',
                                  onTap: () {
                                    _speakCurrentStep();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _toggleStepComplete(index),
                        icon: Icon(isDone ? Icons.undo : Icons.check_circle_outline),
                        label: Text(isDone ? (isTr ? 'Geri al' : 'Undo') : (isTr ? 'Tamam' : 'Done')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _currentStep > 0 ? _prevStep : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(isTr ? 'Onceki' : 'Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentStep < widget.steps.length - 1 ? _nextStep : _finish,
                    icon: Icon(_currentStep < widget.steps.length - 1 ? Icons.arrow_forward : Icons.celebration),
                    label: Text(_currentStep < widget.steps.length - 1 ? (isTr ? 'Sonraki' : 'Next') : (isTr ? 'Bitir' : 'Finish')),
                  ),
                ),
              ],
            ),
          ),
          Text(
            allDone ? (isTr ? 'Tum adimlar tamamlandi' : 'All steps completed') : '',
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
