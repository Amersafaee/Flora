import 'package:verdoro/data/plant_providers.dart';
import 'package:verdoro/data/species_providers.dart';

class MockData {
  // 5‑7 mock plant documents
  static final List<PlantDoc> plantMocks = [
    PlantDoc(
      id: 'p1',
      commonName: 'Snake Plant',
      scientificName: 'Sansevieria trifasciata',
      nickname: 'Greeny',
      zone: '5',
      traits: ['Low Light', 'Hardy'],
      careDefaults: {'water': 'low', 'fertilizer': 'low'},
      healthStatus: 'healthy',
      photoBase64: '',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    PlantDoc(
      id: 'p2',
      commonName: 'Monstera Deliciosa',
      scientificName: 'Monstera deliciosa',
      nickname: 'Monster',
      zone: '9',
      traits: ['Tropical', 'Medium Light'],
      careDefaults: {'water': 'medium', 'fertilizer': 'medium'},
      healthStatus: 'healthy',
      photoBase64: '',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    PlantDoc(
      id: 'p3',
      commonName: 'Aloe Vera',
      scientificName: 'Aloe barbadensis',
      nickname: 'Aloe',
      zone: '8',
      traits: ['Succulent', 'Bright Light'],
      careDefaults: {'water': 'low', 'fertilizer': 'low'},
      healthStatus: 'healthy',
      photoBase64: '',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    PlantDoc(
      id: 'p4',
      commonName: 'Peace Lily',
      scientificName: 'Spathiphyllum',
      nickname: 'Lily',
      zone: '6',
      traits: ['Low Light', 'Moist'],
      careDefaults: {'water': 'medium', 'fertilizer': 'low'},
      healthStatus: 'healthy',
      photoBase64: '',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PlantDoc(
      id: 'p5',
      commonName: 'Fiddle Leaf Fig',
      scientificName: 'Ficus lyrata',
      nickname: 'Figgy',
      zone: '10',
      traits: ['Bright Light', 'Large'],
      careDefaults: {'water': 'medium', 'fertilizer': 'high'},
      healthStatus: 'healthy',
      photoBase64: '',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // 5‑7 mock species for Wiki
  static final List<SpeciesDoc> speciesMocks = [
    SpeciesDoc(
      id: 's1',
      commonName: 'Snake Plant',
      scientificName: 'Sansevieria trifasciata',
      category: 'Succulent',
      traits: ['Low Light', 'Hardy'],
      imageQuery: 'snake plant',
      careDefaults: {'water': 'low', 'fertilizer': 'low'},
      careGuide: {},
    ),
    SpeciesDoc(
      id: 's2',
      commonName: 'Monstera',
      scientificName: 'Monstera deliciosa',
      category: 'Tropical',
      traits: ['Medium Light', 'Tropical'],
      imageQuery: 'monstera',
      careDefaults: {'water': 'medium', 'fertilizer': 'medium'},
      careGuide: {},
    ),
    SpeciesDoc(
      id: 's3',
      commonName: 'Aloe Vera',
      scientificName: 'Aloe barbadensis',
      category: 'Succulent',
      traits: ['Bright Light', 'Succulent'],
      imageQuery: 'aloe vera',
      careDefaults: {'water': 'low', 'fertilizer': 'low'},
      careGuide: {},
    ),
    SpeciesDoc(
      id: 's4',
      commonName: 'Peace Lily',
      scientificName: 'Spathiphyllum',
      category: 'Indoor',
      traits: ['Low Light', 'Moist'],
      imageQuery: 'peace lily',
      careDefaults: {'water': 'medium', 'fertilizer': 'low'},
      careGuide: {},
    ),
    SpeciesDoc(
      id: 's5',
      commonName: 'Fiddle Leaf Fig',
      scientificName: 'Ficus lyrata',
      category: 'Indoor',
      traits: ['Bright Light', 'Large'],
      imageQuery: 'fiddle leaf fig',
      careDefaults: {'water': 'medium', 'fertilizer': 'high'},
      careGuide: {},
    ),
  ];

  // 5‑7 mock swap listings
  static final List<SwapItem> swapMocks = [
    SwapItem(id: 'sw1', plantName: 'Snake Plant', ownerName: 'Alice', description: 'Looking for a low‑light companion', imageQuery: 'snake plant'),
    SwapItem(id: 'sw2', plantName: 'Monstera', ownerName: 'Bob', description: 'Need a bigger pot', imageQuery: 'monstera'),
    SwapItem(id: 'sw3', plantName: 'Aloe Vera', ownerName: 'Carol', description: 'Trade for a succulent', imageQuery: 'aloe vera'),
    SwapItem(id: 'sw4', plantName: 'Peace Lily', ownerName: 'Dave', description: 'Swap for a fern', imageQuery: 'peace lily'),
    SwapItem(id: 'sw5', plantName: 'Fiddle Leaf Fig', ownerName: 'Eve', description: 'Looking for a smaller plant', imageQuery: 'fiddle leaf fig'),
  ];
}

class SwapItem {
  final String id;
  final String plantName;
  final String ownerName;
  final String description;
  final String imageQuery;

  SwapItem({
    required this.id,
    required this.plantName,
    required this.ownerName,
    required this.description,
    required this.imageQuery,
  });
}

