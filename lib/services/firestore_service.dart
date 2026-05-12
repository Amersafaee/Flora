import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/treatment_case_model.dart';
import 'gemini_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/task_utils.dart';
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

  Stream<List<Map<String, dynamic>>> getLightweightPlants() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('plants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'healthScore': data['healthScore'],
          'healthStatus': data['healthStatus'] ?? 'Unknown',
          'lastAssessmentDate': data['lastAssessmentDate'],
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
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
      id: taskId, plantId: task.plantId, plantName: task.plantName, taskType: task.taskType,
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

  Stream<List<Task>> getTasksForWeek(DateTime weekStart) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    final endOfWeek = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return _db.collection('users').doc(uid).collection('tasks')
      .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
      .snapshots()
      .map((snapshot) {
        final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
        return tasks.where((task) {
          final isThisWeek = task.dueDate.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          final isOverdue = !task.isCompleted && task.dueDate.isBefore(weekStart);
          return isThisWeek || isOverdue;
        }).toList()
        ..sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          return a.dueDate.compareTo(b.dueDate);
        });
      });
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

  Stream<List<Task>> getTasksForPlant(String plantId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('tasks')
        .where('plantId', isEqualTo: plantId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList());
  }

  Future<void> markTaskCompleted(String taskId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final taskRef = _db.collection('users').doc(uid).collection('tasks').doc(taskId);
    final taskDoc = await taskRef.get();

    await taskRef.update({'isCompleted': true});
    await updateCareStreak();

    if (!taskDoc.exists) return;
    final data = taskDoc.data()!;
    final repeatType = data['repeatType'] as String? ?? 'none';
    if (repeatType == 'none' || repeatType.isEmpty) return;

    final dueDateRaw = data['dueDate'];
    if (dueDateRaw == null) return;
    DateTime dueDate = dueDateRaw is Timestamp ? dueDateRaw.toDate() : DateTime.now();

    final nextDue = calculateNextDueDate(dueDate, repeatType, (data['repeatDays'] as num?)?.toInt() ?? 7);
    if (nextDue == null) return;

    DateTime finalNextDue = nextDue;
    bool climateAdjusted = false;
    String climateNote = '';

    if (data['taskType'] == 'Watering') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final readingsSnap = await _db.collection('users').doc(uid).collection('zones').doc('main_zone').collection('readings')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

      double sumTemp = 0;
      double sumHum = 0;
      int countTemp = 0;
      int countHum = 0;

      for (var r in readingsSnap.docs) {
        final rData = r.data();
        if (rData['type'] == 'temperature' && rData['value'] is num) {
          sumTemp += (rData['value'] as num).toDouble();
          countTemp++;
        } else if (rData['type'] == 'humidity' && rData['value'] is num) {
          sumHum += (rData['value'] as num).toDouble();
          countHum++;
        }
      }

      double avgTemp = countTemp > 0 ? sumTemp / countTemp : 22.0;
      double avgHum = countHum > 0 ? sumHum / countHum : 50.0;

      final intervalDays = nextDue.difference(dueDate).inDays;
      
      if (avgHum < 40.0 || avgTemp > 27.0) {
        final newIntervalDays = (intervalDays * 0.8).round();
        finalNextDue = dueDate.add(Duration(days: newIntervalDays));
        climateAdjusted = true;
        climateNote = 'Adjusted for dry conditions';
      } else if (avgHum > 70.0 && avgTemp < 18.0) {
        final newIntervalDays = (intervalDays * 1.2).round();
        finalNextDue = dueDate.add(Duration(days: newIntervalDays));
        climateAdjusted = true;
        climateNote = 'Adjusted for humid conditions';
      }
    }

    final newDocRef = _db.collection('users').doc(uid).collection('tasks').doc();
    await newDocRef.set({
      'id': newDocRef.id,
      'plantId': data['plantId'] ?? '',
      'plantName': data['plantName'] ?? '',
      'taskType': data['taskType'] ?? '',
      'dueDate': Timestamp.fromDate(finalNextDue),
      'isCompleted': false,
      'notes': data['notes'] ?? '',
      'repeatType': repeatType,
      'repeatDays': data['repeatDays'] ?? 0,
      if (climateAdjusted) 'climateAdjusted': true,
      if (climateAdjusted) 'climateNote': climateNote,
    });
  }

  Future<void> updateCareStreak() async {
    final uid = currentUserId;
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    int careStreak = (data['careStreak'] as num?)?.toInt() ?? 0;
    final lastCareDateRaw = data['lastCareDate'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime? lastCareDate;
    if (lastCareDateRaw != null && lastCareDateRaw is Timestamp) {
      final d = lastCareDateRaw.toDate();
      lastCareDate = DateTime(d.year, d.month, d.day);
    }

    if (lastCareDate == null) {
      careStreak = 1;
    } else if (lastCareDate == today) {
      return; // Already counted today
    } else if (lastCareDate == today.subtract(const Duration(days: 1))) {
      careStreak += 1;
    } else if (lastCareDate.isBefore(today.subtract(const Duration(days: 1)))) {
      careStreak = 1;
    }

    await docRef.update({
      'careStreak': careStreak,
      'lastCareDate': Timestamp.fromDate(now),
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

  Future<int> checkAndCreateInspectionTasks(String uid) async {
    final plantsSnap = await _db.collection('users').doc(uid).collection('plants').get();
    int newTasksCount = 0;
    
    for (var plantDoc in plantsSnap.docs) {
      final plantData = plantDoc.data();
      final plantId = plantDoc.id;
      final plantName = plantData['name'] ?? 'Unknown';
      
      final growthSnap = await _db.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth')
          .orderBy('timestamp', descending: true).limit(1).get();
      
      bool needsInspection = false;
      if (growthSnap.docs.isEmpty) {
        needsInspection = true;
      } else {
        final lastGrowth = growthSnap.docs.first.data();
        if (lastGrowth['timestamp'] != null) {
          final timestamp = lastGrowth['timestamp'] as Timestamp;
          final diff = DateTime.now().difference(timestamp.toDate()).inDays;
          if (diff > 21) {
            needsInspection = true;
          }
        }
      }
      
      if (needsInspection) {
        final existingTaskSnap = await _db.collection('users').doc(uid).collection('tasks')
            .where('plantId', isEqualTo: plantId)
            .where('taskType', isEqualTo: 'Inspection')
            .where('isCompleted', isEqualTo: false)
            .get();
        
        bool hasFutureTask = false;
        final now = DateTime.now();
        for (var t in existingTaskSnap.docs) {
          final td = t.data();
          if (td['dueDate'] != null) {
            final due = (td['dueDate'] as Timestamp).toDate();
            if (due.isAfter(now) || DateTime(due.year, due.month, due.day).isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
              hasFutureTask = true;
              break;
            }
          }
        }
        
        if (!hasFutureTask) {
          final newTaskRef = _db.collection('users').doc(uid).collection('tasks').doc();
          await newTaskRef.set({
            'id': newTaskRef.id,
            'plantId': plantId,
            'plantName': plantName,
            'taskType': 'Inspection',
            'dueDate': Timestamp.fromDate(now),
            'isCompleted': false,
            'notes': 'No growth journal entry in 21+ days — Flora recommends a check-in',
            'repeatType': 'none',
            'repeatDays': 0,
          });
          newTasksCount++;
        }
      }
    }
    return newTasksCount;
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

  Future<void> seedBlogData() async {
    final collection = _db.collection('blogs');

    // Check if the collection already has documents
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return; // Return early if blogs already exist
    }

    final List<Map<String, dynamic>> blogs = [
      {
        'id': 'common_watering_mistakes',
        'title': 'The Most Common Watering Mistakes and How to Fix Them',
        'category': 'Watering',
        'readMinutes': 6,
        'summary': 'Watering is the hardest part of plant parenting. Learn how to avoid the deadly sins of over and under-watering.',
        'content': '''Welcome to the Digital Conservatory! Watering your plants sounds incredibly simple, but it is actually the number one reason houseplant parents face heartache. You might think that a strict schedule of watering every Sunday is the best way to show your leafy friends you care, but plants do not thrive on human calendars. They have their own rhythms, dictated by the season, the humidity in your home, and the type of pot they are living in. Overwatering is by far the most common mistake you can make. When you water too frequently, the soil stays constantly wet, suffocating the roots. Roots need oxygen just as much as they need water, and sitting in mud leads directly to root rot. To fix this, you need to start checking the soil before you water. Stick your finger about two inches down into the pot. If it feels moist, wait a few more days. If it feels completely dry, it is time for a drink. Underwatering is the opposite problem, usually born out of neglect or a fear of overwatering. When you do not give your plant enough water, the leaves will begin to droop, curl, and eventually crisp up at the edges. The fix here is to water deeply when you do water. Do not just give your plant a tiny sip; instead, take it to the sink and water it until moisture pours out of the drainage holes. This ensures that the entire root ball gets hydrated. Another mistake is using the wrong temperature of water. Always use room temperature water. Ice cold water can shock the tropical roots of your indoor plants. Furthermore, try to avoid getting water directly on the leaves of fuzzy plants like African violets, as this can cause spotting and fungal issues. The pot itself matters greatly, too. Terracotta pots are porous and allow soil to dry out faster, making them great for heavy waterers, whereas plastic pots retain moisture longer. Moreover, never ever use a pot without drainage holes. It is essentially a bathtub with no drain, and water will pool at the bottom where you cannot see it. If you find a beautiful decorative pot without holes, simply keep your plant in its plastic nursery pot and use the decorative one as a cachepot—taking the plastic pot out when you water, letting it drain completely, and then placing it back inside. By paying attention to these simple cues, you will become a much more intuitive plant parent.''',
        'tags': ['watering', 'mistakes', 'basics', 'roots'],
        'publishedDate': '2024-01-15'
      },
      {
        'id': 'understanding_light_levels',
        'title': 'Demystifying Light Levels for Your Indoor Garden',
        'category': 'Light',
        'readMinutes': 5,
        'summary': 'Confused by bright indirect light? We break down exactly what your plant needs to thrive.',
        'content': '''Light is food for your plants. While fertilizer is like a vitamin supplement, light provides the actual energy your plant needs to photosynthesize and grow. When you bring a new plant home, the first thing you need to figure out is where it will live, and that decision is entirely dependent on light. You have probably read the phrase bright indirect light a hundred times, but what does it actually mean? Imagine you are a plant. If you are sitting in a spot where you can see the sky but the sun is not directly hitting your leaves, you are in bright indirect light. This is the sweet spot for the vast majority of tropical houseplants. A few feet away from an east or west-facing window is usually perfect. Direct light, on the other hand, means the sun's rays are beating right down on the plant. South-facing windows often provide direct light. While desert dwellers like cacti and succulents absolutely love this, it will quickly scorch the delicate leaves of a calathea or a fern. Low light is a tricky category. It does not mean no light. A room with no windows is not low light; it is a cave, and no plant will survive there long-term without artificial help. Low light means an area far from a window or a north-facing room where the light is very gentle and ambient. Plants like snake plants and ZZ plants can tolerate this, but keep in mind that they are merely surviving, not necessarily thriving. Growth will be very slow in low light conditions. To measure your light, you can try the shadow test. On a sunny day, hold your hand about a foot above the spot where you want to place your plant. If the shadow is sharp and well-defined, you have bright, direct light. If the shadow is fuzzy but still distinct, you have bright indirect light. If the shadow is barely there, it is a low light spot. Remember that light changes with the seasons. A spot that receives bright light in the summer might be completely shadowed in the winter, meaning you will need to relocate your plants. If your home simply does not have the natural light required, do not despair. Artificial grow lights have come a long way and can perfectly supplement or entirely replace the sun. LED grow lights are energy-efficient and come in various spectrums. Full-spectrum white lights blend seamlessly into your home decor while providing the exact wavelengths your plants need to photosynthesize. Place them a few inches to a foot above your plants and run them for twelve to sixteen hours a day to simulate a bright summer day.''',
        'tags': ['sunlight', 'placement', 'growth', 'grow lights'],
        'publishedDate': '2024-02-10'
      },
      {
        'id': 'diagnosing_yellow_leaves',
        'title': 'Why Are My Leaves Turning Yellow? A Diagnostic Guide',
        'category': 'Beginner',
        'readMinutes': 6,
        'summary': 'Yellow leaves are your plant crying out for help. Learn to interpret the signs and save your green friends.',
        'content': '''Nothing strikes fear into the heart of a plant parent quite like the sudden appearance of a yellow leaf. But before you panic, take a deep breath. A yellow leaf is simply a form of communication. Your plant is trying to tell you that something in its environment needs adjusting. The tricky part is that yellow leaves can mean several entirely different things, so you have to play detective. The most common culprit, as with many plant woes, is your watering routine. Both overwatering and underwatering can cause leaves to yellow. If the yellow leaves are primarily near the bottom of the plant, and they feel soft, limp, and perhaps even a bit mushy, you are likely dealing with overwatering. The roots are drowning and cannot transport nutrients. Let the soil dry out significantly before you water again. Conversely, if the yellow leaves are dry, crispy, and crumbling to the touch, your plant is extremely thirsty. Give it a thorough soaking. If you have ruled out watering, consider your light situation. A plant that is not getting enough light will often shed its older, lower leaves to conserve energy for new growth at the top. The plant is essentially deciding that those lower leaves are not producing enough energy to justify keeping them alive. On the flip side, too much direct sunlight can cause a plant's leaves to look washed out and yellowed, essentially giving them a sunburn. Nutrient deficiencies are another possibility, though less common for new plants. If the leaves are turning yellow but the veins remain green, your plant might be lacking magnesium or iron. A balanced, water-soluble fertilizer applied during the growing season can help correct this. Pests can also be the hidden cause behind yellowing foliage. Sap-sucking insects like spider mites, aphids, or thrips attach themselves to the undersides of leaves and drain the plant's essential fluids. This relentless attack damages the plant tissue, causing a speckled yellowing that eventually takes over the whole leaf. Always check the undersides of yellowing leaves for tiny webs or specks of dust that seem to move. Treating the pest problem promptly is the only way to stop the yellowing in its tracks. Finally, do not forget that plants are living things that age. It is entirely normal for a plant to drop its oldest leaves as it grows. If you see an occasional yellow leaf at the very base of a mature plant, there is likely no cause for concern.''',
        'tags': ['troubleshooting', 'yellow leaves', 'health', 'signs'],
        'publishedDate': '2024-03-05'
      },
      {
        'id': 'beginner_guide_to_propagation',
        'title': 'Multiplying Your Jungle: A Beginner’s Guide to Propagation',
        'category': 'Propagation',
        'readMinutes': 5,
        'summary': 'Turn one plant into many! Discover the joy and simplicity of propagating your houseplants in water.',
        'content': '''Welcome to one of the most rewarding aspects of plant ownership: propagation. There is something truly magical about taking a small clipping from a beloved plant and watching it transform into an entirely new, independent life. It feels like a plant superpower, and the best part is that it is incredibly easy to learn. The simplest and most visually satisfying method for beginners is water propagation. It works beautifully for popular vining plants like pothos, philodendrons, and monsteras. The first and most crucial step is knowing where to cut. You cannot just snip a leaf off anywhere and expect it to grow roots. You need to find a node. A node is the small, slightly raised bump on the stem where a leaf attaches, or where aerial roots might be starting to form. This is the spot where the magic happens, as it contains the cellular blueprints to create new roots. Use a clean, sharp pair of scissors or pruning shears to make a cut about a quarter-inch below the node. Make sure your cutting has at least one or two leaves to provide energy, but remove any leaves that would be submerged in water, as they will rot and foul the liquid. Place your cutting in a glass jar or vase filled with clean, room-temperature water. Ensure the node is completely submerged. Place the vessel in a warm spot that receives bright, indirect light. Direct sun will heat the water too much and cook your fragile new clipping. Now, you wait. Patience is key here. Every few days, change the water to keep it fresh and oxygenated. Over the next few weeks, you will start to see tiny white nubs emerging from the node. These will gradually lengthen into roots. It is a thrilling process to watch unfold. While water propagation is fantastic for beginners, you can also experiment with rooting directly in moist sphagnum moss or perlite. These mediums provide excellent airflow around the developing roots, which can sometimes lead to a stronger, faster-growing root system than water alone. Simply soak the moss, squeeze out the excess water, and nestle your node right into it. Keep the moss consistently damp by enclosing it in a clear plastic bag or a propagation box to maintain incredibly high humidity. Once the roots are a couple of inches long, pot it up in soil, keep it slightly moist to ease the transition, and congratulations on your new plant!''',
        'tags': ['propagation', 'cuttings', 'water rooting', 'nodes'],
        'publishedDate': '2024-04-12'
      },
      {
        'id': 'winter_plant_care_guide',
        'title': 'Winter is Coming: Adjusting Your Plant Care for the Colder Months',
        'category': 'Seasonal',
        'readMinutes': 6,
        'summary': 'As the days get shorter and colder, your plants need a change in routine. Learn how to winterize your indoor garden.',
        'content': '''As the days grow shorter, the temperatures drop, and you start reaching for your cozy sweaters, it is time to realize your houseplants are feeling the change too. Winter requires a significant shift in how you care for your indoor jungle. The routines that worked perfectly in the bright, warm days of summer can actually be harmful during the dormant winter months. The most dramatic change you need to make is to your watering schedule. Because there is less light and less heat, your plants' growth slows down drastically. Many enter a period of semi-dormancy. This means they are not consuming water at nearly the same rate. If you continue to water them as often as you did in July, the soil will stay wet for too long, leading to the dreaded root rot. You must learn to wait. Check the soil diligently before watering, and let it dry out much more thoroughly than you would in the spring. Alongside reducing water, you should completely stop fertilizing. Pushing a plant to grow when it naturally wants to rest will result in weak, spindly, and unhealthy growth. Wait until you see the first signs of active new growth in the early spring before you bring out the plant food again. Temperature and drafts are another major winter concern. Most houseplants originate from tropical environments and despise cold air. Make sure your plants are not sitting near drafty windows or doors that open to the freezing outdoors. If you have older, drafty windows, consider pulling your plants a few feet back into the room from November until March. You can also use temporary window insulation film to block freezing air from seeping in and shocking your tropicals. Pay attention to the temperature fluctuations in your home. A space heater might keep you warm, but if it is blowing dry, hot air directly onto a fern, that plant will crisp up and die within days. Positioning is everything during the winter. Heating your home creates its own set of problems, mainly by destroying humidity. Radiators, forced air, and fireplaces dry out the air intensely. You need to artificially boost the humidity around your plants by grouping them or using a humidifier. Finally, maximize whatever light is available. Clean your windows to let in as much sun as possible, ensuring they emerge healthy and ready to burst with life when spring arrives.''',
        'tags': ['winter', 'dormancy', 'seasonal', 'temperature'],
        'publishedDate': '2024-05-20'
      },
      {
        'id': 'how_to_repot_without_stress',
        'title': 'The Art of Repotting: Giving Your Plants Room to Grow',
        'category': 'Advanced',
        'readMinutes': 5,
        'summary': 'Repotting does not have to be a traumatic experience. Learn the gentle techniques for upgrading your plant’s home.',
        'content': '''Repotting is a necessary chore in the life of a plant parent, but it is often approached with a mix of dread and anxiety. It is true that moving a plant from its established home into a new one causes stress, but if done correctly, that stress is minimal and the long-term benefits are immense. The first step is knowing when it is actually time to repot. Do not repot simply because you bought a pretty new planter. Look for signs that your plant is rootbound. Are roots poking out of the bottom drainage holes? Is the plant pushing itself up out of the pot? Does water run straight through the soil instantly because there is more root than dirt? If you answer yes to these, it is time for an upgrade. Timing matters, too. Spring and early summer are the best times to repot, as the plant is in its active growing phase and will recover much faster. Choose a new pot that is only one to two inches larger in diameter than the current one. Putting a small plant in a massive pot is a recipe for overwatering. Drainage is non-negotiable; ensure your new pot has holes at the bottom. To keep the mess manageable, lay down an old tarp or a large plastic garbage bag on your floor or table before you begin. When you are ready to make the move, water your plant a day or two beforehand. A well-hydrated plant is more flexible and resilient. Gently lay the pot on its side and coax the plant out. Do not yank it by the stem. If it is stuck, tap the sides of the pot to loosen the soil. Once the plant is out, inspect the roots. If they are tightly coiled, gently loosen the outer layer. Sometimes, if a plant is severely rootbound and you do not want to move it to a massive, heavy pot, you can practice root pruning. With a sterilized pair of scissors, carefully trim away the bottom third of the tightly coiled roots. This encourages fresh growth and allows you to put the plant back into the same pot with fresh, nutrient-rich soil. It is a slightly more advanced technique but incredibly useful. Place a layer of fresh mix in the bottom, center the plant, fill in the sides, and water thoroughly. Avoid fertilizing for a few weeks to let the sensitive roots heal.''',
        'tags': ['repotting', 'roots', 'growth', 'potting up'],
        'publishedDate': '2024-06-08'
      },
      {
        'id': 'natural_pest_control_for_houseplants',
        'title': 'Banish the Bugs: Natural Pest Control for Houseplants',
        'category': 'Pests',
        'readMinutes': 6,
        'summary': 'Spider mites, fungus gnats, and mealybugs, oh my! Defend your jungle using safe, natural methods.',
        'content': '''No matter how clean your home is or how careful you are, dealing with pests is an inevitable part of keeping houseplants. It is completely normal, so do not feel like you have failed as a plant parent if you spot a creepy crawler. The key is catching them early and treating them swiftly before an annoyance becomes an infestation. Because our plants live in our enclosed living spaces, often around pets and children, reaching for harsh chemical pesticides should be an absolute last resort. Fortunately, nature provides us with highly effective, gentle solutions. The first line of defense is observation. Every time you water, take a moment to inspect your plants. Look closely at the undersides of the leaves, where pests love to hide. If you see tiny webs, you likely have spider mites. If you notice small, white, cotton-like masses, you are dealing with mealybugs. If tiny black flies are buzzing around the soil, those are fungus gnats. If you spot an infestation, immediately isolate the affected plant. You do not want the bugs spreading to your entire collection. For most physical pests like aphids, spider mites, and mealybugs, a strong spray of water in the shower or sink is an excellent first step to physically knock them off the foliage. Next, employ neem oil. Neem oil is a natural byproduct of the neem tree and acts as an organic insecticide, disrupting the pests' life cycles. Mix a teaspoon of pure, cold-pressed neem oil with a drop of mild dish soap and warm water in a spray bottle. Thoroughly coat the plant, wiping down the leaves carefully. You will need to repeat this process every few days for a couple of weeks to catch newly hatched eggs. For fungus gnats, the problem lies in the wet soil. You must let the top two inches of soil dry out completely between waterings. If you are dealing with a truly severe infestation that natural sprays cannot seem to dent, you might explore beneficial insects. Releasing ladybugs or lacewings onto your indoor plants can be a fascinating, eco-friendly way to decimate aphid or mite populations. Alternatively, for non-edible ornamental plants, systemic granules mixed into the soil are taken up by the plant's roots, making the sap toxic to pests. While not strictly natural, it is an effective last resort when you are desperate to save a beloved plant from total destruction.''',
        'tags': ['pests', 'neem oil', 'organic', 'bugs'],
        'publishedDate': '2024-07-14'
      },
      {
        'id': 'best_soil_mixes_for_indoor_plants',
        'title': 'The Foundation of Health: Creating the Perfect Soil Mix',
        'category': 'Soil',
        'readMinutes': 5,
        'summary': 'Stop using straight potting soil! Learn how to amend your dirt to mimic your plants natural environment.',
        'content': '''One of the biggest leaps you will take in your plant care journey is realizing that standard, store-bought potting soil is rarely good enough straight out of the bag. Soil is the foundation of your plant's health. It provides stability, holds nutrients, and regulates moisture. However, the dense, peat-heavy mixes you find at the hardware store hold onto water for far too long, starving indoor roots of oxygen and almost guaranteeing root rot over time. To truly make your plants thrive, you need to start custom mixing your soil to suit the specific needs of your plants. Think of potting soil as merely the base ingredient. You need to add amendments to improve aeration and drainage. The most essential amendment you can buy is perlite or pumice. These lightweight, porous volcanic rocks create vital air pockets in the soil, allowing oxygen to reach the roots and excess water to drain away quickly. A good rule of thumb for most tropical foliage plants, like monsteras and pothos, is to mix two parts standard potting soil with one part perlite and one part orchid bark. Orchid bark provides excellent chunkiness, mimicking the loose, organic matter these plants climb on in their natural rainforest habitats. When choosing your base soil, consider looking for mixes made with coco coir instead of peat moss. Coco coir is a sustainable byproduct of the coconut industry, whereas peat is harvested from fragile bogs. Coir also rewets much easier if you accidentally let it dry out completely. To give your custom mix an incredible, natural nutrient boost, mix in a generous handful of worm castings. This organic fertilizer will not burn your plants' roots and provides a slow, steady release of essential minerals and beneficial microbes. If you are dealing with moisture-loving plants like ferns or calatheas, try two parts potting soil, one part perlite, and a handful of horticultural charcoal to keep the soil sweet. For succulents and cacti, drainage is everything. Combine one part potting soil with one part pumice, and one part coarse sand. Mixing your own soil might seem messy at first, but it gives you incredible control over your plants' environment. It is like cooking a meal from scratch instead of microwaving a frozen dinner. Storing your ingredients in airtight bins makes the process easy, and watching your plants explode with healthy root growth will prove the effort is worth it.''',
        'tags': ['soil', 'drainage', 'amendments', 'perlite'],
        'publishedDate': '2024-08-22'
      },
      {
        'id': 'how_humidity_affects_tropical_plants',
        'title': 'Creating a Jungle Atmosphere: Why Humidity Matters',
        'category': 'Advanced',
        'readMinutes': 5,
        'summary': 'Crispy leaf edges? The air in your home might be too dry. Discover how to create the humid microclimate your tropicals crave.',
        'content': '''If you have ever purchased a gorgeous, lush calathea or a delicate maidenhair fern, only to watch its leaves slowly turn brown and crispy at the edges despite perfect watering, you have encountered the invisible enemy: a lack of humidity. Most of the popular houseplants we bring into our homes originate from tropical rainforests, where the air is thick with moisture, often sitting at seventy or eighty percent humidity. Our modern, climate-controlled homes, especially in the winter or in arid climates, frequently hover around thirty percent or lower. This drastic difference in air moisture causes a severe issue for plants. Leaves constantly lose water to the air through tiny pores called stomata in a process known as transpiration. When the surrounding air is excessively dry, the plant loses water faster than its roots can pull it up from the soil. The result is those unsightly brown, dry margins, and a plant that generally looks dull and unhappy. So, how do we fix this invisible problem? Misting is often the first thing people try, but unfortunately, it is largely ineffective. Spraying your plants with a bottle only raises the humidity for a few minutes until the water evaporates, and leaving water sitting on leaves can actually encourage fungal diseases. You need solutions that provide consistent, ambient moisture. One excellent method is grouping your plants together. As they all transpire, they release moisture into the air, creating a humid microclimate. When you group your plants, try to place the most humidity-loving plants in the center of the cluster, surrounded by more resilient plants. This puts the sensitive divas right in the thickest part of the moisture cloud created by the collective transpiration. If you have plants that are absolute humidity divas, consider relocating them to a bathroom or kitchen that receives adequate light. The frequent use of showers and sinks makes these rooms naturally more humid than living rooms or bedrooms. Another low-tech solution is the pebble tray. Fill a shallow tray with pebbles and water, placing your pot on top to catch the evaporating moisture. However, if you are serious about keeping fussy tropicals, the best investment you can make is a humidifier. Placing a humidifier in your plant room guarantees a constant, measurable level of moisture in the air. Aim for fifty to sixty percent humidity, and your tropical beauties will truly flourish.''',
        'tags': ['humidity', 'tropicals', 'environment', 'microclimate'],
        'publishedDate': '2024-09-18'
      },
      {
        'id': 'reading_your_plant_signs',
        'title': 'Learning the Language of Leaves: Is Your Plant Thriving or Struggling?',
        'category': 'Beginner',
        'readMinutes': 5,
        'summary': 'Plants speak to us, just very slowly. Learn to interpret their subtle cues to become a master plant whisperer.',
        'content': '''Caring for houseplants is a continuous conversation. You provide water, light, and nutrients, and your plant responds by growing, changing color, or occasionally, drooping dramatically. The secret to becoming a truly successful plant parent is not adhering to a rigid, mathematical schedule, but rather learning to read the subtle visual and tactile signs your plant uses to communicate. A thriving plant is a joy to observe. Its leaves will appear turgid, meaning they are plump, firm, and fully hydrated. The foliage will possess a vibrant color and a natural, healthy sheen. You will see signs of active growth: tiny green spikes emerging from the soil, unfurling new leaves at the tips of vines, and robust, sturdy stems holding the plant upright. A plant that feels secure in its environment will often stand tall, reaching confidently toward its light source. Conversely, a struggling plant will send out distress signals long before it completely fails. Wilting is the most common cry for help. While a slight droop might just mean it is thirsty, a severe, sudden collapse can indicate shock or severe root rot. Pay close attention to the texture of the leaves. If they feel thin, papery, and brittle, your plant is severely dehydrated. If they feel unusually soft, mushy, or translucent, you are likely dealing with overwatering and cellular breakdown. Part of reading your plant involves noticing when it is physically struggling under its own weight. Climbing plants like Monsteras or vining Philodendrons will begin to look messy and unsupported without something to grab onto. Providing a moss pole or a trellis not only helps them grow larger, more mature leaves, but it also signals that you understand their natural climbing habits. Furthermore, take note of dust accumulation. A dusty leaf cannot photosynthesize properly. Gently wiping the foliage with a damp microfiber cloth is a great time to check in, read the signs, and bond with your collection. The speed of growth is another excellent indicator of overall health. A plant that produces zero new growth during the sunny months of spring and summer is telling you that something is wrong with its environment—usually a lack of light or exhausted soil. By taking the time to touch your plants, lift their pots, and closely inspect their leaves, you will develop an intuitive understanding of this silent language.''',
        'tags': ['observation', 'health', 'beginner tips', 'growth signs'],
        'publishedDate': '2024-10-02'
      }
    ];

    final batch = _db.batch();
    for (var b in blogs) {
      final docRef = collection.doc(b['id'] as String);
      b['createdAt'] = FieldValue.serverTimestamp();
      batch.set(docRef, b);
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
        .where('plantId', isEqualTo: plantId)
        .snapshots().map((snap) {
          final cases = snap.docs.map((d) => TreatmentCase.fromMap(d.data())).toList();
          cases.sort((a, b) => b.detectedDate.compareTo(a.detectedDate));
          return cases;
        });
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
    if (!plantData.containsKey('lastAssessment') || plantData['lastAssessment'] == null) {
      return score;
    }
    final plantName = plantData['name'] ?? '';
    
    final tasksQuery = await _db.collection('users').doc(userUid).collection('tasks')
        .where('plantName', isEqualTo: plantName).get();
        
    final tasksDocs = tasksQuery.docs.toList();
    tasksDocs.sort((a, b) {
      final aDate = a.data()['dueDate'] as Timestamp?;
      final bDate = b.data()['dueDate'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    final top10Tasks = tasksDocs.take(10).toList();
        
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (top10Tasks.isNotEmpty) {
      final waterTasks = top10Tasks.where((d) => d.data()['taskType'] == 'Watering').toList();
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
      final last3 = top10Tasks.take(3).toList();
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
        .where('type', isEqualTo: 'temperature').get();
        
    var tempDocs = tempQuery.docs.toList();
    tempDocs.sort((a, b) {
      final aTs = a.data()['timestamp'] as Timestamp?;
      final bTs = b.data()['timestamp'] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });
        
    if (tempDocs.isNotEmpty) {
      final temp = (tempDocs.first.data()['value'] as num?)?.toDouble() ?? 20.0;
      if (temp < 15 || temp > 28) { score -= 5; }
    }
    
    final humQuery = await _db.collection('users').doc(userUid).collection('zones').doc(zoneUid).collection('readings')
        .where('type', isEqualTo: 'humidity').get();
        
    var humDocs = humQuery.docs.toList();
    humDocs.sort((a, b) {
      final aTs = a.data()['timestamp'] as Timestamp?;
      final bTs = b.data()['timestamp'] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });
        
    if (humDocs.isNotEmpty) {
      final hum = (humDocs.first.data()['value'] as num?)?.toDouble() ?? 50.0;
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
          .get();

      var postDocs = postsQuery.docs.toList();
      postDocs.sort((a, b) {
        final aTs = a.data()['timestamp'] as Timestamp?;
        final bTs = b.data()['timestamp'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });
      final topPosts = postDocs.take(10).toList();

      for (var doc in topPosts) {
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
