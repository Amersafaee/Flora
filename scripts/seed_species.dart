// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

final speciesList = [
  {
    "id": "monstera_deliciosa",
    "commonName": "Monstera deliciosa",
    "scientificName": "Monstera deliciosa",
    "traits": ["Tropical", "Beginner", "Climbing", "Air Purifying"],
    "category": "Tropical",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright indirect light is best. Avoid direct sun which can scorch the leaves.",
      "water": "Water every 1-2 weeks, allowing soil to dry out between waterings.",
      "humidity": "Prefers high humidity. Consider misting or using a humidifier.",
      "soil": "Peat-based potting soil with perlite for good drainage.",
      "temperature": "65°F-85°F (18°C-30°C). Don't let it drop below 60°F (15°C).",
      "propagation": "Propagate by stem cuttings in water or soil."
    },
    "imageQuery": "monstera plant"
  },
  {
    "id": "snake_plant",
    "commonName": "Snake Plant",
    "scientificName": "Sansevieria trifasciata",
    "traits": ["Succulent", "Low Light", "Beginner", "Air Purifying"],
    "category": "Succulent",
    "careDefaults": {"sun": "low", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Very adaptable. Can handle low light to full sun.",
      "water": "Water every 2-3 weeks, allowing soil to completely dry out.",
      "humidity": "Average home humidity is fine.",
      "soil": "Free-draining succulent or cactus mix.",
      "temperature": "70°F-90°F (21°C-32°C).",
      "propagation": "Propagate by leaf cuttings or division."
    },
    "imageQuery": "snake plant"
  },
  {
    "id": "pothos",
    "commonName": "Pothos",
    "scientificName": "Epipremnum aureum",
    "traits": ["Tropical", "Low Light", "Beginner", "Climbing", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect light, but tolerates low light.",
      "water": "Water every 1-2 weeks, let the top inch of soil dry out.",
      "humidity": "Any humidity level is fine.",
      "soil": "Well-draining potting mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Very easy to propagate from stem cuttings in water."
    },
    "imageQuery": "pothos plant"
  },
  {
    "id": "zz_plant",
    "commonName": "ZZ Plant",
    "scientificName": "Zamioculcas zamiifolia",
    "traits": ["Tropical", "Low Light", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Tolerates low light well. Keep out of direct sun.",
      "water": "Water every 2-3 weeks. Allow soil to dry completely.",
      "humidity": "Average home humidity.",
      "soil": "Well-draining potting soil.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division or leaf cuttings."
    },
    "imageQuery": "zz plant"
  },
  {
    "id": "peace_lily",
    "commonName": "Peace Lily",
    "scientificName": "Spathiphyllum",
    "traits": ["Tropical", "Flowering", "Low Light", "Air Purifying"],
    "category": "Flowering",
    "careDefaults": {"sun": "low", "water": "high", "fertilizer": "medium"},
    "careGuide": {
      "light": "Medium to low indirect light.",
      "water": "Keep soil lightly moist. It will droop dramatically when thirsty.",
      "humidity": "Prefers high humidity.",
      "soil": "Rich, well-draining soil.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "peace lily"
  },
  {
    "id": "spider_plant",
    "commonName": "Spider Plant",
    "scientificName": "Chlorophytum comosum",
    "traits": ["Tropical", "Pet Friendly", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water when the top 2 inches of soil are dry.",
      "humidity": "Average humidity is fine.",
      "soil": "Well-draining potting mix.",
      "temperature": "60°F-80°F (15°C-27°C).",
      "propagation": "Easily propagated from 'spiderettes' (pups)."
    },
    "imageQuery": "spider plant"
  },
  {
    "id": "fiddle_leaf_fig",
    "commonName": "Fiddle Leaf Fig",
    "scientificName": "Ficus lyrata",
    "traits": ["Tropical", "Air Purifying"],
    "category": "Tropical",
    "careDefaults": {"sun": "high", "water": "medium", "fertilizer": "high"},
    "careGuide": {
      "light": "Bright, indirect light to some full sun.",
      "water": "Water when the top inch of soil is dry.",
      "humidity": "Prefers higher humidity.",
      "soil": "Well-draining, rich soil.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Stem cuttings or air layering."
    },
    "imageQuery": "fiddle leaf fig"
  },
  {
    "id": "rubber_plant",
    "commonName": "Rubber Plant",
    "scientificName": "Ficus elastica",
    "traits": ["Tropical", "Air Purifying"],
    "category": "Tropical",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water every 1-2 weeks. Allow soil to dry out between waterings.",
      "humidity": "Average humidity.",
      "soil": "Well-draining soil.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Stem cuttings or air layering."
    },
    "imageQuery": "rubber plant"
  },
  {
    "id": "aloe_vera",
    "commonName": "Aloe Vera",
    "scientificName": "Aloe barbadensis miller",
    "traits": ["Succulent", "Beginner", "Air Purifying"],
    "category": "Succulent",
    "careDefaults": {"sun": "high", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect sunlight or artificial light.",
      "water": "Water heavily, but infrequently. Let soil completely dry.",
      "humidity": "Prefers dry conditions.",
      "soil": "Cactus or succulent mix.",
      "temperature": "55°F-80°F (13°C-27°C).",
      "propagation": "Propagate by removing and repotting pups."
    },
    "imageQuery": "aloe vera plant"
  },
  {
    "id": "prickly_pear_cactus",
    "commonName": "Prickly Pear Cactus",
    "scientificName": "Opuntia",
    "traits": ["Cactus", "Beginner"],
    "category": "Cactus",
    "careDefaults": {"sun": "high", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Full sun is ideal.",
      "water": "Water only when soil is completely dry.",
      "humidity": "Prefers dry air.",
      "soil": "Cactus/succulent soil mix.",
      "temperature": "65°F-90°F (18°C-32°C).",
      "propagation": "Propagate via stem cuttings (pads)."
    },
    "imageQuery": "prickly pear cactus"
  },
  {
    "id": "boston_fern",
    "commonName": "Boston Fern",
    "scientificName": "Nephrolepis exaltata",
    "traits": ["Tropical", "Pet Friendly", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "high", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Keep soil constantly moist, but not soggy.",
      "humidity": "Requires high humidity. Mist frequently.",
      "soil": "Rich, loamy potting soil.",
      "temperature": "65°F-75°F (18°C-24°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "boston fern"
  },
  {
    "id": "bird_of_paradise",
    "commonName": "Bird of Paradise",
    "scientificName": "Strelitzia",
    "traits": ["Tropical", "Flowering", "Air Purifying"],
    "category": "Tropical",
    "careDefaults": {"sun": "high", "water": "medium", "fertilizer": "high"},
    "careGuide": {
      "light": "Bright light to full sun.",
      "water": "Keep soil evenly moist in summer, drier in winter.",
      "humidity": "Prefers high humidity.",
      "soil": "Rich, well-draining soil.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "bird of paradise plant"
  },
  {
    "id": "calathea_orbifolia",
    "commonName": "Calathea orbifolia",
    "scientificName": "Calathea orbifolia",
    "traits": ["Tropical", "Pet Friendly", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "high", "fertilizer": "medium"},
    "careGuide": {
      "light": "Medium indirect light. Direct sun will burn leaves.",
      "water": "Keep soil consistently moist. Sensitive to tap water.",
      "humidity": "Requires very high humidity.",
      "soil": "Peat-based potting mix.",
      "temperature": "65°F-80°F (18°C-27°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "calathea orbifolia"
  },
  {
    "id": "heartleaf_philodendron",
    "commonName": "Heartleaf Philodendron",
    "scientificName": "Philodendron hederaceum",
    "traits": ["Tropical", "Climbing", "Low Light", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Tolerates low light, prefers medium indirect light.",
      "water": "Water when top half of soil is dry.",
      "humidity": "Average to high humidity.",
      "soil": "Well-draining potting soil.",
      "temperature": "65°F-80°F (18°C-27°C).",
      "propagation": "Easily propagated via stem cuttings in water."
    },
    "imageQuery": "heartleaf philodendron"
  },
  {
    "id": "chinese_evergreen",
    "commonName": "Chinese Evergreen",
    "scientificName": "Aglaonema",
    "traits": ["Tropical", "Low Light", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Low to bright indirect light.",
      "water": "Water when top half of soil is dry.",
      "humidity": "Average humidity.",
      "soil": "Peat-based potting mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division or stem cuttings."
    },
    "imageQuery": "chinese evergreen plant"
  },
  {
    "id": "dracaena_marginata",
    "commonName": "Dracaena marginata",
    "scientificName": "Dracaena marginata",
    "traits": ["Tropical", "Low Light", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect light but tolerates low light.",
      "water": "Water when the top half of soil is dry.",
      "humidity": "Average humidity.",
      "soil": "Well-draining loamy soil.",
      "temperature": "65°F-80°F (18°C-27°C).",
      "propagation": "Stem cuttings."
    },
    "imageQuery": "dracaena marginata"
  },
  {
    "id": "jade_plant",
    "commonName": "Jade Plant",
    "scientificName": "Crassula ovata",
    "traits": ["Succulent", "Beginner"],
    "category": "Succulent",
    "careDefaults": {"sun": "high", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Full sun or bright indirect light.",
      "water": "Water thoroughly, then let soil dry completely.",
      "humidity": "Prefers dry air.",
      "soil": "Succulent/cactus mix.",
      "temperature": "65°F-75°F (18°C-24°C).",
      "propagation": "Easily propagated from stem or leaf cuttings."
    },
    "imageQuery": "jade plant"
  },
  {
    "id": "string_of_pearls",
    "commonName": "String of Pearls",
    "scientificName": "Senecio rowleyanus",
    "traits": ["Succulent", "Climbing"],
    "category": "Succulent",
    "careDefaults": {"sun": "high", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright indirect light or morning sun.",
      "water": "Water when soil is completely dry.",
      "humidity": "Low to average humidity.",
      "soil": "Cactus/succulent mix.",
      "temperature": "70°F-80°F (21°C-27°C).",
      "propagation": "Stem cuttings laid on top of soil."
    },
    "imageQuery": "string of pearls plant"
  },
  {
    "id": "hoya_carnosa",
    "commonName": "Hoya carnosa",
    "scientificName": "Hoya carnosa",
    "traits": ["Tropical", "Climbing", "Flowering", "Pet Friendly"],
    "category": "Flowering",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water when soil is mostly dry.",
      "humidity": "Average to high humidity.",
      "soil": "Well-draining chunky mix.",
      "temperature": "60°F-80°F (15°C-27°C).",
      "propagation": "Stem cuttings."
    },
    "imageQuery": "hoya carnosa"
  },
  {
    "id": "anthurium",
    "commonName": "Anthurium",
    "scientificName": "Anthurium andraeanum",
    "traits": ["Tropical", "Flowering", "Air Purifying"],
    "category": "Flowering",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Keep soil slightly moist but never soggy.",
      "humidity": "High humidity is required.",
      "soil": "Coarse, well-draining potting mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "anthurium plant"
  },
  {
    "id": "moth_orchid",
    "commonName": "Moth Orchid",
    "scientificName": "Phalaenopsis",
    "traits": ["Tropical", "Flowering", "Pet Friendly"],
    "category": "Flowering",
    "careDefaults": {"sun": "medium", "water": "low", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water every 1-2 weeks. Let the medium dry out slightly.",
      "humidity": "50-70% humidity is ideal.",
      "soil": "Orchid bark mix (not regular potting soil).",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Keikis (baby plants) develop on flower spikes."
    },
    "imageQuery": "moth orchid"
  },
  {
    "id": "croton",
    "commonName": "Croton",
    "scientificName": "Codiaeum variegatum",
    "traits": ["Tropical"],
    "category": "Tropical",
    "careDefaults": {"sun": "high", "water": "medium", "fertilizer": "high"},
    "careGuide": {
      "light": "Bright light to full sun. Colors fade in low light.",
      "water": "Water when top half-inch of soil is dry.",
      "humidity": "High humidity.",
      "soil": "Well-draining potting soil.",
      "temperature": "60°F-85°F (15°C-30°C).",
      "propagation": "Stem cuttings."
    },
    "imageQuery": "croton plant"
  },
  {
    "id": "parlour_palm",
    "commonName": "Parlour Palm",
    "scientificName": "Chamaedorea elegans",
    "traits": ["Tropical", "Pet Friendly", "Low Light", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Low to medium indirect light.",
      "water": "Water when top inch of soil is dry.",
      "humidity": "Average to high humidity.",
      "soil": "Peat-based potting mix.",
      "temperature": "65°F-80°F (18°C-27°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "parlour palm"
  },
  {
    "id": "tradescantia_zebrina",
    "commonName": "Tradescantia zebrina",
    "scientificName": "Tradescantia zebrina",
    "traits": ["Climbing", "Beginner"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright indirect light.",
      "water": "Keep soil consistently moist but not soggy.",
      "humidity": "Average home humidity.",
      "soil": "Standard potting mix.",
      "temperature": "60°F-80°F (15°C-27°C).",
      "propagation": "Very easily propagated from stem cuttings in water or soil."
    },
    "imageQuery": "tradescantia zebrina"
  },
  {
    "id": "pilea_peperomioides",
    "commonName": "Pilea peperomioides",
    "scientificName": "Pilea peperomioides",
    "traits": ["Pet Friendly", "Beginner"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water when the top 1-2 inches of soil are dry.",
      "humidity": "Average humidity.",
      "soil": "Well-draining potting mix.",
      "temperature": "60°F-75°F (15°C-24°C).",
      "propagation": "Easily propagated by separating offsets (pups)."
    },
    "imageQuery": "pilea peperomioides"
  },
  {
    "id": "string_of_hearts",
    "commonName": "String of Hearts",
    "scientificName": "Ceropegia woodii",
    "traits": ["Succulent", "Climbing", "Pet Friendly"],
    "category": "Succulent",
    "careDefaults": {"sun": "medium", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Water thoroughly, then let soil completely dry out.",
      "humidity": "Average home humidity.",
      "soil": "Cactus or succulent mix.",
      "temperature": "60°F-80°F (15°C-27°C).",
      "propagation": "Propagate by stem cuttings or tubers."
    },
    "imageQuery": "string of hearts plant"
  },
  {
    "id": "alocasia_polly",
    "commonName": "Alocasia polly",
    "scientificName": "Alocasia amazonica",
    "traits": ["Tropical"],
    "category": "Tropical",
    "careDefaults": {"sun": "medium", "water": "high", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Keep soil evenly moist. Do not let it completely dry out.",
      "humidity": "Requires high humidity.",
      "soil": "Rich, well-draining potting mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "alocasia polly"
  },
  {
    "id": "cast_iron_plant",
    "commonName": "Cast Iron Plant",
    "scientificName": "Aspidistra elatior",
    "traits": ["Low Light", "Beginner", "Pet Friendly", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "low", "water": "low", "fertilizer": "low"},
    "careGuide": {
      "light": "Low light to medium indirect light.",
      "water": "Water when the top half of the soil is dry.",
      "humidity": "Average humidity.",
      "soil": "Standard potting mix.",
      "temperature": "60°F-80°F (15°C-27°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "cast iron plant"
  },
  {
    "id": "prayer_plant",
    "commonName": "Prayer Plant",
    "scientificName": "Maranta leuconeura",
    "traits": ["Tropical", "Pet Friendly"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "high", "fertilizer": "medium"},
    "careGuide": {
      "light": "Bright, indirect light.",
      "water": "Keep soil constantly moist but not soggy. Sensitive to hard water.",
      "humidity": "Requires high humidity.",
      "soil": "Peat-based potting mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Propagate by division."
    },
    "imageQuery": "prayer plant"
  },
  {
    "id": "pothos_neon",
    "commonName": "Pothos Neon",
    "scientificName": "Epipremnum aureum 'Neon'",
    "traits": ["Tropical", "Climbing", "Beginner", "Air Purifying"],
    "category": "Foliage",
    "careDefaults": {"sun": "medium", "water": "medium", "fertilizer": "low"},
    "careGuide": {
      "light": "Bright indirect light to maintain neon color.",
      "water": "Water when the top inch of soil is dry.",
      "humidity": "Average to high humidity.",
      "soil": "Standard well-draining mix.",
      "temperature": "65°F-85°F (18°C-30°C).",
      "propagation": "Stem cuttings in water."
    },
    "imageQuery": "neon pothos"
  }
];

void main() async {
  const projectId = 'flora-99ff7';
  const baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/species';

  print('Seeding 30 species to Firestore ($projectId)...');

  for (final species in speciesList) {
    final docId = species['id'] as String;
    final url = Uri.parse('$baseUrl?documentId=$docId');

    final traits = (species['traits'] as List<String>).map((t) => {'stringValue': t}).toList();
    final careDefaults = species['careDefaults'] as Map<String, String>;
    final careGuide = species['careGuide'] as Map<String, String>;

    final payload = {
      'fields': {
        'commonName': {'stringValue': species['commonName']},
        'scientificName': {'stringValue': species['scientificName']},
        'category': {'stringValue': species['category']},
        'imageQuery': {'stringValue': species['imageQuery']},
        'traits': {
          'arrayValue': {
            'values': traits,
          }
        },
        'careDefaults': {
          'mapValue': {
            'fields': {
              'sun': {'stringValue': careDefaults['sun']},
              'water': {'stringValue': careDefaults['water']},
              'fertilizer': {'stringValue': careDefaults['fertilizer']},
            }
          }
        },
        'careGuide': {
          'mapValue': {
            'fields': {
              'light': {'stringValue': careGuide['light']},
              'water': {'stringValue': careGuide['water']},
              'humidity': {'stringValue': careGuide['humidity']},
              'soil': {'stringValue': careGuide['soil']},
              'temperature': {'stringValue': careGuide['temperature']},
              'propagation': {'stringValue': careGuide['propagation']},
            }
          }
        }
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Seeded $docId');
      } else if (response.statusCode == 409) {
        // ALREADY EXISTS
        final patchUrl = Uri.parse('$baseUrl/$docId');
        final patchResponse = await http.patch(
          patchUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (patchResponse.statusCode == 200) {
          print('✅ Updated $docId');
        } else {
          print('❌ Failed to update $docId: ${patchResponse.body}');
        }
      } else {
        print('❌ Failed to seed $docId: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Error seeding $docId: $e');
    }
  }

  print('Done seeding species!');
}
