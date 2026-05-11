# Flora App Complete Audit

## Screen Files Inventory
- add_growth_entry_screen.dart
- add_plant_screen.dart
- add_task_screen.dart
- all_plants_screen.dart
- badges_screen.dart
- batch_care_screen.dart
- care_insights_screen.dart
- care_plan_screen.dart
- care_screen.dart
- chat_screen.dart
- climate_screen.dart
- collection_personality_screen.dart
- community_screen.dart
- create_listing_screen.dart
- create_post_screen.dart
- edit_plant_screen.dart
- edit_profile_screen.dart
- family_tree_screen.dart
- flora_chats_list_screen.dart
- flora_screen.dart
- global_search_screen.dart
- home_screen.dart
- identify_result_screen.dart
- identify_screen.dart
- light_meter_screen.dart
- listing_detail_screen.dart
- login_screen.dart
- memorial_garden_screen.dart
- notification_settings_screen.dart
- plant_detail_screen.dart
- plant_passport_screen.dart
- post_comments_screen.dart
- profile_screen.dart
- shareable_card_screen.dart
- signup_screen.dart
- swap_market_screen.dart
- treatment_case_screen.dart
- vacation_mode_screen.dart
- vitals_dashboard_screen.dart
- weekly_report_screen.dart
- wiki_plant_detail_screen.dart
- wiki_screen.dart
- zones_screen.dart

## Service Files Inventory
- auth_service.dart
- badges_service.dart
- care_intelligence_service.dart
- demo_config_service.dart
- firestore_service.dart
- flora_context_service.dart
- gemini_service.dart
- milestone_service.dart
- notification_service.dart
- storage_service.dart
- theme_service.dart
- weekly_report_service.dart

---

