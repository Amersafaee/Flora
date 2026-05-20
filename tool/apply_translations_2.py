#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
"""
apply_translations_2.py
-----------------------
1. Adds all keys from arb_translations_2.json to lib/l10n/app_en.arb
   using the provided English values mapping.
2. Updates all 14 non-English ARB files with translations from
   arb_translations_2.json.
"""
import json
import os

LOCALES = ['es', 'fr', 'de', 'pt', 'ar', 'fa', 'ja', 'ko', 'it', 'nl', 'tr', 'pl', 'sv', 'hi']
L10N_DIR = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')
TRANSLATIONS_FILE = os.path.join(os.path.dirname(__file__), 'arb_translations_2.json')

# English values for all new keys
ENGLISH_VALUES = {
    "syncToCalendar": "Sync to Calendar",
    "historyTab": "History",
    "todaysTasks": "Today's Tasks",
    "noCareTasksYet": "No care tasks yet",
    "addPlantForCareSchedule": "Add a plant to get a care schedule built automatically by Flora",
    "addAPlant": "Add a Plant",
    "swipeThroughTasksFast": "Swipe through all tasks fast",
    "personalizedScheduleBasedOnHome": "Personalized schedule based on your home",
    "notSignedIn": "Not signed in.",
    "noCompletedTasksYet": "No completed tasks yet.",
    "tasksDoneThisWeek": "{count} tasks done this week",
    "syncingTasksToCalendar": "Syncing tasks to calendar...",
    "syncedTasksToCalendar": "Synced {count} tasks to your calendar \U0001f4c5",
    "noUpcomingTasksToSync": "No upcoming tasks to sync or calendar permission denied",
    "calendarSyncFailed": "Calendar sync failed. Please try again.",
    "rescheduleCare": "Reschedule {plantName}'s care?",
    "completedDaysLateReschedule": "You completed this {taskType} {days} days late. Do you want to schedule the next one from today, or keep the original schedule?",
    "keepSchedule": "Keep schedule",
    "fromToday": "From today",
    "roomClimate": "Room Climate",
    "addCaptionOrQuestion": "Add a caption or question... (optional)",
    "clearChatHistory": "Clear Chat History",
    "aboutFlora": "About Flora",
    "floraIsReviewingYourPlants": "Flora is reviewing your plants\u2026",
    "hiIAmFlora": "Hi, I'm Flora",
    "yourPersonalPlantCareAssistant": "Your personal plant care assistant",
    "howOftenWaterMonstera": "How often should I water my Monstera",
    "whyLeavesYellow": "Why are my plant leaves turning yellow",
    "plantsGoodForLowLight": "What plants are good for low light",
    "howToRepotPlant": "How do I repot a plant",
    "floraKnowsPlantsDesc": "Flora knows your entire plant collection and uses that knowledge to give you personalized advice.",
    "version100": "Version 1.0.0",
    "todayTimestamp": "Today, {time}",
    "askFloraAnythingAboutPlants": "Ask Flora anything about plants",
    "loadingWeather": "Loading weather...",
    "currentLocation": "Current Location",
    "yourConservatoryIsEmpty": "Your conservatory is empty",
    "addFirstPlantDescription": "Add your first plant and Flora will build a personalised care plan for it automatically",
    "addYourFirstPlantEmoji": "Add Your First Plant \U0001f331",
    "orIdentifyWithCamera": "Or identify a plant with your camera",
    "offlineShowingCachedData": "You are offline \u2014 showing cached data",
    "noTasksForToday": "No tasks for today.",
    "plantsLabel": "Plants",
    "assessAPlant": "Assess a plant",
    "avgHealth": "Avg Health",
    "identifyEmoji": "Identify \U0001f4f7",
    "careEmoji": "Care \U0001f5d3\ufe0f",
    "communityEmoji": "Community \U0001f331",
    "dailyCare": "Daily Care",
    "viewAll": "VIEW ALL",
    "fromTheCommunity": "From the Community",
    "noCommunityPostsYet": "No community posts yet.",
    "byAuthor": "by {author}",
    "learnSomethingNew": "Learn Something New",
    "plantGuidesLoading": "Plant guides loading\u2026",
    "thirstyOverdueByDays": "\U0001f4a7 {plant} is thirsty \u2014 watering overdue by {days} days",
    "needsUrgentAttention": "\U0001f6a8 {plant} needs urgent attention",
    "careTasksToday": "\U0001f4cb You have {count} care tasks today",
    "addFirstPlantToGetStarted": "\U0001f331 Add your first plant to get started",
    "allPlantsThrivingToday": "\U0001f33f All {count} plants are thriving today",
    "plantFallbackCategory": "Plant",
    "viewPlantPassport": "View Plant Passport",
    "markAsUnhealthy": "Mark as Unhealthy",
    "plantMarkedAsUnhealthy": "Plant marked as unhealthy",
    "markAsDeceased": "Mark as Deceased",
    "deletePlant": "Delete Plant",
    "deletePlantConfirm": "Delete Plant?",
    "thisActionCannotBeUndone": "This action cannot be undone.",
    "analyzeWithFloraToGetHealthScore": "Analyze with Flora to get health score",
    "vitals": "Vitals",
    "never": "Never",
    "noHistory": "No history",
    "lastLightReading": "Last Light Reading",
    "lastHealthAssessment": "LAST HEALTH ASSESSMENT",
    "newGrowthDetected": "New growth detected! \U0001f331",
    "issuesDetected": "Issues detected",
    "recommendations": "Recommendations",
    "healthCases": "Health Cases",
    "viewFamilyTree": "View Family Tree",
    "createTimeLapse": "Create Time-lapse",
    "watchPlantGrowOverTime": "Watch your plant grow over time",
    "listForSwapEmoji": "List for Swap \U0001f504",
    "upcomingTasks": "Upcoming Tasks",
    "noUpcomingTasks": "No upcoming tasks.",
    "careGuideFromWiki": "Care Guide from Wiki",
    "communityDiscussions": "Community Discussions",
    "seeAllDiscussions": "See all discussions",
    "growthHistory": "Growth History",
    "noGrowthHistoryYet": "No growth history yet.",
    "journalEntry": "JOURNAL ENTRY",
    "propagatedFrom": "\U0001f331 Propagated from {name}",
    "propagationsFromThisPlant": "\U0001fab4 {count} propagations from this plant",
    "myProfile": "My Profile",
    "changeProfilePhoto": "Change Profile Photo",
    "profilePhotoUpdated": "Profile photo updated!",
    "uploadFailed": "Upload failed: {error}",
    "plants": "Plants",
    "settingsHeader": "SETTINGS",
    "myBadgesAndLevel": "My Badges and Level",
    "myCity": "My City",
    "tapToSetYourCity": "Tap to set your city",
    "cityHintText": "e.g. London, Tokyo, New York",
    "citySetTo": "City set to {city} \U0001f324\ufe0f",
    "plantHistory": "Plant History",
    "myCollectionPersonality": "My Collection Personality",
    "aboutHeader": "ABOUT",
    "digitalConservatoryVersion": "Digital Conservatory v1.0.0",
    "sendFeedback": "Send Feedback",
    "markAllAsRead": "Mark all as read",
    "noNewNotifications": "No new notifications \U0001f33f",
    "welcomeToFlora": "Welcome to Flora",
    "joinFloraStartJourney": "Join Flora and start your plant journey.",
    "signInToYourCollection": "Sign in to your plant collection.",
    "yourPersonalPlantCompanion": "Your personal plant companion.",
    "emailAddress": "Email address",
    "fullNameLabel": "Full name",
    "confirmPassword": "Confirm password",
    "dontHaveAccountSignUp": "Don't have an account? Sign Up",
    "alreadyHaveAccountSignIn": "Already have an account? Sign In",
    "byAgreeingTermsPrivacy": "By continuing you agree to our Terms & Privacy Policy.",
    "pleaseEnterValidEmail": "Please enter a valid email address.",
    "pleaseEnterYourPassword": "Please enter your password.",
    "pleaseEnterYourName": "Please enter your name.",
    "passwordMinSixChars": "Password must be at least 6 characters.",
    "passwordsDoNotMatch": "Passwords do not match.",
    "connectionTimedOut": "Connection timed out. Check your internet and try again.",
    "welcomeToFloraSnackbar": "\U0001f331 Welcome to Flora! Your garden awaits.",
    "noInternetCheckNetwork": "No internet connection. Please check your network.",
    "emailLooksInvalid": "That email address looks invalid.",
    "noAccountFoundTryCreating": "No account found with this email. Try creating one!",
    "incorrectEmailOrPassword": "Incorrect email or password. Please try again.",
    "accountExistsWithEmail": "An account already exists with this email. Try signing in!",
    "passwordTooWeakSixChars": "Password is too weak. Use at least 6 characters.",
    "anErrorOccurredTryAgain": "An error occurred. Please try again.",
    "letsSetUpYourGarden": "Let's set up your garden",
    "whatShouldWeCallYou": "What should we call you?",
    "yourName": "Your name",
    "letsGo": "Let's go",
    "errorSavingProfile": "Error saving profile: {error}",
    "noPreviousChats": "No previous chats.",
    "deleteChatTitle": "Delete Chat?",
    "thisCannotBeUndone": "This cannot be undone.",
    "deleteAction": "Delete",
    "pleaseSignInFirst": "Please sign in first.",
    "hiImFlora": "Hi! I'm Flora",
    "floraChatIntro": "Your AI plant consultant. Ask me anything about your plants \u2014 or just say hello.",
    "askFloraAnythingEllipsis": "Ask Flora anything\u2026",
    "aiErrorPrefix": "AI Error: {error}",
    "settingsTitle": "Settings",
    "profileSection": "Profile",
    "plantLover": "Plant Lover",
    "editNameTitle": "Edit Name",
    "yourNameHint": "Your name",
    "requiredField": "Required",
    "saveAction": "Save",
    "notificationsSection": "Notifications",
    "dailyCareReminder": "Daily Care Reminder",
    "careTasksToggle": "Care Tasks",
    "floraChatMessages": "Flora Chat Messages",
    "swapMarketMessages": "Swap Market Messages",
    "appSection": "App",
    "myWishlist": "My Wishlist",
    "aboutSection": "About",
    "appVersion": "App Version",
    "deleteAccountTitle": "Delete Account?",
    "deleteAccountConfirmBody": "This will permanently delete your account, plants, chats, and swap listings. This cannot be undone.",
    "failedToDeleteAccount": "Failed to delete account: {error}",
    "myWishlistTitle": "My Wishlist",
    "wishlistIsEmpty": "Your wishlist is empty.",
    "explorePlantWiki": "Explore Plant Wiki",
    "whatAreYouOffering": "What are you offering?",
    "cuttingChip": "Cutting",
    "seedsChip": "Seeds",
    "wholePlantChip": "Whole Plant",
    "thisItemIsFree": "This item is free",
    "titleHintSwap": "e.g. Variegated Monstera Cutting",
    "descriptionHintSwap": "Describe the condition, size, or what you want in exchange...",
    "cityField": "City",
    "cityHintSwap": "e.g. Seattle, WA",
    "detectLocationTooltip": "Detect Location",
    "postListing": "Post Listing",
    "listingPostedSuccessfully": "Listing posted successfully! \U0001f331",
    "failedToPostListing": "Failed to post listing: {error}",
    "couldNotDetectLocation": "Could not detect location: {error}",
    "fillInAllRequiredFields": "Please fill in all required fields.",
    "listingNotFound": "Listing not found.",
    "freeLabel": "FREE",
    "completedBadge": "COMPLETED",
    "descriptionHeader": "Description",
    "listedByHeader": "Listed By",
    "messageAction": "Message",
    "markAsCompleted": "Mark as Completed",
    "listingMarkedCompleted": "Listing marked as completed \u2705",
    "deleteListingAction": "Delete Listing",
    "listingDeleted": "Listing deleted",
    "cuttingLabel": "Cutting",
    "seedsLabel": "Seeds",
    "wholePlantLabel": "Whole Plant",
    "tradePlantsNearby": "Trade plants with people nearby.",
    "findingNearbyPlants": "Finding nearby plants...",
    "showingListingsNear": "Showing listings near {city}",
    "nothingNearbyYet": "Nothing nearby yet",
    "beFirstToShareInArea": "Be the first to share in your area!",
    "listAPlant": "List a plant",
    "nearbyLabel": "Nearby",
    "yourListingBadge": "Your Listing",
    "freeFilter": "Free",
    "speciesNotFound": "Species not found.",
    "myCollection": "My Collection",
    "sunLabel": "Sun",
    "feedLabel": "Feed",
    "lightTab": "Light",
    "waterTab": "Water",
    "humidityTab": "Humidity",
    "soilTab": "Soil",
    "tempTab": "Temp",
    "propagateTab": "Propagate",
    "noInfo": "No info",
    "addToCollectionFab": "Add to collection",
    "findNextGreenCompanion": "Find your next green companion.",
    "searchByNameOrType": "Search by name or type\u2026",
    "noPlantsMatch": "No plants match",
    "tryDifferentFilterOrSearch": "Try a different filter or search term.",
    "wikiFilterTropical": "Tropical",
    "wikiFilterSucculent": "Succulent",
    "addGrowthEntry": "Add Growth Entry",
    "galleryAction": "Gallery",
    "noteField": "Note",
    "howIsYourPlantDoing": "How is your plant doing?",
    "heightCmOptional": "Height (cm) \u2014 optional",
    "addPhotoNoteOrHeight": "Add a photo, note, or height to save.",
    "growthEntryAdded": "\U0001f4dd Growth entry added!",
    "failedToSavePrefix": "Failed to save: {error}",
    "plantNotFound": "Plant not found",
    "plantNoLongerExists": "This plant no longer exists.",
    "editNicknameMenu": "Edit nickname",
    "deletePlantMenu": "Delete plant",
    "heightStat": "Height",
    "entriesStat": "Entries",
    "noEntriesYet": "No entries yet",
    "tapPlusToAddGrowthEntry": "Tap + to add your first growth entry",
    "editNicknameTitle": "Edit Nickname",
    "nicknameField": "Nickname",
    "deletePlantTitle": "Delete plant?",
    "deletePlantBody": "This will permanently remove \"{name}\".",
    "healthyStatus": "Healthy",
    "needsCareStatus": "Needs care",
    "conservatoryIsThriving": "Your conservatory is thriving.",
    "identifyAPlant": "Identify a Plant",
    "pointCameraAtAnyPlant": "Point your camera at any plant",
    "everythingsThrivingToday": "Everything's thriving today!",
    "plantsAreHappyHealthy": "Your plants are happy and healthy.",
    "noTasksScheduledForDay": "No tasks scheduled for this day.",
    "snoozeOneDay": "Snooze 1 day",
    "snoozeThreeDays": "Snooze 3 days",
    "taskDoneNextScheduled": "{label} done! \u2705 Next task scheduled.",
    "cameraAccessRequired": "Camera access is required",
    "grantAccess": "Grant Access",
    "idSpeciesMode": "ID Species",
    "detectDiseaseMode": "Detect Disease",
    "captureAndIdentify": "Capture & Identify",
    "orPickFromGallery": "or pick from gallery",
    "analyzingYourPlant": "Analyzing your plant...",
    "failedToCapturePhoto": "Failed to capture photo",
    "failedToIdentifyPrefix": "Failed to identify: {error}",
    "pickAnIcon": "Pick an icon",
    "plantNameAsterisk": "Plant name *",
    "speciesVariety": "Species / variety",
    "locationEgLivingRoom": "Location (e.g. Living room)",
    "wateringFrequencyEg": "Watering frequency (e.g. Every 3 days)",
    "addToMyGarden": "Add to my garden",
    "requiredValidator": "Required",
    "locationField": "Location",
    "wateringFrequencyField": "Watering frequency",
    "saveChangesButton": "Save changes",
    "sendMessageToStartSwapping": "Send a message to start swapping!",
}

