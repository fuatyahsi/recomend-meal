import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    // Ekran kararmasını engelle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Ekranı açık tut - WakeLock yerine basit yaklaşım
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final allDone = _completedSteps.length == widget.steps.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.recipeName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Malzeme listesi butonu
          if (widget.ingredients != null && widget.ingredients!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list_alt, color: Colors.white),
              tooltip: isTr ? 'Malzemeler' : 'Ingredients',
              onPressed: () => _showIngredients(context, isTr),
            ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(widget.steps.length, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _completedSteps.contains(i)
                          ? Colors.green
                          : i == _currentStep
                              ? Colors.orange
                              : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Adım sayacı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTr
                      ? 'Adım ${_currentStep + 1} / ${widget.steps.length}'
                      : 'Step ${_currentStep + 1} / ${widget.steps.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_completedSteps.length}/${widget.steps.length} ${isTr ? 'tamamlandı' : 'done'}',
                  style: TextStyle(
                    color: allDone ? Colors.green : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Ana içerik - adımlar
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              itemCount: widget.steps.length,
              itemBuilder: (context, index) {
                final isCompleted = _completedSteps.contains(index);
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Adım numarası
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 28)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Adım metni
                        Text(
                          widget.steps[index],
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 22,
                            height: 1.5,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Tamamla/geri al butonu
                        TextButton.icon(
                          onPressed: () => _toggleStepComplete(index),
                          icon: Icon(
                            isCompleted
                                ? Icons.undo
                                : Icons.check_circle_outline,
                            color: isCompleted ? Colors.white54 : Colors.green,
                          ),
                          label: Text(
                            isCompleted
                                ? (isTr ? 'Geri Al' : 'Undo')
                                : (isTr ? 'Tamamlandı' : 'Done'),
                            style: TextStyle(
                              color:
                                  isCompleted ? Colors.white54 : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                );
              },
            ),
          ),

          // Alt navigasyon butonları
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Geri butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStep > 0 ? _prevStep : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(isTr ? 'Önceki' : 'Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withOpacity(0.05),
                      disabledForegroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // İleri/Bitir butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStep < widget.steps.length - 1
                        ? _nextStep
                        : () => _showCompleteDialog(context, isTr),
                    icon: Icon(
                      _currentStep == widget.steps.length - 1
                          ? Icons.celebration
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentStep == widget.steps.length - 1
                          ? (isTr ? 'Bitir' : 'Finish')
                          : (isTr ? 'Sonraki' : 'Next'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIngredients(BuildContext context, bool isTr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTr ? 'Malzemeler' : 'Ingredients',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.ingredients!.map((ing) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ing,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, bool isTr) {
    final allDone = _completedSteps.length == widget.steps.length;

    if (allDone) {
      // Tüm adımlar tamamlandı - kutlama
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isTr ? 'Afiyet Olsun!' : 'Bon Appétit!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉🍽️👨‍🍳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                isTr
                    ? 'Tüm adımları tamamladın! Yemeğin hazır!'
                    : 'All steps completed! Your meal is ready!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // dialog
                Navigator.pop(context); // cooking mode
              },
              child: Text(isTr ? 'Kapat' : 'Close'),
            ),
          ],
        ),
      );
    } else {
      // Bazı adımlar tamamlanmamış - onay sor
      final remaining = widget.steps.length - _completedSteps.length;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isTr ? 'Emin misin?' : 'Are you sure?'),
          content: Text(
            isTr
                ? '$remaining adım henüz tamamlanmadı. Yine de bitirmek istiyor musun?'
                : '$remaining step(s) not completed yet. Do you still want to finish?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTr ? 'Devam Et' : 'Continue Cooking'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // dialog
                Navigator.pop(context); // cooking mode
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(isTr ? 'Bitir' : 'Finish', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}
