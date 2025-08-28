// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

void addVastuRecord() async {
  Map<String, String> vastuData = {
    'name': 'मटकी',
    'next_month_demand': '0',
    'previous_stock': '0',
    'received_this_month': '0',
    'remaining': '0',
    'total': '0',
    'used': '0',
  };

  try {
    await FirebaseFirestore.instance
        .collection('vastu_records')
        .doc('April')
        .collection('items')
        .add(vastuData);

    // ignore: avoid_print
    print('✅ Vastu record added successfully.');
  } catch (e) {
    print('❌ Error adding record: $e');
  }
}
