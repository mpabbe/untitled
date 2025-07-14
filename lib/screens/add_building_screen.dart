import 'package:flutter/material.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';

class AddBuildingScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const AddBuildingScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _uniqueNameController = TextEditingController();
  final _regionNameController = TextEditingController();

  String? _selectedVerificationPerson;
  BuildingStatus _selectedStatus = BuildingStatus.notStarted;
  String? _selectedKolodetsStatus;

  final List<TextEditingController> _imageUrlControllers = [];

  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _valueControllers = [];
  final List<TextEditingController> _sizeControllers = []; // yangi o'lchami uchun controllerlar

  bool _isSaving = false;

  final _tasdiqlovchilar = ['Алишер Каримов', 'Шахноз Иброҳимова', 'Бобур Раҳимов'];
  final _kolodetsStatusList = ['Бор', 'Йўқ', 'Номаълум'];

  @override
  void initState() {
    super.initState();
    _addKeyValue();
    _addImageUrlField();
  }

  void _addKeyValue() {
    setState(() {
      _keyControllers.add(TextEditingController());
      _valueControllers.add(TextEditingController());
      _sizeControllers.add(TextEditingController()); // yangi maydon uchun
    });
  }

  void _removeKeyValue(int index) {
    if (_keyControllers.length > 1) {
      setState(() {
        _keyControllers[index].dispose();
        _valueControllers[index].dispose();
        _sizeControllers[index].dispose(); // yangi maydon uchun
        _keyControllers.removeAt(index);
        _valueControllers.removeAt(index);
        _sizeControllers.removeAt(index); // yangi maydon uchun
      });
    }
  }

  void _addImageUrlField() {
    setState(() {
      _imageUrlControllers.add(TextEditingController());
    });
  }

  void _removeImageUrlField(int index) {
    setState(() {
      _imageUrlControllers[index].dispose();
      _imageUrlControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrls = _imageUrlControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      // Endi materiallarni List<Map<String, String>> formatida saqlaymiz
      final materials = <Map<String, String>>[];
      for (int i = 0; i < _keyControllers.length; i++) {
        final key = _keyControllers[i].text.trim();
        final value = _valueControllers[i].text.trim();
        final size = _sizeControllers[i].text.trim();

        if (key.isNotEmpty && value.isNotEmpty) {
          final material = {
            'name': key,
            'quantity': value,
          };
          if (size.isNotEmpty) {
            material['size'] = size;
          }
          materials.add(material);
        }
      }

      final building = Building(
        id: id,
        latitude: widget.latitude,
        longitude: widget.longitude,
        uniqueName: _uniqueNameController.text.trim(),
        regionName: _regionNameController.text.trim(),
        verificationPerson: _selectedVerificationPerson,
        kolodetsStatus: _selectedKolodetsStatus,
        images: imageUrls,
        customData: materials,
        status: _selectedStatus,
        createdAt: DateTime.now(),
      );

      await FirebaseService.saveBuilding(building);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Бино сақланди'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатолик: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildImagePreview(String url) {
    if (url.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8),
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(height: 4),
                  Text('URL хато', style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uniqueNameController.dispose();
    _regionNameController.dispose();
    for (final c in _imageUrlControllers) {
      c.dispose();
    }
    for (final c in _keyControllers) {
      c.dispose();
    }
    for (final c in _valueControllers) {
      c.dispose();
    }
    for (final c in _sizeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Янги бино қўшиш'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_uniqueNameController, 'Юник номи', required: true),
              SizedBox(height: 12),
              _buildTextField(_regionNameController, 'Ҳудуд номи', required: true),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedVerificationPerson,
                decoration: InputDecoration(
                  labelText: 'Тасдиқловчи одам',
                  border: OutlineInputBorder(),
                ),
                items: _tasdiqlovchilar
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVerificationPerson = val),
                validator: (val) => val == null ? 'Илтимос танланг' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedKolodetsStatus,
                decoration: InputDecoration(
                  labelText: 'Колодец статус',
                  border: OutlineInputBorder(),
                ),
                items: _kolodetsStatusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedKolodetsStatus = val),
                validator: (val) => val == null ? 'Илтимос танланг' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<BuildingStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Иш ҳолати',
                  border: OutlineInputBorder(),
                ),
                items: BuildingStatus.values
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(_statusText(status)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              SizedBox(height: 20),

              // Image URLs section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Расм URLлари:',
                            style: Theme.of(context).textTheme.titleMedium),
                        ElevatedButton.icon(
                          onPressed: _addImageUrlField,
                          icon: Icon(Icons.add_link),
                          label: Text('URL қўшиш'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ..._imageUrlControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: 'Rasm URL ${index + 1}',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.image),
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () => _removeImageUrlField(index),
                                ),
                              ],
                            ),
                            _buildImagePreview(controller.text.trim()),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_imageUrlControllers.isEmpty)
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Ҳали расм қўшилмаган',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Construction materials section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Қурилиш материаллари:',
                            style: Theme.of(context).textTheme.titleMedium),
                        ElevatedButton.icon(
                          onPressed: _addKeyValue,
                          icon: Icon(Icons.add),
                          label: Text('Материал қўшиш'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ListView.builder(
                      itemCount: _keyControllers.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _keyControllers[i],
                                    decoration: InputDecoration(
                                      labelText: 'Номи',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.construction),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _valueControllers[i],
                                    decoration: InputDecoration(
                                      labelText: 'Миқдори',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.numbers),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: _keyControllers.length > 1
                                      ? () => _removeKeyValue(i)
                                      : null,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _sizeControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Ўлчами (ихтиёрий)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.straighten),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Сақлаш', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.text_fields),
      ),
      validator: (value) =>
      required && (value == null || value.isEmpty) ? 'Майдон тўлдирилиши шарт' : null,
    );
  }

  String _statusText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted:
        return 'Бошланмаган';
      case BuildingStatus.inProgress:
        return 'Жараёнда';
      case BuildingStatus.finished:
        return 'Тугалланган';
    }
  }
}