# Keys that have ICU placeholders — need @key metadata in ARB
PLACEHOLDER_KEYS = {
    "tasksDoneThisWeek": {"count": "int"},
    "syncedTasksToCalendar": {"count": "int"},
    "rescheduleCare": {"plantName": "String"},
    "completedDaysLateReschedule": {"taskType": "String", "days": "int"},
    "todayTimestamp": {"time": "String"},
    "thirstyOverdueByDays": {"plant": "String", "days": "int"},
    "needsUrgentAttention": {"plant": "String"},
    "careTasksToday": {"count": "int"},
    "allPlantsThrivingToday": {"count": "int"},
    "byAuthor": {"author": "String"},
    "propagatedFrom": {"name": "String"},
    "propagationsFromThisPlant": {"count": "int"},
    "uploadFailed": {"error": "String"},
    "citySetTo": {"city": "String"},
    "errorSavingProfile": {"error": "String"},
    "aiErrorPrefix": {"error": "String"},
    "failedToDeleteAccount": {"error": "String"},
    "failedToPostListing": {"error": "String"},
    "couldNotDetectLocation": {"error": "String"},
    "showingListingsNear": {"city": "String"},
    "failedToSavePrefix": {"error": "String"},
    "failedToIdentifyPrefix": {"error": "String"},
    "deletePlantBody": {"name": "String"},
    "taskDoneNextScheduled": {"label": "String"},
}


