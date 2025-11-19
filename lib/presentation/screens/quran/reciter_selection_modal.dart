// [ ملف جديد: lib/presentation/screens/quran/reciter_selection_modal.dart ]

import 'package:flutter/material.dart';
import '../../../data/models/quran_models.dart';

class ReciterSelectionModal extends StatelessWidget {
  final List<Reciter> reciters;
  final Function(Reciter reciter) onReciterSelected;
  final int? selectedReciterId;

  const ReciterSelectionModal({
    super.key,
    required this.reciters,
    required this.onReciterSelected,
    this.selectedReciterId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("اختر القارئ", style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: reciters.length,
              itemBuilder: (context, index) {
                final reciter = reciters[index];
                final isSelected = reciter.id == selectedReciterId;
                
                return ListTile(
                  title: Text(reciter.nameArabic),
                  subtitle: Text("${reciter.bitRate} | ${reciter.slug}"),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => onReciterSelected(reciter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}