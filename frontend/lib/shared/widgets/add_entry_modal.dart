import 'dart:convert';
import 'package:gastos_claros/shared/models/registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/widgets/currency_widgets.dart';
import 'package:gastos_claros/shared/models/yape_extraction_result.dart';

/// Modal para agregar un Saldo (ingreso) o Gasto.
/// Incluye upload Yape con extracción IA y formulario manual.
class AddEntryModal extends ConsumerStatefulWidget {
  /// "ingreso" o "gasto"
  final String type;
  final Registro? record;

  const AddEntryModal({super.key, required this.type, this.record});

  @override
  ConsumerState<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends ConsumerState<AddEntryModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<XFile> _selectedImages = [];
  bool _hasExtracted = false;
  bool _editingBusy = false;
  String? _editError;
  String? _extractedId;

  bool get isIngreso => widget.type == 'ingreso';
  String get typeLabel => isIngreso ? 'Saldo' : 'Gasto';

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _montoCtrl.text = record.monto.toStringAsFixed(2);
      _nombreCtrl.text = record.nombre;
      _descripcionCtrl.text = record.descripcion;
      _selectedDate = record.fecha.toUtc().subtract(const Duration(hours: 5));
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, _selectedDate.hour, _selectedDate.minute,
          _selectedDate.second, _selectedDate.millisecond, _selectedDate.microsecond);
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _montoCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (!mounted) return;

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
          _hasExtracted = false;
        });
        await _processImages();
      }
    } catch (error) {
      if (!mounted) return;
      ref
          .read(uploadYapeProvider.notifier)
          .setError('No se pudo seleccionar la imagen: $error');
    }
  }

  Future<void> _processImages() async {
    final uploadNotifier = ref.read(uploadYapeProvider.notifier);
    uploadNotifier.prepareImages(_selectedImages.length);

    try {
      final base64Images = <String>[];
      for (var i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        final ext = image.name.split('.').last.toLowerCase();
        final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/png';
        base64Images.add('data:$mime;base64,${base64Encode(bytes)}');
        uploadNotifier.updatePreparationProgress(i + 1, _selectedImages.length);
      }

      if (!mounted) return;
      await uploadNotifier.uploadImages(
        base64Images: base64Images,
        type: widget.type,
      );

      if (!mounted) return;
      final state = ref.read(uploadYapeProvider);
      if (state.results != null && state.results!.isNotEmpty) {
        final result = state.results!.firstWhere(
          (result) => result.saved,
          orElse: () => state.results!.first,
        );
        if (result.saved) _populateFromResult(result);
        setState(() => _hasExtracted = true);
      }
    } catch (error) {
      if (mounted) uploadNotifier.setError(error.toString());
    }
  }

  void _populateFromResult(YapeExtractionResult result) {
    setState(() {
      _montoCtrl.text = result.monto > 0 ? result.monto.toStringAsFixed(2) : '';
      _nombreCtrl.text = result.nombre;
      _descripcionCtrl.text = result.descripcion;
      _selectedDate = result.fecha.toUtc().subtract(const Duration(hours: 5));
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, _selectedDate.hour, _selectedDate.minute,
          _selectedDate.second, _selectedDate.millisecond, _selectedDate.microsecond);
      _extractedId = result.id;
    });
    ref.invalidate(balanceProvider);
    ref.invalidate(ingresosHistoryProvider);
    ref.invalidate(gastosHistoryProvider);
  }

  Future<void> _selectDateTime() async {
    final picked = await showOmniDateTimePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 650),
      transitionBuilder: (_, anim1, __, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: null,
    );
    if (picked != null) {
      if (mounted) setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    if (monto == null) return;

    if (widget.record != null || _extractedId != null) {
      await _modify();
      return;
    }
    final success = await ref.read(manualEntryProvider.notifier).save(
          monto: monto,
          nombre:
              _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          fecha: _peruDate,
          type: widget.type,
        );

    if (success && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      // Refrescar datos
      ref.invalidate(balanceProvider);
      ref.invalidate(ingresosHistoryProvider);
      ref.invalidate(gastosHistoryProvider);
      ref.read(manualEntryProvider.notifier).reset();
      Navigator.of(context).pop();
      _showSuccessSnack(messenger);
    }
  }

  DateTime get _peruDate => DateTime.utc(_selectedDate.year, _selectedDate.month,
      _selectedDate.day, _selectedDate.hour + 5, _selectedDate.minute,
      _selectedDate.second, _selectedDate.millisecond, _selectedDate.microsecond);

  Future<void> _modify({bool delete = false}) async {
    if (_editingBusy) return;
    if (delete) {
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: const Text('El registro se eliminará permanentemente.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar'))],
      ));
      if (confirmed != true || !mounted) return;
    }
    setState(() { _editingBusy = true; _editError = null; });
    try {
      await ref.read(apiServiceProvider).modifyRecord(
        id: widget.record?.id ?? _extractedId!, type: widget.type, delete: delete,
        values: delete ? null : {'monto': double.parse(_montoCtrl.text.replaceAll(',', '.')),
          'nombre': _nombreCtrl.text.trim(), 'descripcion': _descripcionCtrl.text.trim(),
          'fecha': _peruDate.toIso8601String()},
      );
      if (!mounted) return;
      ref.invalidate(balanceProvider);
      ref.invalidate(ingresosHistoryProvider);
      ref.invalidate(gastosHistoryProvider);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _editError = 'No se pudo guardar el cambio. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _editingBusy = false);
    }
  }

  void _showSuccessSnack(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('$typeLabel agregado exitosamente'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _close() async {
    try {
      await _animCtrl.reverse();
    } on TickerCanceled {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadYapeProvider);
    final entryState = ref.watch(manualEntryProvider);

    return GestureDetector(
      onTap: () {},
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfacePurple,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.modal),
            ),
            border: Border.all(
              color: AppColors.accentPurple.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar + Close
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.mutedPurple.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _editingBusy ? null : _close,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.deepPurpleBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.mutedText,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Título flotante
                  Text(
                    '${widget.record == null ? 'Agregar' : 'Editar'} $typeLabel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Área de upload Yape
                  if (widget.record == null) _buildUploadArea(uploadState),
                  const SizedBox(height: AppSpacing.lg),

                  // Cards de resultados IA
                  if (_hasExtracted && uploadState.results != null)
                    _buildExtractionResults(uploadState.results!),

                  // Formulario manual
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monto
                        _buildLabel('Monto *'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _montoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 16,
                            color: AppColors.whiteText,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            prefixText: 'S/. ',
                            prefixStyle: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '0.00',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'El monto es requerido';
                            }
                            if (double.tryParse(v.replaceAll(',', '.')) == null ||
                                !double.parse(v.replaceAll(',', '.')).isFinite ||
                                double.parse(v.replaceAll(',', '.')) < 0.01) {
                              return 'Ingresa un monto válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Nombre (opcional)
                        _buildLabel('Nombre (opcional)'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _nombreCtrl,
                          style: const TextStyle(color: AppColors.whiteText),
                          decoration: const InputDecoration(
                            hintText: 'Ej: Juan Pérez, Grifo Repsol',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Descripción
                        _buildLabel('Descripción *'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _descripcionCtrl,
                          style: const TextStyle(color: AppColors.whiteText),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Ej: Almuerzo, Gasolina 90, Pago Yape',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'La descripción es requerida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Fecha y Hora
                        _buildLabel('Fecha y Hora *'),
                        const SizedBox(height: AppSpacing.xs),
                        GestureDetector(
                          onTap: _selectDateTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepPurpleBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.input),
                              border: Border.all(
                                color: AppColors.mutedPurple.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.accentPurple,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  formatFechaHora(_selectedDate),
                                  style: const TextStyle(
                                    color: AppColors.whiteText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: entryState.isSaving || _editingBusy || uploadState.isUploading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md + 2,
                              ),
                              backgroundColor: AppColors.accentPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: entryState.isSaving || _editingBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          AppColors.whiteText),
                                    ),
                                  )
                                : Text(
                                    widget.record == null ? 'Guardar $typeLabel' : 'Guardar cambios',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        if (widget.record != null)
                          TextButton.icon(
                            onPressed: _editingBusy ? null : () => _modify(delete: true),
                            icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
                            label: const Text('Eliminar registro', style: TextStyle(color: AppColors.dangerRed)),
                          ),
                        if (_editError != null) Text(_editError!, style: const TextStyle(color: AppColors.dangerRed)),
                        // Error de guardado
                        if (entryState.error != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            entryState.error!,
                            style: const TextStyle(
                              color: AppColors.dangerRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUploadArea(UploadYapeState uploadState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: uploadState.isUploading ? null : _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.deepPurpleBg,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: uploadState.isUploading
                    ? AppColors.accentPurple.withOpacity(0.5)
                    : AppColors.mutedPurple.withOpacity(0.4),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: uploadState.isUploading
                ? _buildUploadProgress(uploadState)
                : _buildUploadIdle(),
          ),
        ),
        if (uploadState.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            uploadState.error!,
            style: const TextStyle(
              color: AppColors.dangerRed,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadIdle() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.upload_rounded,
            color: AppColors.accentPurple,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Subir captura YAPE',
          style: TextStyle(
            color: AppColors.whiteText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toca para seleccionar imágenes',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress(UploadYapeState uploadState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentPurple,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                uploadState.status ?? 'Procesando capturas...',
                style: const TextStyle(
                  color: AppColors.accentPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(
          uploadState.progressPerImage.length,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Captura ${i + 1}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${uploadState.progressPerImage[i].toInt()}%',
                      style: const TextStyle(
                        color: AppColors.accentPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: uploadState.progressPerImage[i] / 100,
                    backgroundColor: AppColors.mutedPurple.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurple,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractionResults(List<YapeExtractionResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capturas procesadas',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final result = results[i];
              return GestureDetector(
                onTap: result.saved ? () => _populateFromResult(result) : null,
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.deepPurpleBg,
                    borderRadius: BorderRadius.circular(AppRadius.captureCard),
                    border: Border.all(
                      color: result.saved
                          ? AppColors.successGreen.withOpacity(0.3)
                          : AppColors.dangerRed.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Captura ${result.captureIndex}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMonto(result.monto),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: AppColors.accentPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (result.nombre.isNotEmpty)
                        Text(
                          result.nombre,
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        result.saved
                            ? result.descripcion
                            : result.error ?? result.descripcion,
                        style: TextStyle(
                          color: result.saved
                              ? AppColors.mutedText
                              : AppColors.dangerRed,
                          fontSize: 11,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Muestra el modal de AddEntryModal como bottom sheet.
void showAddEntryModal(BuildContext context, {required String type, Registro? record}) {
  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (sheetContext) => AddEntryModal(type: type, record: record),
  );
}
