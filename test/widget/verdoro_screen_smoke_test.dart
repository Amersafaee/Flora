import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdoro/screens/verdoro_screen.dart';
import 'package:verdoro/services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'verdoro_screen_smoke_test.mocks.dart';

@GenerateMocks([GeminiService, FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot])
void main() {
  group('Verdoro Screen Smoke Tests', () {
    late MockGeminiService mockGeminiService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDoc;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockGeminiService = MockGeminiService();
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDoc = MockDocumentReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection(any)).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDoc);
      when(mockDoc.collection(any)).thenReturn(mockCollection);
      when(mockCollection.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockCollection);
      
      // We need to return a stream of snapshots for the messages listener
      when(mockCollection.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: Scaffold(
          body: VerdoroScreen(
            conversationId: 'test_conv',
            geminiService: mockGeminiService,
            firestore: mockFirestore,
          ),
        ),
      );
    }

    testWidgets('VerdoroScreen can be built without throwing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(VerdoroScreen), findsOneWidget);
    });

    testWidgets('Send button is disabled when text field is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(seconds: 3));

      final sendButtonContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byWidgetPredicate((widget) => widget is Container && widget.child is Icon && (widget.child as Icon).icon == Icons.send)
        ).first
      );
      
      final decoration = sendButtonContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFCCCCCC)); // Disabled color
    });

    testWidgets('Send button is enabled when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(seconds: 3));

      await tester.enterText(find.byType(TextField), 'Hello Verdoro');
      await tester.pump(const Duration(milliseconds: 300));

      final sendButtonContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byWidgetPredicate((widget) => widget is Container && widget.child is Icon && (widget.child as Icon).icon == Icons.send)
        ).first
      );
      
      final decoration = sendButtonContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF154212)); // Enabled color
    });

    testWidgets('Suggested question chips are visible when no messages exist', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('How often should I water my Monstera'), findsOneWidget);
      expect(find.text('Why are my plant leaves turning yellow'), findsOneWidget);
      expect(find.text('What plants are good for low light'), findsOneWidget);
      expect(find.text('How do I repot a plant'), findsOneWidget);
    });
  });
}
