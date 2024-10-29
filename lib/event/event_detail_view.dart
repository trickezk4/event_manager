import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:event_manager/event/event_model.dart';
import 'package:event_manager/event/event_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;
  const EventDetailView({super.key, required this.event});

  @override
  State<EventDetailView> createState() => _EventDataViewState();
}

class _EventDataViewState extends State<EventDetailView> {
  final subjectController = TextEditingController();
  final notesController = TextEditingController();
  final eventService = EventService();

  @override
  void initState() {
    super.initState();
    subjectController.text = widget.event.subject;
    notesController.text = widget.event.notes ?? '';
  }

  Future<void> _pickedDateTime({required bool isStart}) async {
    // Hiện hộp thoại chọn ngày
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? widget.event.startTime : widget.event.endTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      // Hiện hộp thoại chọn giờ
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStart ? widget.event.startTime : widget.event.endTime,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isStart) {
            widget.event.startTime = newDateTime;
            if (widget.event.startTime.isAfter(widget.event.endTime)) {
              // Tự thiết lập endTime 1 tiếng sau startTime
              widget.event.endTime =
                  widget.event.startTime.add(const Duration(hours: 1));
            }
          } else {
            widget.event.endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    widget.event.subject = subjectController.text;
    widget.event.notes = notesController.text;
    await eventService.saveEvent(widget.event);
    if (!mounted) return;
    Navigator.of(context).pop(true); // Trở về màn hình trước đó
  }

  Future<void> _deleteEvent() async {
    await eventService.deleteEvent(widget.event);
    if (!mounted) return;
    Navigator.of(context).pop(true); // Trở về màn hình trước đó
  }

  @override
  Widget build(BuildContext context) {
    final al = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.id == null ? al!.addEvent : al!.eventDetails,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Tên sự kiện'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Sự kiện cả ngày'),
                trailing: Switch(
                    value: widget.event.isAllDay,
                    onChanged: (value) {
                      setState(() {
                        widget.event.isAllDay = value;
                      });
                    }),
              ),
              // Sử dụng toán tử trải rộng trong dart
              if (!widget.event.isAllDay) ...[
                const SizedBox(height: 16),
                ListTile(
                  title:
                      Text('Bắt đầu: ${widget.event.formatedStartTimeString}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickedDateTime(isStart: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title:
                      Text('Kết thúc: ${widget.event.formatedEndTimeString}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickedDateTime(isStart: false),
                ),
                TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: "Ghi chú sự kiện"),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Chỉ hiển thị nút xóa nếu không phải sự kiện mới
                  if (widget.event.id != null)
                    FilledButton.tonalIcon(
                        onPressed: _deleteEvent,
                        label: const Text('Xóa sự kiện')),
                  FilledButton.icon(
                    onPressed: _saveEvent,
                    label: const Text('Lưu sự kiện'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