### Screen name: Add Growth Entry Screen
**Purpose:** Manages add growth entry screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () async {                   final picked = await _picker.pi... (working)
- ElevatedButton: _isLoading... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Add Plant Screen
**Purpose:** Manages add plant screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () async {                   final picked = await _picker.pi... (working)
- ElevatedButton: _isLoading... (working)
**Every data connection:** Reads/Writes to dummy
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Add Task Screen
**Purpose:** Manages add task screen
**Every button and what it does:**
- IconButton ('Plant Name'): () {                         setState(() {                  ... (working)
- ElevatedButton: _isLoading... (working)
- ElevatedButton: () {         setState(() {           _selectedTaskType = lab... (working)
- GestureDetector: () {         setState(() {           _repeatType = label;   ... (working)
**Every data connection:** Reads/Writes to dummy
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: All Plants Screen
**Purpose:** Manages all plants screen
**Every button and what it does:**
- IconButton ('Not logged in'): () {                         Navigator.push(                ... (working)
- FloatingActionButton (Icon: add): () {           Navigator.push(context, MaterialPageRoute(bui... (working)
**Every data connection:** Reads/Writes to plants, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Badges Screen
**Purpose:** Manages badges screen
**Every button and what it does:**
- No standard buttons detected or handled via other widgets
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Batch Care Screen
**Purpose:** Manages batch care screen
**Every button and what it does:**
- No standard buttons detected or handled via other widgets
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Care Insights Screen
**Purpose:** Manages care insights screen
**Every button and what it does:**
- IconButton ('Failed to generate plan. Please try again.'): _isGeneratingPlan... (working)
**Every data connection:** Reads/Writes to plants, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Care Plan Screen
**Purpose:** Manages care plan screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () {               // ignore: deprecated_member_use         ... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Care Screen
**Purpose:** Manages care screen
**Every button and what it does:**
- GestureDetector (Icon: check_circle): () async {                                       await _fire... (working)
- FloatingActionButton (Icon: add): () {                 Navigator.push(context, MaterialPageRou... (working)
- GestureDetector (Icon: person): () {                       Navigator.push(context, MaterialP... (working)
- IconButton (Icon: search): _prevWeek... (working)
- GestureDetector: _nextWeek... (working)
- GestureDetector ('Something went wrong'): onTap... (working)
- GestureDetector ('Done'): () async {               if (!task.isCompleted) {           ... (working)
**Every data connection:** Reads/Writes to plants, tasks, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Chat Screen
**Purpose:** Manages chat screen
**Every button and what it does:**
- IconButton ('Coming soon'): () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(con... (coming soon)
- GestureDetector: _sendMessage... (working)
**Every data connection:** Reads/Writes to messages, conversations
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Climate Screen
**Purpose:** Manages climate screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () {                         Navigator.push(context, Materia... (working)
- IconButton (Icon: save): onSave... (working)
**Every data connection:** Reads/Writes to zones, readings, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Collection Personality Screen
**Purpose:** Manages collection personality screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): _sharePersonality... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** no/partial (missing Theme usage)

### Screen name: Community Screen
**Purpose:** Manages community screen
**Every button and what it does:**
- FloatingActionButton ('Create Post'): () {           showModalBottomSheet(             context: co... (working)
- GestureDetector (Icon: person): () {                         Navigator.push(                ... (working)
- GestureDetector: () {                     Navigator.push(                    ... (working)
- ElevatedButton: () {                           Navigator.push(              ... (working)
- ElevatedButton: () {                           Navigator.push(              ... (working)
- OutlinedButton ('Failed to load posts'): () {         Navigator.push(           context,           Ma... (working)
- IconButton ('Report Post'): () {                   showModalBottomSheet(                ... (coming soon)
- TextButton ('Are you sure you want to delete this post?'): () async {                                           await F... (working)
- IconButton: () async {                           if (currentUserId == nu... (working)
- IconButton ('$commentsCount'): () {                       Navigator.push(                  ... (working)
- IconButton ('$commentsCount'): () {                   ScaffoldMessenger.of(context).showSna... (coming soon)
**Every data connection:** Reads/Writes to posts, likes
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Create Listing Screen
**Purpose:** Manages create listing screen
**Every button and what it does:**
- TextButton ('Save'): _saveListing... (working)
**Every data connection:** Reads/Writes to swap_listings
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Create Post Screen
**Purpose:** Manages create post screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): _savePost... (working)
- IconButton ('Add Photo'): _pickImage... (working)
**Every data connection:** Reads/Writes to posts
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Edit Plant Screen
**Purpose:** Manages edit plant screen
**Every button and what it does:**
- TextButton ('Save Changes'): _isFetching... (working)
**Every data connection:** Reads/Writes to plants, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Edit Profile Screen
**Purpose:** Manages edit profile screen
**Every button and what it does:**
- IconButton ('Edit Profile'): _saveProfile... (working)
- TextButton: _isUploading... (working)
**Every data connection:** Reads/Writes to users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Family Tree Screen
**Purpose:** Manages family tree screen
**Every button and what it does:**
- TextButton ('Cancel'): () async {                 final name = parentNameController... (working)
- ElevatedButton ('Save'): () async {                 final name = childNameController.... (working)
- ElevatedButton ('Save'): _showRecordParentDialog... (working)
- OutlinedButton: _showAddPropagationDialog... (working)
**Every data connection:** Reads/Writes to lineage
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Flora Chats List Screen
**Purpose:** Manages flora chats list screen
**Every button and what it does:**
- TextButton ('Delete Conversation'): () {                                   Navigator.push(      ... (working)
**Every data connection:** Reads/Writes to messages, flora_chats, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Flora Screen
**Purpose:** Manages flora screen
**Every button and what it does:**
- IconButton ('Clear Chat History'): () {                       showModalBottomSheet(            ... (working)
- GestureDetector: _pickImage... (working)
- GestureDetector: _hasText... (working)
- GestureDetector: () {         _textController.text = text;         _hasText =... (working)
**Every data connection:** Reads/Writes to messages, flora_chats, users
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Global Search Screen
**Purpose:** Manages global search screen
**Every button and what it does:**
- IconButton ('Coming soon'): () {         ScaffoldMessenger.of(context).showSnackBar(    ... (coming soon)
**Every data connection:** Reads/Writes to posts, plants, users, species
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Home Screen
**Purpose:** Manages home screen
**Every button and what it does:**
- FloatingActionButton (Icon: add): () {           Navigator.push(             context,         ... (working)
- FloatingActionButton (Icon: add): () {                       Navigator.push(                  ... (working)
- IconButton (Icon: search): () { Navigator.push(context, MaterialPageRoute(builder: (_) ... (working)
- GestureDetector: () {                             Navigator.push(context, Mat... (working)
- GestureDetector: () {                             Navigator.push(context, Mat... (working)
- IconButton: () {                                   if (!task.isCompleted... (working)
- GestureDetector: () {                   Navigator.push(                     c... (working)
- TextButton ('Memorial Garden'): () {                               Navigator.push(context, M... (working)
- GestureDetector: () {                               Navigator.push(          ... (working)
- TextButton ('Memorial Garden'): () {                           Navigator.push(context, Mater... (working)
- GestureDetector: () {                             Navigator.push(            ... (working)
- GestureDetector: () {                             Navigator.push(            ... (working)
**Every data connection:** Reads/Writes to posts, species
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Identify Result Screen
**Purpose:** Manages identify result screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () {                           Navigator.push(              ... (working)
- ElevatedButton (Icon: add_circle_outline): _isOpeningFlora... (working)
**Every data connection:** Reads/Writes to messages, flora_chats, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** no/partial (missing Theme usage)

### Screen name: Identify Screen
**Purpose:** Manages identify screen
**Every button and what it does:**
- GestureDetector: onTap... (working)
- GestureDetector: _clearImage... (working)
- ElevatedButton: _isAnalyzing... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** no/partial (missing Theme usage)

### Screen name: Light Meter Screen
**Purpose:** Manages light meter screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): _isMeasuring... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Listing Detail Screen
**Purpose:** Manages listing detail screen
**Every button and what it does:**
- TextButton ('Delete Listing'): _deleteListing... (working)
- ElevatedButton: _messageSent... (working)
**Every data connection:** Reads/Writes to interests, swap_listings
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Login Screen
**Purpose:** Manages login screen
**Every button and what it does:**
- IconButton: _isLoading... (working)
- ElevatedButton: _isLoading... (working)
- ElevatedButton: _isLoading... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Memorial Garden Screen
**Purpose:** Manages memorial garden screen
**Every button and what it does:**
- No standard buttons detected or handled via other widgets
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Notification Settings Screen
**Purpose:** Manages notification settings screen
**Every button and what it does:**
- No standard buttons detected or handled via other widgets
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Plant Detail Screen
**Purpose:** Manages plant detail screen
**Every button and what it does:**
- FloatingActionButton (Icon: add): () {           Navigator.push(             context,         ... (working)
- IconButton (Icon: arrow_back): () {                         final plantMap = Map<String, dy... (working)
- IconButton ('Edit Plant'): () {                         showModalBottomSheet(          ... (working)
- TextButton ('This action cannot be undone.'): () async {                                                 f... (working)
- InkWell: () {                         Navigator.push(                ... (working)
- OutlinedButton: () {                       Navigator.of(context).push(      ... (working)
- OutlinedButton (Icon: account_tree_outlined): () {                       _showTimeLapse(context, plantId);... (working)
- ElevatedButton ('Mark $plantName as Deceased'): () {                         Navigator.pop(context);        ... (working)
**Every data connection:** Reads/Writes to growth, plants, tasks, users
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Plant Passport Screen
**Purpose:** Manages plant passport screen
**Every button and what it does:**
- TextButton ('Share'): _sharePassport... (working)
- ElevatedButton: () {                   Navigator.push(                     c... (working)
- ElevatedButton ('List on Swap Market'): _sharePassport... (working)
**Every data connection:** Reads/Writes to growth, plants, users, treatment_cases, tasks
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Post Comments Screen
**Purpose:** Manages post comments screen
**Every button and what it does:**
- GestureDetector: () async {                                           final c... (working)
- IconButton (Icon: send): _hasText... (working)
**Every data connection:** Reads/Writes to posts, comments
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Profile Screen
**Purpose:** Manages profile screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): _isUploadingPhoto... (working)
- OutlinedButton: () {                         Navigator.of(context).push(    ... (broken/empty)
- OutlinedButton ('Edit Profile'): () {                   Navigator.of(context).push(          ... (working)
- OutlinedButton: _handleSignOut... (working)
- OutlinedButton: onTap... (working)
**Every data connection:** Reads/Writes to users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Shareable Card Screen
**Purpose:** Manages shareable card screen
**Every button and what it does:**
- ElevatedButton ('Close'): _shareCard... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** no/partial (missing Theme usage)

### Screen name: Signup Screen
**Purpose:** Manages signup screen
**Every button and what it does:**
- IconButton: () {                       setState(() {                    ... (working)
- ElevatedButton: _isLoading... (working)
- ElevatedButton: () {                       Navigator.pop(context);          ... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Swap Market Screen
**Purpose:** Manages swap market screen
**Every button and what it does:**
- IconButton ('Coming soon'): () {                         ScaffoldMessenger.of(context).s... (coming soon)
- FloatingActionButton ('List Your Plant'): () {           Navigator.push(             context,         ... (working)
- GestureDetector: () {           setState(() {             _selectedFilter = l... (working)
- GestureDetector: () {           Navigator.push(             context,         ... (working)
**Every data connection:** Reads/Writes to swap_listings
**Known bugs or issues:**
- Contains 'Coming soon' placeholders
**Missing features that were planned but not implemented:** See bugs/Coming soon
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Treatment Case Screen
**Purpose:** Manages treatment case screen
**Every button and what it does:**
- ElevatedButton: () async {                   Navigator.pop(context);        ... (working)
- OutlinedButton: () async {                   Navigator.pop(context);        ... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Vacation Mode Screen
**Purpose:** Manages vacation mode screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): _generateCarePlan... (working)
**Every data connection:** Reads/Writes to plants, tasks, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Vitals Dashboard Screen
**Purpose:** Manages vitals dashboard screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () {                           Navigator.push(              ... (working)
**Every data connection:** Reads/Writes to plants, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Weekly Report Screen
**Purpose:** Manages weekly report screen
**Every button and what it does:**
- ElevatedButton: () async {                     await WeeklyReportService().m... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** no/partial (missing Theme usage)

### Screen name: Wiki Plant Detail Screen
**Purpose:** Manages wiki plant detail screen
**Every button and what it does:**
- IconButton (Icon: arrow_back): () {                         Navigator.push(                ... (working)
- ElevatedButton: () {                         // Pop back to main navigation ... (working)
**Every data connection:** Reads/Writes to None direct (may use services)
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Wiki Screen
**Purpose:** Manages wiki screen
**Every button and what it does:**
- GestureDetector (Icon: person): () {                         Navigator.push(                ... (working)
- IconButton (Icon: search): () { Navigator.push(context, MaterialPageRoute(builder: (_) ... (working)
- GestureDetector (Icon: check): () {           setState(() {             _selectedFilter = l... (working)
- GestureDetector: () {         Navigator.push(context, MaterialPageRoute(build... (working)
- GestureDetector: () async {                               final user = Fireba... (working)
**Every data connection:** Reads/Writes to bookmarks, users, species
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))

### Screen name: Zones Screen
**Purpose:** Manages zones screen
**Every button and what it does:**
- TextButton ('Edit Zone'): () async {               final newName = controller.text.tri... (working)
- TextButton ('Cancel'): () {                 _addZone(controller.text);             ... (working)
- IconButton ('Please log in'): _showAddZoneDialog... (working)
**Every data connection:** Reads/Writes to zones, users
**Known bugs or issues:**
- No explicit TODOs or placeholders found
**Missing features that were planned but not implemented:** None immediately apparent
**Dark mode support:** yes (uses Theme.of(context))


---

### Service name: Auth Service
**Purpose:** Service for auth service
**Methods that work:**
- signUpWithEmailAndPassword
- signInWithEmailAndPassword
- signOut
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Badges Service
**Purpose:** Service for badges service
**Methods that work:**
- checkAndAwardBadges
- getUserBadges
- getUserLevel
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- Potential unbounded get() query


### Service name: Care Intelligence Service
**Purpose:** Service for care intelligence service
**Methods that work:**
- generateWeeklyCarePlan
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Demo Config Service
**Purpose:** Service for demo config service
**Methods that work:**
- useMockData
- setMockData
- isFirstLoginDone
- setFirstLoginDone
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Firestore Service
**Purpose:** Service for firestore service
**Methods that work:**
- saveUserProfile
- getUserProfile
- addPlant
- getPlants
- deletePlant
- updatePlant
- addTask
- getTasksForToday
- updateTask
- deleteTask
- markTaskCompleted
- addGrowthEntry
- getGrowthEntries
- getTotalPlantsCount
- getCompletedTasksCount
- getTotalJournalEntriesCount
- seedSpeciesData
- seedSwapListings
- createTreatmentCase
- getTreatmentCases
- updateTreatmentCaseProgress
- resolveTreatmentCase
- computeAndSaveHealthScore
- computeAllHealthScores
- markPlantAsDeceased
- addFloraAnswer
- checkAndAnswerUnansweredQuestions
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Flora Context Service
**Purpose:** Service for flora context service
**Methods that work:**
- buildContext
- _fetchProfile
- _fetchPlants
- _fetchClimateReadings
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Gemini Service
**Purpose:** Service for gemini service
**Methods that work:**
- generatePersonalizedWeeklyPlan
- generateCommunityAnswer
- analyzeePlantImage
- mimeFor
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Milestone Service
**Purpose:** Service for milestone service
**Methods that work:**
- checkMilestones
- generateShareableCard
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- Potential unbounded get() query


### Service name: Notification Service
**Purpose:** Service for notification service
**Methods that work:**
- initialize
- cancelTaskNotification
- cancelAllNotifications
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Storage Service
**Purpose:** Service for storage service
**Methods that work:**
- _compressIfNeeded
- uploadPlantPhoto
- uploadGrowthPhoto
- uploadPostPhoto
- deletePhoto
- _showError
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Theme Service
**Purpose:** Service for theme service
**Methods that work:**
- saveThemeMode
- loadThemeMode
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis


### Service name: Weekly Report Service
**Purpose:** Service for weekly report service
**Methods that work:**
- generateWeeklyReport
- shouldShowWeeklyReport
- markWeeklyReportShown
**Methods that are empty or broken:**
- None empty or broken
**Any performance concerns:**
- No immediate major concerns detected by static analysis

