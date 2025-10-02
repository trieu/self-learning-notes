Tutorial: Getting Started with Dart & Flutter on Ubuntu 22.04 using VS CodeWelcome! This guide will walk you through the entire process of setting up your development environment and building your first mobile app with Flutter. We'll cover everything from installing the necessary tools to understanding the basics of the Dart programming language and finally, building a user interface.Part 1: Setting Up Your Development EnvironmentOur first goal is to get all the required software installed and configured on your Ubuntu machine.Step 1: Install Visual Studio CodeVS Code is a powerful, free code editor that has excellent support for Dart and Flutter development. The easiest way to install it on Ubuntu is using the Snap store.Open your terminal (Ctrl+Alt+T) and run this command:sudo snap install --classic code
Step 2: Install the Flutter SDKThe Flutter SDK includes everything you need to build apps, including the Dart SDK, so you don't need to install Dart separately. We'll use Snap for this as well, as it simplifies the installation and path configuration.In your terminal, run:sudo snap install flutter --classic
After the installation, you need to run the following command to let your system know where to find the flutter command:flutter sdk-path
This will output a path, for example: /home/your-username/snap/flutter/common/flutter. You don't need to add this to your .bashrc manually when using the snap installation, but it's good to know where it is.Step 3: Verify Your Installation with flutter doctorFlutter comes with a handy tool called flutter doctor that checks your environment and reports on the status of your installation. Run it now:flutter doctor
You will likely see some issues marked with an [!]. Don't worry, this is normal! Here’s how to fix the most common ones:Android toolchain: Flutter needs the Android SDK to build apps for Android. The easiest way to get this is to install Android Studio.sudo snap install android-studio --classic
Once installed, open Android Studio. It will guide you through a setup wizard which will download the necessary Android SDK components. You only need to do this once.Android licenses: After installing the Android toolchain, run the following command and accept all the license agreements by typing y and pressing Enter.flutter doctor --android-licenses
Chrome (for web development): If you want to build web apps with Flutter, install Google Chrome:wget [https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb](https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb)
sudo dpkg -i google-chrome-stable_current_amd64.deb
Run flutter doctor again. Once everything has a green checkmark [✓], you're ready to proceed!Step 4: Configure VS Code for FlutterNow, let's turn VS Code into a Flutter powerhouse.Open VS Code.Click on the Extensions icon in the activity bar on the left (or press Ctrl+Shift+X).In the search bar, type Flutter.Find the official extension named Flutter (usually the first result, from Dart Code) and click Install.Installing this extension will automatically install the Dart extension as well, giving you everything you need, including syntax highlighting, code completion, and debugging tools.Part 2: Learning Dart FundamentalsBefore diving into Flutter, it's essential to understand the basics of the Dart language.Let's create a simple project to practice.Create a folder for your practice code: mkdir ~/dart_practice && cd ~/dart_practiceCreate a file named main.dart: touch main.dartOpen this folder in VS Code: code .Now, add the following code to main.dart:// The main function is the entry point for all Dart apps.
void main() {
  // 1. Variables and Data Types
  String name = "World";    // Text
  int year = 2025;          // Integers
  double temperature = 28.5;  // Decimals
  bool isLearning = true;   // True or false

  print("Hello, $name!"); // String interpolation lets you use variables in strings
  print("Welcome to $year. The temperature is ${temperature}°C.");

  // 2. Collections (Lists and Maps)
  // A List is an ordered collection of items (like an array).
  List<String> fruits = ['Apple', 'Banana', 'Orange'];
  print("My favorite fruit is ${fruits[0]}."); // Access items by index

  // A Map is a collection of key-value pairs.
  Map<String, String> user = {
    'name': 'Alex',
    'profession': 'Developer'
  };
  print("${user['name']} is a ${user['profession']}.");

  // 3. Functions
  // Functions group code to perform a specific task.
  greetUser("Maria");

  // 4. Control Flow (if/else and loops)
  if (isLearning) {
    print("Keep going!");
  }

  for (String fruit in fruits) {
    print("I like to eat $fruit.");
  }
}