def load_json(filepath):
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        return json.load(f)


def write_arb(filepath, data):
    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def update_english_arb(translations):
    filepath = os.path.join(L10N_DIR, 'app_en.arb')
    print(f'Updating app_en.arb...')
    arb = load_json(filepath)

    added = 0
    skipped = 0
    for key, en_value in ENGLISH_VALUES.items():
        if key not in arb:
            arb[key] = en_value
            added += 1
            # Add placeholder metadata if needed
            if key in PLACEHOLDER_KEYS:
                meta_key = f'@{key}'
                if meta_key not in arb:
                    placeholders = {}
                    for ph_name, ph_type in PLACEHOLDER_KEYS[key].items():
                        placeholders[ph_name] = {"type": ph_type}
                    arb[meta_key] = {"placeholders": placeholders}
        else:
            skipped += 1

    write_arb(filepath, arb)
    print(f'  app_en.arb: {added} keys added, {skipped} already present')
    return added


def update_locale_arbs(translations):
    for locale in LOCALES:
        filepath = os.path.join(L10N_DIR, f'app_{locale}.arb')
        if not os.path.exists(filepath):
            print(f'  SKIP: {filepath} not found')
            continue

        print(f'Updating {locale}...', end=' ', flush=True)
        arb = load_json(filepath)

        updated = 0
        added = 0
        for key, lang_map in translations.items():
            if locale in lang_map:
                if key in arb:
                    arb[key] = lang_map[locale]
                    updated += 1
                else:
                    arb[key] = lang_map[locale]
                    added += 1

        write_arb(filepath, arb)
        print(f'OK ({updated} updated, {added} new keys added)')


def main():
    print('Loading arb_translations_2.json...')
    translations = load_json(TRANSLATIONS_FILE)
    print(f'  Loaded {len(translations)} translation keys')
    print()

    # Step 1: Update English ARB
    update_english_arb(translations)
    print()

    # Step 2: Update all non-English ARBs
    print('Updating non-English ARB files...')
    update_locale_arbs(translations)
    print()
    print('Done.')


if __name__ == '__main__':
    main()
