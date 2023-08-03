import 'package:flutter/material.dart';
import 'package:game_giveaways/list_widget.dart';

void main() {
  var theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.orange.shade700,
      secondary: Colors.deepOrange.shade500,
      background: Colors.grey.shade900,
      surface: Colors.grey.shade800,
      error: Colors.red.shade800,
      onPrimary: Colors.orange.shade100,
      onSecondary: Colors.deepOrange.shade100,
      onBackground: Colors.grey,
    ),
  );
  runApp(App(theme: theme));
}

class App extends StatelessWidget {
  const App({super.key, required this.theme});

  final ThemeData theme;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Game Giveaways",
      theme: theme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("Game Giveaways"),
      ),
      body: DefaultTextStyle(
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          child: Stack(children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Data is provided by "),
                  LinkWidget(
                      text: "GamerPower.com",
                      url: Uri.parse("https://www.gamerpower.com"))
                ]),
              ),
            ),
          ])),
    );
  }
}
