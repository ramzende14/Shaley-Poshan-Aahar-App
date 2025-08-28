import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VastuReadOnlyTable extends StatefulWidget {
  final String selectedMonth;
  const VastuReadOnlyTable({super.key, required this.selectedMonth});

  @override
  State<VastuReadOnlyTable> createState() => _VastuReadOnlyTableState();
}

class _VastuReadOnlyTableState extends State<VastuReadOnlyTable> {
  Map<String, Map<String, String>> allData = {};
  bool isLoading = true;

  final List<String> itemNames = [
    "तांदूळ", "गहू", "मुगडाळ", "तूरडाळ", "मसूरडाळ", "मटकी",
    "वाटाणा", "हरभरा", "मूग", "चवळी", "सोयाबीन वडी", "मीठ",
    "हळद", "भाजीपाला", "साखर", "मिरची पावडर / मसाला",
    "दूध / दुध पावडर", "नाचणी सत्व", "सोयाबीन तेल", "जिरे"
  ];

  final List<String> headers = [
    "अ.क्र", "वस्तूचे नाव", "मागील शिल्लक", "प्राप्ती (महिना)",
    "एकूण", "वापरलेले", "शिल्लक", "पुढील महिन्याची मागणी", "Edit"
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    Map<String, Map<String, String>> tempData = {};

    for (String itemName in itemNames) {
      if (itemName == "तांदूळ") {
        final snap = await FirebaseFirestore.instance
            .collection('tandul_entries')
            .where('month', isEqualTo: widget.selectedMonth)
            .get();

        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.data();
          double received = double.tryParse(doc['received'] ?? '0') ?? 0;
          double used = double.tryParse(doc['used'] ?? '0') ?? 0;
          double total = double.tryParse(doc['total'] ?? '0') ?? 0;
          double previous = total - received;
          double remaining = total - used;

          tempData[itemName] = {
            "previous_stock": previous.toStringAsFixed(2),
            "received_this_month": received.toStringAsFixed(2),
            "total": total.toStringAsFixed(2),
            "used": used.toStringAsFixed(2),
            "remaining": remaining.toStringAsFixed(2),
            "next_month_demand": "0"
          };
        } else {
          tempData[itemName] = _emptyRow();
        }
      } else {
        final snap = await FirebaseFirestore.instance
            .collection('vastu_records')
            .doc(widget.selectedMonth)
            .collection('items')
            .where('name', isEqualTo: itemName)
            .get();

        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.data();
          double previous = double.tryParse(doc["previous_stock"] ?? "0") ?? 0;
          double received = double.tryParse(doc["received_this_month"] ?? "0") ?? 0;
          double used = double.tryParse(doc["used"] ?? "0") ?? 0;
          double total = previous + received;
          double remaining = total - used;

          tempData[itemName] = {
            "previous_stock": previous.toStringAsFixed(2),
            "received_this_month": received.toStringAsFixed(2),
            "total": total.toStringAsFixed(2),
            "used": used.toStringAsFixed(2),
            "remaining": remaining.toStringAsFixed(2),
            "next_month_demand": (doc["next_month_demand"] ?? "0").toString()
          };
        } else {
          tempData[itemName] = _emptyRow();
        }
      }
    }

    setState(() {
      allData = tempData;
      isLoading = false;
    });
  }

  Map<String, String> _emptyRow() {
    return {
      "previous_stock": "0.00",
      "received_this_month": "0.00",
      "total": "0.00",
      "used": "0.00",
      "remaining": "0.00",
      "next_month_demand": "0"
    };
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("महिना: ${widget.selectedMonth}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 900),
                  child: Table(
                    border: TableBorder.all(color: Colors.black),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(50),
                      1: FixedColumnWidth(140),
                      8: FixedColumnWidth(60),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.deepPurple.shade100),
                        children: headers
                            .map((header) => Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(header,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                      ),
                      for (int i = 0; i < itemNames.length; i++) _buildDataRow(i),
                    ],
                  ),
                ),
              )
            ],
          );
  }

  TableRow _buildDataRow(int index) {
    String name = itemNames[index];
    final data = allData[name] ?? _emptyRow();

    return TableRow(
      children: [
        _cell("${index + 1}"),
        _cell(name),
        _cell(data["previous_stock"]!),
        _cell(data["received_this_month"]!),
        _cell(data["total"]!),
        _cell(data["used"]!),
        _cell(data["remaining"]!),
        _cell(data["next_month_demand"]!),
        IconButton(
          onPressed: () => _showEditDialog(name, data),
          icon: const Icon(Icons.edit, color: Colors.deepPurple),
          tooltip: "Edit",
        ),
      ],
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  void _showEditDialog(String itemName, Map<String, String> data) {
    final previousController = TextEditingController(text: data["previous_stock"]);
    final receivedController = TextEditingController(text: data["received_this_month"]);
    final usedController = TextEditingController(text: data["used"]);
    final demandController = TextEditingController(text: data["next_month_demand"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$itemName चे संपादन करा"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: "मागील शिल्लक"), controller: previousController),
            TextField(decoration: const InputDecoration(labelText: "महिन्याची प्राप्ती"), controller: receivedController),
            TextField(decoration: const InputDecoration(labelText: "वापरलेले"), controller: usedController),
            TextField(decoration: const InputDecoration(labelText: "पुढील महिन्याची मागणी"), controller: demandController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("रद्द")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final previous = double.tryParse(previousController.text) ?? 0;
                final received = double.tryParse(receivedController.text) ?? 0;
                final used = double.tryParse(usedController.text) ?? 0;
                final total = previous + received;
                final remaining = total - used;

                allData[itemName] = {
                  "previous_stock": previous.toStringAsFixed(2),
                  "received_this_month": received.toStringAsFixed(2),
                  "total": total.toStringAsFixed(2),
                  "used": used.toStringAsFixed(2),
                  "remaining": remaining.toStringAsFixed(2),
                  "next_month_demand": demandController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text("जतन करा"),
          )
        ],
      ),
    );
  }
}
