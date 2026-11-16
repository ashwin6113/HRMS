import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: "Calendar & Leaves"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Calendar & Schedule Screen", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
