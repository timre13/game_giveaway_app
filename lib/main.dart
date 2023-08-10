import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_giveaways/link_widget.dart';
import 'package:url_launcher/url_launcher.dart';

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
  api.Platform? _platformFilter;
  api.GiveawayType? _typeFilter;

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
            Row(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onBackground),
                        borderRadius: BorderRadius.circular(5)),
                    child: DropdownButton(
                        underline: Container(),
                        value: _platformFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("All Platforms")),
                          ...api.Platform.values
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e.getDisplayName())))
                              .toList(growable: false)
                        ],
                        onChanged: (value) {
                          setState(() {
                            _platformFilter = value;
                          });
                        })),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onBackground),
                        borderRadius: BorderRadius.circular(5)),
                    child: DropdownButton(
                        underline: Container(),
                        value: _typeFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("All Types")),
                          ...api.GiveawayType.values
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e.getDisplayName())))
                              .toList(growable: false)
                        ],
                        onChanged: (value) {
                          setState(() {
                            _typeFilter = value;
                          });
                        })),
              ],
            ),
            Padding(
                padding: const EdgeInsets.only(top: 60),
                child: GiveawayList(
                    platformFilter: _platformFilter, typeFilter: _typeFilter)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Theme.of(context).colorScheme.background,
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
  const GiveawayList(
      {Key? key, required this.platformFilter, required this.typeFilter})
      : super(key: key);

  final api.Platform? platformFilter;
  final api.GiveawayType? typeFilter;

  @override
  State<GiveawayList> createState() => _GiveawayListState();
}

class _GiveawayListState extends State<GiveawayList> {
  @override
  Widget build(BuildContext context) {
    Future<List<api.Giveaway>> giveaways = api.getGiveaways(
        platform: widget.platformFilter, type: widget.typeFilter);
    return FutureBuilder(
        future: giveaways,
        builder: (context, snapshot) {
          Widget child;
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              child = const Center(child: CircularProgressIndicator());
              break;
            default:
              if (snapshot.hasError) {
                child = LayoutBuilder(builder: (context, constraints) {
                  return ListView(children: [
                    SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                            child: Text(
                                "Failed to get giveaways:\n${api.getExceptionMessage(snapshot.error as Exception)}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))))
                  ]);
                });
              } else {
                child = ListView.builder(
                    itemBuilder: (context, index) =>
                        GiveawayWidget(snapshot.data![index]),
                    itemCount: snapshot.data!.length);
              }
              break;
          }

          return RefreshIndicator(
              child: child,
              onRefresh: () async {
                // This way the pull down spinner will be shown while doing work
                try {
                  List<api.Giveaway> results = await api.getGiveaways();
                  giveaways = Future.value(results);
                } catch (e) {
                  giveaways = Future.error(e);
                }

                setState(() {
                  giveaways = giveaways;
                });
              });
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
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: () => openGiveaway(context, widget.giveaway),
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(children: [
                Image.network(widget.giveaway.thumbnail),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(widget.giveaway.title,
                        textAlign: TextAlign.center)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BorderedText(widget.giveaway.worth,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 0, 255, 0),
                              fontSize: 12)),
                      if (widget.giveaway.endDate != null &&
                          !widget.giveaway.remainingTime!.isNegative)
                        BorderedText(
                            "${formatDuration(widget.giveaway.remainingTime!)} left",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 200, 200, 0),
                                fontSize: 12)),
                      BorderedText(widget.giveaway.type,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 110, 110, 255),
                              fontSize: 12)),
                    ])
              ])),
        ));
  }
}

void openGiveaway(context, api.Giveaway giveaway) {
  if (kDebugMode) {
    print("Opening giveaway: ${giveaway.id}");
  }

  showGeneralDialog(
    context: context,
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        Transform.translate(
            offset: Offset(
                0,
                (1 - animation.value) *
                        (MediaQuery.of(context).size.height -
                            MediaQuery.of(context).viewPadding.top) +
                    MediaQuery.of(context).viewPadding.top),
            child: child),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Material(
          child: Column(children: [
        Image.network(giveaway.image, height: 215),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(giveaway.title,
                  style: Theme.of(context).textTheme.titleMedium),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                BorderedText("Worth: ${giveaway.worth}",
                    style:
                        const TextStyle(color: Color.fromARGB(255, 0, 255, 0))),
                if (giveaway.endDate != null &&
                    !giveaway.remainingTime!.isNegative)
                  BorderedText(
                      "${formatDuration(giveaway.remainingTime!)} left",
                      style: const TextStyle(
                          color: Color.fromARGB(255, 200, 200, 0))),
                BorderedText("Type: ${giveaway.type}",
                    style: const TextStyle(
                        color: Color.fromARGB(255, 110, 110, 255))),
              ]),
              Wrap(
                children: giveaway.platforms
                    .split(", ")
                    .map((e) => BorderedText(e,
                        style: TextStyle(color: Colors.purple.shade400)))
                    .toList(growable: false),
              ),
              BorderedText("Claimed by: ${giveaway.users}+",
                  style: const TextStyle(color: Colors.blue)),
              const Divider(),
              SizedBox(
                  height: 350,
                  child: Stack(alignment: Alignment.topCenter, children: [
                    ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          Text(giveaway.description,
                              textAlign: TextAlign.justify),
                          const Divider(),
                          const Text("Instructions:"),
                          Text("${giveaway.instructions}\n",
                              textAlign: TextAlign.justify),
                        ]),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                            height: 30,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Color(0x00212121),
                                  Color(0xff212121)
                                ])))),
                  ]))
            ])),
        Padding(
            padding: const EdgeInsets.only(top: 20),
            child: FilledButton(
                onPressed: () => launchUrl(Uri.parse(giveaway.openGiveawayUrl)),
                child: Text("Claim",
                    style: Theme.of(context).textTheme.bodyLarge)))
      ]));
    },
  );
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
