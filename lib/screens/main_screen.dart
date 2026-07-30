import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import '../services/speech_service.dart';
import '../services/query_parser.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SpeechService _speechService = SpeechService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initVoiceTriggerListening();
  }

  void _initVoiceTriggerListening() {
    // This would be enhanced to listen for voice triggers in the background
    // For MVP, voice triggers work when actively recording
  }

  void _switchToResultsTab() {
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeScreen(onVoiceTrigger: _switchToResultsTab),
          const ResultsScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).primaryColor,
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Voice'),
            Tab(icon: Icon(Icons.list), text: 'Results'),
          ],
        ),
      ),
    );
  }
}
