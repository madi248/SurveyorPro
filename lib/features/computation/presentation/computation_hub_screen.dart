import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/computation_definitions.dart';
import '../domain/computation_types.dart';

class ComputationHubScreen extends StatefulWidget {
  const ComputationHubScreen({super.key});

  @override
  State<ComputationHubScreen> createState() => _ComputationHubScreenState();
}

class _ComputationHubScreenState extends State<ComputationHubScreen> {
  String? _selectedCategoryId;
  String? _activeCalcId;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Form State
  final Map<String, TextEditingController> _inputCtrls = {};
  Map<String, dynamic>? _calcResult;

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (var c in _inputCtrls.values) c.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_activeCalcId != null) {
      setState(() {
        _activeCalcId = null;
        _calcResult = null;
        _inputCtrls.clear();
      });
    } else if (_selectedCategoryId != null) {
      setState(() => _selectedCategoryId = null);
    } else if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
        _searchCtrl.clear();
      });
    } else {
      context.go('/dashboard');
    }
  }

  void _handleItemClick(CalculationItem item) {
    if (item.targetRoute != null) {
      context.go(item.targetRoute!);
    } else if (calcDefs.containsKey(item.id)) {
      setState(() {
        _activeCalcId = item.id;
        _initForm(calcDefs[item.id]!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calculation ${item.name} not implemented yet')));
    }
  }

  void _initForm(CalcDefinition def) {
    _inputCtrls.clear();
    for (var input in def.inputs) {
      _inputCtrls[input.key] = TextEditingController(text: input.defaultValue ?? '');
    }
    _calcResult = null;
  }

  void _performCalculation() {
    if (_activeCalcId == null) return;
    final def = calcDefs[_activeCalcId]!;
    final values = _inputCtrls.map((key, ctrl) => MapEntry(key, ctrl.text));
    
    // Focus scope unfocus to hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _calcResult = def.calculate(values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = _selectedCategoryId != null ? computationData[_selectedCategoryId] : null;
    final activeCalcDef = _activeCalcId != null ? calcDefs[_activeCalcId] : null;

    // Filter Logic
    List<CalculationItem> filteredItems = [];
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      for (var cat in computationData.values) {
        for (var item in cat.items) {
           if (item.name.toLowerCase().contains(query) || item.desc.toLowerCase().contains(query)) {
             filteredItems.add(item);
           }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                   IconButton(
                     onPressed: _handleBack,
                     icon: const Icon(Icons.arrow_back, color: Colors.white),
                   ),
                   const SizedBox(width: 8),
                   Text(
                     activeCalcDef?.title ?? activeCategory?.title ?? 'Computation Hub',
                     style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                   const Spacer(),
                   IconButton(
                     onPressed: () => context.go('/settings'),
                     icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                   ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _activeCalcId != null 
                  ? _buildCalculationForm(activeCalcDef!) 
                  : _selectedCategoryId != null 
                      ? _buildCategoryView(activeCategory!) 
                      : _buildHubHome(filteredItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubHome(List<CalculationItem> filteredResults) {
    if (_searchQuery.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = filteredResults[index];
          return _buildListItem(item);
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Find formula or method...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() { _searchQuery = ''; _searchCtrl.clear(); })) : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),

          const SizedBox(height: 24),
          Text('RECENTLY USED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAction('Inverse Calc', Icons.square_foot, () => context.go('/computation/cogo_inverse')), // Route needs to exist
                const SizedBox(width: 12),
                _buildQuickAction('Trig Leveling', Icons.landscape, () => context.go('/computation/trig_leveling')),
                const SizedBox(width: 12),
                _buildQuickAction('Bowditch Rule', Icons.polyline, () => context.go('/computation/traverse')),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('CATEGORIES', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 12),
          GridView.count(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             crossAxisCount: 2,
             crossAxisSpacing: 16,
             mainAxisSpacing: 16,
             childAspectRatio: 1.1,
             children: computationData.values.map((cat) => _buildCategoryCard(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView(CategoryData category) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: category.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildListItem(category.items[index]);
      },
    );
  }

  Widget _buildCalculationForm(CalcDefinition def) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Inputs
           ...def.inputs.map((input) => Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Text(input.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                  const SizedBox(height: 6),
                  if (input.type == 'select' && input.options != null)
                    DropdownButtonFormField<String>(
                      value: _inputCtrls[input.key]?.text.isNotEmpty == true ? _inputCtrls[input.key]?.text : null,
                      dropdownColor: AppColors.surface,
                      items: input.options!.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _inputCtrls[input.key]!.text = val ?? ''),
                      decoration: _inputDecoration(),
                    )
                  else
                    TextField(
                      controller: _inputCtrls[input.key],
                      keyboardType: input.type == 'number' ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
                      maxLines: input.type == 'textarea' ? 4 : 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(placeholder: input.placeholder),
                    ),
               ],
             ),
           )),

           const SizedBox(height: 24),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               onPressed: _performCalculation,
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: Text('Calculate', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
             ),
           ),

           // Results
           if (_calcResult != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(children: [Icon(Icons.check_circle, color: AppColors.primary, size: 20), SizedBox(width: 8), Text('RESULTS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary))]),
                     const Divider(color: Colors.grey),
                     ...def.outputOrder.map((key) {
                        if (_calcResult![key] == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(key, style: const TextStyle(color: Colors.grey)),
                               Text(_calcResult![key].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                     }),
                     if (_calcResult!.containsKey('Error'))
                        Text(_calcResult!['Error'], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
           ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? placeholder}) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[800]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[800]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildListItem(CalculationItem item) {
    return ListTile(
      onTap: () => _handleItemClick(item),
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[800]!)),
      title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(item.desc, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing: item.targetRoute != null || item.badge == 'NEW' 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(item.badge ?? 'APP', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ) 
          : const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildCategoryCard(CategoryData cat) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = cat.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
               child: Icon(cat.icon, color: cat.color),
             ),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(cat.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 2),
                 Text(cat.description, style: TextStyle(color: Colors.grey[400], fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
             Icon(icon, color: AppColors.primary, size: 18),
             const SizedBox(width: 8),
             Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
