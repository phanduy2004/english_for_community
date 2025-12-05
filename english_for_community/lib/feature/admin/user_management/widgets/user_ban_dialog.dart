import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dashboard_home/bloc/admin_bloc.dart';
import '../../dashboard_home/bloc/admin_event.dart';

class UserBanDialog extends StatefulWidget {
  final String userId; // Receive user ID to ban

  const UserBanDialog({super.key, required this.userId});

  @override
  State<UserBanDialog> createState() => _UserBanDialogState();
}

class _UserBanDialogState extends State<UserBanDialog> {
  String _selectedType = 'temporary'; // 'temporary' | 'permanent'
  int _selectedHours = 24;
  final TextEditingController _reasonController = TextEditingController();

  // Shadcn Colors
  final textMain = const Color(0xFF09090B);
  final textMuted = const Color(0xFF71717A);
  final borderCol = const Color(0xFFE4E4E7);

  final List<int> _durationOptions = [1, 6, 12, 24, 72, 168]; // Hours

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Ban Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: textMain)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Select Type
              Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderCol),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Temporary', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Automatically unbanned after duration', style: TextStyle(fontSize: 12)),
                      value: 'temporary',
                      groupValue: _selectedType,
                      activeColor: textMain,
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                    Divider(height: 1, color: borderCol),
                    RadioListTile<String>(
                      title: const Text('Permanent', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Cannot access again', style: TextStyle(fontSize: 12)),
                      value: 'permanent',
                      groupValue: _selectedType,
                      activeColor: Colors.red,
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Select Duration (If temporary)
              if (_selectedType == 'temporary') ...[
                Text('Ban Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durationOptions.map((hours) {
                    final isSelected = _selectedHours == hours;
                    return ChoiceChip(
                      label: Text(_formatDuration(hours)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedHours = hours);
                      },
                      selectedColor: textMain,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textMain,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? textMain : borderCol),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Reason
              Text('Reason (Required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ex: Spam messages, inappropriate language...',
                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: textMain),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: textMain,
            side: BorderSide(color: borderCol),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              // Simple validation
              return;
            }

            // --- CALL BLOC HERE ---
            context.read<AdminBloc>().add(BanUserEvent(
              userId: widget.userId,
              banType: _selectedType,
              durationInHours: _selectedType == 'permanent' ? 0 : _selectedHours,
              reason: _reasonController.text,
            ));

            Navigator.pop(context); // Close Dialog
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626), // Red-600
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm Ban'),
        ),
      ],
    );
  }

  String _formatDuration(int hours) {
    if (hours >= 24) {
      final days = hours ~/ 24;
      return '$days days';
    }
    return '$hours hours';
  }
}