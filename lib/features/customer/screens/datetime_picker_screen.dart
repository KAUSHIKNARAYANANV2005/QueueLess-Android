import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/glass_card.dart';

class DateTimePickerScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const DateTimePickerScreen({super.key, required this.bookingData});

  @override
  State<DateTimePickerScreen> createState() => _DateTimePickerScreenState();
}

class _DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime _selectedDay = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  final List<String> _aiSlots = ['10:00 AM', '2:00 PM', '4:30 PM'];
  final List<Map<String, dynamic>> _allSlots = [
    {'time': '9:00 AM', 'available': true},
    {'time': '9:30 AM', 'available': false},
    {'time': '10:00 AM', 'available': true},
    {'time': '10:30 AM', 'available': true},
    {'time': '11:00 AM', 'available': false},
    {'time': '11:30 AM', 'available': true},
    {'time': '12:00 PM', 'available': false},
    {'time': '12:30 PM', 'available': true},
    {'time': '2:00 PM', 'available': true},
    {'time': '2:30 PM', 'available': true},
    {'time': '4:00 PM', 'available': true},
    {'time': '4:30 PM', 'available': true},
  ];

  DateTime _getSelectedDateTime() {
    if (_selectedTime == null) return _selectedDay;
    final timeParts = _selectedTime!.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (_selectedTime!.contains('PM') && hour != 12) hour += 12;
    if (_selectedTime!.contains('AM') && hour == 12) hour = 0;
    return DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.bookingData['serviceName'] ?? 'Service';
    final price = (widget.bookingData['price'] ?? 0.0) as double;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Date & Time'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected service chip
                Container(
                  margin: const EdgeInsets.only(bottom: 12, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('$serviceName · ₹${price.toInt()}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
                // Calendar
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 60)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    onDaySelected: (sel, focused) => setState(() {
                      _selectedDay = sel;
                      _focusedDay = focused;
                      _selectedTime = null;
                    }),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                      todayTextStyle: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      weekendTextStyle: AppTextStyles.body.copyWith(color: AppColors.coralError),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppTextStyles.h4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selected date display
                Text(
                  'Selected: ${DateFormat('EEEE, MMMM d').format(_selectedDay)}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // AI recommended slots
                GlassCard(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.08),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.tealSuccess, size: 16),
                      const SizedBox(width: 6),
                      Text('AI Recommended Slots', style: AppTextStyles.label.copyWith(color: AppColors.tealSuccess)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _aiSlots.map((t) => GestureDetector(
                        onTap: () => setState(() => _selectedTime = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: _selectedTime == t ? AppGradients.teal : null,
                            color: _selectedTime == t ? null : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: AppColors.tealSuccess.withValues(alpha: 0.4)),
                          ),
                          child: Text(t, style: TextStyle(
                            color: _selectedTime == t ? Colors.white : AppColors.tealSuccess,
                            fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                        ),
                      )).toList(),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Text('All Available Slots', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8, crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: _allSlots.map((slot) {
                    final isSelected = _selectedTime == slot['time'];
                    final isAvailable = slot['available'] as bool;
                    return GestureDetector(
                      onTap: isAvailable ? () => setState(() => _selectedTime = slot['time'] as String) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.primary : null,
                          color: isSelected ? null : isAvailable ? Colors.white : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : isAvailable ? AppColors.border : Colors.transparent,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot['time'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : isAvailable ? AppColors.textPrimary : AppColors.textHint,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.e3),
              child: PremiumButton(
                label: _selectedTime == null ? 'Select a time slot' : 'Confirm: $_selectedTime →',
                onPressed: _selectedTime == null
                    ? null
                    : () => context.push('/booking-confirmation', extra: {
                        ...widget.bookingData,
                        'selectedDateTime': _getSelectedDateTime().toIso8601String(),
                        'selectedTime': _selectedTime,
                        'selectedDate': DateFormat('MMM d, yyyy').format(_selectedDay),
                      }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
