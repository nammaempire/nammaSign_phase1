import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/home/domain/billboard_listing.dart';
import '../../../../features/home/presentation/providers/listings_provider.dart';
import '../../../shared/theme/admin_theme.dart';

/// Dialog form to create a new area. Saves to Firestore at `areas/{id}` via
/// the admin-only `adminCreate` repository method.
class AddAreaDialog extends ConsumerStatefulWidget {
  const AddAreaDialog({super.key});

  @override
  ConsumerState<AddAreaDialog> createState() => _AddAreaDialogState();
}

class _AddAreaDialogState extends ConsumerState<AddAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController(text: '500');
  final _boards = TextEditingController(text: '4');
  final _views = TextEditingController(text: '25000');
  final _displayLabel = TextEditingController(text: 'YOUR AD');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _price.dispose();
    _boards.dispose();
    _views.dispose();
    _displayLabel.dispose();
    super.dispose();
  }

  /// Derive a stable Firestore doc id from the area name.
  String _idFromName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final boards = int.parse(_boards.text);
    final price = int.parse(_price.text);
    final views = int.parse(_views.text);
    final id = _idFromName(_name.text);
    final listing = BillboardListing(
      id: id,
      location: _name.text.trim(),
      boardType: '$boards LED Boards',
      displayLabel: _displayLabel.text.trim(),
      fullAddress: _address.text.trim(),
      pricePerDay: price,
      viewsPerDay: views,
      availability: AvailabilityStatus.available,
      boardCount: boards,
      slotsLeft: boards,
    );
    try {
      await ref
          .read(listingsRepositoryProvider)
          .adminCreate(id: id, listing: listing);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Area "${listing.location}" created.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add new area'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(
                  controller: _name,
                  label: 'Area name',
                  hint: 'e.g. Indiranagar',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _address,
                  label: 'Full address',
                  hint: 'e.g. 100 Feet Road, near Metro',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _price,
                        label: 'Price per day (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => int.tryParse(v ?? '') == null
                            ? 'Numeric'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _boards,
                        label: 'Number of boards',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n <= 0
                              ? '1 or more'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _views,
                        label: 'Estimated views/day',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _displayLabel,
                        label: 'Display label',
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AdminColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create area'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
