// ignore_for_file: unused_import, file_names, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthWiseWrapperPage extends StatefulWidget {
  final Widget Function(String month) builder;
  const MonthWiseWrapperPage({super.key, required this.builder});

  @override
  State<MonthWiseWrapperPage> createState() => _MonthWiseWrapperPageState();
}

class _MonthWiseWrapperPageState extends State<MonthWiseWrapperPage> {
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
          child: DropdownButtonFormField<String>(
            value: _selectedMonth,
            items: _months
                .map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    ))
                .toList(),
            onChanged: (val) => setState(() {
              _selectedMonth = val!;
            }),
            decoration: InputDecoration(
              labelText: 'महिना निवडा',
              border: OutlineInputBorder(),
            ),
          ),
      
          ),  ),
        Expanded(
          child: widget.builder(_selectedMonth),
        ),
      ],
    );
  }
}
