import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker/country_picker.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../utils/theme.dart';
import '../l10n/app_localizations.dart';

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
    
    if (!context.mounted) return;

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
      
      if (!context.mounted) return;

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
          title: Text(context.loc('addActivity.color.select',
              fallback: 'Seleccionar Color')),
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
              child: Text(context.loc('common.cancel',
                  fallback: 'Cancelar')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(context.loc('common.confirm',
                  fallback: 'Seleccionar')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ActivityProvider>();
      
      final category = _selectedExistingCategory ?? _categoryController.text;
      final providerName = _selectedExistingProvider ?? _providerController.text;
      final country = _selectedCountry?.name ?? _countryController.text;
      final sanitizedCategory = category.isEmpty ? 'Sin categoría' : category;
      final sanitizedProvider = providerName.isEmpty ? 'Sin proveedor' : providerName;
      final sanitizedCountry = country.isEmpty ? 'Sin país' : country;
      
      final activity = Activity(
        id: widget.activityToEdit?.id,
        name: _nameController.text,
        category: sanitizedCategory,
        provider: sanitizedProvider,
        country: sanitizedCountry,
        date: _selectedDate,
        colorHex: _hexController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.activityToEdit?.createdAt,
      );
      
      if (widget.activityToEdit != null) {
        await provider.updateActivity(activity);
      } else {
        await provider.addActivity(activity);
      }
      
      if (_applyCategoryColor && sanitizedCategory.isNotEmpty) {
        await provider.applyCategoryColor(sanitizedCategory, _hexController.text);
      }
      
      if (!context.mounted) return;
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
                          ? context.loc('addActivity.title.edit',
                              fallback: 'Editar Actividad')
                          : context.loc('addActivity.title.new',
                              fallback: 'Registrar Nueva Actividad'),
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
                          _buildLabel(context.loc('addActivity.name.label',
                              fallback: 'Nombre de la Actividad'), Icons.edit),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: context.loc('addActivity.name.hint',
                                  fallback: 'Ej: Ejercicio, Lectura, Proyecto...'),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.loc('addActivity.validation.required',
                                    fallback: 'Por favor ingresa el nombre');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Categoría
                          _buildLabel(context.loc('addActivity.category.label',
                              fallback: 'Categoría'), Icons.category),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedExistingCategory,
                                  decoration: InputDecoration(
                                    hintText: context.loc('addActivity.category.hint',
                                        fallback: 'Selecciona o escribe nueva...'),
                                  ),
                                  dropdownColor: AppTheme.surfaceDark,
                                  style: const TextStyle(color: Colors.white),
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(context.loc('addActivity.category.new',
                                          fallback: 'Nueva categoría...')),
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
                              decoration: InputDecoration(
                                hintText: context.loc('addActivity.category.hint',
                                    fallback: 'Escribe nueva categoría'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // Proveedor
                          _buildLabel(context.loc('addActivity.provider.label',
                              fallback: 'Proveedor'), Icons.business),
                          DropdownButtonFormField<String>(
                            value: _selectedExistingProvider,
                            decoration: InputDecoration(
                              hintText: context.loc('addActivity.provider.hint',
                                  fallback: 'Selecciona o escribe nuevo proveedor'),
                            ),
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(context.loc('addActivity.provider.new',
                                    fallback: 'Nuevo proveedor...')),
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
                              decoration: InputDecoration(
                                hintText: context.loc('addActivity.provider.hint',
                                    fallback: 'Escribe nuevo proveedor'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // País
                          _buildLabel(context.loc('addActivity.country.label',
                              fallback: 'País'), Icons.public),
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
                                    hintText: context.loc('addActivity.country.search',
                                        fallback: 'Buscar país'),
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
                                  hintText: context.loc('addActivity.country.hint',
                                      fallback: 'Selecciona país'),
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
                          _buildLabel(context.loc('addActivity.dateTime.label',
                              fallback: 'Fecha y Hora'), Icons.calendar_today),
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
                          _buildLabel(context.loc('addActivity.color.label',
                              fallback: 'Color'), Icons.palette),
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
                                  decoration: InputDecoration(
                                    hintText: '#8B5CF6',
                                    labelText: context.loc('addActivity.color.hex',
                                        fallback: 'Código hexadecimal'),
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
                                      context.loc('addActivity.color.applyToCategory',
                                          fallback: 'Aplicar este color a todas las actividades de esta categoría'),
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
                          _buildLabel(context.loc('addActivity.notes.label',
                              fallback: 'Notas (Opcional)'), Icons.note),
                          TextFormField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: context.loc('addActivity.notes.hint',
                                  fallback: 'Añade cualquier nota o detalle sobre esta actividad...'),
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _saveActivity(),
                              icon: const Icon(Icons.save),
                              label: Text(
                                widget.activityToEdit != null 
                                    ? context.loc('addActivity.button.update',
                                        fallback: 'Actualizar Actividad')
                                    : context.loc('addActivity.button.save',
                                        fallback: 'Guardar Actividad'),
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










