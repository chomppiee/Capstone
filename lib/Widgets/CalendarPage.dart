// lib/widgets/CalendarPage.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Calendar'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_highlights')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 1) Build map of day → [docId]
          _events.clear();
          for (var doc in snap.data!.docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final ts = data['date_time'] as Timestamp?;
            if (ts == null) continue;
            final d = ts.toDate();
            final dayKey = DateTime(d.year, d.month, d.day);
            _events.putIfAbsent(dayKey, () => []).add(doc.id);
          }

          // Helper: get IDs for a given day
          List<String> _getEventsForDay(DateTime day) {
            return _events[DateTime(day.year, day.month, day.day)] ?? [];
          }

          // 2) Filter docs for the focused month
          final monthDocs = snap.data!.docs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final ts = data['date_time'] as Timestamp?;
            if (ts == null) return false;
            final d = ts.toDate();
            return d.year == _focusedDay.year && d.month == _focusedDay.month;
          }).toList();

          return Column(
            children: [
              // --- Calendar Widget ---
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() {
                    _focusedDay = focused;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // --- Events This Month ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Events in ${DateFormat.yMMMM().format(_focusedDay)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              monthDocs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No events this month'),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: monthDocs.length,
                        itemBuilder: (context, idx) {
                          final doc = monthDocs[idx];
                          final data = doc.data()! as Map<String, dynamic>;
                          final title = data['title'] ?? 'Untitled';
                          final ts = data['date_time'] as Timestamp?;
                          final dayStr = ts != null
                              ? DateFormat.d().format(ts.toDate())
                              : '';
                          return GestureDetector(
                            onTap: () => _showEventDetails(context, doc.id),
                            child: Card(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayStr,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        title,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 8),

              // --- Events on Selected Day ---
              Expanded(
                child: Builder(builder: (_) {
                  final dayEvents =
                      _getEventsForDay(_selectedDay ?? _focusedDay);
                  if (dayEvents.isEmpty) {
                    return const Center(child: Text('No events on this day'));
                  }
                  return ListView.builder(
                    itemCount: dayEvents.length,
                    itemBuilder: (context, i) {
                      final docId = dayEvents[i];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('community_highlights')
                            .doc(docId)
                            .get(),
                        builder: (context, dsnap) {
                          if (!dsnap.hasData) return const SizedBox();
                          final data =
                              dsnap.data!.data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Untitled';
                          final ts = data['date_time'] as Timestamp?;
                          final timeStr = ts != null
                              ? DateFormat('hh:mm a').format(ts.toDate())
                              : '';
                          return ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(title),
                            subtitle: timeStr.isNotEmpty
                                ? Text(timeStr)
                                : null,
                            onTap: () => _showEventDetails(context, docId),
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  // Reusable detail dialog
  void _showEventDetails(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('community_highlights')
            .doc(docId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data()! as Map<String, dynamic>;
          final title = data['title'] ?? 'Untitled';
          final desc = data['description'] ?? '';
          final img = (data['image_url'] as String?) ?? '';
          final ts = data['date_time'] as Timestamp?;
          final dateStr = ts != null
              ? DateFormat('EEE, MMM d').format(ts.toDate())
              : '';
          final timeStr = ts != null
              ? DateFormat('hh:mm a').format(ts.toDate())
              : '';

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (img.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Image.network(img,
                          height: 200, fit: BoxFit.cover),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        if (dateStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text(dateStr),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Text(timeStr),
                              ],
                            ),
                          ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(desc),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
