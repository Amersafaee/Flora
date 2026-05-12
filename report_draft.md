# Flora App State Report Draft

### add_growth_entry_screen.dart
**Classes:** AddGrowthEntryScreen, _AddGrowthEntryScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - await _firestoreService.addGrowthEntry(widget.plantId, entry);
  - await FirestoreService().saveHealthAssessment(widget.plantId, assessment);
  - await FirestoreService().createTreatmentCase(tCase);
**Buttons/Actions:**
- onTap: () async { [Working]
- onPressed: () => Navigator.pop(context, true), [Working]
- child: ElevatedButton( [Working]
- IconButton( [Working]
- Not now [Working]
- onPressed: _isLoading ? null : _saveEntry, [Working]
- GestureDetector( [Working]
- onPressed: () => Navigator.pop(context), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context, false),
  - onPressed: () => Navigator.pop(context, true),
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### add_plant_screen.dart
**Classes:** AddPlantScreen, _AddPlantScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final docRef = FirebaseFirestore.instance.collection('dummy').doc();
  - await _firestoreService.addPlant(plant);
  - await _firestoreService.addTask(Task(
**Buttons/Actions:**
- onTap: () async { [Working]
- onPressed: () async { [Working]
- child: ElevatedButton( [Working]
- IconButton( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
- onPressed: _isLoading ? null : _savePlant, [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const FloraChatsListScreen()));
  - Navigator.pop(context); // close bottom sheet
  - Navigator.pop(context); // close add plant screen
  - Navigator.pop(context); // close sheet


### add_task_screen.dart
**Classes:** AddTaskScreen, _AddTaskScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final taskId = widget.task?.id ?? FirebaseFirestore.instance.collection('dummy').doc().id;
  - final uid = _firestoreService.currentUserId;
  - final query = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants')
  - await _firestoreService.updateTask(task);
**Buttons/Actions:**
- onPressed: _isLoading ? null : _saveTask, [Working]
- Due Date [Working]
- return GestureDetector( [Working]
- child: ElevatedButton( [Working]
- IconButton( [Working]
- onTap: () => _selectDate(context), [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
**Navigation:**
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### all_plants_screen.dart
**Classes:** AllPlantsScreen
**Firestore Usage:**
  - stream: FirestoreService().getPlants(),
**Buttons/Actions:**
- leading: IconButton( [Working]
- return GestureDetector( [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));


### badges_screen.dart
**Classes:** BadgesScreen, _BadgesScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
**Buttons/Actions:**
- leading: IconButton( [Working]
- onPressed: () => Navigator.of(context).pop(), [Working]
**Navigation:**
  - onPressed: () => Navigator.of(context).pop(),


### batch_care_screen.dart
**Classes:** BatchCareScreen, _BatchCareScreenState
**Firestore Usage:**
  - final uid = FirestoreService().currentUserId;
  - await FirestoreService().markTaskCompleted(task.id);
  - await FirestoreService().addTask(Task(
**Buttons/Actions:**
- onTap: () => _handleSwipe(false), [Working]
- leading: IconButton( [Working]
- child: GestureDetector( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.pop(context);


### care_insights_screen.dart
**Classes:** CareInsightsScreen, _CareInsightsScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final snap = await FirebaseFirestore.instance
**Buttons/Actions:**
- leading: IconButton( [Working]
- onPressed: _isGeneratingPlan ? null : _generatePersonalizedPlan, [Working]
- onPressed: () => _showReasoningSheet(task['reasoning']), [Working]
- IconButton( [Working]
- onPressed: () => Navigator.pop(ctx), [Working]
- onPressed: () => Navigator.pop(context), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(ctx),
  - onPressed: () => Navigator.pop(context),


### care_plan_screen.dart
**Classes:** CarePlanScreen, _CarePlanScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final plantsStream = _firestoreService.getPlants();
  - stream: _firestoreService.getPlants(),
**Buttons/Actions:**
- Close [Working]
- ElevatedButton( [Working]
- onPressed: _isGenerating ? null : _regeneratePlan, [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),


### care_screen.dart
**Classes:** CareScreen, _CareScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final uid = _firestoreService.currentUserId;
  - final snap = await FirebaseFirestore.instance
  - await _firestoreService.markTaskCompleted(task.id);
  - final updatedSnap = await FirebaseFirestore.instance
**Buttons/Actions:**
- onTap: () async { [Working]
- onTap: _prevWeek, [Working]
- onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())), [Working]
- IconButton( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onTap: () { [Working]
- : GestureDetector( [Working]
**Navigation:**
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
  - Navigator.push(context, MaterialPageRoute(
  - onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));
  - onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BatchCareScreen(tasks: pendingTasks))),


### chat_screen.dart
**Classes:** ChatScreen, _ChatScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _firestore = FirebaseFirestore.instance;
**Buttons/Actions:**
- GestureDetector( [Working]
- leading: IconButton( [Working]
- onPressed: () => Navigator.of(context).pop(), [Working]
- onTap: _sendMessage, [Working]
**Navigation:**
  - onPressed: () => Navigator.of(context).pop(),


### climate_screen.dart
**Classes:** ClimateScreen, _ClimateScreenState, RealChartPainter
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final ref = FirebaseFirestore.instance
  - await FirebaseFirestore.instance
**Buttons/Actions:**
- onPressed: () => Navigator.of(context).pop(), [Working]
- onPressed: onSave, [Working]
- onPressed: () { [Working]
- IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.of(context).pop(),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));


### collection_personality_screen.dart
**Classes:** CollectionPersonalityScreen, _CollectionPersonalityScreenState
**Firestore Usage:**
  - final uid = FirestoreService().currentUserId;
  - final stream = FirestoreService().getPlants();
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
- onPressed: _sharePersonality, [Working]
- child: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),


### community_screen.dart
**Classes:** CommunityScreen, _CommunityScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final qs = await FirebaseFirestore.instance.collection('challenges').limit(1).get();
  - await FirebaseFirestore.instance.collection('challenges').add({
  - await FirestoreService().checkAndAnswerUnansweredQuestions();
  - stream: FirebaseFirestore.instance.collection('challenges').where('isActive', isEqualTo: true).limit(1).snapshots(),
**Buttons/Actions:**
- Ask a Question [Working]
- child: ElevatedButton( [Working]
- Show your Plant [Working]
- child: GestureDetector( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- Share a Tip [Working]
- onTap: () { [Working]
**Navigation:**
  - Navigator.pop(context);
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'Tips')));
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'Questions')));
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'Showcase')));
  - Navigator.push(


### create_listing_screen.dart
**Classes:** CreateListingScreen, _CreateListingScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - await FirebaseFirestore.instance.collection('swap_listings').add({
**Buttons/Actions:**
- Save [Working]
**Navigation:**
  - Navigator.pop(context);


### create_post_screen.dart
**Classes:** CreatePostScreen, _CreatePostScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final _firestore = FirebaseFirestore.instance;
  - final postDoc = await _firestore.collection('posts').add({
**Buttons/Actions:**
- leading: IconButton( [Working]
- Save [Working]
- Add Photo [Working]
- onPressed: () => setState(() => _image = null), [Working]
- IconButton( [Working]
- onPressed: () => Navigator.pop(context), [Working]
**Navigation:**
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### edit_plant_screen.dart
**Classes:** EditPlantScreen, _EditPlantScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(widget.plantId).get();
  - await FirestoreService().updatePlant(updatedPlant);
**Buttons/Actions:**
- Save Changes [Working]
**Navigation:**
  - Navigator.pop(context);


### edit_profile_screen.dart
**Classes:** EditProfileScreen, _EditProfileScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
**Buttons/Actions:**
- Edit Profile [Working]
- Save [Working]
- Change Photo [Working]
- leading: IconButton( [Working]
**Navigation:**
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### family_tree_screen.dart
**Classes:** FamilyTreeScreen, _FamilyTreeScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  - await _firestore.collection('lineage').add({
  - stream: _firestore.collection('lineage').snapshots(),
**Buttons/Actions:**
- onPressed: _showRecordParentDialog, [Working]
- onPressed: () async { [Working]
- leading: IconButton( [Working]
- child: ElevatedButton( [Working]
- Cancel [Working]
- onPressed: () => Navigator.of(context).pop(), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - if (context.mounted) Navigator.pop(context);
  - onPressed: () => Navigator.of(context).pop(),


### flora_chats_list_screen.dart
**Classes:** FloraChatsListScreen
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - FirebaseFirestore.instance
  - final batch = FirebaseFirestore.instance.batch();
**Buttons/Actions:**
- Cancel [Working]
- child: GestureDetector( [Working]
- onPressed: () => _createNewConversation(context), [Working]
- onTap: () { [Working]
- Delete [Working]
**Navigation:**
  - Navigator.push(
  - onPressed: () => Navigator.pop(ctx, false),
  - onPressed: () => Navigator.pop(ctx, true),


### flora_screen.dart
**Classes:** ChatMessage, FloraScreen, _FloraScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore? firestore;
  - late final FirebaseFirestore _firestore = widget.firestore ?? FirebaseFirestore.instance;
  - final batch = _firestore.batch();
**Buttons/Actions:**
- Take Photo [Working]
- child: ElevatedButton( [Working]
- Choose from Gallery [Working]
- IconButton( [Working]
- About Flora [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
- Clear Chat History [Working]
**Navigation:**
  - onTap: () => Navigator.pop(ctx, ImageSource.camera),
  - onTap: () => Navigator.pop(ctx, ImageSource.gallery),
  - onPressed: () => Navigator.pop(context),
  - Navigator.pop(context);


### global_search_screen.dart
**Classes:** GlobalSearchScreen, _GlobalSearchScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final speciesTask = FirebaseFirestore.instance.collection('species').get();
  - final postsTask = FirebaseFirestore.instance.collection('posts').get();
  - plantsTask = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('plants').get();
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
- leading: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(


### home_screen.dart
**Classes:** HomeScreen, _HomeScreenState, ShimmerBox
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final uid = FirestoreService().currentUserId;
  - await FirestoreService().computeAllHealthScores(uid);
  - stream: userId != null ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots() : const Stream.empty(),
  - FirebaseFirestore.instance.collection('users').doc(userId).collection('plants').get(),
**Buttons/Actions:**
- onTap: onTap, [Working]
- card = GestureDetector( [Working]
- return GestureDetector( [Working]
- onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareScreen())), [Working]
- IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }), [Working]
- onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: urgentPlant!.id))), [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onTap: () { [Working]
**Navigation:**
  - Navigator.push(
  - IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }),
  - onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareScreen())),
  - onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: urgentPlant!.id))),
  - onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsDashboardScreen())),


### identify_result_screen.dart
**Classes:** IdentifyResultScreen, _IdentifyResultScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final db = FirebaseFirestore.instance;
  - future: FirebaseFirestore.instance.collection('species').get(),
**Buttons/Actions:**
- onPressed: _isOpeningFlora ? null : _openFloraWithPlantContext, [Working]
- IconButton( [Working]
- child: GestureDetector( [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
**Navigation:**
  - Navigator.push(
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: match!)));


### identify_screen.dart
**Classes:** IdentifyScreen, _IdentifyScreenState
**Buttons/Actions:**
- From Gallery [Working]
- onTap: onTap, [Working]
- Take Photo [Working]
- return GestureDetector( [Working]
- onTap: _clearImage, [Working]
- onPressed: _isAnalyzing ? null : _analyzeImage, [Working]
- child: GestureDetector( [Working]
- return ElevatedButton( [Working]
**Navigation:**
  - Navigator.push(


### light_meter_screen.dart
**Classes:** LightMeterScreen, _LightMeterScreenState
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- child: ElevatedButton( [Working]
- onPressed: _isMeasuring ? _stopMeasuring : _startMeasuring, [Working]
- IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),


### listing_detail_screen.dart
**Classes:** ListingDetailScreen, _ListingDetailScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final convRef = FirebaseFirestore.instance.collection('swap_conversations').doc(convId);
  - await FirebaseFirestore.instance
  - await FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).update({
  - stream: FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).snapshots(),
**Buttons/Actions:**
- onPressed: () async { [Working]
- leading: IconButton( [Working]
- Cancel [Working]
- onPressed: _deleteListing, [Working]
- IconButton( [Working]
- onPressed: () => _editListing(currentData), [Working]
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
- Are you sure you want to remove this listing from the swap market? [Working]
**Navigation:**
  - Navigator.push(context, MaterialPageRoute(builder: (_) => SwapChatScreen(conversationId: convId)));
  - TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
  - onPressed: () => Navigator.pop(ctx, true),
  - if (mounted) Navigator.pop(context);
  - if (ctx.mounted) Navigator.pop(ctx);


### login_screen.dart
**Classes:** LoginScreen, _LoginScreenState
**Buttons/Actions:**
- onPressed: _isLoading ? null : _login, [Working]
- onPressed: _isLoading [Working]
- child: ElevatedButton( [Working]
- onTap: _isLoading [Working]
- GestureDetector( [Working]
- suffixIcon: IconButton( [Working]
**Navigation:**
  - Navigator.pushReplacement(
  - Navigator.push(


### memorial_garden_screen.dart
**Classes:** MemorialGardenScreen
**Firestore Usage:**
  - stream: FirestoreService().getPlants(),


### notification_settings_screen.dart
**Classes:** NotificationSettingsScreen, _NotificationSettingsScreenState
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- leading: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),


### onboarding_screen.dart
**Classes:** OnboardingScreen, _OnboardingScreenState
**Buttons/Actions:**
- child: ElevatedButton( [Working]
- onPressed: _currentPage == 3 ? _completeOnboarding : _nextPage, [Working]
**Navigation:**
  - Navigator.pushReplacement(


### plant_detail_screen.dart
**Classes:** PlantDetailScreen
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - ? FirebaseFirestore.instance
  - await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).update({
  - await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).delete();
  - stream: FirebaseFirestore.instance
**Buttons/Actions:**
- Mark as Unhealthy [Working]
- Edit Plant [Working]
- IconButton( [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.of(context).pop(), [Working]
- View Plant Passport [Working]
**Navigation:**
  - Navigator.push(
  - onPressed: () => Navigator.of(context).pop(),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => ShareableCardScreen(plant: plantObj)));
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### plant_passport_screen.dart
**Classes:** PlantPassportScreen, _PlantPassportScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final db = FirebaseFirestore.instance;
**Buttons/Actions:**
- leading: IconButton( [Working]
- child: ElevatedButton( [Working]
- onPressed: _sharePassport, [Working]
- Share [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(


### post_comments_screen.dart
**Classes:** PostCommentsScreen, _PostCommentsScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
  - await FirebaseFirestore.instance.collection('users').doc(postAuthorUid).collection('notifications').add({
  - future: FirebaseFirestore.instance
  - await FirestoreService().addGrowthEntry(
**Buttons/Actions:**
- onTap: () async { [Working]
- onPressed: _hasText ? _sendComment : null, [Working]
- return GestureDetector( [Working]
- GestureDetector( [Working]
- : IconButton( [Working]
**Navigation:**
  - Navigator.pop(context);


### profile_screen.dart
**Classes:** ProfileScreen, _ProfileScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  - await FirebaseFirestore.instance
  - future: _firestoreService.getTotalPlantsCount(),
  - future: _firestoreService.getCompletedTasksCount(),
**Buttons/Actions:**
- Take a Photo [Working]
- Choose from Gallery [Working]
- IconButton( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
- onTap: _isUploadingPhoto ? null : _uploadProfilePhoto, [Working]
**Navigation:**
  - onTap: () => Navigator.pop(ctx, ImageSource.camera),
  - onTap: () => Navigator.pop(ctx, ImageSource.gallery),
  - Navigator.of(context).pushAndRemoveUntil(
  - onPressed: () => Navigator.pop(context),
  - Navigator.of(context).push(


### shareable_card_screen.dart
**Classes:** ShareableCardScreen, _ShareableCardScreenState
**Firestore Usage:**
  - final uid = FirestoreService().currentUserId;
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
- onPressed: _shareCard, [Working]
- leading: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),


### signup_screen.dart
**Classes:** SignupScreen, _SignupScreenState
**Buttons/Actions:**
- child: ElevatedButton( [Working]
- onPressed: () { [Working]
- GestureDetector( [Working]
- onPressed: _isLoading ? null : _signup, [Working]
- onTap: () { [Working]
- suffixIcon: IconButton( [Working]
**Navigation:**
  - Navigator.pop(context); // Go back after successful signup and let Auth stream handle routing
  - Navigator.pop(context);


### swap_chat_screen.dart
**Classes:** SwapChatScreen, _SwapChatScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final messagesRef = FirebaseFirestore.instance
  - await FirebaseFirestore.instance
  - stream: FirebaseFirestore.instance
**Buttons/Actions:**
- onPressed: _sendMessage, [Working]
- IconButton( [Working]


### swap_conversations_screen.dart
**Classes:** SwapConversationsScreen, _SwapConversationsScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final db = FirebaseFirestore.instance;
**Buttons/Actions:**
- onTap: () { [Working]
**Navigation:**
  - Navigator.push(


### swap_market_screen.dart
**Classes:** SwapMarketScreen, _SwapMarketScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - stream: FirebaseFirestore.instance
**Buttons/Actions:**
- IconButton( [Working]
- child: GestureDetector( [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.pop(context);
  - Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(doc: docs[index])));
  - Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapConversationsScreen()));
  - Navigator.push(


### treatment_case_screen.dart
**Classes:** TreatmentCaseScreen, _TreatmentCaseScreenState
**Firestore Usage:**
  - await _firestoreService.updateTreatmentCaseProgress(
  - await _firestoreService.resolveTreatmentCase(tCase.id);
  - stream: _firestoreService.getTreatmentCases(widget.plantId),
**Buttons/Actions:**
- onPressed: () async { [Working]
- leading: IconButton( [Working]
- Check Progress [Working]
- onPressed: () => Navigator.pop(context), [Working]
- ElevatedButton( [Working]
**Navigation:**
  - if (mounted) Navigator.pop(context);
  - Navigator.pop(context); // Close loading dialog
  - if (mounted) Navigator.pop(context); // Close loading dialog
  - Navigator.pop(context);
  - onPressed: () => Navigator.pop(context),


### vacation_mode_screen.dart
**Classes:** VacationModeScreen, _VacationModeScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final uid = _firestoreService.currentUserId;
  - final snapshot = await FirebaseFirestore.instance
  - final tasksSnapshot = await FirebaseFirestore.instance
**Buttons/Actions:**
- leading: IconButton( [Working]
- onTap: () => _selectDate(context, true), [Working]
- child: ElevatedButton( [Working]
- GestureDetector( [Working]
- onPressed: () => Navigator.of(context).pop(), [Working]
- Close [Working]
- onPressed: _generateCarePlan, [Working]
- onTap: () => _selectDate(context, false), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - onPressed: () => Navigator.of(context).pop(),


### vitals_dashboard_screen.dart
**Classes:** VitalsDashboardScreen, _VitalsDashboardScreenState, HealthRingPainter
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').snapshots(),
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- onTap: () { [Working]
- leading: IconButton( [Working]
- return GestureDetector( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(


### weekly_report_screen.dart
**Classes:** WeeklyReportScreen
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- child: ElevatedButton( [Working]
- onPressed: () async { [Working]
- child: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - if (context.mounted) Navigator.pop(context);


### wiki_plant_detail_screen.dart
**Classes:** WikiPlantDetailScreen
**Buttons/Actions:**
- onPressed: () => Navigator.pop(context), [Working]
- child: ElevatedButton( [Working]
- onPressed: () { [Working]
- child: IconButton( [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(context),
  - Navigator.push(
  - Navigator.of(context).popUntil((route) => route.isFirst);
  - // it's a tab, let's see if we can use Navigator.popUntil route.settings.name == '/'
  - // We will use Navigator.popUntil then try to push FloraScreen or maybe the user just means "go to Flora screen".


### wiki_screen.dart
**Classes:** WikiScreen, _WikiScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - FirestoreService().seedSpeciesData();
  - FirestoreService().seedBlogData();
  - stream: FirebaseFirestore.instance.collection('species').snapshots(),
  - stream: FirebaseFirestore.instance.collection('blogs').orderBy('createdAt', descending: true).snapshots(),
**Buttons/Actions:**
- onTap: () async { [Working]
- return GestureDetector( [Working]
- child: GestureDetector( [Working]
- GestureDetector( [Working]
- IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }), [Working]
- onTap: () { [Working]
**Navigation:**
  - Navigator.push(
  - IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }),
  - Navigator.push(context, MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: plantData)));


### zones_screen.dart
**Classes:** ZonesScreen, _ZonesScreenState
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final _firestore = FirebaseFirestore.instance;
  - await FirebaseFirestore.instance
**Buttons/Actions:**
- onPressed: () async { [Working]
- leading: IconButton( [Working]
- Cancel [Working]
- IconButton( [Working]
- onPressed: () { [Working]
- onPressed: () => Navigator.pop(context), [Working]
- onPressed: () => _editZone(id, name), [Working]
**Navigation:**
  - onPressed: () => Navigator.pop(dialogCtx),
  - Navigator.pop(dialogCtx);
  - onPressed: () => Navigator.pop(context),
  - Navigator.pop(context);


### auth_service.dart
**Classes:** AuthService


### badges_service.dart
**Classes:** BadgesService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db = FirebaseFirestore.instance;
  - final int plantsCount = await _firestoreService.getTotalPlantsCount();
  - final int tasksCount = await _firestoreService.getCompletedTasksCount();
  - final int journalsCount = await _firestoreService.getTotalJournalEntriesCount();


### care_intelligence_service.dart
**Classes:** CareIntelligenceService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db = FirebaseFirestore.instance;


### demo_config_service.dart
**Classes:** DemoConfigService


### firestore_service.dart
**Classes:** FirestoreService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db = FirebaseFirestore.instance;


### flora_context_service.dart
**Classes:** FloraContextService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db;
  - FloraContextService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;


### gemini_service.dart
**Classes:** GeminiService


### milestone_service.dart
**Classes:** MilestoneService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db = FirebaseFirestore.instance;


### notification_service.dart
**Classes:** NotificationService


### storage_service.dart
**Classes:** StorageService


### theme_service.dart
**Classes:** ThemeService


### weekly_report_service.dart
**Classes:** WeeklyReportService
**Firestore Usage:**
  - import 'package:cloud_firestore/cloud_firestore.dart';
  - final FirebaseFirestore _db = FirebaseFirestore.instance;


