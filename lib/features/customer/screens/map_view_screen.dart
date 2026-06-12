import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

  Position? _userPosition;
  bool _locationLoading = true;
  bool _businessLoading = true;
  String? _locationError;

  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _filtered = [];
  String? _selectedBusinessId;

  Set<Marker> _markers = {};
  String _selectedCategory = 'All';
  bool _showList = false;

  late AnimationController _panelCtrl;
  late Animation<double> _panelAnim;

  static const _initialCamera = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Bengaluru default
    zoom: 13,
  );

  final List<String> _categories = [
    'All', 'Clinic', 'Salon', 'Spa', 'Bank', 'Government', 'Lab', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _panelAnim = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeInOutCubic);
    _initLocation();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    setState(() => _locationLoading = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() { _userPosition = pos; _locationLoading = false; });
        final ctrl = await _mapController.future;
        ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 14),
        ));
        _buildMarkers();
      } else {
        if (mounted) setState(() { _locationLoading = false; _locationError = 'Location access denied'; });
      }
    } catch (e) {
      if (mounted) setState(() { _locationLoading = false; _locationError = e.toString(); });
    }
  }

  // ── Businesses ────────────────────────────────────────────────────────────
  Future<void> _loadBusinesses() async {
    setState(() => _businessLoading = true);
    try {
      final list = await FirebaseService.instance.getNearbyBusinesses(
        _userPosition?.latitude ?? 12.9716,
        _userPosition?.longitude ?? 77.5946,
        null, // no category filter — chips handle UI filtering
      );
      // Convert BusinessModel list to raw maps for the map screen
      final maps = list.map((b) => {
        'id': b.id,
        'name': b.name,
        'category': b.category,
        'lat': b.lat,
        'lng': b.lng,
        'rating': b.rating,
        'totalWaiting': 0,
        'isOpen': true,
      }).toList();
      if (mounted) {
        setState(() {
          _businesses = maps;
          _filtered = maps;
          _businessLoading = false;
        });
        _buildMarkers();
      }
    } catch (e) {
      // Use mock data when Firestore is empty
      if (mounted) {
        setState(() {
          _businesses = _mockBusinesses();
          _filtered = _mockBusinesses();
          _businessLoading = false;
        });
        _buildMarkers();
      }
    }
  }

  List<Map<String, dynamic>> _mockBusinesses() => [
    {'id': 'b1', 'name': 'Dr. Sharma Clinic', 'category': 'Clinic', 'lat': 12.9720, 'lng': 77.5950, 'rating': 4.8, 'totalWaiting': 3, 'isOpen': true},
    {'id': 'b2', 'name': 'Lakme Salon', 'category': 'Salon', 'lat': 12.9680, 'lng': 77.5920, 'rating': 4.5, 'totalWaiting': 1, 'isOpen': true},
    {'id': 'b3', 'name': 'Apollo Diagnostics', 'category': 'Lab', 'lat': 12.9750, 'lng': 77.6010, 'rating': 4.6, 'totalWaiting': 6, 'isOpen': true},
    {'id': 'b4', 'name': 'State Bank of India', 'category': 'Bank', 'lat': 12.9700, 'lng': 77.5880, 'rating': 3.9, 'totalWaiting': 12, 'isOpen': true},
    {'id': 'b5', 'name': 'BBMP Citizen Centre', 'category': 'Government', 'lat': 12.9735, 'lng': 77.5970, 'rating': 3.2, 'totalWaiting': 20, 'isOpen': false},
  ];

  void _buildMarkers() {
    final markers = <Marker>{};

    // User location marker
    if (_userPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You are here'),
        zIndex: 2,
      ));
    }

    // Business markers
    for (final b in _filtered) {
      final lat = (b['lat'] as num?)?.toDouble() ?? 0;
      final lng = (b['lng'] as num?)?.toDouble() ?? 0;
      if (lat == 0 && lng == 0) continue;

      final isOpen = b['isOpen'] as bool? ?? true;
      final isSelected = _selectedBusinessId == b['id'];

      markers.add(Marker(
        markerId: MarkerId(b['id'] as String),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueYellow
              : isOpen
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: b['name'] as String,
          snippet: '${b['totalWaiting'] ?? 0} in queue · ${isOpen ? 'Open' : 'Closed'}',
          onTap: () => _onMarkerInfoTap(b),
        ),
        onTap: () => _onMarkerTap(b),
        zIndex: isSelected ? 1 : 0,
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  void _onMarkerTap(Map<String, dynamic> b) {
    setState(() => _selectedBusinessId = b['id'] as String?);
    _buildMarkers();
    _panelCtrl.forward();
  }

  void _onMarkerInfoTap(Map<String, dynamic> b) {
    context.push('/business/${b['id']}');
  }

  void _filterBusinesses(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _businesses.where((b) {
        final matchQuery = q.isEmpty ||
            (b['name'] as String).toLowerCase().contains(q) ||
            (b['category'] as String).toLowerCase().contains(q);
        final matchCat = _selectedCategory == 'All' ||
            b['category'] == _selectedCategory;
        return matchQuery && matchCat;
      }).toList();
    });
    _buildMarkers();
  }

  Future<void> _goToMyLocation() async {
    if (_userPosition == null) {
      await _initLocation();
      return;
    }
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(_userPosition!.latitude, _userPosition!.longitude), zoom: 15),
    ));
  }

  Map<String, dynamic>? get _selectedBusiness =>
      _selectedBusinessId == null ? null :
      _businesses.where((b) => b['id'] == _selectedBusinessId).firstOrNull;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GlassContainer.light(
            padding: const EdgeInsets.all(4),
            borderRadius: AppRadius.full,
            child: IconButton(
              key: const Key('map_back_btn'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: GlassContainer.light(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          borderRadius: AppRadius.full,
          child: const Text('Nearby Businesses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GlassContainer.light(
              padding: const EdgeInsets.all(4),
              borderRadius: AppRadius.full,
              child: IconButton(
                key: const Key('map_list_toggle_btn'),
                icon: Icon(_showList ? Icons.map_rounded : Icons.list_rounded, color: Colors.white, size: 20),
                onPressed: () => setState(() => _showList = !_showList),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: Stack(children: [

        // ── Google Map ──────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: _initialCamera,
          onMapCreated: (ctrl) {
            _mapController.complete(ctrl);
            _setMapStyle(ctrl);
          },
          markers: _markers,
          myLocationEnabled: _userPosition != null,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          onTap: (_) {
            setState(() => _selectedBusinessId = null);
            _panelCtrl.reverse();
          },
        ),

        // ── Search + Filter Overlay ─────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 12, right: 12,
          child: Column(children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: AppShadows.e3,
              ),
              child: TextField(
                key: const Key('map_search_field'),
                controller: _searchCtrl,
                onChanged: _filterBusinesses,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search clinics, salons, banks...',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textHint),
                          onPressed: () { _searchCtrl.clear(); _filterBusinesses(''); },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    key: Key('map_cat_${cat.toLowerCase()}'),
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _filterBusinesses(_searchCtrl.text);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.primary : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: AppShadows.e2,
                      ),
                      child: Text(cat, style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // ── My Location FAB ────────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: _selectedBusiness != null ? 230 : 120,
          child: GlassContainer.light(
            padding: const EdgeInsets.all(2),
            borderRadius: AppRadius.full,
            child: FloatingActionButton.small(
              key: const Key('map_location_fab'),
              heroTag: 'location',
              backgroundColor: AppColors.primary,
              onPressed: _goToMyLocation,
              child: _locationLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),

        // ── Business Count Badge ──────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: _selectedBusiness != null ? 280 : 170,
          child: GlassContainer.light(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            borderRadius: AppRadius.full,
            child: Text(
              '${_filtered.length} places',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),

        // ── List View Overlay (toggle) ──────────────────────────────────────
        if (_showList)
          Positioned(
            top: MediaQuery.of(context).padding.top + 160,
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Colors.white,
              child: _businessLoading
                  ? ListView(children: List.generate(4, (_) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: LoadingShimmer.shimmerListItem(),
                    )))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _BusinessListTile(
                        business: _filtered[i],
                        userLat: _userPosition?.latitude,
                        userLng: _userPosition?.longitude,
                        onTap: () {
                          setState(() { _showList = false; _selectedBusinessId = _filtered[i]['id'] as String?; });
                          _panelCtrl.forward();
                          _buildMarkers();
                          _flyToMarker(_filtered[i]);
                        },
                      ),
                    ),
            ),
          ),

        // ── Selected Business Bottom Sheet ──────────────────────────────────
        if (_selectedBusiness != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SizeTransition(
              sizeFactor: _panelAnim,
              axisAlignment: -1,
              child: _BusinessBottomSheet(
                business: _selectedBusiness!,
                userLat: _userPosition?.latitude,
                userLng: _userPosition?.longitude,
                onBook: () => context.push('/service-selection', extra: {
                  'businessId': _selectedBusiness!['id'],
                  'businessName': _selectedBusiness!['name'],
                }),
                onView: () => context.push('/business/${_selectedBusiness!['id']}'),
                onClose: () {
                  setState(() => _selectedBusinessId = null);
                  _panelCtrl.reverse();
                  _buildMarkers();
                },
              ),
            ),
          ),

        // ── Location Error Banner ───────────────────────────────────────────
        if (_locationError != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coralError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.coralError.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.location_off_rounded, color: AppColors.coralError, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_locationError!, style: const TextStyle(color: AppColors.coralError, fontSize: 13))),
                TextButton(onPressed: _initLocation, child: const Text('Retry')),
              ]),
            ),
          ),
      ]),
    );
  }

  Future<void> _flyToMarker(Map<String, dynamic> b) async {
    final lat = (b['lat'] as num?)?.toDouble() ?? 0;
    final lng = (b['lng'] as num?)?.toDouble() ?? 0;
    if (lat == 0 && lng == 0) return;
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(lat, lng), zoom: 16),
    ));
  }

  Future<void> _setMapStyle(GoogleMapController ctrl) async {
    // Subtle grey map style for premium feel
    await ctrl.setMapStyle('''[
      {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9d6e8"}]},
      {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f8f7ff"}]}
    ]''');
  }
}