// A simple function that takes a String argument.
void greetUser(String username) {
  print("Hello, $username! Welcome to the app.");
}
To run this code, open the integrated terminal in VS Code (`Ctrl+``) and type:dart run main.dart
Play around with this file to get comfortable with the basic syntax.Part 3: Building Your First Flutter AppNow for the exciting part! We'll build a simple app that displays a static list of stocks, inspired by the UI you provided.Step 1: Create a New Flutter Project in VS CodeOpen the Command Palette: Ctrl+Shift+P.Type Flutter: New Project.Select Application.Choose a folder to save your project in (e.g., your Home or Documents folder).Give your project a name, like stock_tracker_app. Note: Project names must be in snake_case.VS Code will create a new Flutter project and open it. The most important file is lib/main.dart.Step 2: Run the Default AppBefore we write any code, let's run the starter app.In the bottom-right corner of the VS Code status bar, click where it says No Device.Select a device to run on. You can choose Chrome (web) for the quickest start, or Start Android Emulator if you have one configured.Press F5 (or go to Run > Start Debugging).After a moment, you'll see a simple counter application. This confirms your setup is working perfectly. Try clicking the + button—notice how the app updates instantly? That's Flutter's Hot Reload, and it's one of the features that makes development so fast and enjoyable.Step 3: Build the Stock List UINow, delete all the code in lib/main.dart and replace it with the following. We'll build it up piece by piece, with comments explaining each part.import 'package:flutter/material.dart';

// The main() function is the entry point for our Flutter app.
void main() {
  // runApp() inflates the given widget and attaches it to the screen.
  runApp(const StockTrackerApp());
}

// This is the root widget of our application.
// It's a StatelessWidget because its properties don't change over time.
class StockTrackerApp extends StatelessWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is a widget that wraps a number of apps that are
    // designed to be Material Design applications.
    return MaterialApp(
      title: 'Stock Tracker',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // A light grey background
      ),
      home: const StockListScreen(), // The main screen of our app
    );
  }
}

// This widget represents the main screen of our application.
class StockListScreen extends StatelessWidget {
  const StockListScreen({super.key});

  // A list of mock data to display. In a real app, this would come from an API.
  final List<Map<String, dynamic>> stockData = const [
    {'symbol': 'AAPL', 'company': 'Apple Inc.', 'price': 182.54, 'change': 1.24},
    {'symbol': 'MSFT', 'company': 'Microsoft Corporation', 'price': 318.21, 'change': -2.10},
    {'symbol': 'TSLA', 'company': 'Tesla Inc.', 'price': 256.78, 'change': 5.32},
    {'symbol': 'AMZN', 'company': 'Amazon.com, Inc.', 'price': 134.56, 'change': -0.86},
    {'symbol': 'GOOGL', 'company': 'Alphabet Inc.', 'price': 142.33, 'change': 1.45},
  ];

  @override
  Widget build(BuildContext context) {
    // Scaffold implements the basic material design visual layout structure.
    return Scaffold(
      // The AppBar at the top of the screen.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        title: const Text(
          'Market Overview',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      // The body of the screen.
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0), // Add some padding around the list
        itemCount: stockData.length, // The number of items in the list
        // itemBuilder builds each item in the list on demand.
        itemBuilder: (BuildContext context, int index) {
          // Get the data for the current stock.
          final stock = stockData[index];
          // Use our custom widget to display the stock info.
          return StockListItem(
            symbol: stock['symbol'],
            company: stock['company'],
            price: stock['price'],
            change: stock['change'],
          );
        },
      ),
    );
  }
}


// A custom, reusable widget to display information for a single stock.
class StockListItem extends StatelessWidget {
  const StockListItem({
    super.key,
    required this.symbol,
    required this.company,
    required this.price,
    required this.change,
  });

  final String symbol;
  final String company;
  final double price;
  final double change;

  @override
  Widget build(BuildContext context) {
    // A Card with a slight shadow and rounded corners.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          // mainAxisAlignment spreads out the children across the row.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // A Column to hold the symbol and company name.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4), // A small space between texts
                Text(
                  company,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            // A Column to hold the price and change.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  change.toStringAsFixed(2),
                  // Conditionally set the color based on the change value.
                  style: TextStyle(
                    color: change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Step 4: Run Your New App!Press F5 in VS Code. Your app will rebuild, and you should now see a clean, scrollable list of stocks.Try changing a value in the stockData list and saving the file. You'll see the UI update instantly thanks to Hot Reload!Congratulations and Next StepsYou've successfully set up your Flutter development environment, learned the fundamentals of Dart, and built your very first Flutter application. This is a huge accomplishment!From here, you can continue your journey by exploring:More Widgets: Discover Flutter's vast widget catalog to build more complex layouts. Check out the Flutter Widget Catalog.State Management: Learn how to manage app state as your applications grow more complex.User Input: Add TextField widgets and buttons to make your apps interactive.Networking: Use packages like http to fetch live data from a real API over the internet.Happy coding!