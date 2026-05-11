import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class SwapListing {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String ownerInitials;
  final String type; // "cutting" | "seeds" | "whole_plant"
  final String title;
  final String description;
  final String imageUrl;
  final bool isFree;
  final String city;
  final String geohash;
  final DateTime createdAt;
  final String status; // "available" | "completed"

  SwapListing({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerInitials,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isFree,
    required this.city,
    required this.geohash,
    required this.createdAt,
    required this.status,
  });

  factory SwapListing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SwapListing(
      id: doc.id,
      ownerUid: d['ownerUid'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? 'Anonymous',
      ownerInitials: d['ownerInitials'] as String? ?? '?',
      type: d['type'] as String? ?? 'cutting',
      title: d['title'] as String? ?? 'Unknown',
      description: d['description'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? 'https://source.unsplash.com/400x300/?plant',
      isFree: d['isFree'] as bool? ?? false,
      city: d['city'] as String? ?? 'Unknown City',
      geohash: d['geohash'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerInitials': ownerInitials,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isFree': isFree,
      'city': city,
      'geohash': geohash,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}

// ── Location State ────────────────────────────────────────────────────────
class UserLocation {
  final double lat;
  final double lng;
  final String geohash;
  final String city;
  UserLocation({required this.lat, required this.lng, required this.geohash, required this.city});
}

final userLocationProvider = StateProvider<UserLocation?>((ref) => null);

Future<void> determineUserLocation(WidgetRef ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }
  if (permission == LocationPermission.deniedForever) return;

  final pos = await Geolocator.getCurrentPosition();
  final hash = GeoHasher().encode(pos.longitude, pos.latitude, precision: 5);
  
  ref.read(userLocationProvider.notifier).state = UserLocation(
    lat: pos.latitude,
    lng: pos.longitude,
    geohash: hash,
    city: 'Local Area', // geocoding can be complex if we use the package without API key on windows, so fallback
  );
}

// ── Swap Listings State ───────────────────────────────────────────────────

final swapFilterProvider = StateProvider<String>((ref) => 'All');

final swapListingsProvider = StreamProvider<List<SwapListing>>((ref) {
  final filter = ref.watch(swapFilterProvider);
  final userLoc = ref.watch(userLocationProvider);

  Query query = FirebaseFirestore.instance
      .collection('swap_listings')
      .where('status', isEqualTo: 'available');

  // Prefix match rough 50km
  if (userLoc != null && userLoc.geohash.length >= 3) {
    final prefix = userLoc.geohash.substring(0, 3);
    query = query
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: '$prefix~');
  }

  // If a type filter is selected
  if (filter == 'Free') {
    query = query.where('isFree', isEqualTo: true);
  } else if (filter == 'Cuttings') {
    query = query.where('type', isEqualTo: 'cutting');
  } else if (filter == 'Seeds') {
    query = query.where('type', isEqualTo: 'seeds');
  } else if (filter == 'Whole Plants') {
    query = query.where('type', isEqualTo: 'whole_plant');
  }

  return query.snapshots().map((snap) {
    final list = snap.docs.map((doc) => SwapListing.fromDoc(doc)).toList();
    
    // Sort by approximate distance
    if (userLoc != null) {
      final hasher = GeoHasher();
      list.sort((a, b) {
        if (a.geohash.isEmpty || b.geohash.isEmpty) return 0;
        final aCoords = hasher.decode(a.geohash);
        final bCoords = hasher.decode(b.geohash);
        final distA = Geolocator.distanceBetween(userLoc.lat, userLoc.lng, aCoords[1], aCoords[0]);
        final distB = Geolocator.distanceBetween(userLoc.lat, userLoc.lng, bCoords[1], bCoords[0]);
        return distA.compareTo(distB);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return list;
  });
});

final swapDetailProvider = StreamProvider.family<SwapListing?, String>((ref, id) {
  return FirebaseFirestore.instance.collection('swap_listings').doc(id).snapshots().map((doc) {
    if (!doc.exists) return null;
    return SwapListing.fromDoc(doc);
  });
});

Future<void> completeListing(String id) async {
  await FirebaseFirestore.instance.collection('swap_listings').doc(id).update({
    'status': 'completed',
  });
}

Future<void> deleteListing(String id) async {
  await FirebaseFirestore.instance.collection('swap_listings').doc(id).delete();
}

