import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/treatment_case_model.dart';
import 'gemini_service.dart';
import 'package:flutter/foundation.dart';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<UserProfile?> getUserProfile() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // --- Plants ---
  Future<void> addPlant(Plant plant) async {
    final uid = currentUserId;
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid).collection('plants').doc();
    final plantId = plant.id.isEmpty ? docRef.id : plant.id;
    final newPlant = Plant(
      id: plantId, name: plant.name, commonName: plant.commonName,
      category: plant.category, zone: plant.zone, imageUrl: plant.imageUrl,
      healthStatus: plant.healthStatus, dateAdded: plant.dateAdded, healthScore: plant.healthScore,
    );
    await _db.collection('users').doc(uid).collection('plants').doc(plantId).set(newPlant.toMap());
  }

  Stream<List<Plant>> getPlants() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('plants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Plant.fromMap(doc.data())).toList();
    });
  }

  Future<void> deletePlant(String plantId) async {
    final uid = currentUserId;
    if (uid == null) return;
    final plantRef = _db.collection('users').doc(uid).collection('plants').doc(plantId);
    final growthSnap = await plantRef.collection('growth').get();
    for (var doc in growthSnap.docs) {
      await doc.reference.delete();
    }
    await plantRef.delete();
  }

  Future<void> updatePlant(Plant plant) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('plants').doc(plant.id).update(plant.toMap());
  }

  // --- Tasks ---
  Future<void> addTask(Task task) async {
    final uid = currentUserId;
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid).collection('tasks').doc();
    final taskId = task.id.isEmpty ? docRef.id : task.id;
    final newTask = Task(
      id: taskId, plantName: task.plantName, taskType: task.taskType,
      dueDate: task.dueDate, isCompleted: task.isCompleted, notes: task.notes,
      repeatType: task.repeatType, repeatDays: task.repeatDays,
    );
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).set(newTask.toMap());
  }

  Stream<List<Task>> getTasksForToday() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _db.collection('users').doc(uid).collection('tasks')
      .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
      .where('dueDate', isLessThanOrEqualTo: endOfDay)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList());
  }

  Stream<List<Task>> getTasksForYesterdayAndToday() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    final now = DateTime.now();
    final startOfYesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _db.collection('users').doc(uid).collection('tasks')
      .where('dueDate', isGreaterThanOrEqualTo: startOfYesterday)
      .where('dueDate', isLessThanOrEqualTo: endOfToday)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList());
  }

  Future<void> updateTask(Task task) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).delete();
  }

  Future<void> markTaskCompleted(String taskId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final taskRef = _db.collection('users').doc(uid).collection('tasks').doc(taskId);
    final taskDoc = await taskRef.get();

    await taskRef.update({'isCompleted': true});

    if (!taskDoc.exists) return;
    final data = taskDoc.data()!;
    final repeatType = data['repeatType'] as String? ?? 'none';
    if (repeatType == 'none' || repeatType.isEmpty) return;

    final dueDateRaw = data['dueDate'];
    if (dueDateRaw == null) return;
    DateTime dueDate = dueDateRaw is Timestamp ? dueDateRaw.toDate() : DateTime.now();

    DateTime nextDue;
    switch (repeatType) {
      case 'daily':
        nextDue = dueDate.add(const Duration(days: 1));
        break;
      case 'every2days':
        nextDue = dueDate.add(const Duration(days: 2));
        break;
      case 'weekly':
        nextDue = dueDate.add(const Duration(days: 7));
        break;
      case 'biweekly':
        nextDue = dueDate.add(const Duration(days: 14));
        break;
      case 'monthly':
        nextDue = DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        break;
      default:
        final repeatDays = (data['repeatDays'] as num?)?.toInt() ?? 7;
        nextDue = dueDate.add(Duration(days: repeatDays));
    }

    final newDocRef = _db.collection('users').doc(uid).collection('tasks').doc();
    await newDocRef.set({
      'id': newDocRef.id,
      'plantName': data['plantName'] ?? '',
      'taskType': data['taskType'] ?? '',
      'dueDate': Timestamp.fromDate(nextDue),
      'isCompleted': false,
      'notes': data['notes'] ?? '',
      'repeatType': repeatType,
      'repeatDays': data['repeatDays'] ?? 0,
    });
  }

  // --- Growth Entries ---
  Future<void> addGrowthEntry(String plantId, Map<String, dynamic> entry) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth').add(entry);
  }

  Stream<List<Map<String, dynamic>>> getGrowthEntries(String plantId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth')
        .orderBy('timestamp', descending: true).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<int> getTotalPlantsCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final snap = await _db.collection('users').doc(uid).collection('plants').count().get();
    return snap.count ?? 0;
  }

  Future<int> getCompletedTasksCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final snap = await _db.collection('users').doc(uid).collection('tasks').where('isCompleted', isEqualTo: true).count().get();
    return snap.count ?? 0;
  }

  Future<int> getTotalJournalEntriesCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    int count = 0;
    final plants = await _db.collection('users').doc(uid).collection('plants').get();
    for (var plant in plants.docs) {
      final entries = await plant.reference.collection('growth').count().get();
      count += entries.count ?? 0;
    }
    return count;
  }

  Future<void> seedSpeciesData() async {
    final collection = _db.collection('species');

    final List<Map<String, dynamic>> species = [
      {
        'id': 'monstera_deliciosa',
        'name': 'Monstera Deliciosa',
        'commonName': 'Swiss Cheese Plant',
        'category': 'Tropical',
        'difficulty': 'Easy',
        'light': 'Bright indirect light',
        'water': 'Every 1-2 weeks',
        'humidity': 'High 60 percent plus',
        'temperature': '18-30°C',
        'soilType': 'Well-draining potting mix',
        'fertilizer': 'Monthly in spring and summer',
        'toxicity': 'Toxic to pets',
        'description': 'The Monstera Deliciosa is one of the most recognisable houseplants on earth. Native to the tropical rainforests of Central America, it has evolved its iconic split and holey leaves to allow wind and heavy rain to pass through without damaging the plant. In the wild it can grow to 20 metres tall, climbing trees with its aerial roots. Indoors it becomes a dramatic focal point that transforms any room into a lush green sanctuary.',
        'careTips': [
          'Wipe leaves monthly with a damp cloth to remove dust and help photosynthesis',
          'Rotate the pot every few weeks so all sides receive even light and the plant grows upright',
          'Provide a moss pole or trellis as it matures — it will reward you with larger and more fenestrated leaves',
          'Yellow leaves almost always mean overwatering — always check the soil before watering',
          'Aerial roots that reach the soil will boost growth significantly — do not cut them',
          'Mist the leaves in summer or place on a pebble tray with water to raise humidity'
        ],
        'funFact': 'The name Deliciosa refers to the edible fruit the plant produces in the wild — it tastes like a combination of pineapple and banana. It takes about a year to ripen and is only safe to eat when the scales fall off naturally.',
        'imageUrl': '',
      },
      {
        'id': 'snake_plant',
        'name': 'Sansevieria Trifasciata',
        'commonName': 'Snake Plant',
        'category': 'Succulent',
        'difficulty': 'Very Easy',
        'light': 'Low to bright indirect light',
        'water': 'Every 2-6 weeks',
        'humidity': 'Low to average',
        'temperature': '15-29°C',
        'soilType': 'Cactus or succulent mix',
        'fertilizer': 'Once in spring only',
        'toxicity': 'Mildly toxic to pets',
        'description': 'The Snake Plant is the undisputed champion of low-maintenance houseplants. Originally from West Africa where it grows in rocky, dry environments, it has developed remarkable survival strategies including the ability to perform CAM photosynthesis — absorbing CO2 at night rather than during the day. This makes it uniquely beneficial in bedrooms where it quietly improves air quality while you sleep. It will tolerate neglect, dark corners, and erratic watering that would kill almost any other plant.',
        'careTips': [
          'Allow the soil to dry out completely between waterings — root rot is the only real way to kill this plant',
          'In winter reduce watering to once a month or even less',
          'Avoid getting water in the crown of the plant which can cause rot at the base',
          'It tolerates low light but grows faster and produces more striking variegation in brighter conditions',
          'Repot only when roots are visibly escaping the drainage holes — it actually prefers being rootbound',
          'Perfect plant for bedrooms, offices, and bathrooms with minimal natural light'
        ],
        'funFact': 'NASA included the Snake Plant in their famous Clean Air Study finding it removes toxins including benzene, formaldehyde, trichloroethylene, and xylene from indoor air. One plant per 100 square feet is the recommended ratio for meaningful air purification.',
        'imageUrl': '',
      },
      {
        'id': 'pothos',
        'name': 'Epipremnum Aureum',
        'commonName': 'Pothos',
        'category': 'Tropical',
        'difficulty': 'Very Easy',
        'light': 'Low to bright indirect light',
        'water': 'Every 1-2 weeks',
        'humidity': 'Average',
        'temperature': '15-29°C',
        'soilType': 'Standard potting mix',
        'fertilizer': 'Every 2-3 months',
        'toxicity': 'Toxic to pets and humans',
        'description': 'Pothos is perhaps the world most widely grown houseplant and for excellent reason. Its trailing vines can grow over 10 metres long indoors, cascading beautifully from shelves or climbing walls with minimal care. Originally from the Society Islands of French Polynesia, it has naturalised across tropical regions worldwide and demonstrates extraordinary adaptability. Whether you want a trailing accent, a climbing statement piece, or a full hanging basket, Pothos delivers with virtually zero effort.',
        'careTips': [
          'Let the soil dry halfway before watering — it is far more tolerant of underwatering than overwatering',
          'Variegated varieties like Golden and Marble Queen need more light to maintain their patterns',
          'Propagates incredibly easily — place a node cutting in water and roots appear within 2 weeks',
          'Trim long vines regularly to encourage bushier more compact growth',
          'Brown leaf tips usually indicate low humidity or fluoride in tap water — use filtered water',
          'Clean the leaves occasionally as dust reduces their ability to absorb light'
        ],
        'funFact': 'In ideal outdoor tropical conditions Pothos leaves can grow to over 60 centimetres wide and develop deep fenestrations similar to Monstera. The small heart-shaped leaves we see indoors are actually the juvenile form — the plant never matures to its adult form without climbing a tall tree.',
        'imageUrl': '',
      },
      {
        'id': 'fiddle_leaf_fig',
        'name': 'Ficus Lyrata',
        'commonName': 'Fiddle Leaf Fig',
        'category': 'Tropical',
        'difficulty': 'Hard',
        'light': 'Bright indirect light — needs consistency',
        'water': 'Every 1-2 weeks — consistency is key',
        'humidity': 'Moderate to high',
        'temperature': '16-24°C — no cold drafts',
        'soilType': 'Well-draining rich mix with perlite',
        'fertilizer': 'Monthly in spring and summer',
        'toxicity': 'Toxic to pets',
        'description': 'The Fiddle Leaf Fig has earned a reputation as the most dramatic and rewarding houseplant for those willing to meet its specific needs. Native to the tropical rainforests of West Africa where it grows as a tall canopy tree, it has evolved to receive consistent warmth, humidity, and filtered light. Indoors it demands respect — sudden changes in environment cause immediate leaf drop. However when you find its perfect spot and establish a consistent care routine, it rewards you with spectacular architectural beauty that defines a room.',
        'careTips': [
          'Never move it once it has settled — even rotating it can cause leaf drop initially',
          'Water on a consistent schedule and always check that the top 5cm of soil is dry first',
          'Never let it sit in water — drain the saucer after watering every single time',
          'Dust the large leaves regularly — dirty leaves visibly stress this plant',
          'Brown edges mean low humidity — brown spots with yellow halos mean overwatering',
          'Introduce it to its permanent spot in spring when growth is active so it can adjust more easily'
        ],
        'funFact': 'The Fiddle Leaf Fig gets its common name from the shape of its leaves which resemble the body of a fiddle or violin. In its native West African habitat it is an epiphyte that begins life growing on other trees before its roots eventually reach the ground and it establishes as a full tree reaching 12 metres tall.',
        'imageUrl': '',
      },
      {
        'id': 'zz_plant',
        'name': 'Zamioculcas Zamiifolia',
        'commonName': 'ZZ Plant',
        'category': 'Succulent',
        'difficulty': 'Very Easy',
        'light': 'Low to bright indirect light',
        'water': 'Every 2-3 weeks',
        'humidity': 'Low to average',
        'temperature': '15-26°C',
        'soilType': 'Well-draining cactus mix',
        'fertilizer': 'Once or twice a year maximum',
        'toxicity': 'Toxic to pets and humans',
        'description': 'The ZZ Plant is a geological survivor. Native to the drought-prone grasslands and forests of Eastern Africa from Kenya to South Africa, it has evolved thick rhizomes underground that store water for months at a time. This makes it extraordinarily tolerant of neglect and irregular watering. Its waxy deep green leaves naturally repel dust and stay glossy and attractive with minimal intervention. If you have ever felt you cannot keep a plant alive, the ZZ Plant will change your mind.',
        'careTips': [
          'Less is definitively more — when in doubt do not water',
          'The rhizomes store months of water — you can go on holiday without arranging a plant sitter',
          'It tolerates fluorescent lighting making it one of the best plants for windowless offices',
          'Wipe leaves occasionally with a damp cloth to maintain the natural wax gloss',
          'Propagate by placing individual leaflets in moist soil — it takes months but it works',
          'Repot only every 2-3 years as it actually prefers being slightly rootbound'
        ],
        'funFact': 'The ZZ Plant was only introduced to the houseplant market in 1996 when Dutch nurseries began propagating it commercially. Before that it was relatively unknown outside its native African habitat despite being an extraordinary survivor. It has since become one of the top 10 selling houseplants worldwide.',
        'imageUrl': '',
      },
      {
        'id': 'peace_lily',
        'name': 'Spathiphyllum Wallisii',
        'commonName': 'Peace Lily',
        'category': 'Tropical',
        'difficulty': 'Easy',
        'light': 'Low to medium indirect light',
        'water': 'Every 1-2 weeks — drooping signals thirst',
        'humidity': 'High',
        'temperature': '18-27°C',
        'soilType': 'Rich well-draining mix',
        'fertilizer': 'Every 6 weeks in growing season',
        'toxicity': 'Toxic to pets and humans',
        'description': 'The Peace Lily is one of the most forgiving and communicative houseplants you can own. When it needs water it dramatically droops its leaves — giving you a clear signal before any real damage occurs. Native to the tropical forests of Colombia and Venezuela, it thrives in the dappled light beneath the forest canopy making it perfectly adapted to low-light indoor environments. Its elegant white spathes and deep glossy leaves bring a sense of calm serenity to any space, which is perhaps why it has become one of the most gifted plants for homes and offices.',
        'careTips': [
          'Use the droop as your watering signal — it is more reliable than any schedule',
          'Keep well away from cold drafts and air conditioning vents',
          'Remove spent flowers by cutting the stem at the base to encourage new blooms',
          'Wipe leaves regularly with a damp cloth to keep them glossy and dust-free',
          'Brown leaf tips indicate fluoride sensitivity — switch to filtered or rainwater',
          'It will bloom more reliably in slightly brighter indirect light despite tolerating low light'
        ],
        'funFact': 'The white part of a Peace Lily flower that looks like a petal is actually a modified leaf called a spathe. The true flowers are the tiny yellowish white structures on the central spike called the spadix. This structure is shared with other aroids including Anthuriums, Monsteras, and Calla Lilies.',
        'imageUrl': '',
      },
      {
        'id': 'rubber_plant',
        'name': 'Ficus Elastica',
        'commonName': 'Rubber Plant',
        'category': 'Tropical',
        'difficulty': 'Easy',
        'light': 'Bright indirect light',
        'water': 'Every 1-2 weeks',
        'humidity': 'Moderate',
        'temperature': '15-24°C',
        'soilType': 'Well-draining potting mix',
        'fertilizer': 'Monthly in growing season',
        'toxicity': 'Toxic to pets',
        'description': 'The Rubber Plant is a bold architectural houseplant that makes an immediate statement. Native to Southeast Asia from northeast India through to Malaysia, it naturally grows as a large tree in tropical rainforests. Its large glossy leaves come in varieties ranging from deep emerald green to almost black burgundy to variegated cream and pink. In the 19th century it was cultivated extensively in plantations across Southeast Asia for latex production before synthetic rubber replaced it. Today it is treasured purely for its dramatic good looks as a fast-growing indoor tree.',
        'careTips': [
          'Allow the top inch of soil to dry out before watering — it dislikes constantly moist soil',
          'Clean the large leaves regularly to maintain their signature glossy appearance',
          'Pinch out the growing tip to encourage branching and create a bushier rather than leggy plant',
          'Avoid sudden temperature changes and cold drafts which cause leaf drop',
          'The milky white sap is an irritant — wear gloves when pruning and keep away from eyes',
          'New leaves emerge wrapped in a red sheath which unfurls dramatically — do not pull it'
        ],
        'funFact': 'Before the development of the Hevea brasiliensis plantation rubber tree in the 19th century, Ficus Elastica was the primary commercial source of natural rubber. The name Elastica refers to the elastic properties of its latex sap. Alexander the Great reportedly used bridges made from the woven aerial roots of related Ficus species during his campaigns in India.',
        'imageUrl': '',
      },
      {
        'id': 'calathea_ornata',
        'name': 'Calathea Ornata',
        'commonName': 'Pinstripe Plant',
        'category': 'Tropical',
        'difficulty': 'Hard',
        'light': 'Medium indirect light — no direct sun',
        'water': 'Every 1-2 weeks — keep consistently moist',
        'humidity': 'Very high 70 percent plus',
        'temperature': '18-27°C',
        'soilType': 'Moist well-draining peat-free mix',
        'fertilizer': 'Every 4 weeks in growing season',
        'toxicity': 'Non-toxic — safe for pets and children',
        'description': 'Calathea Ornata is a living work of art. Native to the tropical forests of Colombia and Venezuela, it has evolved its extraordinary leaf patterns as camouflage in the dappled light of the forest floor. The deep green leaves are painted with precise pink and white pinstripes and the undersides are a rich burgundy purple. What makes Calatheas truly magical is their nyctinasty — the leaves fold upward at night and open again in the morning in response to light changes. Caring for a Calathea is an art form but the reward is unmatched.',
        'careTips': [
          'Use only distilled water, rainwater, or water left out overnight — tap water causes brown tips',
          'Never let it dry out completely but equally never let it sit in water',
          'Humidity below 50 percent causes curling and brown edges — a humidifier is ideal',
          'Keep away from all direct sunlight which bleaches the distinctive pinstripe patterns',
          'Wipe leaves gently with a damp cloth — never use leaf shine products which block pores',
          'Normal leaf movement folding at night and opening in morning means your plant is thriving'
        ],
        'funFact': 'Calatheas are sometimes called Prayer Plants because their leaves fold up at night in a gesture resembling praying hands. This movement is caused by a joint at the base of each leaf stem called a pulvinus which changes water pressure to move the leaf. Scientists believe this behaviour may have evolved to allow rainwater to reach the roots more effectively.',
        'imageUrl': '',
      },
      {
        'id': 'aloe_vera',
        'name': 'Aloe Barbadensis Miller',
        'commonName': 'Aloe Vera',
        'category': 'Succulent',
        'difficulty': 'Very Easy',
        'light': 'Bright direct or indirect light',
        'water': 'Every 2-3 weeks — drought tolerant',
        'humidity': 'Low',
        'temperature': '13-27°C',
        'soilType': 'Sandy gritty cactus mix',
        'fertilizer': 'Once or twice a year only',
        'toxicity': 'The gel is safe topically but toxic if ingested by pets',
        'description': 'Aloe Vera is one of the most useful plants you can keep in your home. Cultivated by humans for over 6000 years, it has been documented in ancient Egyptian, Greek, Roman, Indian, and Chinese medical texts. The clear gel stored in its thick succulent leaves contains over 75 potentially active compounds including vitamins, minerals, enzymes, amino acids, and polysaccharides with well-documented soothing properties for burns and skin irritations. It is also extraordinarily easy to grow, thriving on bright light and minimal water.',
        'careTips': [
          'Plant in terracotta pots which draw excess moisture away from the roots unlike plastic',
          'Water deeply then allow the soil to dry completely before watering again — usually 2-3 weeks',
          'Reduce watering significantly in winter when the plant is dormant',
          'Harvest gel by cutting the outermost most mature leaves cleanly at the base',
          'Offset pups that appear around the base can be separated and potted individually',
          'Brown mushy leaves at the base almost always indicate root rot from overwatering'
        ],
        'funFact': 'Ancient Egyptians called Aloe Vera the plant of immortality and it was reportedly used by Cleopatra as part of her beauty regimen. Alexander the Great is said to have conquered the island of Socotra specifically to secure the Aloe supply for treating his soldiers wounds. NASA confirmed its gel absorbs electromagnetic radiation making it useful near computers and televisions.',
        'imageUrl': '',
      },
      {
        'id': 'spider_plant',
        'name': 'Chlorophytum Comosum',
        'commonName': 'Spider Plant',
        'category': 'Tropical',
        'difficulty': 'Very Easy',
        'light': 'Bright to medium indirect light',
        'water': 'Every 1-2 weeks',
        'humidity': 'Average',
        'temperature': '13-27°C',
        'soilType': 'Standard well-draining mix',
        'fertilizer': 'Every 2 weeks in summer',
        'toxicity': 'Non-toxic — completely safe for pets and children',
        'description': 'The Spider Plant is one of the most cheerful and generous houseplants in existence. Native to coastal areas of South Africa, it produces long arching stems tipped with miniature plantlets that dangle in the air like little spiders on their webs — hence the name. It is one of the safest plants for households with pets and small children, completely non-toxic and mildly hallucinogenic to cats in a harmless way that makes it irresistibly entertaining. Its adaptability, fast growth, and easy propagation have made it a beloved feature of homes and offices for generations.',
        'careTips': [
          'Propagate the dangling baby spiderettes by placing them in a small pot of moist soil while still attached',
          'Brown tips are almost always caused by fluoride or chlorine in tap water — use filtered water',
          'It thrives in hanging baskets where the babies can cascade dramatically',
          'Divide root-bound plants in spring to create multiple new plants instantly',
          'Feed every two weeks in summer for maximum growth and the most prolific baby production',
          'Despite preferring bright light it is remarkably tolerant of lower light conditions'
        ],
        'funFact': 'Spider Plants were included in NASAs 1989 Clean Air Study and were found to be extraordinarily effective at removing indoor air pollutants — a single plant can remove up to 95 percent of toxic agents from a sealed environment within 24 hours according to the study. They are also mildly hallucinogenic to cats due to compounds related to opioids though the effect is completely harmless.',
        'imageUrl': '',
      },
    ];

    final batch = _db.batch();
    for (final s in species) {
      final ref = collection.doc(s['id'] as String);
      batch.set(ref, s);
    }
    await batch.commit();
  }

  Future<void> seedSwapListings() async {}

  Future<void> saveHealthAssessment(String plantId, Map<String, dynamic> assessmentData) async {
    final uid = currentUserId;
    if (uid == null) return;
    final condition = assessmentData['condition']?.toString() ?? 'Healthy';
    final String healthStatus;
    switch (condition) {
      case 'Thriving':
      case 'Healthy':
        healthStatus = 'Healthy';
        break;
      case 'Needs Attention':
        healthStatus = 'Needs Attention';
        break;
      case 'Critical':
        healthStatus = 'Critical';
        break;
      default:
        healthStatus = 'Healthy';
    }
    await _db.collection('users').doc(uid).collection('plants').doc(plantId).set({
      'lastAssessment': assessmentData,
      'lastAssessmentDate': FieldValue.serverTimestamp(),
      'healthStatus': healthStatus,
    }, SetOptions(merge: true));
  }

  Future<String> createTreatmentCase(TreatmentCase treatmentCase) async {
    final uid = currentUserId;
    if (uid == null) return '';
    final docRef = _db.collection('users').doc(uid).collection('treatment_cases').doc();
    final caseWithId = TreatmentCase(
      id: docRef.id, plantId: treatmentCase.plantId, plantName: treatmentCase.plantName,
      diagnosis: treatmentCase.diagnosis, severity: treatmentCase.severity,
      detectedDate: treatmentCase.detectedDate, status: treatmentCase.status,
      treatmentSteps: treatmentCase.treatmentSteps, followUpDates: treatmentCase.followUpDates,
      progressNotes: treatmentCase.progressNotes, resolvedDate: treatmentCase.resolvedDate,
      initialPhotoUrl: treatmentCase.initialPhotoUrl, latestPhotoUrl: treatmentCase.latestPhotoUrl,
    );
    await docRef.set(caseWithId.toMap());
    return docRef.id;
  }

  Stream<List<TreatmentCase>> getTreatmentCases(String plantId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('treatment_cases')
        .where('plantId', isEqualTo: plantId).orderBy('detectedDate', descending: true)
        .snapshots().map((snap) => snap.docs.map((d) => TreatmentCase.fromMap(d.data())).toList());
  }

  Future<void> updateTreatmentCaseProgress({required String caseId, required String progressNote, required String photoUrl, required String newStatus}) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('treatment_cases').doc(caseId).update({
      'progressNotes': FieldValue.arrayUnion([progressNote]),
      'latestPhotoUrl': photoUrl,
      'status': newStatus,
    });
  }

  Future<void> resolveTreatmentCase(String caseId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('treatment_cases').doc(caseId).update({
      'status': 'Resolved',
      'resolvedDate': FieldValue.serverTimestamp(),
    });
  }

  Future<int> computeAndSaveHealthScore(String userUid, String plantId) async {
    int score = 100;
    final plantDoc = await _db.collection('users').doc(userUid).collection('plants').doc(plantId).get();
    if (!plantDoc.exists) return score;
    final plantData = plantDoc.data()!;
    final plantName = plantData['name'] ?? '';
    
    final tasksQuery = await _db.collection('users').doc(userUid).collection('tasks')
        .where('plantName', isEqualTo: plantName).orderBy('dueDate', descending: true).limit(10).get();
        
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (tasksQuery.docs.isNotEmpty) {
      final waterTasks = tasksQuery.docs.where((d) => d.data()['taskType'] == 'Watering').toList();
      if (waterTasks.isNotEmpty) {
        final lastWater = waterTasks.first.data();
        if (lastWater['isCompleted'] == false) {
          final dueDate = (lastWater['dueDate'] as Timestamp).toDate();
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          if (dueDay.isBefore(today)) {
            final daysOverdue = today.difference(dueDay).inDays;
            if (daysOverdue >= 1 && daysOverdue <= 3) { score -= 10; }
            else if (daysOverdue > 3) { score -= 20; }
          }
        }
      }

      int skipCount = 0;
      final last3 = tasksQuery.docs.take(3).toList();
      for (var doc in last3) {
        final data = doc.data();
        if (data['isCompleted'] == false) {
          final dueDate = (data['dueDate'] as Timestamp).toDate();
          final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          if (dueDay.isBefore(today)) { skipCount++; }
        }
      }
      if (skipCount >= 2) score -= 15;
    }

    if (plantData.containsKey('lastAssessment') && plantData['lastAssessment'] != null) {
      final assessment = plantData['lastAssessment'] as Map<String, dynamic>;
      final overallScore = (assessment['overallScore'] as num?)?.toInt() ?? 100;
      score = ((score * 0.6) + (overallScore * 0.4)).round();
    }

    if (plantData.containsKey('lastAssessmentDate') && plantData['lastAssessmentDate'] != null) {
      final lastAssessmentTs = (plantData['lastAssessmentDate'] as Timestamp).toDate();
      if (now.difference(lastAssessmentTs).inDays > 30) score -= 5;
    }

    final zoneUid = plantData['zone']?.toString().isNotEmpty == true ? plantData['zone'] : 'main_zone';
    
    final tempQuery = await _db.collection('users').doc(userUid).collection('zones').doc(zoneUid).collection('readings')
        .where('type', isEqualTo: 'temperature').orderBy('timestamp', descending: true).limit(1).get();
        
    if (tempQuery.docs.isNotEmpty) {
      final temp = (tempQuery.docs.first.data()['value'] as num?)?.toDouble() ?? 20.0;
      if (temp < 15 || temp > 28) { score -= 5; }
    }
    
    final humQuery = await _db.collection('users').doc(userUid).collection('zones').doc(zoneUid).collection('readings')
        .where('type', isEqualTo: 'humidity').orderBy('timestamp', descending: true).limit(1).get();
        
    if (humQuery.docs.isNotEmpty) {
      final hum = (humQuery.docs.first.data()['value'] as num?)?.toDouble() ?? 50.0;
      if (hum < 30) { score -= 10; }
    }

    if (score < 0) score = 0;
    if (score > 100) score = 100;

    await plantDoc.reference.update({
      'healthScore': score,
      'healthScoreUpdatedAt': FieldValue.serverTimestamp(),
    });

    return score;
  }

  Future<void> computeAllHealthScores(String userUid) async {
    final plantsQuery = await _db.collection('users').doc(userUid).collection('plants').get();
    final futures = plantsQuery.docs.map((doc) => computeAndSaveHealthScore(userUid, doc.id));
    await Future.wait(futures);
  }

  Future<void> markPlantAsDeceased(String plantId, String memorialNote) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('plants').doc(plantId).update({
      'isDeceased': true,
      'deceasedDate': FieldValue.serverTimestamp(),
      'memorialNote': memorialNote,
    });
  }

  Future<void> addFloraAnswer(String postId, String answerText) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'authorUid': 'flora-ai',
      'authorName': 'Flora AI',
      'text': answerText,
      'timestamp': FieldValue.serverTimestamp(),
      'isFloraAnswer': true,
    });
    await _db.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  Future<void> checkAndAnswerUnansweredQuestions() async {
    try {
      final postsQuery = await _db.collection('posts')
          .where('category', isEqualTo: 'Question')
          .where('status', isEqualTo: 'published')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (var doc in postsQuery.docs) {
        final data = doc.data();
        final postId = doc.id;
        
        final commentsQuery = await doc.reference.collection('comments')
            .where('isFloraAnswer', isEqualTo: true)
            .get();
            
        if (commentsQuery.docs.isEmpty) {
          final title = data['title'] as String? ?? '';
          final content = data['content'] as String? ?? '';
          final category = data['category'] as String? ?? '';
          
          final gemini = GeminiService();
          final answer = await gemini.generateCommunityAnswer(title, content, category);
          
          await addFloraAnswer(postId, answer);
          
          // Delay to avoid rate limits
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      debugPrint('Error checking unanswered questions: $e');
    }
  }
}
