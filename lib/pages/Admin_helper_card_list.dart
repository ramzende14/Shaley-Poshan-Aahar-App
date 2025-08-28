// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zp/pages/Admin_helper_mandhan_page.dart';

class HelperCardList extends StatelessWidget {
  const HelperCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0), // ✅ 1.5cm space below AppBar
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('helpers').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    elevation: 4,
                    child: ListTile(
                      title: Text(name, style: const TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HelperMandanPage(helperName: name),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(context, doc.id, name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, doc.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddHelperDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'नवीन मदतनीस जोडा',
      ),
    );
  }

  void _showAddHelperDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('नवीन मदतनीस जोडा'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'नाव'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('helpers').add({'name': name});
              }
              Navigator.pop(context);
            },
            child: const Text('जोडा'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String docId, String oldName) {
    final nameController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('मदतनीस नाव बदला'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'नाव'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance.collection('helpers').doc(docId).update({'name': newName});
              }
              Navigator.pop(context);
            },
            child: const Text('अपडेट'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('हटवा'),
        content: const Text('तुला हा मदतनीस हटवायचा आहे का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('helpers').doc(docId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('हो'),
          ),
        ],
      ),
    );
  }
}
