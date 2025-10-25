import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker/country_picker.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../utils/theme.dart';

class AddActivityScreen extends StatefulWidget {
  final Activity? activityToEdit;
  
  const AddActivityScreen({Key? key, this.activityToEdit}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _providerController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();
  final _hexController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Color _selectedColor = AppTheme.primaryPurple;
  bool _applyCategoryColor = false;
  String? _selectedExistingCategory;
  String? _selectedExistingProvider;
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    if (widget.activityToEdit != null) {
      _loadActivityData();
    } else {
      _hexController.text = '#8B5CF6';
    }
  }

  void _loadActivityData() {
    final activity = widget.activityToEdit!;
    _nameController.text = activity.name;
    _categoryController.text = activity.category;
    _providerController.text = activity.provider;
    _countryController.text = activity.country;
    _notesController.text = activity.notes ?? '';
    _selectedDate = activity.date;
    _selectedColor = activity.color;
    _hexController.text = activity.colorHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _providerController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryPurple,
                onPrimary: Colors.white,
                surface: AppTheme.cardDark,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Seleccionar Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                  _hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Seleccionar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ActivityProvider>();
      
      final category = _selectedExistingCategory ?? _categoryController.text;
      final providerName = _selectedExistingProvider ?? _providerController.text;
      final country = _selectedCountry?.name ?? _countryController.text;
      
      final activity = Activity(
        id: widget.activityToEdit?.id,
        name: _nameController.text,
        category: category.isEmpty ? 'Sin categoría' : category,
        provider: providerName.isEmpty ? 'Sin proveedor' : providerName,
        country: country.isEmpty ? 'Sin país' : country,
        date: _selectedDate,
        colorHex: _hexController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.activityToEdit?.createdAt,
      );
      
      if (widget.activityToEdit != null) {
        provider.updateActivity(activity);
      } else {
        provider.addActivity(activity);
      }
      
      if (_applyCategoryColor && category.isNotEmpty) {
        provider.applyCategoryColor(category, _hexController.text);
      }
      
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryPurple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.activityToEdit != null 
                          ? 'Editar Actividad' 
                          : 'Registrar Nueva Actividad',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre de la Actividad
                          _buildLabel('Nombre de la Actividad', Icons.edit),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Ej: Ejercicio, Lectura, Proyecto...',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Categoría
                          _buildLabel('Categoría', Icons.category),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedExistingCategory,
                                  decoration: const InputDecoration(
                                    hintText: 'Selecciona o escribe nueva...',
                                  ),
                                  dropdownColor: AppTheme.surfaceDark,
                                  style: const TextStyle(color: Colors.white),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Nueva categoría...'),
                                    ),
                                    ...provider.categories.map((cat) => 
                                      DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedExistingCategory = value;
                                      if (value != null) {
                                        _categoryController.clear();
                                        final color = provider.getCategoryColor(value);
                                        if (color != null) {
                                          _selectedColor = Color(int.parse(
                                            color.replaceFirst('#', '0xff')
                                          ));
                                          _hexController.text = color;
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_selectedExistingCategory == null) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _categoryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Escribe nueva categoría',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // Proveedor
                          _buildLabel('Proveedor', Icons.business),
                          DropdownButtonFormField<String>(
                            value: _selectedExistingProvider,
                            decoration: const InputDecoration(
                              hintText: 'Selecciona o escribe nuevo...',
                            ),
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Nuevo proveedor...'),
                              ),
                              ...provider.providers.map((prov) => 
                                DropdownMenuItem(
                                  value: prov,
                                  child: Text(prov),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedExistingProvider = value;
                                if (value != null) {
                                  _providerController.clear();
                                }
                              });
                            },
                          ),
                          if (_selectedExistingProvider == null) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _providerController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Escribe nuevo proveedor',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // País
                          _buildLabel('País', Icons.public),
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: false,
                                onSelect: (Country country) {
                                  setState(() {
                                    _selectedCountry = country;
                                    _countryController.text = country.name;
                                  });
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: AppTheme.cardDark,
                                  textStyle: const TextStyle(color: Colors.white),
                                  searchTextStyle: const TextStyle(color: Colors.white),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Buscar país',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceDark,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _countryController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Selecciona país',
                                  suffixIcon: _selectedCountry != null
                                      ? Text(
                                          _selectedCountry!.flagEmoji,
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Fecha y Hora
                          _buildLabel('Fecha y Hora', Icons.calendar_today),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                                    '${_selectedDate.year} '
                                    '${_selectedDate.hour.toString().padLeft(2, '0')}:'
                                    '${_selectedDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Color
                          _buildLabel('Color', Icons.palette),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _selectColor,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _hexController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '#8B5CF6',
                                    labelText: 'Código hexadecimal',
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[#0-9A-Fa-f]'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value.length == 7 && value.startsWith('#')) {
                                      try {
                                        setState(() {
                                          _selectedColor = Color(
                                            int.parse(value.replaceFirst('#', '0xff')),
                                          );
                                        });
                                      } catch (e) {
                                        // Invalid color
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Apply color to category checkbox
                          if ((_selectedExistingCategory ?? _categoryController.text).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _applyCategoryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _applyCategoryColor = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryPurple,
                                  ),
                                  const Icon(
                                    FontAwesomeIcons.lightbulb,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Aplicar este color a todas las actividades de esta categoría',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          
                          // Notas
                          _buildLabel('Notas (Opcional)', Icons.note),
                          TextFormField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Añade cualquier nota o detalle sobre esta actividad...',
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveActivity,
                              icon: const Icon(Icons.save),
                              label: Text(
                                widget.activityToEdit != null 
                                    ? 'Actualizar Actividad' 
                                    : 'Guardar Actividad',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.lightPurple),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.lightPurple,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}