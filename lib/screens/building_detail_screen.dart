import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';
import 'map_picker_screen.dart';

class BuildingDetailScreen extends StatefulWidget {
  final Building building;

  const BuildingDetailScreen({Key? key, required this.building}) : super(key: key);

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _uniqueNameController;
  late TextEditingController _regionNameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String? _selectedVerificationPerson;
  String? _selectedKolodetsStatus;
  late BuildingStatus _status;

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _sizeControllers = [];

  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _tasdiqlovchilar = ['Алишер Каримов', 'Шахноз Иброҳимова', 'Бобур Раҳимов'];
  final List<String> _kolodetsStatusList = ['Бор', 'Йўқ', 'Номаълум'];

  @override
  void initState() {
    super.initState();

    _uniqueNameController = TextEditingController(text: widget.building.uniqueName);
    _regionNameController = TextEditingController(text: widget.building.regionName);
    _latitudeController = TextEditingController(text: widget.building.latitude.toString());
    _longitudeController = TextEditingController(text: widget.building.longitude.toString());

    _selectedVerificationPerson = widget.building.verificationPerson;
    _selectedKolodetsStatus = widget.building.kolodetsStatus;
    _status = widget.building.status;

    // customData dan controllerlarni yaratish
    if (widget.building.customData.isNotEmpty) {
      for (var item in widget.building.customData) {
        _nameControllers.add(TextEditingController(text: item['name'] ?? ''));
        _quantityControllers.add(TextEditingController(text: item['quantity'] ?? ''));
        _sizeControllers.add(TextEditingController(text: item['size'] ?? ''));
      }
    } else {
      // Kamida bitta bo‘sh satr bo‘lsin
      _addMaterialField();
    }
  }

  void _addMaterialField() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController());
      _sizeControllers.add(TextEditingController());
    });
  }

  void _removeMaterialField(int index) {
    if (_nameControllers.length <= 1) return; // Hech qachon hammasini olib tashlamaslik uchun

    setState(() {
      _nameControllers[index].dispose();
      _quantityControllers[index].dispose();
      _sizeControllers[index].dispose();

      _nameControllers.removeAt(index);
      _quantityControllers.removeAt(index);
      _sizeControllers.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Materiallarni List<Map<String,String>> shaklida yig‘ish
      final List<Map<String, String>> materials = [];
      for (int i = 0; i < _nameControllers.length; i++) {
        final name = _nameControllers[i].text.trim();
        final quantity = _quantityControllers[i].text.trim();
        final size = _sizeControllers[i].text.trim();

        if (name.isNotEmpty && quantity.isNotEmpty) {
          final map = {
            'name': name,
            'quantity': quantity,
          };
          if (size.isNotEmpty) map['size'] = size;
          materials.add(map);
        }
      }

      final updatedBuilding = Building(
        id: widget.building.id,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        uniqueName: _uniqueNameController.text.trim(),
        regionName: _regionNameController.text.trim(),
        verificationPerson: _selectedVerificationPerson,
        kolodetsStatus: _selectedKolodetsStatus,
        status: _status,
        images: widget.building.images, // Bu yerda o'zgarmas qoladi (agar kerak bo'lsa o'zgartiring)
        customData: materials,
        createdAt: widget.building.createdAt,
      );

      await FirebaseService.saveBuilding(updatedBuilding);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oʻzgarishlar saqlandi'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updatedBuilding); // Orqaga updatedBuilding bilan qaytish
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik yuz berdi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Binoni oʻchirish'),
        content: Text('Rostdan ham oʻchirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Bekor qilish')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await FirebaseService.deleteBuilding(widget.building.id);
                if (mounted) Navigator.pop(context, 'deleted');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isDeleting = false);
              }
            },
            child: Text('Oʻchirish', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _statusToText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted:
        return 'Boshlanmagan';
      case BuildingStatus.inProgress:
        return 'Jarayonda';
      case BuildingStatus.finished:
        return 'Tugallangan';
    }
  }

  Future<void> _openInMaps() async {
    final lat = _latitudeController.text;
    final lng = _longitudeController.text;
    final url = 'https://maps.yandex.com/?ll=$lng,$lat&z=16';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xarita ochilmadi')));
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: double.tryParse(_latitudeController.text) ?? 0.0,
          initialLongitude: double.tryParse(_longitudeController.text) ?? 0.0,
        ),
      ),
    );

    if (result is Map<String, double>) {
      setState(() {
        _latitudeController.text = result['lat']!.toStringAsFixed(6);
        _longitudeController.text = result['lng']!.toStringAsFixed(6);
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool required = true,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: required
          ? (val) => val == null || val.isEmpty ? 'To\'ldirish shart' : null
          : null,
    );
  }

  @override
  void dispose() {
    _uniqueNameController.dispose();
    _regionNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    for (var c in _nameControllers) c.dispose();
    for (var c in _quantityControllers) c.dispose();
    for (var c in _sizeControllers) c.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bino tafsilotlari'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _isDeleting ? null : _showDeleteDialog,
          ),
        ],
      ),
      body: _isSaving || _isDeleting
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_uniqueNameController, 'Noyob nom'),
              SizedBox(height: 12),
              _buildTextField(_regionNameController, 'Hudud nomi'),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedVerificationPerson,
                decoration: InputDecoration(
                  labelText: 'Tekshiruvchi shaxs',
                  border: OutlineInputBorder(),
                ),
                items: _tasdiqlovchilar
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVerificationPerson = val),
                validator: (val) => val == null ? 'Tanlash majburiy' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedKolodetsStatus,
                decoration: InputDecoration(
                  labelText: 'Kolodets holati',
                  border: OutlineInputBorder(),
                ),
                items: _kolodetsStatusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedKolodetsStatus = val),
                validator: (val) => val == null ? 'Tanlash majburiy' : null,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _latitudeController,
                      'Kenglik',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _longitudeController,
                      'Uzunlik',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.map),
                    label: Text("Xaritada ko'rish"),
                    onPressed: _openInMaps,
                  ),
                  Spacer(),
                  TextButton.icon(
                    icon: Icon(Icons.edit_location_alt),
                    label: Text("Manzilni tanlash"),
                    onPressed: _pickLocationFromMap,
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<BuildingStatus>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Holati',
                  border: OutlineInputBorder(),
                ),
                items: BuildingStatus.values
                    .map((status) =>
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusToText(status)),
                    ))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              SizedBox(height: 20),

              // Editable customData (materiallar) ro'yxati
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Qo\'shimcha materiallar', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addMaterialField,
                  ),
                ],
              ),
              ListView.builder(
                itemCount: _nameControllers.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Nomi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.construction),
                              ),
                              validator: (val) =>
                              val == null || val.isEmpty ? 'To\'ldirish shart' : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Miqdori',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              validator: (val) =>
                              val == null || val.isEmpty ? 'To\'ldirish shart' : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: _nameControllers.length > 1
                                ? () => _removeMaterialField(i)
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _sizeControllers[i],
                        decoration: InputDecoration(
                          labelText: 'O\'lchami (ixtiyoriy)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Rasmlar ko'rsatish qismi
              if (widget.building.images.isNotEmpty) ...[
                Text('Rasmlar', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.building.images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = widget.building.images[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.broken_image, color: Colors.red),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
              ]

            ],
          ),
        ),
      ),
    );
  }
}