// ── Business List Tile ─────────────────────────────────────────────────────

class _BusinessListTile extends StatelessWidget {
  final Map<String, dynamic> business;
  final double? userLat;
  final double? userLng;
  final VoidCallback onTap;

  const _BusinessListTile({required this.business, this.userLat, this.userLng, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = business['isOpen'] as bool? ?? true;
    final waiting = business['totalWaiting'] as int? ?? 0;
    final rating = (business['rating'] as num?)?.toDouble() ?? 0;
    final lat = (business['lat'] as num?)?.toDouble() ?? 0;
    final lng = (business['lng'] as num?)?.toDouble() ?? 0;

    String? distLabel;
    if (userLat != null && userLng != null && lat != 0) {
      distLabel = LocationService.distanceLabel(userLat!, userLng!, lat, lng);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        baseShadow: AppShadows.e1,
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(business['name'] as String, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
              Text(' $rating', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              Text('  ·  ', style: AppTextStyles.caption),
              Text('$waiting in queue', style: AppTextStyles.caption),
              if (distLabel != null) ...[
                Text('  ·  ', style: AppTextStyles.caption),
                Text(distLabel, style: AppTextStyles.caption),
              ],
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? AppColors.teal.withValues(alpha: 0.1) : AppColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(isOpen ? 'Open' : 'Closed',
              style: TextStyle(color: isOpen ? AppColors.teal : AppColors.coral, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ]),
      ),
    );
  }
}

// ── Selected Business Bottom Sheet ─────────────────────────────────────────

class _BusinessBottomSheet extends StatelessWidget {
  final Map<String, dynamic> business;
  final double? userLat;
  final double? userLng;
  final VoidCallback onBook;
  final VoidCallback onView;
  final VoidCallback onClose;

  const _BusinessBottomSheet({
    required this.business, this.userLat, this.userLng,
    required this.onBook, required this.onView, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = business['isOpen'] as bool? ?? true;
    final waiting = business['totalWaiting'] as int? ?? 0;
    final rating = (business['rating'] as num?)?.toDouble() ?? 0;
    final lat = (business['lat'] as num?)?.toDouble() ?? 0;
    final lng = (business['lng'] as num?)?.toDouble() ?? 0;

    String? distLabel;
    if (userLat != null && userLng != null && lat != 0) {
      distLabel = LocationService.distanceLabel(userLat!, userLng!, lat, lng);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: AppShadows.e4,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Header row
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(business['name'] as String, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
              Text(' $rating', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
              if (distLabel != null) ...[
                const Text('  ·  '),
                Text(distLabel, style: AppTextStyles.caption),
              ],
            ]),
          ])),
          IconButton(key: const Key('map_sheet_close_btn'), onPressed: onClose, icon: const Icon(Icons.close_rounded, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 16),

        // Stats row
        Row(children: [
          _StatChip(
            icon: Icons.people_rounded,
            label: '$waiting in queue',
            color: waiting > 5 ? AppColors.coral : AppColors.teal,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: isOpen ? Icons.circle_rounded : Icons.circle_outlined,
            label: isOpen ? 'Open Now' : 'Closed',
            color: isOpen ? AppColors.teal : AppColors.coral,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.category_rounded,
            label: business['category'] as String? ?? 'Business',
            color: AppColors.primary,
          ),
        ]),
        const SizedBox(height: 16),

        // Action buttons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            key: const Key('map_view_profile_btn'),
            onPressed: onView,
            icon: const Icon(Icons.info_outline_rounded, size: 16),
            label: const Text('View Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: ElevatedButton.icon(
            key: const Key('map_book_btn'),
            onPressed: isOpen ? onBook : null,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text('Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              elevation: 0,
            ),
          )),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ]),
    );
  }
}
