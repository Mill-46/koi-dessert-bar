import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:koi_dessert_bar/core/constants/app_colors.dart';
import 'package:koi_dessert_bar/features/admin/providers/admin_provider.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class AdminProductFormView extends StatefulWidget {
  final ProductModel? product;

  const AdminProductFormView({super.key, this.product});

  @override
  State<AdminProductFormView> createState() => _AdminProductFormViewState();
}

class _AdminProductFormViewState extends State<AdminProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _catCtrl;

  File? _pickedImage;
  bool _isAvailable = true;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _descCtrl = TextEditingController(text: product?.description ?? '');
    _priceCtrl = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');
    _catCtrl = TextEditingController(text: product?.category ?? 'Other');
    _isAvailable = product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final admin = context.read<AdminProvider>();
    final product = ProductModel(
      id: _isEdit ? widget.product!.id : '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      category: _catCtrl.text.trim(),
      imageUrl: widget.product?.imageUrl,
      isAvailable: _isAvailable,
    );

    final success = await admin.saveProduct(product, imageFile: _pickedImage);
    if (!mounted) {
      return;
    }

    if (success) {
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(admin.error ?? 'Failed to save'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final categories = [
      'Parfait',
      'Beverages',
      'Dessert',
      'Waffle',
      'Crepe',
      'Other',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Product' : 'New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, fit: BoxFit.cover)
                        : widget.product?.imageUrl != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: widget.product!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(color: Colors.black26),
                                  const Center(
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _Field(
                'Product Name',
                _nameCtrl,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _Field('Description', _descCtrl, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      'Price (Rp)',
                      _priceCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      'Stock',
                      _stockCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(_catCtrl.text)
                    ? _catCtrl.text
                    : 'Other',
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _catCtrl.text = value ?? 'Other',
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available on menu'),
                subtitle: Text(
                  _isAvailable ? 'Visible to customers' : 'Hidden from menu',
                ),
                value: _isAvailable,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: admin.isLoading ? null : _save,
                child: admin.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field(
    this.label,
    this.ctrl, {
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}
