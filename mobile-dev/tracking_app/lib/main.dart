import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tracking_app/tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    print("✅ Loaded .env");
  } catch (e) {
    print("⚠️ Could not load .env: $e");
  }

  runApp(const TrackingApp());
}


class TrackingApp extends StatelessWidget {
  const TrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TrackingHomePage(),
    );
  }
}


class TrackingHomePage extends StatefulWidget {
  const TrackingHomePage({super.key});

  @override
  State<TrackingHomePage> createState() => _TrackingHomePageState();
}

class _TrackingHomePageState extends State<TrackingHomePage> {
  // Instantiate the service. It can be reused.
  final _trackingService = TrackingService();

  String selectedEvent = "screen-view"; // default option
  bool isLoading = false;
  String statusMessage = "";

  Future<void> sendEvent() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final result = await _trackingService.sendEvent(selectedEvent);

    // Check if the widget is still in the tree before calling setState.
    if (!mounted) return;

    setState(() {
      statusMessage = result.message;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedEvent,
              decoration: const InputDecoration(
                labelText: "Select Event Name",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "screen-view", child: Text("screen-view")),
                DropdownMenuItem(value: "stock-view", child: Text("stock-view")),
                DropdownMenuItem(value: "content-view", child: Text("content-view")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedEvent = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : sendEvent,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send"),
            ),
            const SizedBox(height: 20),
            Text(statusMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
