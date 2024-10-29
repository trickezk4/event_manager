// import 'dart:collection';

import 'package:event_manager/event/event_data_source.dart';
import 'package:event_manager/event/event_detail_view.dart';
import 'package:event_manager/event/event_model.dart';
import 'package:event_manager/event/event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class EventView extends StatefulWidget {
  const EventView({super.key});

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  final eventService = EventService();

  // Danh sách sự kiện
  List<EventModel> items = [];

  // Tạo CalendarController để điều khiển SfCalendar
  final calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    calendarController.view = CalendarView.day;
    loadEvents();
  }

  Future<void> loadEvents() async {
    final events = await eventService.getAllEvents();
    setState(() {
      items = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    final al = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(al.appTitle),
        actions: [
          PopupMenuButton<CalendarView>(
            onSelected: (value) {
              setState(() {
                calendarController.view = value;
              });
            },
            itemBuilder: (context) => CalendarView.values.map((view) {
              return PopupMenuItem<CalendarView>(
                value: view,
                child: ListTile(
                  title: Text(view.name),
                ),
              );
            }).toList(),
            icon: getCalendarViewIcon(calendarController.view!),
          ),
          IconButton(
            onPressed: () {
              calendarController.displayDate = DateTime.now();
            },
            icon: const Icon(Icons.today_outlined),
          ),
          IconButton(
            onPressed: loadEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SfCalendar(
        controller: calendarController,
        dataSource: EventDataSource(items),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment),
        // Nhấn giữ vào cell để thêm sự kiện
        onLongPress: (details) {
          // Không có sự kiện trong cell
          if (details.targetElement == CalendarElement.calendarCell) {
            // Tạo một đối tượng sự kiện tại thời gian trong lịch theo giao diện
            final newEvent = EventModel(
                startTime: details.date!,
                endTime: details.date!.add(const Duration(hours: 1)),
                subject: 'Sự kiện mới');
            // Điều hướng và định tuyến bàng cách đưa newEvent vào detail view
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return EventDetailView(event: newEvent);
              },
            )).then((value) async {
              // Sau khi pop ở detail view
              if (value == true) {
                await loadEvents();
              }
            });
          }
        },
        // Chạm vào sự kiện để xem và cập nhật
        onTap: (details) {
          // touch vào sự kiện -> sửa hoặc xóa
          if (details.targetElement == CalendarElement.appointment) {
            final EventModel event = details.appointments!.first;
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return EventDetailView(event: event);
              },
            )).then((value) async {
              // Sau khi pop ở detail view
              if (value == true) {
                await loadEvents();
              }
            });
          }
        },
      ),
    );
  }

  // Hàm lấy icon tương ứng với calendar view
  Icon getCalendarViewIcon(CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return const Icon(Icons.calendar_view_day_outlined);
      case CalendarView.week:
        return const Icon(Icons.calendar_view_week_outlined);
      case CalendarView.workWeek:
        return const Icon(Icons.work_history_outlined);
      case CalendarView.month:
        return const Icon(Icons.calendar_view_month_outlined);
      case CalendarView.schedule:
        return const Icon(Icons.schedule_outlined);
      default:
        return const Icon(Icons.calendar_today_outlined);
    }
  }
}
