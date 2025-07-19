import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class VerifierManagementScreen extends StatefulWidget {
  @override
  _VerifierManagementScreenState createState() => _VerifierManagementScreenState();
}

class _VerifierManagementScreenState extends State<VerifierManagementScreen> {
  List<Map<String, dynamic>> _verifiers = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVerifiers();
  }

  Future<void> _loadVerifiers() async {
    try {
      final verifiers = await FirebaseService.getAllVerifiers();
      setState(() {
        _verifiers = verifiers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Тасдиқловчиларни юклашда хатолик: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тасдиқловчилар бошқаруви'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAddVerifierDialog,
            icon: Icon(Icons.add),
            tooltip: 'Янги тасдиқловчи қўшиш',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _verifiers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Тасдиқловчилар мавжуд эмас'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddVerifierDialog,
                        icon: Icon(Icons.add),
                        label: Text('Биринчи тасдиқловчини қўшиш'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _verifiers.length,
                  itemBuilder: (context, index) {
                    final verifier = _verifiers[index];
                    final isActive = verifier['isActive'] ?? true; // Null safety
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.red,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(verifier['name'] ?? 'Номсиз'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Калит: ${verifier['key'] ?? 'Йўқ'}'),
                            Text(
                              isActive ? 'Фаол' : 'Нофаол',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.block : Icons.check_circle,
                                    color: isActive ? Colors.red : Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(isActive ? 'Нофаол қилиш' : 'Фаол қилиш'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Таҳрирлаш'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Ўчириш'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) => _handleMenuAction(value, verifier),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> verifier) {
    switch (action) {
      case 'toggle':
        _toggleVerifierStatus(verifier);
        break;
      case 'edit':
        _showEditVerifierDialog(verifier);
        break;
      case 'delete':
        _showDeleteConfirmation(verifier);
        break;
    }
  }

  Future<void> _toggleVerifierStatus(Map<String, dynamic> verifier) async {
    try {
      final currentStatus = verifier['isActive'] ?? true; // Null safety
      await FirebaseService.updateVerifierStatus(
        verifier['key'],
        !currentStatus,
      );
      _loadVerifiers();
      _showSuccess('Тасдиқловчи ҳолати ўзгартирилди');
    } catch (e) {
      _showError('Хатолик: $e');
    }
  }

  void _showAddVerifierDialog() {
    _nameController.clear();
    _keyController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Янги тасдиқловчи қўшиш'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Исм',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Калит',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Бекор қилиш'),
          ),
          ElevatedButton(
            onPressed: _addVerifier,
            child: Text('Қўшиш'),
          ),
        ],
      ),
    );
  }

  void _showEditVerifierDialog(Map<String, dynamic> verifier) {
    _nameController.text = verifier['name'];
    _keyController.text = verifier['key'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Тасдиқловчини таҳрирлаш'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Исм',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Калит',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Бекор қилиш'),
          ),
          ElevatedButton(
            onPressed: () => _updateVerifier(verifier['key']),
            child: Text('Сақлаш'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVerifier() async {
    if (_nameController.text.trim().isEmpty || _keyController.text.trim().isEmpty) {
      _showError('Барча майdonларни тўлдиринг');
      return;
    }

    try {
      await FirebaseService.addVerifier(
        _nameController.text.trim(),
        _keyController.text.trim(),
      );
      Navigator.pop(context);
      _loadVerifiers();
      _showSuccess('Тасдиқловчи қўшилди');
    } catch (e) {
      _showError('Хатолик: $e');
    }
  }

  Future<void> _updateVerifier(String oldKey) async {
    try {
      await FirebaseService.updateVerifier(
        oldKey,
        _nameController.text.trim(),
        _keyController.text.trim(),
      );
      Navigator.pop(context);
      _loadVerifiers();
      _showSuccess('Тасдиқловчи янгиланди');
    } catch (e) {
      _showError('Хатолик: $e');
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> verifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Тасдиқловчини ўчириш'),
        content: Text('${verifier['name']} тасдиқловчисини ўчиришни хоҳлайсизми?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Йўқ'),
          ),
          ElevatedButton(
            onPressed: () => _deleteVerifier(verifier['key']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ҳа, ўчириш'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVerifier(String key) async {
    try {
      await FirebaseService.deleteVerifier(key);
      Navigator.pop(context);
      _loadVerifiers();
      _showSuccess('Тасдиқловчи ўчирилди');
    } catch (e) {
      _showError('Хатолик: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }
}


