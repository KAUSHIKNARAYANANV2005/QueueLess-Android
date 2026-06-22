import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/glass_card.dart';

class DateTimePickerScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const DateTimePickerScreen({super.key, required this.bookingData});

  @override
  State<DateTimePickerScreen> createState() => _DateTimePickerScreenState();
}

class _DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedTime;
  
  BusinessModel? _business;
  List<BookingModel> _dayBookings = [];
  bool _loading = true;
  List<Map<String, dynamic>> _allSlots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final businessId = widget.bookingData['businessId'] as String;
    
    try {
      _business = await FirebaseService.instance.getBusinessById(businessId);
      await _fetchSlotsForDay();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchSlotsForDay() async {
    if (_business == null) return;
    setState(() => _loading = true);
    
    final businessId = _business!.id;
    // Get bookings for the day to check conflicts
    // In a real app we'd query by date range. We'll fetch all active/confirmed and filter locally for simplicity.
    try {
      final allBookings = await FirebaseService.instance.getBusinessBookings(businessId, _selectedDay);
      _dayBookings = allBookings;
          
      _generateSlots();
    } catch (_) {}
    
    if (mounted) setState(() => _loading = false);
  }

  int _parseTimeStr(String timeStr) {
    // "09:00 AM" -> minutes from midnight
    final parts = timeStr.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    int m = int.parse(hm[1]);
    if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
    if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
    return h * 60 + m;
  }

  String _formatTimeMins(int mins) {
    int h = mins ~/ 60;
    int m = mins % 60;
    String period = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }

  void _generateSlots() {
    _allSlots.clear();
    _selectedTime = null;
    
    if (_business?.hours == null) return;
    
    final dayName = DateFormat('EEEE').format(_selectedDay);
    final hours = _business!.hours![dayName];
    if (hours == null || hours['isOpen'] != true) return; // closed
    
    final startMins = _parseTimeStr(hours['start']);
    final endMins = _parseTimeStr(hours['end']);
    // Default duration 30 if not provided
    int duration = 30;
    
    int currentMins = startMins;
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDay, now);
    final nowMins = now.hour * 60 + now.minute;
    
    final selectedStaffId = widget.bookingData['staffId'] as String?;

    while (currentMins + duration <= endMins) {
      if (isToday && currentMins <= nowMins) {
        currentMins += duration;
        continue;
      }
      
      // Conflict check
      bool available = true;
      int conflictingBookings = _dayBookings.where((b) {
        final bMins = b.dateTime.hour * 60 + b.dateTime.minute;
        return bMins == currentMins && (selectedStaffId == null || b.staffId == selectedStaffId);
      }).length;
      
      if (conflictingBookings > 0) available = false;
      
      _allSlots.add({
        'time': _formatTimeMins(currentMins),
        'available': available,
        'minutes': currentMins,
      });
      
      currentMins += duration;
    }
  }

  DateTime _getSelectedDateTime() {
    if (_selectedTime == null) return _selectedDay;
    final mins = _parseTimeStr(_selectedTime!);
    return DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, mins ~/ 60, mins % 60);
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
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 60)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    onDaySelected: (sel, focused) {
                      setState(() {
                        _selectedDay = sel;
                        _focusedDay = focused;
                      });
                      _fetchSlotsForDay();
                    },
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
                const SizedBox(height: 20),
                Text('Available Slots', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_allSlots.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No available slots for this day.', style: AppTextStyles.body),
                    ),
                  )
                else
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
                            color: isSelected ? null : isAvailable ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
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
              decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: AppShadows.e3),
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
