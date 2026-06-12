import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/widgets/status_badge.dart';


class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Nearest';
  List<BusinessModel> _results = [];
  bool _loading = false;

  final List<String> _filters = ['All', 'Clinic', 'Salon', 'Government', 'Spa', 'Nearby', 'Top Rated', 'Available', 'Low Wait'];
  final List<String> _sortOptions = ['Nearest', 'Top Rated', 'Fastest'];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _query = q; });
    final results = await FirebaseService.instance.getNearbyBusinesses(
      12.9716, 77.5946,
      _selectedFilter == 'All' || _selectedFilter == 'Nearby' || _selectedFilter == 'Top Rated' || _selectedFilter == 'Available' || _selectedFilter == 'Low Wait' ? null : _selectedFilter,
    );
    if (mounted) {
      setState(() {
        _results = q.isEmpty ? results : results.where((b) => b.name.toLowerCase().contains(q.toLowerCase()) || b.category.toLowerCase().contains(q.toLowerCase())).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search clinics, salons, govt...',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            filled: false,
          ),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 15),
        ),
        leading: const AppBackButton(fallback: '/home'),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _search(''); }),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;
                return GestureDetector(
                  onTap: () { setState(() => _selectedFilter = f); _search(_query); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.primary : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(f, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),
          // Results header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('${_results.length} results', style: AppTextStyles.h4),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _sortBy = v ?? 'Nearest'),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text('No results found', style: AppTextStyles.h3),
                            Text('Try a different search or filter', style: AppTextStyles.body),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) => _SearchResultCard(business: _results[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: const Text('Map View', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final BusinessModel business;
  const _SearchResultCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/${business.id}'),
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.e1,
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
              child: const Icon(Icons.store_rounded, color: Colors.white54, size: 32),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(business.name, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        StatusBadge(status: 'active', fontSize: 9),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(business.category, style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.amberWarning),
                        Text(' ${business.rating}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.tealSuccess),
                        Text(' ~15 min', style: AppTextStyles.caption.copyWith(color: AppColors.tealSuccess)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/service-selection'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
                            child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
