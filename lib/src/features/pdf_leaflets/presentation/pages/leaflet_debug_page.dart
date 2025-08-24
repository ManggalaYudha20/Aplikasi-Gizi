import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class LeafletDebugPage extends StatefulWidget {
  const LeafletDebugPage({super.key});

  @override
  State<LeafletDebugPage> createState() => _LeafletDebugPageState();
}

class _LeafletDebugPageState extends State<LeafletDebugPage> {
  bool _isInitialized = false;
  String _debugInfo = '';
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _isInitialized = true;
        _debugInfo = 'Firebase initialized successfully\n';
      });
      _testFirestoreConnection();
    } catch (e) {
      setState(() {
        _debugInfo = 'Firebase initialization failed: $e\n';
      });
    }
  }

  Future<void> _testFirestoreConnection() async {
    setState(() {
      _isLoading = true;
      _debugInfo += 'Testing Firestore connection...\n';
    });

    try {
      // Test 1: Check if we can access the collection
      final collection = FirebaseFirestore.instance.collection('leaflets');
      _debugInfo += 'Collection reference created: leaflets\n';

      // Test 2: Get collection metadata
      final snapshot = await collection.get();
      _debugInfo += 'Query successful. Found ${snapshot.docs.length} documents\n';

      // Test 3: List all documents
      _documents.clear();
      for (var doc in snapshot.docs) {
        _documents.add({
          'id': doc.id,
          'data': doc.data(),
        });
        _debugInfo += 'Document ${doc.id}: ${doc.data()}\n';
      }

      // Test 4: Check Firestore rules
      try {
        await collection.limit(1).get();
        _debugInfo += 'Firestore rules: Read access granted\n';
      } catch (e) {
        _debugInfo += 'Firestore rules error: $e\n';
      }

    } catch (e) {
      _debugInfo += 'Firestore error: $e\n';
      if (e.toString().contains('permission-denied')) {
        _debugInfo += 'PERMISSION DENIED: Check Firestore rules\n';
      } else if (e.toString().contains('unavailable')) {
        _debugInfo += 'UNAVAILABLE: Check internet connection\n';
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addTestDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('leaflets').add({
        'title': 'Test Leaflet ${DateTime.now().toString()}',
        'description': 'This is a test document added from debug page',
        'url': 'https://example.com/test.pdf',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _debugInfo += 'Test document added successfully\n';
      await _testFirestoreConnection(); // Refresh data
    } catch (e) {
      _debugInfo += 'Error adding test document: $e\n';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaflet Debug Page'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Status: ${_isInitialized ? "Initialized" : "Not Initialized"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isInitialized && !_isLoading ? _testFirestoreConnection : null,
                  child: const Text('Refresh Data'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isInitialized && !_isLoading ? _addTestDocument : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Add Test Doc'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Information:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            if (_documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Documents Found:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._documents.map((doc) => Card(
                child: ListTile(
                  title: Text('ID: ${doc['id']}'),
                  subtitle: Text(doc['data'].toString()),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}