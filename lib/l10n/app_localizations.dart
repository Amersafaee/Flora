import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('sv'),
    Locale('tr'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @garden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get garden;

  /// No description provided for @verdoro.
  ///
  /// In en, this message translates to:
  /// **'Flora'**
  String get verdoro;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here'**
  String get newHere;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Google Sign In'**
  String get googleSignIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @identifyAnyPlant.
  ///
  /// In en, this message translates to:
  /// **'Identify any plant'**
  String get identifyAnyPlant;

  /// No description provided for @neverMissAWatering.
  ///
  /// In en, this message translates to:
  /// **'Never miss a watering'**
  String get neverMissAWatering;

  /// No description provided for @swapWithPlantLovers.
  ///
  /// In en, this message translates to:
  /// **'Swap with plant lovers'**
  String get swapWithPlantLovers;

  /// No description provided for @cameraFloraNames.
  ///
  /// In en, this message translates to:
  /// **'Point your camera and Flora names it'**
  String get cameraFloraNames;

  /// No description provided for @floraRemindsWhenToCare.
  ///
  /// In en, this message translates to:
  /// **'Flora reminds you exactly when to care'**
  String get floraRemindsWhenToCare;

  /// No description provided for @tradeCuttingsLocally.
  ///
  /// In en, this message translates to:
  /// **'Trade cuttings and seeds locally'**
  String get tradeCuttingsLocally;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @todaysCare.
  ///
  /// In en, this message translates to:
  /// **'Today\'s care'**
  String get todaysCare;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @dayCareStreak.
  ///
  /// In en, this message translates to:
  /// **'day care streak'**
  String get dayCareStreak;

  /// No description provided for @startYourStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get startYourStreak;

  /// No description provided for @completeACareTaskToday.
  ///
  /// In en, this message translates to:
  /// **'complete a care task today'**
  String get completeACareTaskToday;

  /// No description provided for @keepItGoingTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Keep it going, you have tasks today'**
  String get keepItGoingTasksToday;

  /// No description provided for @perfectNothingDueToday.
  ///
  /// In en, this message translates to:
  /// **'Perfect, nothing due today'**
  String get perfectNothingDueToday;

  /// No description provided for @plantsInYourGarden.
  ///
  /// In en, this message translates to:
  /// **'plants in your garden'**
  String get plantsInYourGarden;

  /// No description provided for @goodWateringDay.
  ///
  /// In en, this message translates to:
  /// **'Good watering day'**
  String get goodWateringDay;

  /// No description provided for @myGarden.
  ///
  /// In en, this message translates to:
  /// **'My Garden'**
  String get myGarden;

  /// No description provided for @addPlant.
  ///
  /// In en, this message translates to:
  /// **'Add Plant'**
  String get addPlant;

  /// No description provided for @allPlants.
  ///
  /// In en, this message translates to:
  /// **'All Plants'**
  String get allPlants;

  /// No description provided for @noPlantsYet.
  ///
  /// In en, this message translates to:
  /// **'No plants yet'**
  String get noPlantsYet;

  /// No description provided for @addYourFirstPlant.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant'**
  String get addYourFirstPlant;

  /// No description provided for @searchPlants.
  ///
  /// In en, this message translates to:
  /// **'Search plants'**
  String get searchPlants;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @lastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last Watered'**
  String get lastWatered;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @waterAction.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterAction;

  /// No description provided for @fertilise.
  ///
  /// In en, this message translates to:
  /// **'Fertilise'**
  String get fertilise;

  /// No description provided for @repot.
  ///
  /// In en, this message translates to:
  /// **'Repot'**
  String get repot;

  /// No description provided for @prune.
  ///
  /// In en, this message translates to:
  /// **'Prune'**
  String get prune;

  /// No description provided for @mist.
  ///
  /// In en, this message translates to:
  /// **'Mist'**
  String get mist;

  /// No description provided for @inspect.
  ///
  /// In en, this message translates to:
  /// **'Inspect'**
  String get inspect;

  /// No description provided for @treat.
  ///
  /// In en, this message translates to:
  /// **'Treat'**
  String get treat;

  /// No description provided for @growthJournal.
  ///
  /// In en, this message translates to:
  /// **'Growth Journal'**
  String get growthJournal;

  /// No description provided for @treatmentCases.
  ///
  /// In en, this message translates to:
  /// **'Treatment Cases'**
  String get treatmentCases;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @careHistory.
  ///
  /// In en, this message translates to:
  /// **'Care History'**
  String get careHistory;

  /// No description provided for @nextWatering.
  ///
  /// In en, this message translates to:
  /// **'Next watering'**
  String get nextWatering;

  /// No description provided for @lightRequirement.
  ///
  /// In en, this message translates to:
  /// **'Light requirement'**
  String get lightRequirement;

  /// No description provided for @wateringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Watering frequency'**
  String get wateringFrequency;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil type'**
  String get soilType;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @askVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora'**
  String get askVerdoro;

  /// No description provided for @careTips.
  ///
  /// In en, this message translates to:
  /// **'Care Tips'**
  String get careTips;

  /// No description provided for @funFact.
  ///
  /// In en, this message translates to:
  /// **'Fun Fact'**
  String get funFact;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttention;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @careCalendar.
  ///
  /// In en, this message translates to:
  /// **'Care Calendar'**
  String get careCalendar;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @batchCare.
  ///
  /// In en, this message translates to:
  /// **'Batch Care'**
  String get batchCare;

  /// No description provided for @careStreak.
  ///
  /// In en, this message translates to:
  /// **'Care Streak'**
  String get careStreak;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @smartCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Smart Care Plan'**
  String get smartCarePlan;

  /// No description provided for @careInsights.
  ///
  /// In en, this message translates to:
  /// **'Care Insights'**
  String get careInsights;

  /// No description provided for @completeAll.
  ///
  /// In en, this message translates to:
  /// **'Complete all'**
  String get completeAll;

  /// No description provided for @tasksDueToday.
  ///
  /// In en, this message translates to:
  /// **'tasks due today'**
  String get tasksDueToday;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'tasks completed'**
  String get tasksCompleted;

  /// No description provided for @askVerdoroAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora anything'**
  String get askVerdoroAnything;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @verdoroIsThinking.
  ///
  /// In en, this message translates to:
  /// **'Flora is thinking'**
  String get verdoroIsThinking;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @basedOnYourGarden.
  ///
  /// In en, this message translates to:
  /// **'Based on your garden'**
  String get basedOnYourGarden;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @identifyPlant.
  ///
  /// In en, this message translates to:
  /// **'Identify Plant'**
  String get identifyPlant;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @analyzeWithVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Analyze with Flora'**
  String get analyzeWithVerdoro;

  /// No description provided for @identifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying'**
  String get identifying;

  /// No description provided for @addToMyCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to My Collection'**
  String get addToMyCollection;

  /// No description provided for @analyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze Another'**
  String get analyzeAnother;

  /// No description provided for @continueWithVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Continue with Flora'**
  String get continueWithVerdoro;

  /// No description provided for @healthStatus.
  ///
  /// In en, this message translates to:
  /// **'Health Status'**
  String get healthStatus;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Common Name'**
  String get commonName;

  /// No description provided for @scientificName.
  ///
  /// In en, this message translates to:
  /// **'Scientific Name'**
  String get scientificName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @weeklyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Weekly Challenge'**
  String get weeklyChallenge;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @showcase.
  ///
  /// In en, this message translates to:
  /// **'Showcase'**
  String get showcase;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @wiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki'**
  String get wiki;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @searchSpecies.
  ///
  /// In en, this message translates to:
  /// **'Search species'**
  String get searchSpecies;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @careGuide.
  ///
  /// In en, this message translates to:
  /// **'Care Guide'**
  String get careGuide;

  /// No description provided for @readFullCareGuide.
  ///
  /// In en, this message translates to:
  /// **'Read the full care guide'**
  String get readFullCareGuide;

  /// No description provided for @swapMarket.
  ///
  /// In en, this message translates to:
  /// **'Swap Market'**
  String get swapMarket;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create Listing'**
  String get createListing;

  /// No description provided for @plantPassport.
  ///
  /// In en, this message translates to:
  /// **'Plant Passport'**
  String get plantPassport;

  /// No description provided for @makeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get makeAnOffer;

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message Seller'**
  String get messageSeller;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @traded.
  ///
  /// In en, this message translates to:
  /// **'Traded'**
  String get traded;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @memorialGarden.
  ///
  /// In en, this message translates to:
  /// **'Memorial Garden'**
  String get memorialGarden;

  /// No description provided for @vacationMode.
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get vacationMode;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @editCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Care Plan'**
  String get editCarePlan;

  /// No description provided for @daysAway.
  ///
  /// In en, this message translates to:
  /// **'days away'**
  String get daysAway;

  /// No description provided for @plantsInGoodHands.
  ///
  /// In en, this message translates to:
  /// **'Your plants are in good hands'**
  String get plantsInGoodHands;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @memorialMessage.
  ///
  /// In en, this message translates to:
  /// **'May this plant rest peacefully in the soil'**
  String get memorialMessage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectAction;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @addSomePlantsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add some plants first'**
  String get addSomePlantsFirst;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @watering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get watering;

  /// No description provided for @fertilizing.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing'**
  String get fertilizing;

  /// No description provided for @repotting.
  ///
  /// In en, this message translates to:
  /// **'Repotting'**
  String get repotting;

  /// No description provided for @pruning.
  ///
  /// In en, this message translates to:
  /// **'Pruning'**
  String get pruning;

  /// No description provided for @misting.
  ///
  /// In en, this message translates to:
  /// **'Misting'**
  String get misting;

  /// No description provided for @inspecting.
  ///
  /// In en, this message translates to:
  /// **'Inspecting'**
  String get inspecting;

  /// No description provided for @treating.
  ///
  /// In en, this message translates to:
  /// **'Treating'**
  String get treating;

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My Badges'**
  String get myBadges;

  /// No description provided for @memorialGardenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plants in the memorial garden yet — every plant lives a full life here first'**
  String get memorialGardenEmpty;

  /// No description provided for @joinedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedBadgeLabel;

  /// No description provided for @passedLabel.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passedLabel;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @keepGrowingBadges.
  ///
  /// In en, this message translates to:
  /// **'Keep growing to unlock more badges.'**
  String get keepGrowingBadges;

  /// No description provided for @earnedBadges.
  ///
  /// In en, this message translates to:
  /// **'EARNED BADGES'**
  String get earnedBadges;

  /// No description provided for @lockedBadges.
  ///
  /// In en, this message translates to:
  /// **'LOCKED BADGES'**
  String get lockedBadges;

  /// No description provided for @couldNotLoadBadges.
  ///
  /// In en, this message translates to:
  /// **'Could not load badges.'**
  String get couldNotLoadBadges;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// No description provided for @myZones.
  ///
  /// In en, this message translates to:
  /// **'My Zones'**
  String get myZones;

  /// No description provided for @editZone.
  ///
  /// In en, this message translates to:
  /// **'Edit Zone'**
  String get editZone;

  /// No description provided for @zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone Name'**
  String get zoneName;

  /// No description provided for @zoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Zone updated'**
  String get zoneUpdated;

  /// No description provided for @addZone.
  ///
  /// In en, this message translates to:
  /// **'Add Zone'**
  String get addZone;

  /// No description provided for @zoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living Room'**
  String get zoneHint;

  /// No description provided for @noZonesYet.
  ///
  /// In en, this message translates to:
  /// **'No zones added yet.'**
  String get noZonesYet;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get pleaseLogIn;

  /// No description provided for @dailyCareReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Care Reminders'**
  String get dailyCareReminders;

  /// No description provided for @dailyCareRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about watering and feeding'**
  String get dailyCareRemindersSubtitle;

  /// No description provided for @morningDigest.
  ///
  /// In en, this message translates to:
  /// **'Morning Digest at 8 AM'**
  String get morningDigest;

  /// No description provided for @morningDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One bundled notification each morning'**
  String get morningDigestSubtitle;

  /// No description provided for @urgentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Urgent Alerts'**
  String get urgentAlerts;

  /// No description provided for @urgentAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate alerts for critical plant issues'**
  String get urgentAlertsSubtitle;

  /// No description provided for @communityReplies.
  ///
  /// In en, this message translates to:
  /// **'Community Replies'**
  String get communityReplies;

  /// No description provided for @communityRepliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone replies to your post'**
  String get communityRepliesSubtitle;

  /// No description provided for @myPlants.
  ///
  /// In en, this message translates to:
  /// **'My Plants'**
  String get myPlants;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @noPlantsYetAddOne.
  ///
  /// In en, this message translates to:
  /// **'No plants yet. Add one!'**
  String get noPlantsYetAddOne;

  /// No description provided for @editPlant.
  ///
  /// In en, this message translates to:
  /// **'Edit Plant'**
  String get editPlant;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @plantNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Plant name cannot be empty'**
  String get plantNameEmpty;

  /// No description provided for @plantUpdated.
  ///
  /// In en, this message translates to:
  /// **'Plant updated'**
  String get plantUpdated;

  /// No description provided for @failedToUpdatePlant.
  ///
  /// In en, this message translates to:
  /// **'Failed to update plant'**
  String get failedToUpdatePlant;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @unknownZone.
  ///
  /// In en, this message translates to:
  /// **'Unknown Zone'**
  String get unknownZone;

  /// No description provided for @digitalConservatory.
  ///
  /// In en, this message translates to:
  /// **'Digital Conservatory'**
  String get digitalConservatory;

  /// No description provided for @yourPersonalBotanicalGuide.
  ///
  /// In en, this message translates to:
  /// **'Your personal botanical guide'**
  String get yourPersonalBotanicalGuide;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @alreadyHaveAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountQ;

  /// No description provided for @addPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Photo (optional)'**
  String get addPhotoOptional;

  /// No description provided for @startYourPlantJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your plant journey today'**
  String get startYourPlantJourney;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @welcomeToDigitalConservatory.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Digital Conservatory'**
  String get welcomeToDigitalConservatory;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal AI plant sanctuary. Meet Flora — she knows your plants and keeps them thriving.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @neverMissACareDay.
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Care Day'**
  String get neverMissACareDay;

  /// No description provided for @onboardingCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flora builds a smart care calendar for every plant you own and reminds you exactly when to water, fertilize, and check in.'**
  String get onboardingCareSubtitle;

  /// No description provided for @identifyAnyPlantInstantly.
  ///
  /// In en, this message translates to:
  /// **'Identify Any Plant Instantly'**
  String get identifyAnyPlantInstantly;

  /// No description provided for @onboardingIdentifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any plant for instant AI identification, health diagnosis, and a personalized care plan from Flora.'**
  String get onboardingIdentifySubtitle;

  /// No description provided for @joinTheCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Community'**
  String get joinTheCommunity;

  /// No description provided for @onboardingCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your journey, swap cuttings with local plant lovers, and get expert advice from thousands of plant parents.'**
  String get onboardingCommunitySubtitle;

  /// No description provided for @letsGrowSomething.
  ///
  /// In en, this message translates to:
  /// **'Let\'s grow something'**
  String get letsGrowSomething;

  /// No description provided for @gotItLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Got it, let\'s go!'**
  String get gotItLetsGo;

  /// No description provided for @plantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Plant Name'**
  String get plantNameLabel;

  /// No description provided for @plantNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monstera Deliciosa'**
  String get plantNameHint;

  /// No description provided for @plantNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Plant name is required.'**
  String get plantNameRequired;

  /// No description provided for @taskType.
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get taskType;

  /// No description provided for @pleaseSelectTaskType.
  ///
  /// In en, this message translates to:
  /// **'Please select a task type.'**
  String get pleaseSelectTaskType;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes...'**
  String get notesHint;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @taskUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully'**
  String get taskUpdatedSuccessfully;

  /// No description provided for @taskAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task added successfully'**
  String get taskAddedSuccessfully;

  /// No description provided for @updateTask.
  ///
  /// In en, this message translates to:
  /// **'Update Task'**
  String get updateTask;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save Task'**
  String get saveTask;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does Not Repeat'**
  String get doesNotRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @everyTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get everyTwoDays;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @everyTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get everyTwoWeeks;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @newHereQ.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHereQ;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @connectionSlow.
  ///
  /// In en, this message translates to:
  /// **'Connection is slow, please check your internet and try again.'**
  String get connectionSlow;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get noAccountFound;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPassword;

  /// No description provided for @noInternetTryAgain.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get noInternetTryAgain;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get tooManyAttempts;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists'**
  String get emailAlreadyInUse;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooWeak;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @signUpFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed: '**
  String get signUpFailedPrefix;

  /// No description provided for @addJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Journal Entry'**
  String get addJournalEntry;

  /// No description provided for @notSureAskVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Not sure what to write? Ask Flora'**
  String get notSureAskVerdoro;

  /// No description provided for @journalEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Journal entry saved'**
  String get journalEntrySaved;

  /// No description provided for @askFloraAboutThis.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora about this'**
  String get askFloraAboutThis;

  /// No description provided for @viewTreatmentCases.
  ///
  /// In en, this message translates to:
  /// **'View Treatment Cases'**
  String get viewTreatmentCases;

  /// No description provided for @pleaseAddANote.
  ///
  /// In en, this message translates to:
  /// **'Please add a note about your plant.'**
  String get pleaseAddANote;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get saveEntry;

  /// No description provided for @plantLabel.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get plantLabel;

  /// No description provided for @heightInCm.
  ///
  /// In en, this message translates to:
  /// **'Height in cm'**
  String get heightInCm;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 64'**
  String get heightHint;

  /// No description provided for @newLeaves.
  ///
  /// In en, this message translates to:
  /// **'New Leaves'**
  String get newLeaves;

  /// No description provided for @newLeavesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get newLeavesHint;

  /// No description provided for @notesPlantHint.
  ///
  /// In en, this message translates to:
  /// **'Describe how your plant looks today...'**
  String get notesPlantHint;

  /// No description provided for @verdoroNoticedSomething.
  ///
  /// In en, this message translates to:
  /// **'Flora noticed something'**
  String get verdoroNoticedSomething;

  /// No description provided for @aiCarePlan.
  ///
  /// In en, this message translates to:
  /// **'AI Care Plan'**
  String get aiCarePlan;

  /// No description provided for @regeneratePlan.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Plan'**
  String get regeneratePlan;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @errorGeneratingPlanPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error generating plan: '**
  String get errorGeneratingPlanPrefix;

  /// No description provided for @myCarePlan.
  ///
  /// In en, this message translates to:
  /// **'My Care Plan'**
  String get myCarePlan;

  /// No description provided for @addPlantsToSeePlan.
  ///
  /// In en, this message translates to:
  /// **'Add plants to see your care plan'**
  String get addPlantsToSeePlan;

  /// No description provided for @couldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages.'**
  String get couldNotLoadMessages;

  /// No description provided for @sayHelloStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Say hello and start the conversation.'**
  String get sayHelloStartConversation;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @postTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give your post a title'**
  String get postTitleHint;

  /// No description provided for @postBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Share your plant story or question...'**
  String get postBodyHint;

  /// No description provided for @titleBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and body are required.'**
  String get titleBodyRequired;

  /// No description provided for @postSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post shared successfully'**
  String get postSharedSuccessfully;

  /// No description provided for @failedToSharePostPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to share post: '**
  String get failedToSharePostPrefix;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @photoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo updated successfully.'**
  String get photoUpdatedSuccessfully;

  /// No description provided for @failedToUpdatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo.'**
  String get failedToUpdatePhoto;

  /// No description provided for @displayNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty.'**
  String get displayNameCannotBeEmpty;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get failedToUpdateProfile;

  /// No description provided for @mySwapConversations.
  ///
  /// In en, this message translates to:
  /// **'My Swap Conversations'**
  String get mySwapConversations;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @noActiveConversations.
  ///
  /// In en, this message translates to:
  /// **'No active conversations'**
  String get noActiveConversations;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @listingLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listingLabel;

  /// No description provided for @minRead.
  ///
  /// In en, this message translates to:
  /// **'min read'**
  String get minRead;

  /// No description provided for @askVerdoroAboutTopic.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora about this topic'**
  String get askVerdoroAboutTopic;

  /// No description provided for @quickCare.
  ///
  /// In en, this message translates to:
  /// **'Quick Care'**
  String get quickCare;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get allDone;

  /// No description provided for @plantsCaredFor.
  ///
  /// In en, this message translates to:
  /// **'Your plants have been taken care of'**
  String get plantsCaredFor;

  /// No description provided for @backToCare.
  ///
  /// In en, this message translates to:
  /// **'Back to Care'**
  String get backToCare;

  /// No description provided for @swipeToCompleteOrSkip.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to complete, swipe left to skip'**
  String get swipeToCompleteOrSkip;

  /// No description provided for @checkSoilBeforeWatering.
  ///
  /// In en, this message translates to:
  /// **'Check soil moisture before watering.'**
  String get checkSoilBeforeWatering;

  /// No description provided for @useDilutedFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Use diluted liquid fertilizer.'**
  String get useDilutedFertilizer;

  /// No description provided for @choosePot2InchesLarger.
  ///
  /// In en, this message translates to:
  /// **'Choose a pot 2 inches larger.'**
  String get choosePot2InchesLarger;

  /// No description provided for @careForPlantGently.
  ///
  /// In en, this message translates to:
  /// **'Care for your plant gently.'**
  String get careForPlantGently;

  /// No description provided for @livingRoomClimate.
  ///
  /// In en, this message translates to:
  /// **'Living Room Climate'**
  String get livingRoomClimate;

  /// No description provided for @monitoringEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Monitoring your plant\'s environment'**
  String get monitoringEnvironment;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'TEMPERATURE'**
  String get temperatureLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'HUMIDITY'**
  String get humidityLabel;

  /// No description provided for @recentReadings.
  ///
  /// In en, this message translates to:
  /// **'Recent Readings'**
  String get recentReadings;

  /// No description provided for @tempLegend.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get tempLegend;

  /// No description provided for @humidityLegend.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLegend;

  /// No description provided for @enterHint.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterHint;

  /// No description provided for @readingSaved.
  ///
  /// In en, this message translates to:
  /// **'Reading saved'**
  String get readingSaved;

  /// No description provided for @aiPlantConsultant.
  ///
  /// In en, this message translates to:
  /// **'AI Plant Consultant'**
  String get aiPlantConsultant;

  /// No description provided for @pleaseLogInToUseVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Please log in to use Flora.'**
  String get pleaseLogInToUseVerdoro;

  /// No description provided for @startFirstConversation.
  ///
  /// In en, this message translates to:
  /// **'Start your first conversation with Flora'**
  String get startFirstConversation;

  /// No description provided for @tapPlusToBegin.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to begin'**
  String get tapPlusToBegin;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This cannot be undone.'**
  String get deleteConversationConfirm;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search across your plants and the wiki.'**
  String get searchPrompt;

  /// No description provided for @noResultsForPrefix.
  ///
  /// In en, this message translates to:
  /// **'No results for'**
  String get noResultsForPrefix;

  /// No description provided for @wikiPlants.
  ///
  /// In en, this message translates to:
  /// **'Wiki Plants'**
  String get wikiPlants;

  /// No description provided for @communityPosts.
  ///
  /// In en, this message translates to:
  /// **'Community Posts'**
  String get communityPosts;

  /// No description provided for @analyzeYourPlant.
  ///
  /// In en, this message translates to:
  /// **'Analyze Your Plant'**
  String get analyzeYourPlant;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// No description provided for @selectPhotoToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Select a Photo to Analyze'**
  String get selectPhotoToAnalyze;

  /// No description provided for @analyzingLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzingLabel;

  /// No description provided for @couldNotAccessImagePrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not access image: '**
  String get couldNotAccessImagePrefix;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please try again.'**
  String get analysisFailed;

  /// No description provided for @welcomeToPlantScanner.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Plant Scanner'**
  String get welcomeToPlantScanner;

  /// No description provided for @plantScannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Identify plants and instantly diagnose problems.'**
  String get plantScannerDescription;

  /// No description provided for @plantScannerTip1.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo to identify unknown species'**
  String get plantScannerTip1;

  /// No description provided for @plantScannerTip2.
  ///
  /// In en, this message translates to:
  /// **'Scan sick plants for instant AI diagnosis'**
  String get plantScannerTip2;

  /// No description provided for @plantScannerTip3.
  ///
  /// In en, this message translates to:
  /// **'Add identified plants to your collection'**
  String get plantScannerTip3;

  /// No description provided for @tradeChat.
  ///
  /// In en, this message translates to:
  /// **'Trade Chat'**
  String get tradeChat;

  /// No description provided for @viewListing.
  ///
  /// In en, this message translates to:
  /// **'View Listing'**
  String get viewListing;

  /// No description provided for @startTradeNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Start the trade negotiation!'**
  String get startTradeNegotiation;

  /// No description provided for @failedToSendImagePrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to send image: '**
  String get failedToSendImagePrefix;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required to share your location'**
  String get locationPermissionRequired;

  /// No description provided for @couldNotGetLocationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: '**
  String get couldNotGetLocationPrefix;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @sendImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImageTooltip;

  /// No description provided for @shareLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocationTooltip;

  /// No description provided for @grownWithDigitalConservatory.
  ///
  /// In en, this message translates to:
  /// **'Grown with Digital Conservatory'**
  String get grownWithDigitalConservatory;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get shareCard;

  /// No description provided for @healthLabel.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthLabel;

  /// No description provided for @daysTogether.
  ///
  /// In en, this message translates to:
  /// **'Days Together'**
  String get daysTogether;

  /// No description provided for @checkIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get checkIns;

  /// No description provided for @checkOutMyPlant.
  ///
  /// In en, this message translates to:
  /// **'Check out my plant on Digital Conservatory!'**
  String get checkOutMyPlant;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get topCategories;

  /// No description provided for @shareMyPersonality.
  ///
  /// In en, this message translates to:
  /// **'Share My Personality'**
  String get shareMyPersonality;

  /// No description provided for @buddingPlantParent.
  ///
  /// In en, this message translates to:
  /// **'Budding Plant Parent'**
  String get buddingPlantParent;

  /// No description provided for @buddingPlantParentDesc.
  ///
  /// In en, this message translates to:
  /// **'Every great conservatory starts somewhere. You are at the beginning of a beautiful journey.'**
  String get buddingPlantParentDesc;

  /// No description provided for @masterConservatoryKeeper.
  ///
  /// In en, this message translates to:
  /// **'Master Conservatory Keeper'**
  String get masterConservatoryKeeper;

  /// No description provided for @masterConservatoryKeeperDesc.
  ///
  /// In en, this message translates to:
  /// **'Your diverse collection shows true botanical expertise. You understand that every plant has its own needs and you meet them all.'**
  String get masterConservatoryKeeperDesc;

  /// No description provided for @tropicalRainforestCurator.
  ///
  /// In en, this message translates to:
  /// **'Tropical Rainforest Curator'**
  String get tropicalRainforestCurator;

  /// No description provided for @tropicalRainforestCuratorDesc.
  ///
  /// In en, this message translates to:
  /// **'You have a passion for lush dramatic plants that bring the jungle indoors. Your collection is bold and statement-making.'**
  String get tropicalRainforestCuratorDesc;

  /// No description provided for @desertGardenArchitect.
  ///
  /// In en, this message translates to:
  /// **'Desert Garden Architect'**
  String get desertGardenArchitect;

  /// No description provided for @desertGardenArchitectDesc.
  ///
  /// In en, this message translates to:
  /// **'You appreciate resilience and minimalist beauty. Your collection is low-maintenance and timelessly elegant.'**
  String get desertGardenArchitectDesc;

  /// No description provided for @shadeGardenSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Shade Garden Specialist'**
  String get shadeGardenSpecialist;

  /// No description provided for @shadeGardenSpecialistDesc.
  ///
  /// In en, this message translates to:
  /// **'You have mastered the art of thriving in low light. Your collection is soft textured and wonderfully calming.'**
  String get shadeGardenSpecialistDesc;

  /// No description provided for @urbanKitchenGardener.
  ///
  /// In en, this message translates to:
  /// **'Urban Kitchen Gardener'**
  String get urbanKitchenGardener;

  /// No description provided for @urbanKitchenGardenerDesc.
  ///
  /// In en, this message translates to:
  /// **'Your plants are both beautiful and practical. You grow with purpose and your kitchen thanks you for it.'**
  String get urbanKitchenGardenerDesc;

  /// No description provided for @listYourPlant.
  ///
  /// In en, this message translates to:
  /// **'List Your Plant'**
  String get listYourPlant;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @titleDescLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Title, description, and location are required.'**
  String get titleDescLocationRequired;

  /// No description provided for @listingCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing created successfully!'**
  String get listingCreatedSuccessfully;

  /// No description provided for @failedToSaveListingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to save listing: '**
  String get failedToSaveListingPrefix;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @listingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monstera Albo cutting'**
  String get listingTitleHint;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your plant or cutting'**
  String get descriptionHint;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking For'**
  String get lookingFor;

  /// No description provided for @lookingForHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rare Philodendrons or leave empty if free'**
  String get lookingForHint;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living room, South-facing window'**
  String get locationHint;

  /// No description provided for @addAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addAPhoto;

  /// No description provided for @tapToChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose from gallery or camera'**
  String get tapToChoosePhoto;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @lightMeter.
  ///
  /// In en, this message translates to:
  /// **'Light Meter'**
  String get lightMeter;

  /// No description provided for @tapMeasureToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Measure to start'**
  String get tapMeasureToStart;

  /// No description provided for @pointCameraAtLight.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the light source'**
  String get pointCameraAtLight;

  /// No description provided for @lowLight.
  ///
  /// In en, this message translates to:
  /// **'Low Light'**
  String get lowLight;

  /// No description provided for @lowLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Good for shade-tolerant plants like Pothos and Snake Plant'**
  String get lowLightDesc;

  /// No description provided for @mediumLight.
  ///
  /// In en, this message translates to:
  /// **'Medium Light'**
  String get mediumLight;

  /// No description provided for @mediumLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Ideal for Peace Lily, Philodendron and most Ferns'**
  String get mediumLightDesc;

  /// No description provided for @brightIndirect.
  ///
  /// In en, this message translates to:
  /// **'Bright Indirect'**
  String get brightIndirect;

  /// No description provided for @brightIndirectDesc.
  ///
  /// In en, this message translates to:
  /// **'Perfect for Monstera, Pothos and most tropical plants'**
  String get brightIndirectDesc;

  /// No description provided for @brightDirect.
  ///
  /// In en, this message translates to:
  /// **'Bright Direct'**
  String get brightDirect;

  /// No description provided for @brightDirectDesc.
  ///
  /// In en, this message translates to:
  /// **'Great for succulents, cacti and herbs'**
  String get brightDirectDesc;

  /// No description provided for @veryIntense.
  ///
  /// In en, this message translates to:
  /// **'Very Intense'**
  String get veryIntense;

  /// No description provided for @veryIntenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Too bright for most houseplants — risk of leaf scorch'**
  String get veryIntenseDesc;

  /// No description provided for @stopMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Stop Measuring'**
  String get stopMeasuring;

  /// No description provided for @measureLight.
  ///
  /// In en, this message translates to:
  /// **'Measure Light'**
  String get measureLight;

  /// No description provided for @measuringFiveSeconds.
  ///
  /// In en, this message translates to:
  /// **'Measuring for 5 seconds...'**
  String get measuringFiveSeconds;

  /// No description provided for @saveToPlant.
  ///
  /// In en, this message translates to:
  /// **'Save to a Plant'**
  String get saveToPlant;

  /// No description provided for @saveLightReading.
  ///
  /// In en, this message translates to:
  /// **'Save Light Reading'**
  String get saveLightReading;

  /// No description provided for @noPlantsFound.
  ///
  /// In en, this message translates to:
  /// **'No plants found.'**
  String get noPlantsFound;

  /// No description provided for @lightReadingSavedToPrefix.
  ///
  /// In en, this message translates to:
  /// **'Light reading saved to '**
  String get lightReadingSavedToPrefix;

  /// No description provided for @goingSomewhere.
  ///
  /// In en, this message translates to:
  /// **'Going somewhere?'**
  String get goingSomewhere;

  /// No description provided for @takeCareOfReminders.
  ///
  /// In en, this message translates to:
  /// **'We will take care of your reminders while you are away.'**
  String get takeCareOfReminders;

  /// No description provided for @enableVacationMode.
  ///
  /// In en, this message translates to:
  /// **'Enable Vacation Mode'**
  String get enableVacationMode;

  /// No description provided for @pausesAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Pauses all plant care notifications.'**
  String get pausesAllNotifications;

  /// No description provided for @yourTrip.
  ///
  /// In en, this message translates to:
  /// **'YOUR TRIP'**
  String get yourTrip;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @generateCarePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Generate Care Plan'**
  String get generateCarePlanAction;

  /// No description provided for @yourCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Your Care Plan'**
  String get yourCarePlan;

  /// No description provided for @editCarePlanHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your care plan before sharing…'**
  String get editCarePlanHint;

  /// No description provided for @shareEmoji.
  ///
  /// In en, this message translates to:
  /// **'Share 🌿'**
  String get shareEmoji;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @pleaseSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Please select start and end dates.'**
  String get pleaseSelectDates;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of'**
  String get weekOf;

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get tasksDone;

  /// No description provided for @journalEntries.
  ///
  /// In en, this message translates to:
  /// **'Journal Entries'**
  String get journalEntries;

  /// No description provided for @collectionHealth.
  ///
  /// In en, this message translates to:
  /// **'Collection Health'**
  String get collectionHealth;

  /// No description provided for @starOfTheWeek.
  ///
  /// In en, this message translates to:
  /// **'Star of the Week'**
  String get starOfTheWeek;

  /// No description provided for @closeReport.
  ///
  /// In en, this message translates to:
  /// **'Close Report'**
  String get closeReport;

  /// No description provided for @generatedByVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Generated by Flora every Sunday'**
  String get generatedByVerdoro;

  /// No description provided for @didYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did You Know?'**
  String get didYouKnow;

  /// No description provided for @careGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Care Guidelines'**
  String get careGuidelines;

  /// No description provided for @askVerdoroAboutThisPlant.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora About This Plant'**
  String get askVerdoroAboutThisPlant;

  /// No description provided for @lightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightLabel;

  /// No description provided for @wateringLabel.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get wateringLabel;

  /// No description provided for @soilLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soilLabel;

  /// No description provided for @plantVitals.
  ///
  /// In en, this message translates to:
  /// **'Plant Vitals'**
  String get plantVitals;

  /// No description provided for @collectionHealthOverview.
  ///
  /// In en, this message translates to:
  /// **'Your collection health overview'**
  String get collectionHealthOverview;

  /// No description provided for @yourPlants.
  ///
  /// In en, this message translates to:
  /// **'Your Plants'**
  String get yourPlants;

  /// No description provided for @thriving.
  ///
  /// In en, this message translates to:
  /// **'Thriving'**
  String get thriving;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help'**
  String get needHelp;

  /// No description provided for @savePlant.
  ///
  /// In en, this message translates to:
  /// **'Save Plant'**
  String get savePlant;

  /// No description provided for @commonNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Swiss Cheese Plant'**
  String get commonNameHint;

  /// No description provided for @howOftenCareDesc.
  ///
  /// In en, this message translates to:
  /// **'How often does this plant need care? We will add it to your calendar automatically.'**
  String get howOftenCareDesc;

  /// No description provided for @askVerdoroForAdvice.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora for advice'**
  String get askVerdoroForAdvice;

  /// No description provided for @saveCareSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Care Schedule'**
  String get saveCareSchedule;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @careScheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Care schedule saved — tasks added to your calendar'**
  String get careScheduleSaved;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @every2Days.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get every2Days;

  /// No description provided for @every3Days.
  ///
  /// In en, this message translates to:
  /// **'Every 3 days'**
  String get every3Days;

  /// No description provided for @biWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get biWeekly;

  /// No description provided for @plantAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Plant Analysis'**
  String get plantAnalysis;

  /// No description provided for @openingFlora.
  ///
  /// In en, this message translates to:
  /// **'Opening Flora…'**
  String get openingFlora;

  /// No description provided for @pleaseSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue with Flora.'**
  String get pleaseSignInToContinue;

  /// No description provided for @couldNotOpenVerdoroPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not open Flora: '**
  String get couldNotOpenVerdoroPrefix;

  /// No description provided for @listingsByLocation.
  ///
  /// In en, this message translates to:
  /// **'Listings by Location'**
  String get listingsByLocation;

  /// No description provided for @noListingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No listings available'**
  String get noListingsAvailable;

  /// No description provided for @errorLoadingListings.
  ///
  /// In en, this message translates to:
  /// **'Error loading listings'**
  String get errorLoadingListings;

  /// No description provided for @noListingsForSearch.
  ///
  /// In en, this message translates to:
  /// **'No listings found for your search.'**
  String get noListingsForSearch;

  /// No description provided for @searchPlantsOrCuttings.
  ///
  /// In en, this message translates to:
  /// **'Search plants or cuttings...'**
  String get searchPlantsOrCuttings;

  /// No description provided for @lookingForPrefix.
  ///
  /// In en, this message translates to:
  /// **'Looking for: '**
  String get lookingForPrefix;

  /// No description provided for @cuttings.
  ///
  /// In en, this message translates to:
  /// **'Cuttings'**
  String get cuttings;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @wholePlants.
  ///
  /// In en, this message translates to:
  /// **'Whole Plants'**
  String get wholePlants;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing;

  /// No description provided for @deleteListingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this listing from the swap market?'**
  String get deleteListingConfirm;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get editListing;

  /// No description provided for @aboutThisPlant.
  ///
  /// In en, this message translates to:
  /// **'About this plant'**
  String get aboutThisPlant;

  /// No description provided for @lookingToSwapFor.
  ///
  /// In en, this message translates to:
  /// **'Looking to swap for'**
  String get lookingToSwapFor;

  /// No description provided for @listedBy.
  ///
  /// In en, this message translates to:
  /// **'Listed by'**
  String get listedBy;

  /// No description provided for @passportDetails.
  ///
  /// In en, this message translates to:
  /// **'Passport Details'**
  String get passportDetails;

  /// No description provided for @viewFullListing.
  ///
  /// In en, this message translates to:
  /// **'View Full Listing'**
  String get viewFullListing;

  /// No description provided for @messageSellerEmoji.
  ///
  /// In en, this message translates to:
  /// **'Message Seller 💬'**
  String get messageSellerEmoji;

  /// No description provided for @healthNotAssessed.
  ///
  /// In en, this message translates to:
  /// **'Health: Not assessed'**
  String get healthNotAssessed;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @healthColonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Health: '**
  String get healthColonPrefix;

  /// No description provided for @smartCarePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flora has personalized your care schedule based on your home conditions'**
  String get smartCarePlanSubtitle;

  /// No description provided for @getPersonalizedPlan.
  ///
  /// In en, this message translates to:
  /// **'Get Personalized Plan'**
  String get getPersonalizedPlan;

  /// No description provided for @failedToGeneratePlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate plan. Please try again.'**
  String get failedToGeneratePlan;

  /// No description provided for @yourWeeklyCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Your Weekly Care Plan'**
  String get yourWeeklyCarePlan;

  /// No description provided for @noTasksNext14Days.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for the next 14 days.'**
  String get noTasksNext14Days;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @addSomePlantsForPlan.
  ///
  /// In en, this message translates to:
  /// **'Add some plants first to get a personalized plan'**
  String get addSomePlantsForPlan;

  /// No description provided for @plantFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'Plant Family Tree'**
  String get plantFamilyTree;

  /// No description provided for @recordParentPlant.
  ///
  /// In en, this message translates to:
  /// **'Record Parent Plant'**
  String get recordParentPlant;

  /// No description provided for @recordParentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grandma\'s Monstera'**
  String get recordParentHint;

  /// No description provided for @addPropagation.
  ///
  /// In en, this message translates to:
  /// **'Add Propagation'**
  String get addPropagation;

  /// No description provided for @propagationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Propagation #1'**
  String get propagationHint;

  /// No description provided for @listCuttingForSwap.
  ///
  /// In en, this message translates to:
  /// **'List this cutting for swap?'**
  String get listCuttingForSwap;

  /// No description provided for @listForSwap.
  ///
  /// In en, this message translates to:
  /// **'List for Swap'**
  String get listForSwap;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @parentPlantLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent Plant'**
  String get parentPlantLabel;

  /// No description provided for @propagatedFromThis.
  ///
  /// In en, this message translates to:
  /// **'Propagated From This'**
  String get propagatedFromThis;

  /// No description provided for @noParentRecorded.
  ///
  /// In en, this message translates to:
  /// **'No parent recorded'**
  String get noParentRecorded;

  /// No description provided for @noPropagationsYet.
  ///
  /// In en, this message translates to:
  /// **'No propagations yet'**
  String get noPropagationsYet;

  /// No description provided for @couldNotLoadFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'Could not load family tree.'**
  String get couldNotLoadFamilyTree;

  /// No description provided for @unknownParent.
  ///
  /// In en, this message translates to:
  /// **'Unknown Parent'**
  String get unknownParent;

  /// No description provided for @unknownProp.
  ///
  /// In en, this message translates to:
  /// **'Unknown Prop'**
  String get unknownProp;

  /// No description provided for @joinedCollection.
  ///
  /// In en, this message translates to:
  /// **'Joined Collection'**
  String get joinedCollection;

  /// No description provided for @timesWatered.
  ///
  /// In en, this message translates to:
  /// **'Times Watered'**
  String get timesWatered;

  /// No description provided for @diseaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Disease History'**
  String get diseaseHistory;

  /// No description provided for @careConsistency.
  ///
  /// In en, this message translates to:
  /// **'Care Consistency'**
  String get careConsistency;

  /// No description provided for @careTimeline.
  ///
  /// In en, this message translates to:
  /// **'Care Timeline'**
  String get careTimeline;

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI SUMMARY'**
  String get aiSummary;

  /// No description provided for @listOnSwapMarket.
  ///
  /// In en, this message translates to:
  /// **'List on Swap Market'**
  String get listOnSwapMarket;

  /// No description provided for @sharePassport.
  ///
  /// In en, this message translates to:
  /// **'Share Passport'**
  String get sharePassport;

  /// No description provided for @cleanRecord.
  ///
  /// In en, this message translates to:
  /// **'Clean Record'**
  String get cleanRecord;

  /// No description provided for @recovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get recovered;

  /// No description provided for @activeIssue.
  ///
  /// In en, this message translates to:
  /// **'Active Issue'**
  String get activeIssue;

  /// No description provided for @unknownSpecies.
  ///
  /// In en, this message translates to:
  /// **'Unknown Species'**
  String get unknownSpecies;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get checkedIn;

  /// No description provided for @passportHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'DIGITAL CONSERVATORY PLANT PASSPORT'**
  String get passportHeaderLabel;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @verdoroAiExpertAnswer.
  ///
  /// In en, this message translates to:
  /// **'FLORA AI EXPERT ANSWER'**
  String get verdoroAiExpertAnswer;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to reply!'**
  String get noCommentsYet;

  /// No description provided for @failedToLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments'**
  String get failedToLoadComments;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @failedToPostComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment'**
  String get failedToPostComment;

  /// No description provided for @saveTipToJournal.
  ///
  /// In en, this message translates to:
  /// **'Save this tip to a plant journal'**
  String get saveTipToJournal;

  /// No description provided for @failedToLoadPlants.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plants'**
  String get failedToLoadPlants;

  /// No description provided for @addSomePlantsToSaveTips.
  ///
  /// In en, this message translates to:
  /// **'Add some plants first to save tips'**
  String get addSomePlantsToSaveTips;

  /// No description provided for @failedToSaveToJournal.
  ///
  /// In en, this message translates to:
  /// **'Failed to save to journal'**
  String get failedToSaveToJournal;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @plantWiki.
  ///
  /// In en, this message translates to:
  /// **'Plant Wiki'**
  String get plantWiki;

  /// No description provided for @wikiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore our botanical encyclopedia to find your perfect green companion.'**
  String get wikiSubtitle;

  /// No description provided for @searchByNameSpeciesTrait.
  ///
  /// In en, this message translates to:
  /// **'Search by name, species, or trait...'**
  String get searchByNameSpeciesTrait;

  /// No description provided for @wikiFilterAllPlants.
  ///
  /// In en, this message translates to:
  /// **'All Plants'**
  String get wikiFilterAllPlants;

  /// No description provided for @wikiFilterPetFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pet Friendly'**
  String get wikiFilterPetFriendly;

  /// No description provided for @wikiFilterAirPurifying.
  ///
  /// In en, this message translates to:
  /// **'Air Purifying'**
  String get wikiFilterAirPurifying;

  /// No description provided for @wikiFilterBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get wikiFilterBeginner;

  /// No description provided for @errorLoadingWikiData.
  ///
  /// In en, this message translates to:
  /// **'Error loading wiki data'**
  String get errorLoadingWikiData;

  /// No description provided for @noPlantsInWikiYet.
  ///
  /// In en, this message translates to:
  /// **'No plants in the wiki yet.'**
  String get noPlantsInWikiYet;

  /// No description provided for @noPlantsFoundForSearch.
  ///
  /// In en, this message translates to:
  /// **'No plants found for your search.'**
  String get noPlantsFoundForSearch;

  /// No description provided for @latestFromBlog.
  ///
  /// In en, this message translates to:
  /// **'Latest from the Blog'**
  String get latestFromBlog;

  /// No description provided for @errorLoadingBlogs.
  ///
  /// In en, this message translates to:
  /// **'Error loading blogs'**
  String get errorLoadingBlogs;

  /// No description provided for @blogPostsLoading.
  ///
  /// In en, this message translates to:
  /// **'Blog posts loading...'**
  String get blogPostsLoading;

  /// No description provided for @analyzingProgress.
  ///
  /// In en, this message translates to:
  /// **'Analyzing progress...'**
  String get analyzingProgress;

  /// No description provided for @progressReport.
  ///
  /// In en, this message translates to:
  /// **'Progress Report'**
  String get progressReport;

  /// No description provided for @outOf100.
  ///
  /// In en, this message translates to:
  /// **'out of 100'**
  String get outOf100;

  /// No description provided for @observationLabel.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get observationLabel;

  /// No description provided for @adjustedRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Adjusted Recommendation'**
  String get adjustedRecommendation;

  /// No description provided for @saveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get saveProgress;

  /// No description provided for @markAsResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as Resolved'**
  String get markAsResolved;

  /// No description provided for @plantHealthCases.
  ///
  /// In en, this message translates to:
  /// **'Plant Health Cases'**
  String get plantHealthCases;

  /// No description provided for @noHealthIssuesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No health issues recorded.\nYour plant appears to be doing well.'**
  String get noHealthIssuesRecorded;

  /// No description provided for @detectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Detected '**
  String get detectedPrefix;

  /// No description provided for @checkProgress.
  ///
  /// In en, this message translates to:
  /// **'Check Progress'**
  String get checkProgress;

  /// No description provided for @askTheCommunity.
  ///
  /// In en, this message translates to:
  /// **'Ask the Community'**
  String get askTheCommunity;

  /// No description provided for @recoveryComplete.
  ///
  /// In en, this message translates to:
  /// **'Recovery Complete!'**
  String get recoveryComplete;

  /// No description provided for @beforeLabel.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get beforeLabel;

  /// No description provided for @afterLabel.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get afterLabel;

  /// No description provided for @shareRecoveryStory.
  ///
  /// In en, this message translates to:
  /// **'Share Recovery Story'**
  String get shareRecoveryStory;

  /// No description provided for @recoveredInDays.
  ///
  /// In en, this message translates to:
  /// **'Recovered in {days} days'**
  String recoveredInDays(int days);

  /// No description provided for @recoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Your {plantName} fought back from {diagnosis} and won. You did that.'**
  String recoveryMessage(String plantName, String diagnosis);

  /// No description provided for @searchDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Search discussions...'**
  String get searchDiscussions;

  /// No description provided for @forMyGarden.
  ///
  /// In en, this message translates to:
  /// **'For My Garden'**
  String get forMyGarden;

  /// No description provided for @allPosts.
  ///
  /// In en, this message translates to:
  /// **'All Posts'**
  String get allPosts;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(int days);

  /// No description provided for @joinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Join Challenge'**
  String get joinChallenge;

  /// No description provided for @plantSwapMarket.
  ///
  /// In en, this message translates to:
  /// **'Plant Swap Market'**
  String get plantSwapMarket;

  /// No description provided for @failedToLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get failedToLoadPosts;

  /// No description provided for @beTheFirstToShare.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share'**
  String get beTheFirstToShare;

  /// No description provided for @communityWaiting.
  ///
  /// In en, this message translates to:
  /// **'The community is waiting for your plant story. Share a tip, ask a question, or show off your collection.'**
  String get communityWaiting;

  /// No description provided for @startADiscussion.
  ///
  /// In en, this message translates to:
  /// **'Start a Discussion'**
  String get startADiscussion;

  /// No description provided for @noPostsAboutYourPlants.
  ///
  /// In en, this message translates to:
  /// **'No community posts about your plants yet. Be the first to share!'**
  String get noPostsAboutYourPlants;

  /// No description provided for @noPostsFoundForSearch.
  ///
  /// In en, this message translates to:
  /// **'No posts found for your search.'**
  String get noPostsFoundForSearch;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @cannotReportOwnPost.
  ///
  /// In en, this message translates to:
  /// **'You cannot report your own post'**
  String get cannotReportOwnPost;

  /// No description provided for @reportThisPost.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get reportThisPost;

  /// No description provided for @postHiddenThankYou.
  ///
  /// In en, this message translates to:
  /// **'Post hidden. Thank you for keeping the community safe.'**
  String get postHiddenThankYou;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @deletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get deletePostConfirm;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @youGrowThis.
  ///
  /// In en, this message translates to:
  /// **'You grow this'**
  String get youGrowThis;

  /// No description provided for @sharePostPrefix.
  ///
  /// In en, this message translates to:
  /// **'Check out this plant discussion on Digital Conservatory: '**
  String get sharePostPrefix;

  /// No description provided for @welcomeToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Community'**
  String get welcomeToCommunity;

  /// No description provided for @communityOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with other plant lovers and experts.'**
  String get communityOnboardingDesc;

  /// No description provided for @communityTip1.
  ///
  /// In en, this message translates to:
  /// **'Share your plant progress and tips'**
  String get communityTip1;

  /// No description provided for @communityTip2.
  ///
  /// In en, this message translates to:
  /// **'Ask for help with sick plants'**
  String get communityTip2;

  /// No description provided for @communityTip3.
  ///
  /// In en, this message translates to:
  /// **'Join weekly growing challenges'**
  String get communityTip3;

  /// No description provided for @syncToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Sync to Calendar'**
  String get syncToCalendar;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todaysTasks;

  /// No description provided for @noCareTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No care tasks yet'**
  String get noCareTasksYet;

  /// No description provided for @addPlantForCareSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add a plant to get a care schedule built automatically by Flora'**
  String get addPlantForCareSchedule;

  /// No description provided for @addAPlant.
  ///
  /// In en, this message translates to:
  /// **'Add a Plant'**
  String get addAPlant;

  /// No description provided for @swipeThroughTasksFast.
  ///
  /// In en, this message translates to:
  /// **'Swipe through all tasks fast'**
  String get swipeThroughTasksFast;

  /// No description provided for @personalizedScheduleBasedOnHome.
  ///
  /// In en, this message translates to:
  /// **'Personalized schedule based on your home'**
  String get personalizedScheduleBasedOnHome;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get notSignedIn;

  /// No description provided for @noCompletedTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get noCompletedTasksYet;

  /// No description provided for @tasksDoneThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks done this week} =1{1 task done this week} other{{count} tasks done this week}}'**
  String tasksDoneThisWeek(int count);

  /// No description provided for @syncingTasksToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Syncing tasks to calendar...'**
  String get syncingTasksToCalendar;

  /// No description provided for @syncedTasksToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} tasks to your calendar'**
  String syncedTasksToCalendar(int count);

  /// No description provided for @noUpcomingTasksToSync.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks to sync or calendar permission denied'**
  String get noUpcomingTasksToSync;

  /// No description provided for @calendarSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync failed. Please try again.'**
  String get calendarSyncFailed;

  /// No description provided for @rescheduleCare.
  ///
  /// In en, this message translates to:
  /// **'Reschedule {plantName}\'s care?'**
  String rescheduleCare(String plantName);

  /// No description provided for @completedDaysLateReschedule.
  ///
  /// In en, this message translates to:
  /// **'You completed this {taskType} {days} days late. Do you want to schedule the next one from today, or keep the original schedule?'**
  String completedDaysLateReschedule(String taskType, int days);

  /// No description provided for @keepSchedule.
  ///
  /// In en, this message translates to:
  /// **'Keep schedule'**
  String get keepSchedule;

  /// No description provided for @fromToday.
  ///
  /// In en, this message translates to:
  /// **'From today'**
  String get fromToday;

  /// No description provided for @roomClimate.
  ///
  /// In en, this message translates to:
  /// **'Room Climate'**
  String get roomClimate;

  /// No description provided for @addCaptionOrQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add a caption or question... (optional)'**
  String get addCaptionOrQuestion;

  /// No description provided for @clearChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat History'**
  String get clearChatHistory;

  /// No description provided for @aboutVerdoro.
  ///
  /// In en, this message translates to:
  /// **'About Flora'**
  String get aboutVerdoro;

  /// No description provided for @verdoroIsReviewingYourPlants.
  ///
  /// In en, this message translates to:
  /// **'Flora is reviewing your plants…'**
  String get verdoroIsReviewingYourPlants;

  /// No description provided for @hiIAmVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Flora'**
  String get hiIAmVerdoro;

  /// No description provided for @yourPersonalPlantCareAssistant.
  ///
  /// In en, this message translates to:
  /// **'Your personal plant care assistant'**
  String get yourPersonalPlantCareAssistant;

  /// No description provided for @howOftenWaterMonstera.
  ///
  /// In en, this message translates to:
  /// **'How often should I water my Monstera'**
  String get howOftenWaterMonstera;

  /// No description provided for @whyLeavesYellow.
  ///
  /// In en, this message translates to:
  /// **'Why are my plant leaves turning yellow'**
  String get whyLeavesYellow;

  /// No description provided for @plantsGoodForLowLight.
  ///
  /// In en, this message translates to:
  /// **'What plants are good for low light'**
  String get plantsGoodForLowLight;

  /// No description provided for @howToRepotPlant.
  ///
  /// In en, this message translates to:
  /// **'How do I repot a plant'**
  String get howToRepotPlant;

  /// No description provided for @verdoroKnowsPlantsDesc.
  ///
  /// In en, this message translates to:
  /// **'Flora knows your entire plant collection and uses that knowledge to give you personalized advice.'**
  String get verdoroKnowsPlantsDesc;

  /// No description provided for @version100.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version100;

  /// No description provided for @todayTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayTimestamp(String time);

  /// No description provided for @askFloraAnythingAboutPlants.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora anything about plants'**
  String get askFloraAnythingAboutPlants;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get loadingWeather;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @yourConservatoryIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your conservatory is empty'**
  String get yourConservatoryIsEmpty;

  /// No description provided for @addFirstPlantDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant and Flora will build a personalised care plan for it automatically'**
  String get addFirstPlantDescription;

  /// No description provided for @addYourFirstPlantEmoji.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Plant 🌱'**
  String get addYourFirstPlantEmoji;

  /// No description provided for @orIdentifyWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Or identify a plant with your camera'**
  String get orIdentifyWithCamera;

  /// No description provided for @offlineShowingCachedData.
  ///
  /// In en, this message translates to:
  /// **'You are offline — showing cached data'**
  String get offlineShowingCachedData;

  /// No description provided for @noTasksForToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today.'**
  String get noTasksForToday;

  /// No description provided for @plantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plantsLabel;

  /// No description provided for @assessAPlant.
  ///
  /// In en, this message translates to:
  /// **'Assess a plant'**
  String get assessAPlant;

  /// No description provided for @avgHealth.
  ///
  /// In en, this message translates to:
  /// **'Avg Health'**
  String get avgHealth;

  /// No description provided for @identifyEmoji.
  ///
  /// In en, this message translates to:
  /// **'Identify 📷'**
  String get identifyEmoji;

  /// No description provided for @careEmoji.
  ///
  /// In en, this message translates to:
  /// **'Care 🗓️'**
  String get careEmoji;

  /// No description provided for @communityEmoji.
  ///
  /// In en, this message translates to:
  /// **'Community 🌱'**
  String get communityEmoji;

  /// No description provided for @dailyCare.
  ///
  /// In en, this message translates to:
  /// **'Daily Care'**
  String get dailyCare;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @fromTheCommunity.
  ///
  /// In en, this message translates to:
  /// **'From the Community'**
  String get fromTheCommunity;

  /// No description provided for @noCommunityPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No community posts yet.'**
  String get noCommunityPostsYet;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String byAuthor(String author);

  /// No description provided for @learnSomethingNew.
  ///
  /// In en, this message translates to:
  /// **'Learn Something New'**
  String get learnSomethingNew;

  /// No description provided for @plantGuidesLoading.
  ///
  /// In en, this message translates to:
  /// **'Plant guides loading…'**
  String get plantGuidesLoading;

  /// No description provided for @thirstyOverdueByDays.
  ///
  /// In en, this message translates to:
  /// **'💧 {plant} is thirsty — watering overdue by {days} days'**
  String thirstyOverdueByDays(String plant, int days);

  /// No description provided for @needsUrgentAttention.
  ///
  /// In en, this message translates to:
  /// **'🚨 {plant} needs urgent attention'**
  String needsUrgentAttention(String plant);

  /// No description provided for @careTasksToday.
  ///
  /// In en, this message translates to:
  /// **'📋 You have {count} care tasks today'**
  String careTasksToday(int count);

  /// No description provided for @addFirstPlantToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'🌱 Add your first plant to get started'**
  String get addFirstPlantToGetStarted;

  /// No description provided for @allPlantsThrivingToday.
  ///
  /// In en, this message translates to:
  /// **'🌿 All {count} plants are thriving today'**
  String allPlantsThrivingToday(int count);

  /// No description provided for @plantFallbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get plantFallbackCategory;

  /// No description provided for @viewPlantPassport.
  ///
  /// In en, this message translates to:
  /// **'View Plant Passport'**
  String get viewPlantPassport;

  /// No description provided for @markAsUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unhealthy'**
  String get markAsUnhealthy;

  /// No description provided for @plantMarkedAsUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Plant marked as unhealthy'**
  String get plantMarkedAsUnhealthy;

  /// No description provided for @markAsDeceased.
  ///
  /// In en, this message translates to:
  /// **'Mark as Deceased'**
  String get markAsDeceased;

  /// No description provided for @deletePlant.
  ///
  /// In en, this message translates to:
  /// **'Delete Plant'**
  String get deletePlant;

  /// No description provided for @deletePlantConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Plant?'**
  String get deletePlantConfirm;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @analyzeWithFloraToGetHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Analyze with Flora to get health score'**
  String get analyzeWithFloraToGetHealthScore;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @lastLightReading.
  ///
  /// In en, this message translates to:
  /// **'Last Light Reading'**
  String get lastLightReading;

  /// No description provided for @lastHealthAssessment.
  ///
  /// In en, this message translates to:
  /// **'LAST HEALTH ASSESSMENT'**
  String get lastHealthAssessment;

  /// No description provided for @newGrowthDetected.
  ///
  /// In en, this message translates to:
  /// **'New growth detected!'**
  String get newGrowthDetected;

  /// No description provided for @issuesDetected.
  ///
  /// In en, this message translates to:
  /// **'Issues detected'**
  String get issuesDetected;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @healthCases.
  ///
  /// In en, this message translates to:
  /// **'Health Cases'**
  String get healthCases;

  /// No description provided for @viewFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'View Family Tree'**
  String get viewFamilyTree;

  /// No description provided for @createTimeLapse.
  ///
  /// In en, this message translates to:
  /// **'Create Time-lapse'**
  String get createTimeLapse;

  /// No description provided for @watchPlantGrowOverTime.
  ///
  /// In en, this message translates to:
  /// **'Watch your plant grow over time'**
  String get watchPlantGrowOverTime;

  /// No description provided for @listForSwapEmoji.
  ///
  /// In en, this message translates to:
  /// **'List for Swap 🔄'**
  String get listForSwapEmoji;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @noUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks.'**
  String get noUpcomingTasks;

  /// No description provided for @careGuideFromWiki.
  ///
  /// In en, this message translates to:
  /// **'Care Guide from Wiki'**
  String get careGuideFromWiki;

  /// No description provided for @communityDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Community Discussions'**
  String get communityDiscussions;

  /// No description provided for @seeAllDiscussions.
  ///
  /// In en, this message translates to:
  /// **'See all discussions'**
  String get seeAllDiscussions;

  /// No description provided for @growthHistory.
  ///
  /// In en, this message translates to:
  /// **'Growth History'**
  String get growthHistory;

  /// No description provided for @noGrowthHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No growth history yet.'**
  String get noGrowthHistoryYet;

  /// No description provided for @journalEntry.
  ///
  /// In en, this message translates to:
  /// **'JOURNAL ENTRY'**
  String get journalEntry;

  /// No description provided for @propagatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Propagated from {name}'**
  String propagatedFrom(String name);

  /// No description provided for @propagationsFromThisPlant.
  ///
  /// In en, this message translates to:
  /// **'🪴 {count} propagations from this plant'**
  String propagationsFromThisPlant(int count);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @plants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plants;

  /// No description provided for @settingsHeader.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsHeader;

  /// No description provided for @myBadgesAndLevel.
  ///
  /// In en, this message translates to:
  /// **'My Badges and Level'**
  String get myBadgesAndLevel;

  /// No description provided for @myCity.
  ///
  /// In en, this message translates to:
  /// **'My City'**
  String get myCity;

  /// No description provided for @tapToSetYourCity.
  ///
  /// In en, this message translates to:
  /// **'Tap to set your city'**
  String get tapToSetYourCity;

  /// No description provided for @cityHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g. London, Tokyo, New York'**
  String get cityHintText;

  /// No description provided for @citySetTo.
  ///
  /// In en, this message translates to:
  /// **'City set to {city} ️'**
  String citySetTo(String city);

  /// No description provided for @plantHistory.
  ///
  /// In en, this message translates to:
  /// **'Plant History'**
  String get plantHistory;

  /// No description provided for @myCollectionPersonality.
  ///
  /// In en, this message translates to:
  /// **'My Collection Personality'**
  String get myCollectionPersonality;

  /// No description provided for @aboutHeader.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutHeader;

  /// No description provided for @digitalConservatoryVersion.
  ///
  /// In en, this message translates to:
  /// **'Digital Conservatory v1.0.0'**
  String get digitalConservatoryVersion;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// No description provided for @welcomeToVerdoro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flora'**
  String get welcomeToVerdoro;

  /// No description provided for @joinFloraStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Join Flora and start your plant journey.'**
  String get joinFloraStartJourney;

  /// No description provided for @signInToYourCollection.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your plant collection.'**
  String get signInToYourCollection;

  /// No description provided for @yourPersonalPlantCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your personal plant companion.'**
  String get yourPersonalPlantCompanion;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @dontHaveAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccountSignUp;

  /// No description provided for @alreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccountSignIn;

  /// No description provided for @byAgreeingTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy.'**
  String get byAgreeingTermsPrivacy;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get pleaseEnterYourPassword;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get pleaseEnterYourName;

  /// No description provided for @passwordMinSixChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinSixChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @connectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check your internet and try again.'**
  String get connectionTimedOut;

  /// No description provided for @welcomeToVerdoroSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flora! Your garden awaits.'**
  String get welcomeToVerdoroSnackbar;

  /// No description provided for @noInternetCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get noInternetCheckNetwork;

  /// No description provided for @emailLooksInvalid.
  ///
  /// In en, this message translates to:
  /// **'That email address looks invalid.'**
  String get emailLooksInvalid;

  /// No description provided for @noAccountFoundTryCreating.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Try creating one!'**
  String get noAccountFoundTryCreating;

  /// No description provided for @incorrectEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get incorrectEmailOrPassword;

  /// No description provided for @accountExistsWithEmail.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email. Try signing in!'**
  String get accountExistsWithEmail;

  /// No description provided for @passwordTooWeakSixChars.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get passwordTooWeakSixChars;

  /// No description provided for @anErrorOccurredTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get anErrorOccurredTryAgain;

  /// No description provided for @letsSetUpYourGarden.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your garden'**
  String get letsSetUpYourGarden;

  /// No description provided for @whatShouldWeCallYou.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get whatShouldWeCallYou;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get letsGo;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String errorSavingProfile(String error);

  /// No description provided for @noPreviousChats.
  ///
  /// In en, this message translates to:
  /// **'No previous chats.'**
  String get noPreviousChats;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat?'**
  String get deleteChatTitle;

  /// No description provided for @thisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get thisCannotBeUndone;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @pleaseSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first.'**
  String get pleaseSignInFirst;

  /// No description provided for @hiImFlora.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Flora'**
  String get hiImFlora;

  /// No description provided for @floraChatIntro.
  ///
  /// In en, this message translates to:
  /// **'Your AI plant consultant. Ask me anything about your plants — or just say hello.'**
  String get floraChatIntro;

  /// No description provided for @askFloraAnythingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora anything…'**
  String get askFloraAnythingEllipsis;

  /// No description provided for @aiErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'AI Error: {error}'**
  String aiErrorPrefix(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @plantLover.
  ///
  /// In en, this message translates to:
  /// **'Plant Lover'**
  String get plantLover;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editNameTitle;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @dailyCareReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Care Reminder'**
  String get dailyCareReminder;

  /// No description provided for @careTasksToggle.
  ///
  /// In en, this message translates to:
  /// **'Care Tasks'**
  String get careTasksToggle;

  /// No description provided for @verdoroChatMessages.
  ///
  /// In en, this message translates to:
  /// **'Flora Chat Messages'**
  String get verdoroChatMessages;

  /// No description provided for @swapMarketMessages.
  ///
  /// In en, this message translates to:
  /// **'Swap Market Messages'**
  String get swapMarketMessages;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlist;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account, plants, chats, and swap listings. This cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String failedToDeleteAccount(String error);

  /// No description provided for @myWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlistTitle;

  /// No description provided for @wishlistIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty.'**
  String get wishlistIsEmpty;

  /// No description provided for @explorePlantWiki.
  ///
  /// In en, this message translates to:
  /// **'Explore Plant Wiki'**
  String get explorePlantWiki;

  /// No description provided for @whatAreYouOffering.
  ///
  /// In en, this message translates to:
  /// **'What are you offering?'**
  String get whatAreYouOffering;

  /// No description provided for @cuttingChip.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get cuttingChip;

  /// No description provided for @seedsChip.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsChip;

  /// No description provided for @wholePlantChip.
  ///
  /// In en, this message translates to:
  /// **'Whole Plant'**
  String get wholePlantChip;

  /// No description provided for @thisItemIsFree.
  ///
  /// In en, this message translates to:
  /// **'This item is free'**
  String get thisItemIsFree;

  /// No description provided for @titleHintSwap.
  ///
  /// In en, this message translates to:
  /// **'e.g. Variegated Monstera Cutting'**
  String get titleHintSwap;

  /// No description provided for @descriptionHintSwap.
  ///
  /// In en, this message translates to:
  /// **'Describe the condition, size, or what you want in exchange...'**
  String get descriptionHintSwap;

  /// No description provided for @cityField.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityField;

  /// No description provided for @cityHintSwap.
  ///
  /// In en, this message translates to:
  /// **'e.g. Seattle, WA'**
  String get cityHintSwap;

  /// No description provided for @detectLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Detect Location'**
  String get detectLocationTooltip;

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get postListing;

  /// No description provided for @listingPostedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing posted successfully!'**
  String get listingPostedSuccessfully;

  /// No description provided for @failedToPostListing.
  ///
  /// In en, this message translates to:
  /// **'Failed to post listing: {error}'**
  String failedToPostListing(String error);

  /// No description provided for @couldNotDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not detect location: {error}'**
  String couldNotDetectLocation(String error);

  /// No description provided for @fillInAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get fillInAllRequiredFields;

  /// No description provided for @listingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Listing not found.'**
  String get listingNotFound;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeLabel;

  /// No description provided for @completedBadge.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedBadge;

  /// No description provided for @descriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHeader;

  /// No description provided for @listedByHeader.
  ///
  /// In en, this message translates to:
  /// **'Listed By'**
  String get listedByHeader;

  /// No description provided for @messageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageAction;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @listingMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Listing marked as completed ✅'**
  String get listingMarkedCompleted;

  /// No description provided for @deleteListingAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListingAction;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @cuttingLabel.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get cuttingLabel;

  /// No description provided for @seedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsLabel;

  /// No description provided for @wholePlantLabel.
  ///
  /// In en, this message translates to:
  /// **'Whole Plant'**
  String get wholePlantLabel;

  /// No description provided for @tradePlantsNearby.
  ///
  /// In en, this message translates to:
  /// **'Trade plants with people nearby.'**
  String get tradePlantsNearby;

  /// No description provided for @findingNearbyPlants.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby plants...'**
  String get findingNearbyPlants;

  /// No description provided for @showingListingsNear.
  ///
  /// In en, this message translates to:
  /// **'Showing listings near {city}'**
  String showingListingsNear(String city);

  /// No description provided for @nothingNearbyYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby yet'**
  String get nothingNearbyYet;

  /// No description provided for @beFirstToShareInArea.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share in your area!'**
  String get beFirstToShareInArea;

  /// No description provided for @listAPlant.
  ///
  /// In en, this message translates to:
  /// **'List a plant'**
  String get listAPlant;

  /// No description provided for @nearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyLabel;

  /// No description provided for @yourListingBadge.
  ///
  /// In en, this message translates to:
  /// **'Your Listing'**
  String get yourListingBadge;

  /// No description provided for @freeFilter.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeFilter;

  /// No description provided for @speciesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Species not found.'**
  String get speciesNotFound;

  /// No description provided for @myCollection.
  ///
  /// In en, this message translates to:
  /// **'My Collection'**
  String get myCollection;

  /// No description provided for @sunLabel.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunLabel;

  /// No description provided for @feedLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedLabel;

  /// No description provided for @lightTab.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTab;

  /// No description provided for @waterTab.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterTab;

  /// No description provided for @humidityTab.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityTab;

  /// No description provided for @soilTab.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soilTab;

  /// No description provided for @tempTab.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get tempTab;

  /// No description provided for @propagateTab.
  ///
  /// In en, this message translates to:
  /// **'Propagate'**
  String get propagateTab;

  /// No description provided for @noInfo.
  ///
  /// In en, this message translates to:
  /// **'No info'**
  String get noInfo;

  /// No description provided for @addToCollectionFab.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollectionFab;

  /// No description provided for @findNextGreenCompanion.
  ///
  /// In en, this message translates to:
  /// **'Find your next green companion.'**
  String get findNextGreenCompanion;

  /// No description provided for @searchByNameOrType.
  ///
  /// In en, this message translates to:
  /// **'Search by name or type…'**
  String get searchByNameOrType;

  /// No description provided for @noPlantsMatch.
  ///
  /// In en, this message translates to:
  /// **'No plants match'**
  String get noPlantsMatch;

  /// No description provided for @tryDifferentFilterOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term.'**
  String get tryDifferentFilterOrSearch;

  /// No description provided for @wikiFilterTropical.
  ///
  /// In en, this message translates to:
  /// **'Tropical'**
  String get wikiFilterTropical;

  /// No description provided for @wikiFilterSucculent.
  ///
  /// In en, this message translates to:
  /// **'Succulent'**
  String get wikiFilterSucculent;

  /// No description provided for @addGrowthEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Growth Entry'**
  String get addGrowthEntry;

  /// No description provided for @galleryAction.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryAction;

  /// No description provided for @noteField.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteField;

  /// No description provided for @howIsYourPlantDoing.
  ///
  /// In en, this message translates to:
  /// **'How is your plant doing?'**
  String get howIsYourPlantDoing;

  /// No description provided for @heightCmOptional.
  ///
  /// In en, this message translates to:
  /// **'Height (cm) — optional'**
  String get heightCmOptional;

  /// No description provided for @addPhotoNoteOrHeight.
  ///
  /// In en, this message translates to:
  /// **'Add a photo, note, or height to save.'**
  String get addPhotoNoteOrHeight;

  /// No description provided for @growthEntryAdded.
  ///
  /// In en, this message translates to:
  /// **'Growth entry added!'**
  String get growthEntryAdded;

  /// No description provided for @failedToSavePrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSavePrefix(String error);

  /// No description provided for @plantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plant not found'**
  String get plantNotFound;

  /// No description provided for @plantNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This plant no longer exists.'**
  String get plantNoLongerExists;

  /// No description provided for @editNicknameMenu.
  ///
  /// In en, this message translates to:
  /// **'Edit nickname'**
  String get editNicknameMenu;

  /// No description provided for @deletePlantMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete plant'**
  String get deletePlantMenu;

  /// No description provided for @heightStat.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightStat;

  /// No description provided for @entriesStat.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entriesStat;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYet;

  /// No description provided for @tapPlusToAddGrowthEntry.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first growth entry'**
  String get tapPlusToAddGrowthEntry;

  /// No description provided for @editNicknameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get editNicknameTitle;

  /// No description provided for @nicknameField.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameField;

  /// No description provided for @deletePlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plant?'**
  String get deletePlantTitle;

  /// No description provided for @deletePlantBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{name}\".'**
  String deletePlantBody(String name);

  /// No description provided for @healthyStatus.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthyStatus;

  /// No description provided for @needsCareStatus.
  ///
  /// In en, this message translates to:
  /// **'Needs care'**
  String get needsCareStatus;

  /// No description provided for @conservatoryIsThriving.
  ///
  /// In en, this message translates to:
  /// **'Your conservatory is thriving.'**
  String get conservatoryIsThriving;

  /// No description provided for @identifyAPlant.
  ///
  /// In en, this message translates to:
  /// **'Identify a Plant'**
  String get identifyAPlant;

  /// No description provided for @pointCameraAtAnyPlant.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any plant'**
  String get pointCameraAtAnyPlant;

  /// No description provided for @everythingsThrivingToday.
  ///
  /// In en, this message translates to:
  /// **'Everything\'s thriving today!'**
  String get everythingsThrivingToday;

  /// No description provided for @plantsAreHappyHealthy.
  ///
  /// In en, this message translates to:
  /// **'Your plants are happy and healthy.'**
  String get plantsAreHappyHealthy;

  /// No description provided for @noTasksScheduledForDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for this day.'**
  String get noTasksScheduledForDay;

  /// No description provided for @snoozeOneDay.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 day'**
  String get snoozeOneDay;

  /// No description provided for @snoozeThreeDays.
  ///
  /// In en, this message translates to:
  /// **'Snooze 3 days'**
  String get snoozeThreeDays;

  /// No description provided for @taskDoneNextScheduled.
  ///
  /// In en, this message translates to:
  /// **'{label} done! ✅ Next task scheduled.'**
  String taskDoneNextScheduled(String label);

  /// No description provided for @cameraAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required'**
  String get cameraAccessRequired;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get grantAccess;

  /// No description provided for @idSpeciesMode.
  ///
  /// In en, this message translates to:
  /// **'ID Species'**
  String get idSpeciesMode;

  /// No description provided for @detectDiseaseMode.
  ///
  /// In en, this message translates to:
  /// **'Detect Disease'**
  String get detectDiseaseMode;

  /// No description provided for @captureAndIdentify.
  ///
  /// In en, this message translates to:
  /// **'Capture & Identify'**
  String get captureAndIdentify;

  /// No description provided for @orPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'or pick from gallery'**
  String get orPickFromGallery;

  /// No description provided for @analyzingYourPlant.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your plant...'**
  String get analyzingYourPlant;

  /// No description provided for @failedToCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo'**
  String get failedToCapturePhoto;

  /// No description provided for @failedToIdentifyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to identify: {error}'**
  String failedToIdentifyPrefix(String error);

  /// No description provided for @pickAnIcon.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon'**
  String get pickAnIcon;

  /// No description provided for @plantNameAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Plant name *'**
  String get plantNameAsterisk;

  /// No description provided for @speciesVariety.
  ///
  /// In en, this message translates to:
  /// **'Species / variety'**
  String get speciesVariety;

  /// No description provided for @locationEgLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Location (e.g. Living room)'**
  String get locationEgLivingRoom;

  /// No description provided for @wateringFrequencyEg.
  ///
  /// In en, this message translates to:
  /// **'Watering frequency (e.g. Every 3 days)'**
  String get wateringFrequencyEg;

  /// No description provided for @addToMyGarden.
  ///
  /// In en, this message translates to:
  /// **'Add to my garden'**
  String get addToMyGarden;

  /// No description provided for @requiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidator;

  /// No description provided for @locationField.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationField;

  /// No description provided for @wateringFrequencyField.
  ///
  /// In en, this message translates to:
  /// **'Watering frequency'**
  String get wateringFrequencyField;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @sendMessageToStartSwapping.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start swapping!'**
  String get sendMessageToStartSwapping;

  /// Short format for minutes ago (e.g. 5m ago)
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgoShort(int count);

  /// Short format for hours ago (e.g. 3h ago)
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgoShort(int count);

  /// No description provided for @addGrowthPhotosForTimelapse.
  ///
  /// In en, this message translates to:
  /// **'Add more growth photos to create a time lapse — you need at least 2'**
  String get addGrowthPhotosForTimelapse;

  /// No description provided for @growthTimelapse.
  ///
  /// In en, this message translates to:
  /// **'Growth Time-lapse'**
  String get growthTimelapse;

  /// No description provided for @tapPhotosToViewJourney.
  ///
  /// In en, this message translates to:
  /// **'Tap photos to view your plant\'s journey'**
  String get tapPhotosToViewJourney;

  /// No description provided for @moveToMemorialGarden.
  ///
  /// In en, this message translates to:
  /// **'Move to Memorial Garden'**
  String get moveToMemorialGarden;

  /// No description provided for @leaveNoteAboutPlant.
  ///
  /// In en, this message translates to:
  /// **'Would you like to leave a note about {plantName}?'**
  String leaveNoteAboutPlant(String plantName);

  /// No description provided for @memorialNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Memorial note...'**
  String get memorialNoteHint;

  /// No description provided for @farewellToPlant.
  ///
  /// In en, this message translates to:
  /// **'A farewell to {plantName} ️'**
  String farewellToPlant(String plantName);

  /// No description provided for @thankYouForDaysOfCare.
  ///
  /// In en, this message translates to:
  /// **'Thank you for {days} days of care'**
  String thankYouForDaysOfCare(int days);

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @backArrow.
  ///
  /// In en, this message translates to:
  /// **'← Back'**
  String get backArrow;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @plantsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} plants need attention.'**
  String plantsNeedAttention(int count);

  /// No description provided for @plantsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Plants'**
  String plantsCountLabel(int count);

  /// No description provided for @startYourStreakToday.
  ///
  /// In en, this message translates to:
  /// **'Start your streak today'**
  String get startYourStreakToday;

  /// No description provided for @welcomeBackToYourSanctuary.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your sanctuary.'**
  String get welcomeBackToYourSanctuary;

  /// No description provided for @yourPlantsAssistantSanctuary.
  ///
  /// In en, this message translates to:
  /// **'Your plants, your assistant, your sanctuary.'**
  String get yourPlantsAssistantSanctuary;

  /// No description provided for @plantCareCompanion.
  ///
  /// In en, this message translates to:
  /// **'Plant care companion'**
  String get plantCareCompanion;

  /// No description provided for @viewAllSentenceCase.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllSentenceCase;

  /// No description provided for @postAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postAction;

  /// No description provided for @yourConservatoryIsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your conservatory is waiting'**
  String get yourConservatoryIsWaiting;

  /// No description provided for @swipeToSkip.
  ///
  /// In en, this message translates to:
  /// **'← Skip'**
  String get swipeToSkip;

  /// No description provided for @swipeToComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete →'**
  String get swipeToComplete;

  /// No description provided for @scientificNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Scientific name (optional)'**
  String get scientificNameOptional;

  /// No description provided for @askVerdoroShort.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora...'**
  String get askVerdoroShort;

  /// No description provided for @logCare.
  ///
  /// In en, this message translates to:
  /// **'Log Care'**
  String get logCare;

  /// No description provided for @askVerdoroCTA.
  ///
  /// In en, this message translates to:
  /// **'Ask Flora'**
  String get askVerdoroCTA;

  /// No description provided for @whatShouldICareForToday.
  ///
  /// In en, this message translates to:
  /// **'What should I care for today?'**
  String get whatShouldICareForToday;

  /// No description provided for @addAPlantFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a plant first'**
  String get addAPlantFirst;

  /// No description provided for @tourHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Home'**
  String get tourHomeTitle;

  /// No description provided for @tourHomeBody.
  ///
  /// In en, this message translates to:
  /// **'See what needs attention today — care tasks, streaks, and your plant health at a glance.'**
  String get tourHomeBody;

  /// No description provided for @tourGardenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Garden'**
  String get tourGardenTitle;

  /// No description provided for @tourGardenBody.
  ///
  /// In en, this message translates to:
  /// **'All your plants in one place. Tap a plant to see its full care history and health profile.'**
  String get tourGardenBody;

  /// No description provided for @tourFloraTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet Flora'**
  String get tourFloraTitle;

  /// No description provided for @tourFloraBody.
  ///
  /// In en, this message translates to:
  /// **'Your AI plant companion. Ask anything about your plants — care advice, diagnosis, or just plant chat.'**
  String get tourFloraBody;

  /// No description provided for @tourIdentifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Identify & Analyze'**
  String get tourIdentifyTitle;

  /// No description provided for @tourIdentifyBody.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any plant to identify it instantly or check its health with Flora\'s analysis.'**
  String get tourIdentifyBody;

  /// No description provided for @tourCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tourCommunityTitle;

  /// No description provided for @tourCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Share your plants, join care challenges, explore the wiki, and swap cuttings with other plant lovers.'**
  String get tourCommunityBody;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourStartExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get tourStartExploring;

  /// No description provided for @welcomeTourTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your Home'**
  String get welcomeTourTitle1;

  /// No description provided for @welcomeTourBody1.
  ///
  /// In en, this message translates to:
  /// **'See what needs attention today — care tasks, streaks, and your plant health at a glance.'**
  String get welcomeTourBody1;

  /// No description provided for @welcomeTourTitle2.
  ///
  /// In en, this message translates to:
  /// **'Your Garden'**
  String get welcomeTourTitle2;

  /// No description provided for @welcomeTourBody2.
  ///
  /// In en, this message translates to:
  /// **'All your plants in one place. Tap a plant to see its full care history and health profile.'**
  String get welcomeTourBody2;

  /// No description provided for @welcomeTourTitle3.
  ///
  /// In en, this message translates to:
  /// **'Meet Flora'**
  String get welcomeTourTitle3;

  /// No description provided for @welcomeTourBody3.
  ///
  /// In en, this message translates to:
  /// **'Your AI plant companion. Ask anything about your plants — care advice, diagnosis, or just plant chat.'**
  String get welcomeTourBody3;

  /// No description provided for @welcomeTourTitle4.
  ///
  /// In en, this message translates to:
  /// **'Identify & Analyze'**
  String get welcomeTourTitle4;

  /// No description provided for @welcomeTourBody4.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any plant to identify it instantly or check its health with Flora\'s analysis.'**
  String get welcomeTourBody4;

  /// No description provided for @welcomeTourTitle5.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get welcomeTourTitle5;

  /// No description provided for @welcomeTourBody5.
  ///
  /// In en, this message translates to:
  /// **'Share your plants, join care challenges, explore the wiki, and swap cuttings with other plant lovers.'**
  String get welcomeTourBody5;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get startExploring;

  /// No description provided for @detectAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get detectAutomatically;

  /// No description provided for @usesYourIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Uses your IP address'**
  String get usesYourIpAddress;

  /// No description provided for @askVerdoroAboutThis.
  ///
  /// In en, this message translates to:
  /// **'Ask Verdoro about this'**
  String get askVerdoroAboutThis;

  /// No description provided for @plantNameFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monstera'**
  String get plantNameFieldHint;

  /// No description provided for @recoveringStatus.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get recoveringStatus;

  /// No description provided for @ofCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String ofCounterLabel(String current, String total);

  /// No description provided for @couldNotGenerateCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Could not generate care plan'**
  String get couldNotGenerateCarePlan;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// No description provided for @addFirstPlantForPersonalizedPlan.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant to get a personalized plan'**
  String get addFirstPlantForPersonalizedPlan;

  /// No description provided for @showingCachedPlanRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Showing cached plan. Pull to refresh.'**
  String get showingCachedPlanRefreshHint;

  /// No description provided for @aiGeneratedForPlantsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'AI generated for your plants this week'**
  String get aiGeneratedForPlantsThisWeek;

  /// No description provided for @restDayNoTasksNeeded.
  ///
  /// In en, this message translates to:
  /// **'Rest day. No tasks needed.'**
  String get restDayNoTasksNeeded;

  /// No description provided for @unknownPlantFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown Plant'**
  String get unknownPlantFallback;

  /// No description provided for @chartMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get chartMaxLabel;

  /// No description provided for @chartMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get chartMinLabel;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedLabel;

  /// No description provided for @verdoroIsAnalyzingPlants.
  ///
  /// In en, this message translates to:
  /// **'Verdoro is analyzing your plants...'**
  String get verdoroIsAnalyzingPlants;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'sv',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
