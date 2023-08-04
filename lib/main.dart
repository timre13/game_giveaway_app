import 'package:flutter/material.dart';
import 'package:game_giveaways/list_widget.dart';

import 'api/api.dart' as api;

void main() {
  var theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.orange.shade700,
      secondary: Colors.deepOrange.shade500,
      background: Colors.grey.shade900,
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
            const GiveawayList(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Data is provided by ",
                      style: TextStyle(fontSize: 12)),
                  LinkWidget(
                      text: "GamerPower.com",
                      url: Uri.parse("https://www.gamerpower.com"),
                      fontSize: 12)
                ]),
              ),
            ),
          ])),
    );
  }
}

class GiveawayList extends StatefulWidget {
  const GiveawayList({Key? key}) : super(key: key);

  @override
  State<GiveawayList> createState() => _GiveawayListState();
}

class _GiveawayListState extends State<GiveawayList> {
  Future<List<api.Giveaway>> giveaways = api.getGiveaways();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: giveaways,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemBuilder: (context, index) =>
                    GiveawayWidget(snapshot.data![index]),
                itemCount: snapshot.data!.length);
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                    "Failed to get giveaways: ${(snapshot.error as Exception)}",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}

class GiveawayWidget extends StatefulWidget {
  const GiveawayWidget(this.giveaway, {Key? key}) : super(key: key);

  final api.Giveaway giveaway;

  @override
  State<GiveawayWidget> createState() => _GiveawayWidgetState();
}

class _GiveawayWidgetState extends State<GiveawayWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(children: [
          Image.network(widget.giveaway.thumbnail, width: 540),
          Text(widget.giveaway.title),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BorderedText(widget.giveaway.worth,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 0, 255, 0), fontSize: 12),
                      margin: const EdgeInsets.all(10)),
                  if (widget.giveaway.endDate != null &&
                      !widget.giveaway.remainingTime!.isNegative)
                    BorderedText(
                        "${formatDuration(widget.giveaway.remainingTime!)} left",
                        style: const TextStyle(
                            color: Color.fromARGB(255, 200, 200, 0),
                            fontSize: 12),
                        margin: const EdgeInsets.all(10)),
                  BorderedText(widget.giveaway.type,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 110, 110, 255),
                          fontSize: 12),
                      margin: const EdgeInsets.all(10)),
                ],
              ))
        ]));
  }
}

String formatDuration(Duration duration) {
  if (duration >= const Duration(days: 1)) {
    return "${(duration.inHours / 24.0).ceil()} days";
  }
  if (duration >= const Duration(hours: 1)) {
    return "${(duration.inMinutes / 60.0).ceil()} hours";
  }
  if (duration >= const Duration(minutes: 1)) {
    return duration.toString();
  }
  return "${duration.inSeconds} seconds";
}

class BorderedText extends StatelessWidget {
  const BorderedText(this.text, {Key? key, this.style, this.margin})
      : super(key: key);

  final String text;
  final TextStyle? style;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final color = style?.color ?? Theme.of(context).colorScheme.primary;

    return Card(
      color: color.withOpacity(0.1),
      margin: margin,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: color),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Text(text, style: style)),
    );
  }
}
