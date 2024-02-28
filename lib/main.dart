import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prayer_counter/color_schemes.g.dart';
import 'package:prayer_counter/prayers_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings.dart';

String boxName = 'prayersBox';
String boxName2 = 'fastingBox';
String settingsBox = 'settings';
String peopleBox = 'peopleBox';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter<Prayer>(PrayerAdapter());
  await Hive.openBox<Prayer>(boxName);
  await Hive.openBox<Prayer>(boxName2);
  await Hive.openBox(settingsBox);
  await Hive.openBox(peopleBox);

  runApp(const MyApp());
}

List<String> colorSchemes = [
  "Purple",
  "Baige",
  "Red",
  "Blue",
  "Grey",
  "Green",
  "Device"
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TheThemeProvider themeChangeProvider = TheThemeProvider();
  ThemeColorProvider colorChangeProvider = ThemeColorProvider();

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
    getCurrentColorTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.fontSize =
        await themeChangeProvider.preference.getFontSize();
    themeChangeProvider.darkTheme =
        await themeChangeProvider.preference.getTheme();
    themeChangeProvider.language =
        await themeChangeProvider.preference.getUILanguage();
  }

  void getCurrentColorTheme() async {
    colorChangeProvider.colorTheme =
        await colorChangeProvider.colorThemePreference.getThemeColor();
  }

  ColorScheme colorSchemeChooser(int color, bool darkMode,
      {ColorScheme? deviceLightColorTheme, ColorScheme? deviceDarkColorTheme}) {
    switch (colorSchemes[color]) {
      case "Purple":
        return darkMode ? purpleDarkColorScheme : purpleLightColorScheme;
      case "Baige":
        return darkMode ? baigeDarkColorScheme : baigeLightColorScheme;
      case "Red":
        return darkMode ? redDarkColorScheme : redLightColorScheme;
      case "Grey":
        return darkMode ? greyDarkColorScheme : greyLightColorScheme;
      case "Green":
        return darkMode ? greenDarkColorScheme : greenLightColorScheme;
      case "Blue":
        return darkMode ? blueDarkColorScheme : blueLightColorScheme;
      case "Device":
        return darkMode
            ? (deviceDarkColorTheme ?? blueDarkColorScheme)
            : (deviceLightColorTheme ?? blueLightColorScheme);
    }
    return darkMode ? blueDarkColorScheme : blueLightColorScheme;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<TheThemeProvider>(
        builder: (BuildContext context, value, _) => DynamicColorBuilder(
          builder: (deviceLightColorScheme, deviceDarkColorScheme) =>
              ChangeNotifierProvider(
            create: (_) => colorChangeProvider,
            child: Consumer<ThemeColorProvider>(
              builder: (BuildContext context, value, change) => MaterialApp(
                title: 'عداد القضاء',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  AppLocalizations.delegate, // Add this line
                ],
                supportedLocales: [
                  Locale('en'),
                  Locale('ar'),
                ],
                locale: Locale(themeChangeProvider.language),
                theme: ThemeData(
                  textTheme: textTheme,
                  colorScheme: colorSchemeChooser(
                      colorChangeProvider.colorTheme, false,
                      deviceLightColorTheme: deviceLightColorScheme,
                      deviceDarkColorTheme: deviceDarkColorScheme),
                  useMaterial3: true,
                ),
                darkTheme: ThemeData(
                  textTheme: textTheme,
                  colorScheme: colorSchemeChooser(
                      colorChangeProvider.colorTheme, true,
                      deviceLightColorTheme: deviceLightColorScheme,
                      deviceDarkColorTheme: deviceDarkColorScheme),
                  useMaterial3: true,
                ),
                themeMode: themeChangeProvider.darkTheme
                    ? ThemeMode.dark
                    : ThemeMode.light,
                initialRoute: "/",
                routes: {
                  "/": (context) => Directionality(
                      textDirection: themeChangeProvider.language == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: MyHomePage()),
                  "/people": (context) => Directionality(
                      textDirection: themeChangeProvider.language == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: PeoplePage()),
                  "/settings": (context) => Directionality(
                      textDirection: themeChangeProvider.language == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: SettingsPage()),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorToHex on Color {
  String get toHex {
    return "#${value.toRadixString(16).substring(2)}";
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _personNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<TheThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.personSelector),
          centerTitle: true),
      body: ValueListenableBuilder(
          valueListenable: Hive.box(peopleBox).listenable(),
          builder: (context, box, _) {
            if (box.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.noPeople));
            }

            return ListView.builder(
                itemCount: box.values.length,
                itemBuilder: (context, index) {
                  var person = box.getAt(index);
                  // debugPrint("person: $person");
                  return Slidable(
                    key: const ValueKey(0),
                    enabled: person != 'ME',
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            label: AppLocalizations.of(context)!.delete,
                            icon: Icons.delete_outline_outlined,
                            onPressed: (context) async {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Directionality(
                                      textDirection:
                                          themeChangeProvider.language == 'ar'
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                      child: AlertDialog(
                                        icon:
                                            Icon(Icons.delete_forever_outlined),
                                        title: Text(AppLocalizations.of(
                                                context)!
                                            .titleDeletePersonMessage(person)),
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .contentDeletePersonMessage,
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .cancel)),
                                          ElevatedButton(
                                              onPressed: () async {
                                                await box.deleteAt(index);
                                                final myBox =
                                                    await Hive.box<Prayer>(
                                                        boxName);
                                                final personName =
                                                    themeChangeProvider
                                                        .personName;

                                                // 1. Query and delete (recommended):
                                                await myBox.deleteAll(myBox.keys
                                                    .where((key) =>
                                                        myBox
                                                            .get(key)
                                                            ?.whichPerson ==
                                                        personName)
                                                    .toList());

                                                themeChangeProvider.personName =
                                                    'ME';
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .delete)),
                                        ],
                                      ),
                                    );
                                  });
                            }),
                      ],
                    ),
                    child: RadioListTile(
                        title: Text(
                            person == "ME" &&
                                    themeChangeProvider.language == 'ar'
                                ? 'نفسي'
                                : person,
                            style: TextStyle(fontSize: 24)),
                        value: person,
                        groupValue: themeChangeProvider.personName,
                        onChanged: (newValue) {
                          setState(() {
                            themeChangeProvider.personName = newValue;
                          });
                        }),
                  );
                });
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.person_add_alt),
        onPressed: () {
          _personNameController.text = "";
          showDialog(
              context: context,
              builder: (context) {
                return Directionality(
                  textDirection: themeChangeProvider.language == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.newPersonTitle),
                    content: TextField(
                      decoration: InputDecoration(
                          label: Text(AppLocalizations.of(context)!.personName),
                          border: OutlineInputBorder()),
                      controller: _personNameController,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.cancel)),
                      ElevatedButton(
                          onPressed: () async {
                            if (Hive.box(peopleBox)
                                .values
                                .contains(_personNameController.text.trim())) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Directionality(
                                      textDirection:
                                          themeChangeProvider.language == 'ar'
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                      child: AlertDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .errorAddingPersonTitle),
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .errorAddingPersonMessage),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .ok))
                                        ],
                                      ),
                                    );
                                  });
                            } else {
                              await Hive.box(peopleBox)
                                  .add(_personNameController.text.trim());
                              Navigator.pop(context);
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.add))
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<bool> isSelected = [];
  List<bool> getIsSelected(ThemeColorProvider colorProvider) {
    isSelected = [];
    for (String color in colorSchemes) {
      isSelected
          .add(colorSchemes[colorProvider.colorTheme] == color ? true : false);
    }
    return isSelected;
  }

  List<bool> isSelectedLanguage = [];
  List<bool> getIsSelectedLanguage(TheThemeProvider languageProvider) {
    isSelectedLanguage = [];
    List<String> languages = ['ar', 'en'];
    for (String language in languages) {
      isSelectedLanguage
          .add(languageProvider.language == language ? true : false);
    }
    return isSelectedLanguage;
  }

  String getPrayerName(String prayerName, BuildContext context) {
    switch (prayerName) {
      case 'الصبح':
        return AppLocalizations.of(context)!.morning;

      case 'الظهر':
        return AppLocalizations.of(context)!.noon;

      case 'العصر':
        return AppLocalizations.of(context)!.afternoon;

      case 'المغرب':
        return AppLocalizations.of(context)!.sunset;

      case 'العشاء':
        return AppLocalizations.of(context)!.night;

      default:
        return prayerName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<TheThemeProvider>(context);
    final colorChangeProvider = Provider.of<ThemeColorProvider>(context);
    isSelected = getIsSelected(colorChangeProvider);
    isSelectedLanguage = getIsSelectedLanguage(themeChangeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            bottom: TabBar(
              tabs: [
                Tab(
                    child: Text(AppLocalizations.of(context)!.prayers,
                        style:
                            TextStyle(fontSize: themeChangeProvider.fontSize))),
                Tab(
                    child: Text(AppLocalizations.of(context)!.fasting,
                        style:
                            TextStyle(fontSize: themeChangeProvider.fontSize))),
              ],
            ),
            actions: [
              Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      themeChangeProvider.personName == "ME" &&
                              themeChangeProvider.language == 'ar'
                          ? "نفسي"
                          : themeChangeProvider.personName,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer),
              IconButton(
                  onPressed: () async {
                    if (await Hive.box(peopleBox).values.contains('ME') ==
                        false) {
                      await Hive.box(peopleBox).add('ME');
                    }
                    Navigator.pushNamed(context, "/people");
                  },
                  icon: Icon(Icons.people_alt_outlined)),
              IconButton(
                  onPressed: () => Navigator.pushNamed(context, "/settings"),
                  icon: const Icon(Icons.settings_outlined))
            ],
            leading: IconButton(
                icon: const Icon(Icons.color_lens_outlined),
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) {
                        return Directionality(
                          textDirection: themeChangeProvider.language == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Scaffold(
                            appBar: AppBar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.background,
                                leading: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.close)),
                                centerTitle: true,
                                title: Text(
                                  AppLocalizations.of(context)!.appearance,
                                  style: TextStyle(
                                      fontSize:
                                          themeChangeProvider.fontSize + 5),
                                )),
                            body: Padding(
                              padding: const EdgeInsets.all(10),
                              child: ListView(shrinkWrap: true, children: [
                                SwitchListTile(
                                    title: Text(
                                        AppLocalizations.of(context)!.darkMode,
                                        style: TextStyle(
                                            fontSize:
                                                themeChangeProvider.fontSize)),
                                    value: themeChangeProvider.darkTheme,
                                    onChanged: (bool value) {
                                      themeChangeProvider.darkTheme = value;
                                    }),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(context)!.themes,
                                  style: TextStyle(
                                      fontSize: themeChangeProvider.fontSize),
                                  textAlign:
                                      themeChangeProvider.language == 'ar'
                                          ? TextAlign.right
                                          : TextAlign.left,
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Center(
                                    child: ToggleButtons(
                                      selectedBorderColor:
                                          Theme.of(context).colorScheme.primary,
                                      borderWidth: 3,
                                      isSelected: isSelected,
                                      onPressed: (int index) {
                                        setState(() {
                                          for (int buttonIndex = 0;
                                              buttonIndex < isSelected.length;
                                              buttonIndex++) {
                                            if (buttonIndex == index) {
                                              isSelected[buttonIndex] = true;
                                              colorChangeProvider.colorTheme =
                                                  buttonIndex;
                                            } else {
                                              isSelected[buttonIndex] = false;
                                            }
                                          }
                                        });
                                      },
                                      children: <Widget>[
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                purpleLightColorScheme,
                                            darkColorScheme:
                                                purpleDarkColorScheme),
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                baigeLightColorScheme,
                                            darkColorScheme:
                                                baigeDarkColorScheme),
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                redLightColorScheme,
                                            darkColorScheme:
                                                redDarkColorScheme),
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                blueLightColorScheme,
                                            darkColorScheme:
                                                blueDarkColorScheme),
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                greyLightColorScheme,
                                            darkColorScheme:
                                                greyDarkColorScheme),
                                        themeButton(
                                            themeChange: themeChangeProvider,
                                            lightColorScheme:
                                                greenLightColorScheme,
                                            darkColorScheme:
                                                greenDarkColorScheme),
                                        const Icon(Icons.phone_android),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(context)!.fontSize,
                                  style: TextStyle(
                                      fontSize: themeChangeProvider.fontSize),
                                  textAlign:
                                      themeChangeProvider.language == 'ar'
                                          ? TextAlign.right
                                          : TextAlign.left,
                                ),
                                Center(
                                  child: Slider(
                                    value: themeChangeProvider.fontSize,
                                    max: 36,
                                    min: 20,
                                    divisions: 7,
                                    label: themeChangeProvider.fontSize
                                        .round()
                                        .toString(),
                                    onChanged: (double value) {
                                      setState(() {
                                        themeChangeProvider.fontSize = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(context)!.language,
                                  style: TextStyle(
                                      fontSize: themeChangeProvider.fontSize),
                                  textAlign:
                                      themeChangeProvider.language == 'ar'
                                          ? TextAlign.right
                                          : TextAlign.left,
                                ),
                                SafeArea(
                                  child: Center(
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: ToggleButtons(
                                        selectedBorderColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderWidth: 3,
                                        isSelected: isSelectedLanguage,
                                        onPressed: (int index) {
                                          setState(() {
                                            for (int buttonIndex = 0;
                                                buttonIndex <
                                                    isSelectedLanguage.length;
                                                buttonIndex++) {
                                              if (buttonIndex == index) {
                                                isSelectedLanguage[
                                                    buttonIndex] = true;
                                                themeChangeProvider.language =
                                                    buttonIndex == 0
                                                        ? 'ar'
                                                        : 'en';
                                              } else {
                                                isSelectedLanguage[
                                                    buttonIndex] = false;
                                              }
                                            }
                                          });
                                        },
                                        children: ['ع', 'E']
                                            .map((language) => Text(language,
                                                style: TextStyle(fontSize: 20)))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      });
                }),
            centerTitle: true,
            elevation: 0,
            title: Text(AppLocalizations.of(context)!.title,
                style: TextStyle(
                    fontFamily: "Lateef",
                    fontSize: themeChangeProvider.fontSize + 5))),
        body: TabBarView(
          children: [
            ValueListenableBuilder<Box<Prayer>>(
                valueListenable: Hive.box<Prayer>(boxName).listenable(),
                builder: (context, Box<Prayer> box, widget) {
                  if (box.values
                      .where((element) =>
                          element.whichPerson == themeChangeProvider.personName)
                      .isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: SvgPicture.string(
                              '''
                          <?xml version="1.0" encoding="UTF-8"?>
                          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
                          <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1080px" height="1080px" style="shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd" xmlns:xlink="http://www.w3.org/1999/xlink">
                          <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.background.toHex}" d="M -0.5,-0.5 C 359.5,-0.5 719.5,-0.5 1079.5,-0.5C 1079.5,359.5 1079.5,719.5 1079.5,1079.5C 719.5,1079.5 359.5,1079.5 -0.5,1079.5C -0.5,719.5 -0.5,359.5 -0.5,-0.5 Z"/></g>
                            <g><path style="opacity:1" fill="#101010" d="M 761.5,116.5 C 762.623,122.966 763.29,122.966 763.5,116.5C 765.691,92.8792 767.191,69.2125 768,45.5C 772.676,31.9666 779.343,30.9666 788,42.5C 791.803,48.4392 794.803,54.7726 797,61.5C 802.336,81.5299 804.503,101.863 803.5,122.5C 802.186,127.348 802.186,132.348 803.5,137.5C 804.107,137.376 804.44,137.043 804.5,136.5C 812.821,114.707 820.654,92.707 828,70.5C 829.746,66.6733 831.746,63.0066 834,59.5C 839.051,56.3101 843.051,57.3101 846,62.5C 849.745,70.225 851.579,78.3917 851.5,87C 850.446,110.052 844.779,131.885 834.5,152.5C 835.048,154.556 836.214,156.223 838,157.5C 838.333,413.5 838.667,669.5 839,925.5C 839.367,931.204 840.034,936.87 841,942.5C 843.795,953.22 846.795,963.887 850,974.5C 854.893,993.298 854.56,1011.96 849,1030.5C 844.896,1036.25 840.063,1036.92 834.5,1032.5C 830.337,1018.52 826.17,1004.52 822,990.5C 819.081,984.323 815.414,978.656 811,973.5C 810.178,975.788 809.511,978.122 809,980.5C 808.195,999.859 807.862,1019.19 808,1038.5C 805.756,1040.99 803.423,1040.99 801,1038.5C 791.633,1027.77 784.299,1015.77 779,1002.5C 776.262,1020.42 768.762,1035.92 756.5,1049C 750.081,1052.19 745.915,1050.35 744,1043.5C 744.38,1033.52 744.38,1023.52 744,1013.5C 743.081,1006.15 741.081,999.151 738,992.5C 733.415,1011.44 728.581,1030.27 723.5,1049C 721.5,1049.67 719.5,1049.67 717.5,1049C 712.896,1044.4 709.062,1039.23 706,1033.5C 702.531,1023.95 699.531,1014.28 697,1004.5C 690.448,1019.27 683.115,1033.6 675,1047.5C 673.285,1049.76 671.452,1051.93 669.5,1054C 666.472,1055.14 664.305,1054.31 663,1051.5C 660.769,1026.01 656.102,1001.01 649,976.5C 649.38,1000.39 644.38,1023.05 634,1044.5C 630.025,1049.99 624.858,1053.66 618.5,1055.5C 615.481,1055.74 613.647,1054.41 613,1051.5C 609.733,1027.56 605.066,1003.9 599,980.5C 598,978.5 597,976.5 596,974.5C 595.333,982.5 595.333,990.5 596,998.5C 598.809,1011.72 602.309,1024.72 606.5,1037.5C 606.665,1040.01 605.665,1041.84 603.5,1043C 594.903,1043.88 587.236,1041.54 580.5,1036C 571.889,1028.72 564.723,1020.22 559,1010.5C 555.667,1017.17 552.333,1023.83 549,1030.5C 545.066,1038.22 540.066,1039.22 534,1033.5C 529.73,1025.96 525.73,1018.29 522,1010.5C 516.613,1019.89 509.779,1028.05 501.5,1035C 494.46,1040.9 486.46,1043.57 477.5,1043C 475.406,1041.74 474.406,1039.91 474.5,1037.5C 476.626,1027.62 479.46,1017.95 483,1008.5C 484.16,1002.87 484.993,997.204 485.5,991.5C 486.653,985.681 486.819,979.681 486,973.5C 485.283,974.044 484.783,974.711 484.5,975.5C 481.781,980.491 479.947,985.824 479,991.5C 474.253,1011.31 470.587,1031.31 468,1051.5C 466.309,1055.21 463.475,1056.38 459.5,1055C 452.614,1051.11 447.447,1045.61 444,1038.5C 436.017,1018.29 432.017,997.294 432,975.5C 425.283,1000.8 420.617,1026.47 418,1052.5C 416.192,1054.4 414.025,1054.9 411.5,1054C 409.212,1051.26 407.045,1048.42 405,1045.5C 397.123,1031.48 389.957,1017.14 383.5,1002.5C 381.655,1013.87 378.488,1024.87 374,1035.5C 371.217,1039.95 368.05,1044.12 364.5,1048C 362.635,1049.3 360.635,1049.63 358.5,1049C 352.694,1032.54 348.194,1015.71 345,998.5C 344.527,996.221 343.527,994.221 342,992.5C 340.331,999.841 338.665,1007.17 337,1014.5C 337.221,1024.49 337.221,1034.49 337,1044.5C 334.427,1050.46 330.261,1051.96 324.5,1049C 318.549,1042.92 313.716,1036.09 310,1028.5C 306.707,1019.32 304.04,1009.99 302,1000.5C 297.19,1014.96 289.69,1027.79 279.5,1039C 275.639,1041.49 273.306,1040.49 272.5,1036C 273.078,1032.03 273.411,1028.03 273.5,1024C 272.848,1009.17 272.348,994.339 272,979.5C 271.64,977.579 270.806,975.912 269.5,974.5C 264.648,980.201 260.815,986.534 258,993.5C 254.457,1006.23 250.79,1018.89 247,1031.5C 243.491,1035.61 239.324,1036.45 234.5,1034C 232.218,1030.49 230.718,1026.65 230,1022.5C 227.253,1009.89 226.92,997.222 229,984.5C 232.703,968.358 237.036,952.358 242,936.5C 242.333,676.833 242.667,417.167 243,157.5C 244.685,155.983 246.185,154.316 247.5,152.5C 234.852,128.764 229.019,103.431 230,76.5C 231.536,70.2162 234.036,64.3829 237.5,59C 241.27,56.7214 244.604,57.2214 247.5,60.5C 249.532,63.3681 251.365,66.3681 253,69.5C 260.616,92.351 268.616,115.018 277,137.5C 277.333,123.5 277.667,109.5 278,95.5C 278.605,74.7312 284.605,55.7312 296,38.5C 301.521,32.8433 306.521,33.1767 311,39.5C 312.308,42.7302 313.308,46.0636 314,49.5C 314.668,71.2071 315.835,92.8738 317.5,114.5C 318.105,117.127 318.605,119.793 319,122.5C 319.498,119.518 319.665,116.518 319.5,113.5C 321.336,86.4909 329.836,61.8243 345,39.5C 347.869,36.2959 351.035,33.4626 354.5,31C 358.317,29.9766 361.817,30.4766 365,32.5C 365.167,34.3333 365.333,36.1667 365.5,38C 362.138,60.4287 359.471,82.9287 357.5,105.5C 356.362,108.304 356.195,111.304 357,114.5C 357.717,113.956 358.217,113.289 358.5,112.5C 365.74,98.7644 369.907,84.0977 371,68.5C 371.333,60.8333 371.667,53.1667 372,45.5C 373.864,42.7928 376.364,41.9595 379.5,43C 383.393,48.0511 387.06,53.2178 390.5,58.5C 393.303,54.1979 396.636,50.3645 400.5,47C 407.722,43.198 414.388,44.0313 420.5,49.5C 424.307,43.86 428.307,38.36 432.5,33C 437.851,29.337 442.351,30.1704 446,35.5C 446.333,39.1667 446.667,42.8333 447,46.5C 455.946,40.3681 463.946,41.3681 471,49.5C 477.879,59.7939 482.212,71.1272 484,83.5C 486.794,65.1123 493.127,48.1123 503,32.5C 505.382,29.5728 507.882,26.7395 510.5,24C 516.949,19.6698 520.616,21.1698 521.5,28.5C 518.914,47.0923 518.08,65.759 519,84.5C 522.289,66.3444 527.289,48.6777 534,31.5C 538.333,24.8333 542.667,24.8333 547,31.5C 553.386,47.7111 558.22,64.3778 561.5,81.5C 563.019,64.2406 562.353,47.074 559.5,30C 558.356,25.2841 560.023,22.4507 564.5,21.5C 567.872,22.2686 570.705,23.9352 573,26.5C 581.33,36.154 587.33,47.154 591,59.5C 593.319,67.7435 595.319,76.0769 597,84.5C 598.637,69.3991 604.47,56.2324 614.5,45C 621.226,41.6234 627.726,42.1234 634,46.5C 634.333,43.1667 634.667,39.8333 635,36.5C 636.458,30.9411 639.958,29.1077 645.5,31C 651.352,36.0172 656.019,42.0172 659.5,49C 662.495,48.354 665.495,47.354 668.5,46C 671.833,45.3333 675.167,45.3333 678.5,46C 683.383,49.3821 687.383,53.5488 690.5,58.5C 693.972,53.1944 697.639,48.0278 701.5,43C 704.497,42.2446 706.997,43.0779 709,45.5C 708.866,62.4301 710.866,79.0968 715,95.5C 716.946,102.058 719.946,108.058 724,113.5C 723.467,101.162 722.467,88.8289 721,76.5C 718.777,63.7196 716.944,50.8863 715.5,38C 715.079,31.4186 718.079,28.7519 724.5,30C 728.916,32.4117 732.749,35.5783 736,39.5C 751.394,62.8484 759.894,88.5151 761.5,116.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primaryContainer.toHex}" d="M 512.5,32.5 C 513.161,34.134 513.494,35.9674 513.5,38C 507.743,69.5517 511.243,100.052 524,129.5C 529.848,131.653 531.848,129.653 530,123.5C 528.219,120.726 526.885,117.726 526,114.5C 524.843,94.4017 527.176,74.735 533,55.5C 534.69,49.1256 537.19,43.1256 540.5,37.5C 551.248,61.3162 556.415,86.3162 556,112.5C 553.088,117.894 551.421,123.56 551,129.5C 554.417,131.133 556.75,130.133 558,126.5C 570.402,95.9739 573.569,64.6405 567.5,32.5C 576.184,41.5302 582.018,52.1969 585,64.5C 589.821,82.1617 592.154,100.162 592,118.5C 594.962,126.084 597.628,133.751 600,141.5C 603.447,143.353 605.28,142.353 605.5,138.5C 601.713,116.088 602.213,93.7549 607,71.5C 609.611,63.1023 614.111,55.9356 620.5,50C 621.833,49.3333 623.167,49.3333 624.5,50C 627.778,51.6475 630.945,53.4808 634,55.5C 633.463,80.1533 633.463,104.82 634,129.5C 636,130.833 638,130.833 640,129.5C 640.333,107.833 640.667,86.1667 641,64.5C 641.418,55.8137 642.085,47.147 643,38.5C 656.724,55.3219 664.391,74.6552 666,96.5C 667.795,110.265 666.295,123.598 661.5,136.5C 661.712,138.888 663.045,139.888 665.5,139.5C 666.5,139.167 667.5,138.833 668.5,138.5C 674.074,120.398 674.907,102.065 671,83.5C 669.068,75.2707 666.901,67.1041 664.5,59C 664.598,56.1271 665.932,54.1271 668.5,53C 674.74,51.5365 679.24,53.7032 682,59.5C 683.275,61.7173 684.275,64.0506 685,66.5C 685.333,82.1667 685.667,97.8333 686,113.5C 686.981,121.442 688.981,129.108 692,136.5C 694.853,139.318 697.353,139.152 699.5,136C 690.436,112.883 689.269,89.3826 696,65.5C 697.497,61.8351 699.497,58.5017 702,55.5C 702.533,82.8523 709.866,108.186 724,131.5C 726.592,132.982 728.925,132.648 731,130.5C 731.136,99.6625 727.969,69.1625 721.5,39C 721.667,38.5 721.833,38 722,37.5C 728.058,40.5579 732.391,45.2246 735,51.5C 748.814,77.0182 755.814,104.352 756,133.5C 759.22,137.898 763.053,138.564 767.5,135.5C 768.154,133.885 768.654,132.218 769,130.5C 771.917,102.912 773.584,75.2449 774,47.5C 775.029,44.1247 777.196,42.9581 780.5,44C 788.734,57.7013 793.567,72.5346 795,88.5C 795.899,95.9728 796.399,103.473 796.5,111C 795.823,120.833 795.657,130.666 796,140.5C 799.336,148.3 804.003,149.3 810,143.5C 818.332,119.512 826.665,95.5115 835,71.5C 836.093,69.6508 837.426,67.9842 839,66.5C 841.478,69.7892 843.144,73.4558 844,77.5C 844.977,103.894 838.977,128.561 826,151.5C 825.097,152.701 823.931,153.535 822.5,154C 634.5,154.667 446.5,154.667 258.5,154C 254.574,151.06 251.74,147.227 250,142.5C 239.708,120.953 235.708,98.2861 238,74.5C 238.956,71.6229 240.289,68.9562 242,66.5C 244.167,68.8302 245.834,71.4968 247,74.5C 254.81,97.5971 262.81,120.597 271,143.5C 276.342,148.842 281.009,148.176 285,141.5C 284.648,124.841 284.648,108.175 285,91.5C 286.647,75.5596 291.313,60.5596 299,46.5C 300.577,43.8005 302.743,43.1339 305.5,44.5C 307.193,74.1606 309.36,103.827 312,133.5C 316.158,138.778 320.491,138.778 325,133.5C 324.824,102.187 332.824,73.1869 349,46.5C 351.285,44.0934 353.451,41.5934 355.5,39C 356.448,38.5172 357.448,38.3505 358.5,38.5C 355.095,59.4035 352.262,80.4035 350,101.5C 349.333,111.167 349.333,120.833 350,130.5C 352.459,133.1 354.959,133.1 357.5,130.5C 371.639,107.237 378.805,81.9041 379,54.5C 389.451,72.2315 392.451,91.2315 388,111.5C 386.342,120.637 384.175,129.637 381.5,138.5C 383.924,138.808 386.257,138.474 388.5,137.5C 391.997,129.188 394.164,120.521 395,111.5C 395.333,96.1667 395.667,80.8333 396,65.5C 398.075,58.6445 402.409,53.9779 409,51.5C 412.833,52.6667 415.333,55.1667 416.5,59C 409.38,78.2176 406.547,98.0509 408,118.5C 408.672,125.362 410.172,132.029 412.5,138.5C 414.695,139.769 416.861,139.769 419,138.5C 410.058,105.76 414.391,74.76 432,45.5C 433.309,43.0243 435.142,41.0243 437.5,39.5C 438.841,48.1128 439.674,56.7795 440,65.5C 440.333,86.8333 440.667,108.167 441,129.5C 443,130.833 445,130.833 447,129.5C 447.494,105.156 447.494,80.823 447,56.5C 454.998,47.8833 461.998,48.55 468,58.5C 471.115,63.844 473.448,69.5106 475,75.5C 479.353,96.6409 479.519,117.808 475.5,139C 475.767,142.164 477.433,143.164 480.5,142C 483.256,136.065 485.423,129.899 487,123.5C 489.101,104.748 491.768,86.0818 495,67.5C 498.738,54.6908 504.571,43.0242 512.5,32.5 Z"/></g>
                            <g><path style="opacity:1" fill="#959595" d="M 357.5,105.5 C 357.198,108.059 357.532,110.393 358.5,112.5C 358.217,113.289 357.717,113.956 357,114.5C 356.195,111.304 356.362,108.304 357.5,105.5 Z"/></g>
                            <g><path style="opacity:1" fill="#949494" d="M 319.5,113.5 C 319.665,116.518 319.498,119.518 319,122.5C 318.605,119.793 318.105,117.127 317.5,114.5C 318.167,114.167 318.833,113.833 319.5,113.5 Z"/></g>
                            <g><path style="opacity:1" fill="#999999" d="M 761.5,116.5 C 762.167,116.5 762.833,116.5 763.5,116.5C 763.29,122.966 762.623,122.966 761.5,116.5 Z"/></g>
                            <g><path style="opacity:1" fill="#9b9b9b" d="M 803.5,122.5 C 803.181,127.363 803.514,132.03 804.5,136.5C 804.44,137.043 804.107,137.376 803.5,137.5C 802.186,132.348 802.186,127.348 803.5,122.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primary.toHex}" d="M 253.5,161.5 C 444.834,161.333 636.167,161.5 827.5,162C 829,162.833 830.167,164 831,165.5C 831.667,418.167 831.667,670.833 831,923.5C 830.691,924.766 830.191,925.933 829.5,927C 733.08,928.164 636.58,928.664 540,928.5C 444.167,928.333 348.333,928.167 252.5,928C 252,927.5 251.5,927 251,926.5C 249.335,673.246 249.002,419.913 250,166.5C 250.257,164.093 251.424,162.427 253.5,161.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0e0e0f" d="M 297.5,202.5 C 459.5,202.333 621.5,202.5 783.5,203C 785.286,203.785 786.786,204.951 788,206.5C 788.667,433.5 788.667,660.5 788,887.5C 787.167,888.333 786.333,889.167 785.5,890C 622.167,890.667 458.833,890.667 295.5,890C 294.667,889.167 293.833,888.333 293,887.5C 292.333,660.5 292.333,433.5 293,206.5C 294.397,204.93 295.897,203.596 297.5,202.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primaryContainer.toHex}" d="M 300.5,210.5 C 460.835,210.167 621.168,210.5 781.5,211.5C 782.663,276.459 782.83,341.459 782,406.5C 781.692,407.308 781.192,407.975 780.5,408.5C 767.861,401.933 755.361,395.266 743,388.5C 732.23,394.458 720.73,398.625 708.5,401C 705.368,402.635 702.368,404.468 699.5,406.5C 690.081,392.827 678.748,380.993 665.5,371C 635.754,353.124 605.087,336.791 573.5,322C 563.912,315.083 554.912,307.416 546.5,299C 543.081,296.154 539.414,295.82 535.5,298C 527.675,307.167 518.675,314.833 508.5,321C 490.623,330.185 472.623,339.185 454.5,348C 440.169,355.83 426.169,364.163 412.5,373C 400.45,381.783 390.45,392.45 382.5,405C 372.143,401.179 361.477,397.846 350.5,395C 346.393,392.28 342.06,390.113 337.5,388.5C 325.234,395.636 312.567,402.303 299.5,408.5C 298.333,343.169 298.167,277.836 299,212.5C 299.717,211.956 300.217,211.289 300.5,210.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primary.toHex}" d="M 538.5,304.5 C 539.873,304.343 541.207,304.51 542.5,305C 550.66,314.827 560.326,322.827 571.5,329C 599.717,341.774 627.05,356.107 653.5,372C 680.754,387.589 697.588,410.755 704,441.5C 705.91,453.367 703.077,463.867 695.5,473C 673.244,481.193 650.244,485.86 626.5,487C 568.833,487.667 511.167,487.667 453.5,487C 430.796,486.106 408.796,481.772 387.5,474C 385.376,472.878 383.543,471.378 382,469.5C 376.601,458.655 375.268,447.321 378,435.5C 384.661,412.999 397.161,394.499 415.5,380C 445.998,360.081 477.998,342.748 511.5,328C 521.876,321.794 530.876,313.961 538.5,304.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primary.toHex}" d="M 336.5,396.5 C 349.497,401.779 362.664,406.779 376,411.5C 376.667,413.833 376.667,416.167 376,418.5C 373.645,426.266 371.145,433.933 368.5,441.5C 350.43,446.966 332.43,446.799 314.5,441C 309.468,439.402 304.968,436.902 301,433.5C 296.288,424.833 298.122,418 306.5,413C 317.044,408.233 327.044,402.733 336.5,396.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primary.toHex}" d="M 741.5,396.5 C 754.022,402.43 766.355,408.93 778.5,416C 782.716,421.31 783.549,427.143 781,433.5C 778.374,436.231 775.207,438.064 771.5,439C 752.193,446.482 732.527,447.482 712.5,442C 710.131,434.535 707.631,427.035 705,419.5C 703.726,412.743 706.559,408.576 713.5,407C 720.545,405.155 727.545,403.155 734.5,401C 737.239,399.974 739.572,398.474 741.5,396.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.tertiary.toHex}" d="M 779.5,442.5 C 781.722,442.559 782.722,443.725 782.5,446C 782.385,447.895 781.718,449.562 780.5,451C 774.119,453.929 767.452,455.929 760.5,457C 744.833,457.667 729.167,457.667 713.5,457C 711.686,454.519 711.02,451.685 711.5,448.5C 735.05,455.373 757.716,453.373 779.5,442.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.tertiary.toHex}" d="M 298.5,442.5 C 309.158,446.774 320.158,449.941 331.5,452C 337.833,452.667 344.167,452.667 350.5,452C 356.772,450.652 363.105,449.818 369.5,449.5C 369.662,451.527 369.495,453.527 369,455.5C 368.25,456.126 367.416,456.626 366.5,457C 348.471,457.866 330.471,457.533 312.5,456C 307.262,455.297 302.762,453.13 299,449.5C 298.503,447.19 298.337,444.857 298.5,442.5 Z"/></g>
                            <g><path style="opacity:1" fill="#b1c2d4" d="M 298.5,459.5 C 321.334,465.847 344.501,467.181 368,463.5C 371.314,463.145 373.148,464.645 373.5,468C 371.739,471.431 369.572,474.597 367,477.5C 361.563,490.069 364.23,500.403 375,508.5C 375.667,604.167 375.667,699.833 375,795.5C 374.5,796 374,796.5 373.5,797C 349.167,797.667 324.833,797.667 300.5,797C 300,796.5 299.5,796 299,795.5C 298.5,683.5 298.333,571.5 298.5,459.5 Z"/></g>
                            <g><path style="opacity:1" fill="#b1c2d4" d="M 778.5,459.5 C 779.833,459.5 781.167,459.5 782.5,459.5C 782.667,571.167 782.5,682.834 782,794.5C 781.626,795.416 781.126,796.25 780.5,797C 756.167,797.667 731.833,797.667 707.5,797C 707,796.5 706.5,796 706,795.5C 705.333,700.167 705.333,604.833 706,509.5C 708.468,506.28 711.135,503.28 714,500.5C 718.303,494.062 718.636,487.395 715,480.5C 712.484,476.129 709.984,471.796 707.5,467.5C 707.833,465.167 709.167,463.833 711.5,463.5C 726.788,465.196 742.121,465.696 757.5,465C 764.9,464.227 771.9,462.394 778.5,459.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.tertiary.toHex}" d="M 700.5,477.5 C 703.325,477.081 705.491,478.081 707,480.5C 711.994,490.124 709.828,497.624 700.5,503C 671.032,513.361 640.699,520.028 609.5,523C 568.175,524.415 526.842,524.748 485.5,524C 450.804,522.907 417.138,516.574 384.5,505C 373.274,500.715 369.44,492.882 373,481.5C 374.255,479.406 376.088,478.406 378.5,478.5C 398.496,486.108 419.163,490.941 440.5,493C 500.153,494.601 559.819,494.934 619.5,494C 647.879,494.424 674.879,488.924 700.5,477.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0a0a0a" d="M 332.5,492.5 C 341.939,490.798 348.772,494.131 353,502.5C 357.458,514.942 358.291,527.442 355.5,540C 343.905,541.602 332.238,541.935 320.5,541C 319.069,540.535 317.903,539.701 317,538.5C 311.454,519.28 316.621,503.946 332.5,492.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0a0a0a" d="M 740.5,491.5 C 747.468,491.067 752.968,493.733 757,499.5C 764.999,509.513 767.665,520.846 765,533.5C 764.771,536.458 763.604,538.958 761.5,541C 750.167,541.667 738.833,541.667 727.5,541C 726.069,540.535 724.903,539.701 724,538.5C 723.414,527.025 724.414,515.691 727,504.5C 730.076,498.589 734.576,494.255 740.5,491.5 Z"/></g>
                            <g><path style="opacity:1" fill="#b2c3d5" d="M 698.5,512.5 C 699.499,605.665 699.833,698.999 699.5,792.5C 699.703,794.39 699.037,795.89 697.5,797C 671.5,797.667 645.5,797.667 619.5,797C 619,796.5 618.5,796 618,795.5C 617.989,734.442 617.322,673.442 616,612.5C 600.1,590.625 578.6,578.125 551.5,575C 516.579,571.85 488.079,583.683 466,610.5C 465.333,612.5 464.667,614.5 464,616.5C 463.667,676.167 463.333,735.833 463,795.5C 462.5,796 462,796.5 461.5,797C 435.167,797.667 408.833,797.667 382.5,797C 381.501,702.237 381.168,607.404 381.5,512.5C 430.325,527.665 480.325,534.332 531.5,532.5C 588.4,535.623 644.066,528.956 698.5,512.5 Z"/></g>
                            <g><path style="opacity:1" fill="#32363b" d="M 698.5,512.5 C 698.56,511.957 698.893,511.624 699.5,511.5C 700.832,605.332 700.832,698.999 699.5,792.5C 699.833,698.999 699.499,605.665 698.5,512.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.tertiaryContainer.toHex}" d="M 527.5,581.5 C 558.982,578.601 585.482,588.601 607,611.5C 607.667,612.833 608.333,614.167 609,615.5C 609.831,676.07 609.664,736.57 608.5,797C 562.929,797.83 517.429,797.663 472,796.5C 471.333,736.167 471.333,675.833 472,615.5C 482.82,600.825 496.987,590.658 514.5,585C 518.999,583.961 523.332,582.794 527.5,581.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0a0a0a" d="M 328.5,582.5 C 338.334,581.501 345.834,585.167 351,593.5C 357.146,605.026 357.979,616.859 353.5,629C 341.241,629.547 329.074,629.047 317,627.5C 313.897,613.574 315.563,600.24 322,587.5C 324.326,585.934 326.492,584.268 328.5,582.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0b0b0b" d="M 741.5,582.5 C 748.206,581.407 754.039,583.074 759,587.5C 765.656,599.112 767.656,611.445 765,624.5C 764.167,626.667 762.667,628.167 760.5,629C 749.249,628.77 738.082,628.604 727,628.5C 722.804,615.587 724.137,603.254 731,591.5C 734.103,587.886 737.603,584.886 741.5,582.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0a0a0b" d="M 329.5,669.5 C 342.242,669.399 350.742,675.399 355,687.5C 356.478,695.111 356.812,702.778 356,710.5C 355.208,712.587 354.041,714.421 352.5,716C 342.468,716.713 332.468,716.379 322.5,715C 320.667,714.5 319.5,713.333 319,711.5C 315.175,699.532 315.841,687.865 321,676.5C 323.441,673.546 326.275,671.213 329.5,669.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0b0b0b" d="M 742.5,669.5 C 753.97,668.778 761.137,674.112 764,685.5C 764.87,693.897 764.537,702.23 763,710.5C 761.363,712.81 759.196,714.31 756.5,715C 747.199,716.349 737.866,716.683 728.5,716C 726.513,714.681 725.346,712.848 725,710.5C 723.298,699.053 725.298,688.386 731,678.5C 734.161,674.491 737.994,671.491 742.5,669.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primaryContainer.toHex}" d="M 300.5,804.5 C 353.168,804.333 405.834,804.5 458.5,805C 458.957,805.414 459.291,805.914 459.5,806.5C 441.757,828.741 424.591,851.408 408,874.5C 405.617,877.273 402.783,879.439 399.5,881C 366.561,882.645 333.561,882.979 300.5,882C 300,881.5 299.5,881 299,880.5C 298.333,855.833 298.333,831.167 299,806.5C 299.717,805.956 300.217,805.289 300.5,804.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primaryContainer.toHex}" d="M 621.5,804.5 C 674.168,804.333 726.834,804.5 779.5,805C 780.333,805.833 781.167,806.667 782,807.5C 782.667,831.833 782.667,856.167 782,880.5C 781.167,881.333 780.333,882.167 779.5,883C 746.5,883.667 713.5,883.667 680.5,883C 666.143,864.487 651.643,845.987 637,827.5C 631.194,820.207 626.028,812.54 621.5,804.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primaryContainer.toHex}" d="M 752.5,1042.5 C 751.833,1033.17 751.167,1023.83 750.5,1014.5C 748.983,996.806 743.483,980.472 734,965.5C 731.5,963 729,960.5 726.5,958C 722.38,957.486 720.88,959.32 722,963.5C 731.14,970.712 734.14,980.045 731,991.5C 727.513,1007.11 723.18,1022.44 718,1037.5C 712.8,1031.43 709.467,1024.43 708,1016.5C 703.621,1000.47 701.621,984.132 702,967.5C 699.733,966.065 697.733,966.398 696,968.5C 695.947,979.878 693.947,990.878 690,1001.5C 683.59,1015.32 676.923,1028.99 670,1042.5C 665.945,1016.23 660.612,990.226 654,964.5C 652.221,958.24 648.555,953.574 643,950.5C 641.739,950.759 640.739,951.426 640,952.5C 639.862,964.013 640.362,975.513 641.5,987C 640.62,1006.25 635.786,1024.41 627,1041.5C 625.185,1043.4 623.185,1045.07 621,1046.5C 616.019,1024.21 611.019,1001.88 606,979.5C 595.098,946.769 588.931,947.602 587.5,982C 587.821,989.888 588.654,997.722 590,1005.5C 593.23,1015.35 595.73,1025.35 597.5,1035.5C 583.786,1030.63 573.619,1021.63 567,1008.5C 564.352,1002.26 562.852,995.761 562.5,989C 563.552,976.513 563.718,964.013 563,951.5C 561,950.167 559,950.167 557,951.5C 556.418,968.907 555.084,986.24 553,1003.5C 550.398,1012.7 546.231,1021.04 540.5,1028.5C 532.477,1018.29 527.644,1006.63 526,993.5C 525.12,979.51 524.454,965.51 524,951.5C 522,950.167 520,950.167 518,951.5C 517.292,964.178 517.459,976.845 518.5,989.5C 515.869,1012.09 504.035,1027.75 483,1036.5C 485.021,1026.09 487.687,1015.75 491,1005.5C 494.588,989.37 494.255,973.37 490,957.5C 488,954.833 486,954.833 484,957.5C 480.447,964.606 477.447,971.939 475,979.5C 469.993,1001.85 464.993,1024.18 460,1046.5C 455.616,1043.78 452.282,1040.12 450,1035.5C 439.711,1010.65 436.878,984.982 441.5,958.5C 442.24,951.053 439.407,949.053 433,952.5C 430.287,957.295 427.954,962.295 426,967.5C 420.226,992.268 415.56,1017.27 412,1042.5C 401.782,1025.73 393.449,1008.06 387,989.5C 386.002,982.533 385.336,975.533 385,968.5C 383.267,966.398 381.267,966.065 379,967.5C 379.169,987.986 376.169,1007.99 370,1027.5C 368.056,1031.11 365.723,1034.44 363,1037.5C 361.815,1035.62 360.815,1033.62 360,1031.5C 356.244,1014.98 352.411,998.476 348.5,982C 349.524,974.455 353.024,968.288 359,963.5C 360.12,959.32 358.62,957.486 354.5,958C 344.444,968.271 337.611,980.438 334,994.5C 332.508,1000.46 331.341,1006.46 330.5,1012.5C 329.833,1022.5 329.167,1032.5 328.5,1042.5C 319.791,1032.75 313.958,1021.42 311,1008.5C 308.128,990.622 306.795,972.622 307,954.5C 305.333,953.167 303.667,953.167 302,954.5C 300.243,972.471 296.909,990.138 292,1007.5C 289.252,1012.67 286.252,1017.67 283,1022.5C 282.333,1023.83 281.667,1023.83 281,1022.5C 279.287,1004.54 278.287,986.54 278,968.5C 276.964,965.247 276.297,961.914 276,958.5C 274.776,955.527 272.776,954.86 270,956.5C 269.667,958.833 269.333,961.167 269,963.5C 260.993,971.507 254.993,980.841 251,991.5C 247.236,1002.22 244.569,1013.22 243,1024.5C 241.604,1026.53 239.938,1026.86 238,1025.5C 237.138,1023.91 236.471,1022.25 236,1020.5C 233.846,992.756 238.18,966.09 249,940.5C 250.167,939.333 251.333,938.167 252.5,937C 348.944,935.837 445.444,935.337 542,935.5C 637.5,935.667 733,935.833 828.5,936C 831.187,937.875 833.021,940.375 834,943.5C 838.487,957.627 842.154,971.961 845,986.5C 845.667,996.833 845.667,1007.17 845,1017.5C 844.292,1021.25 843.292,1024.92 842,1028.5C 839.833,1026.17 838.166,1023.5 837,1020.5C 835.089,1003.1 829.423,987.097 820,972.5C 817.705,969.203 815.038,966.203 812,963.5C 811.667,961.167 811.333,958.833 811,956.5C 808.224,954.86 806.224,955.527 805,958.5C 804.118,961.789 803.452,965.123 803,968.5C 802.99,986.625 801.657,1004.62 799,1022.5C 792.306,1015.45 787.973,1007.11 786,997.5C 783.271,983.608 781.271,969.608 780,955.5C 778.267,953.398 776.267,953.065 774,954.5C 774.68,975.12 772.68,995.453 768,1015.5C 764.871,1025.77 759.704,1034.77 752.5,1042.5 Z"/></g>
                            <g><path style="opacity:1" fill="#5c5c5c" d="M 485.5,991.5 C 485.821,985.974 485.488,980.64 484.5,975.5C 484.783,974.711 485.283,974.044 486,973.5C 486.819,979.681 486.653,985.681 485.5,991.5 Z"/></g>
                            <g><path style="opacity:1" fill="#3d4431" d="M 330.5,1012.5 C 330.832,1022.85 330.499,1033.19 329.5,1043.5C 328.893,1043.38 328.56,1043.04 328.5,1042.5C 329.167,1032.5 329.833,1022.5 330.5,1012.5 Z"/></g>
                            <g><path style="opacity:1" fill="#3c4230" d="M 750.5,1014.5 C 751.167,1023.83 751.833,1033.17 752.5,1042.5C 752.44,1043.04 752.107,1043.38 751.5,1043.5C 750.502,1033.86 750.168,1024.19 750.5,1014.5 Z"/></g>
                            </svg>
                            
                            ''',
                              height: 300,
                              width: 500,
                            ),
                          ),
                          // const Image(image: AssetImage('images/kaaba_3d.png')),
                          Text(
                            AppLocalizations.of(context)!.prayersTitle,
                            style: TextStyle(
                                fontSize: themeChangeProvider.fontSize + 15,
                                fontFamily: "Lateef"),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          FilledButton(
                              onPressed: () {
                                Navigator.pushNamed(context, "/settings");
                              },
                              child: Text(
                                AppLocalizations.of(context)!.settingsBtn,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize + 5),
                              ))
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        // Text("عدد الايام المتبقية   "),
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: box.values
                                .where((prayer) =>
                                    prayer.whichPerson ==
                                    themeChangeProvider.personName)
                                .length,
                            itemBuilder: (context, i) {
                              Prayer? prayer = box.values
                                  .where((element) =>
                                      element.whichPerson ==
                                      themeChangeProvider.personName)
                                  .toList()[i];

                              return SizedBox(
                                height: MediaQuery.of(context).size.height / 7,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            onPressed: () {
                                              if (prayer.finished > 0) {
                                                confirmationAlert(context,
                                                    prayer, box, i, false);
                                              }
                                            }),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          getPrayerName(prayer.name, context),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      prayer.finished == prayer.total
                                          ? Container()
                                          : FilledButton(
                                              style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .doneBtn,
                                                style: TextStyle(
                                                    fontSize:
                                                        themeChangeProvider
                                                                .fontSize -
                                                            5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .background),
                                              ),
                                              onPressed: () async {
                                                if (prayer.finished <
                                                    prayer.total) {
                                                  confirmationAlert(context,
                                                      prayer, box, i, true);
                                                }
                                              }),
                                      CircleAvatar(
                                          maxRadius: 45,
                                          child: prayer.finished == prayer.total
                                              ? Text(
                                                  AppLocalizations.of(context)!
                                                      .finishMessage,
                                                  textAlign: TextAlign.center,
                                                )
                                              : Text(
                                                  "${prayer.finished}/${prayer.total}",
                                                  style: const TextStyle(
                                                    fontFamily: 'Ubuntu Mono',
                                                    fontSize: 30,
                                                    fontFeatures: <FontFeature>[
                                                      FontFeature.fractions(),
                                                    ],
                                                  ),
                                                )),
                                    ]),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                            height: 80,
                            child: Center(
                                child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                  AppLocalizations.of(context)!.finishMessage2,
                                  style: TextStyle(
                                      fontSize: 30, fontFamily: "Lateef")),
                            ))),
                      ],
                    );
                  }
                }),
            ValueListenableBuilder<Box<Prayer>>(
                valueListenable: Hive.box<Prayer>(boxName2).listenable(),
                builder: (context, Box<Prayer> box, widget) {
                  if (box.values
                      .where((element) =>
                          element.whichPerson == themeChangeProvider.personName)
                      .isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: SvgPicture.string(
                              '''<?xml version="1.0" encoding="UTF-8"?>
                          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
                          <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1080px" height="1080px" style="shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd" xmlns:xlink="http://www.w3.org/1999/xlink">
                          <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.background.toHex}" d="M -0.5,-0.5 C 359.5,-0.5 719.5,-0.5 1079.5,-0.5C 1079.5,359.5 1079.5,719.5 1079.5,1079.5C 719.5,1079.5 359.5,1079.5 -0.5,1079.5C -0.5,719.5 -0.5,359.5 -0.5,-0.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0d0d0d" d="M 513.5,29.5 C 612.271,25.2535 698.938,55.0869 773.5,119C 822.724,164.271 856.557,219.104 875,283.5C 875.667,537.833 875.667,792.167 875,1046.5C 874.5,1048.33 873.333,1049.5 871.5,1050C 650.167,1050.67 428.833,1050.67 207.5,1050C 206.333,1049.5 205.5,1048.67 205,1047.5C 204.333,794.167 204.333,540.833 205,287.5C 206.892,270.718 211.559,254.718 219,239.5C 267.481,133.034 348.648,65.8676 462.5,38C 479.461,34.0939 496.461,31.2605 513.5,29.5 Z"/></g>
                            <g><path style="opacity:1" fill="${Theme.of(context).colorScheme.primary.toHex}" d="M 513.5,37.5 C 624.484,32.6421 717.984,70.3088 794,150.5C 827.333,188.139 851.666,231.139 867,279.5C 867.667,533.5 867.667,787.5 867,1041.5C 866.5,1042.67 865.667,1043.5 864.5,1044C 647.833,1044.67 431.167,1044.67 214.5,1044C 213.299,1043.1 212.465,1041.93 212,1040.5C 211.333,790.5 211.333,540.5 212,290.5C 214.399,273.837 219.066,257.837 226,242.5C 283.847,121.188 379.68,52.8547 513.5,37.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0f1010" d="M 520.5,66.5 C 629.396,62.82 718.23,102.82 787,186.5C 807.137,213.43 823.137,242.764 835,274.5C 835.667,519.5 835.667,764.5 835,1009.5C 834.5,1011.33 833.333,1012.5 831.5,1013C 636.833,1013.67 442.167,1013.67 247.5,1013C 246.333,1012.5 245.5,1011.67 245,1010.5C 244.333,765.5 244.333,520.5 245,275.5C 277.353,185.146 338.186,122.313 427.5,87C 457.67,75.8665 488.67,69.0332 520.5,66.5 Z"/></g>
                            <g><path style="opacity:1" fill="${themeChangeProvider.darkTheme ? Theme.of(context).colorScheme.primaryContainer.toHex : Theme.of(context).colorScheme.onPrimaryContainer.toHex}" d="M 515.5,73.5 C 614.362,69.1595 697.862,102.493 766,173.5C 792.154,203.442 812.487,237.109 827,274.5C 828.164,396.445 828.664,518.445 828.5,640.5C 828.333,761.5 828.167,882.5 828,1003.5C 827.5,1004 827,1004.5 826.5,1005C 635.167,1005.67 443.833,1005.67 252.5,1005C 252,1004.5 251.5,1004 251,1003.5C 250.333,763.5 250.333,523.5 251,283.5C 255.302,265.934 261.969,249.268 271,233.5C 319.677,148.232 392.511,96.0651 489.5,77C 498.308,75.784 506.974,74.6174 515.5,73.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f0d197" d="M 574.5,161.5 C 582.675,160.901 587.342,164.568 588.5,172.5C 588.233,179.889 584.399,183.889 577,184.5C 567.096,182.026 564.096,176.026 568,166.5C 569.965,164.45 572.132,162.783 574.5,161.5 Z"/></g>
                            <g><path style="opacity:1" fill="#edcf97" d="M 436.5,189.5 C 445.865,188.936 447.865,192.436 442.5,200C 434.48,200.135 432.48,196.635 436.5,189.5 Z"/></g>
                            <g><path style="opacity:1" fill="#efd097" d="M 713.5,204.5 C 721.744,204.228 724.078,207.728 720.5,215C 711.43,216.136 709.096,212.636 713.5,204.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f0d197" d="M 352.5,256.5 C 360.296,256.458 364.963,260.292 366.5,268C 364.246,277.29 358.579,280.623 349.5,278C 340.786,269.45 341.786,262.284 352.5,256.5 Z"/></g>
                            <g><path style="opacity:1" fill="#0c0c0c" d="M 517.5,270.5 C 525.253,270.104 532.92,270.604 540.5,272C 542.673,273.865 543.007,276.031 541.5,278.5C 521.2,293.294 505.033,311.627 493,333.5C 475.523,376.168 478.856,417.168 503,456.5C 534.045,498.143 575.545,515.809 627.5,509.5C 633.592,509.298 635.092,511.965 632,517.5C 611.838,537.5 587.671,550 559.5,555C 507.888,561.909 464.055,546.742 428,509.5C 391.137,463.652 382.803,412.985 403,357.5C 426.209,308.812 464.376,279.812 517.5,270.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f2d296" d="M 525.5,277.5 C 526.873,277.343 528.207,277.51 529.5,278C 478.233,319.88 463.066,372.38 484,435.5C 510.369,493.132 555.536,520.965 619.5,519C 594.932,538.698 566.766,548.865 535,549.5C 478.591,546.815 437.591,520.481 412,470.5C 387.215,408.15 399.382,354.317 448.5,309C 471.109,290.965 496.775,280.465 525.5,277.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f0d197" d="M 729.5,320.5 C 742.528,321.219 746.361,327.552 741,339.5C 733.164,345.692 726.831,344.359 722,335.5C 720.753,328.591 723.253,323.591 729.5,320.5 Z"/></g>
                            <g><path style="opacity:1" fill="#edcf97" d="M 671.5,415.5 C 679.841,414.873 682.175,418.207 678.5,425.5C 669.419,427.192 667.086,423.858 671.5,415.5 Z"/></g>
                            <g><path style="opacity:1" fill="#edcf97" d="M 327.5,427.5 C 333.356,427.854 335.523,430.854 334,436.5C 330.667,440.5 327.333,440.5 324,436.5C 322.665,432.392 323.832,429.392 327.5,427.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f1d297" d="M 313.5,606.5 C 324.653,605.486 329.487,610.486 328,621.5C 324.96,627.603 320.126,629.769 313.5,628C 307.397,624.96 305.231,620.126 307,613.5C 308.694,610.642 310.861,608.309 313.5,606.5 Z"/></g>
                            <g><path style="opacity:1" fill="#eed097" d="M 784.5,618.5 C 793.261,618.397 795.261,621.897 790.5,629C 784.166,630.329 781.332,627.829 782,621.5C 782.698,620.309 783.531,619.309 784.5,618.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f0d197" d="M 640.5,671.5 C 653.547,672.262 657.381,678.595 652,690.5C 643.53,696.922 637.196,695.255 633,685.5C 632.084,678.999 634.584,674.332 640.5,671.5 Z"/></g>
                            <g><path style="opacity:1" fill="#efd097" d="M 447.5,692.5 C 456.865,691.936 458.865,695.436 453.5,703C 445.48,703.135 443.48,699.635 447.5,692.5 Z"/></g>
                            <g><path style="opacity:1" fill="#efd097" d="M 702.5,802.5 C 711.865,801.936 713.865,805.436 708.5,813C 700.48,813.135 698.48,809.635 702.5,802.5 Z"/></g>
                            <g><path style="opacity:1" fill="#eed097" d="M 308.5,807.5 C 312.287,806.814 315.454,807.814 318,810.5C 318.917,815.327 316.917,817.994 312,818.5C 306.153,816.482 304.986,812.815 308.5,807.5 Z"/></g>
                            <g><path style="opacity:1" fill="#ecce97" d="M 541.5,815.5 C 549.302,815.787 551.302,819.287 547.5,826C 541.172,827.971 538.006,825.805 538,819.5C 538.69,817.65 539.856,816.316 541.5,815.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f0d197" d="M 359.5,858.5 C 372.149,856.978 377.316,862.311 375,874.5C 368.16,882.451 361.493,882.451 355,874.5C 353.318,868.158 354.818,862.824 359.5,858.5 Z"/></g>
                            <g><path style="opacity:1" fill="#f1d297" d="M 724.5,892.5 C 735.339,891.837 740.172,896.837 739,907.5C 734.225,915.12 728.058,916.453 720.5,911.5C 715.585,903.794 716.918,897.461 724.5,892.5 Z"/></g>
                            <g><path style="opacity:1" fill="#edcf97" d="M 509.5,953.5 C 516.162,952.997 518.662,955.997 517,962.5C 513.667,966.5 510.333,966.5 507,962.5C 505.93,958.858 506.764,955.858 509.5,953.5 Z"/></g>
                            </svg>
                            ''',
                              height: 250,
                              width: 500,
                            ),
                          ),
                          // Image(image: AssetImage('images/moon_3d.png')),
                          Text(
                            AppLocalizations.of(context)!.fastingTitle,
                            style: TextStyle(
                                fontSize: themeChangeProvider.fontSize + 15,
                                fontFamily: "Lateef"),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          FilledButton(
                              onPressed: () {
                                Navigator.pushNamed(context, "/settings");
                              },
                              child: Text(
                                AppLocalizations.of(context)!.settingsBtn,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize + 5),
                              ))
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: box.values
                                .where((prayer) =>
                                    prayer.whichPerson ==
                                    themeChangeProvider.personName)
                                .length,
                            itemBuilder: (context, i) {
                              var prayer = box.getAt(i)!;
                              return SizedBox(
                                height: MediaQuery.of(context).size.height / 7,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            onPressed: () async {
                                              if (prayer.finished > 0) {
                                                fastingConfirmationAlert(
                                                    context,
                                                    prayer,
                                                    box,
                                                    i,
                                                    false);
                                              }
                                            }),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          getFastingTypeName(
                                              prayer.name, context),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: themeChangeProvider
                                                          .language ==
                                                      'ar'
                                                  ? 25
                                                  : 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      prayer.finished == prayer.total
                                          ? Container()
                                          : FilledButton(
                                              style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .doneBtn,
                                                style: TextStyle(
                                                    fontSize:
                                                        themeChangeProvider
                                                                .fontSize -
                                                            5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .background),
                                              ),
                                              onPressed: () async {
                                                if (prayer.name != 'قضاء') {
                                                  if (box.get(
                                                          'قضاء:${themeChangeProvider.personName}') !=
                                                      null) {
                                                    var is_fasting1_finished = await box
                                                            .get(
                                                                'قضاء:${themeChangeProvider.personName}')!
                                                            .finished ==
                                                        box
                                                            .get(
                                                                'قضاء:${themeChangeProvider.personName}')!
                                                            .total;

                                                    if (is_fasting1_finished) {
                                                      if (prayer.finished <
                                                          prayer.total) {
                                                        fastingConfirmationAlert(
                                                            context,
                                                            prayer,
                                                            box,
                                                            i,
                                                            true);
                                                      }
                                                    } else {
                                                      // show dialog 44

                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              Directionality(
                                                                textDirection:
                                                                    themeChangeProvider.language ==
                                                                            'ar'
                                                                        ? TextDirection
                                                                            .rtl
                                                                        : TextDirection
                                                                            .ltr,
                                                                child:
                                                                    AlertDialog(
                                                                  icon: Icon(Icons
                                                                      .warning_amber_outlined),
                                                                  title: Text(
                                                                      "لا يجوز"),
                                                                  content: Text(
                                                                    "لا يجوز صوم المستحب او صوم آخر وفي الذمة صوم  قضاء عن نفسه.",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            20),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                        child:
                                                                            Text(
                                                                          AppLocalizations.of(context)!
                                                                              .ok,
                                                                          style:
                                                                              TextStyle(fontSize: 15),
                                                                        ),
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context)),
                                                                  ],
                                                                ),
                                                              ));
                                                    }
                                                  } else {
                                                    if (prayer.finished <
                                                        prayer.total) {
                                                      fastingConfirmationAlert(
                                                          context,
                                                          prayer,
                                                          box,
                                                          i,
                                                          true);
                                                    }
                                                  }
                                                } else {
                                                  if (prayer.finished <
                                                      prayer.total) {
                                                    fastingConfirmationAlert(
                                                        context,
                                                        prayer,
                                                        box,
                                                        i,
                                                        true);
                                                  }
                                                }
                                              }),
                                      CircleAvatar(
                                          maxRadius: 45,
                                          child: prayer.finished == prayer.total
                                              ? Text(
                                                  AppLocalizations.of(context)!
                                                      .finishMessage)
                                              : Text(
                                                  "${prayer.finished}/${prayer.total}",
                                                  style: const TextStyle(
                                                    fontFamily: 'Ubuntu Mono',
                                                    fontSize: 30,
                                                    fontFeatures: <FontFeature>[
                                                      FontFeature.fractions(),
                                                    ],
                                                  ),
                                                )),
                                    ]),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                            height: 150,
                            child: Center(
                                child: Column(
                              children: [
                                themeChangeProvider.language == "ar"
                                    ? Card(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .background,
                                        elevation: 3,
                                        margin: EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: ListTile(
                                          leading: Icon(Icons.info_outline),
                                          title: Center(
                                            child: Text(
                                              "لا تصح نية قضاء الصوم إلا قبل الزوال.\n ولا يجوز الافطار فيه بعد الزوال.",
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                const SizedBox(height: 20),
                                Text(
                                    AppLocalizations.of(context)!
                                        .finishMessage2,
                                    style: TextStyle(
                                        fontSize: 30, fontFamily: "Lateef")),
                              ],
                            ))),
                      ],
                    );
                  }
                })
          ],
        ),
      ),
    );
  }

  int indexOfPrayer(prayerName) {
    var prayers = ['الصبح', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    return prayers.indexOf(prayerName) + 1;
  }

  Future<dynamic> confirmationAlert(BuildContext context, Prayer prayer,
      Box<Prayer> box, int i, bool addition) {
    TheThemeProvider themeChangeProvider =
        Provider.of<TheThemeProvider>(context, listen: false);
    return showDialog(
        context: context,
        builder: (context) => Directionality(
              textDirection: themeChangeProvider.language == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AlertDialog(
                icon: Icon(addition
                    ? Icons.done_outline_outlined
                    : Icons.cancel_outlined),
                title: Text(addition
                    ? AppLocalizations.of(context)!.titleDoneMessage
                    : AppLocalizations.of(context)!.titleNotDoneMessage),
                content: Text(
                  addition
                      ? AppLocalizations.of(context)!.contentDoneMessage(
                          getPrayerName(prayer.name, context))
                      : AppLocalizations.of(context)!.contentNotDoneMessage(
                          getPrayerName(prayer.name, context)),
                  style: const TextStyle(fontSize: 20),
                ),
                actions: [
                  TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: () => Navigator.pop(context)),
                  TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: () async {
                        if (addition) {
                          if (prayer.finished != prayer.total) {
                            prayer.finished += 1;
                          }
                        } else {
                          if (prayer.finished > 0) prayer.finished -= 1;
                        }

                        await box
                            .put(
                                '${indexOfPrayer(prayer.name)}-${prayer.name}:${themeChangeProvider.personName}',
                                prayer)
                            .then((e) => Navigator.pop(context));
                        debugPrint(
                            '${indexOfPrayer(prayer.name)}-${prayer.name}:${themeChangeProvider.personName}');
                      })
                ],
              ),
            ));
  }

  String getFastingTypeName(type, BuildContext context) {
    switch (type) {
      case 'قضاء':
        return AppLocalizations.of(context)!.alqada;
      case 'نذر':
        return AppLocalizations.of(context)!.alnadhar;
      case 'كفارة':
        return AppLocalizations.of(context)!.alkafaara;
      default:
        return type;
    }
  }

  Future<dynamic> fastingConfirmationAlert(BuildContext context, Prayer prayer,
      Box<Prayer> box, int i, bool addition) {
    TheThemeProvider themeChangeProvider =
        Provider.of<TheThemeProvider>(context, listen: false);
    return showDialog(
        context: context,
        builder: (context) => Directionality(
              textDirection: themeChangeProvider.language == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AlertDialog(
                icon: Icon(addition
                    ? Icons.done_outline_outlined
                    : Icons.cancel_outlined),
                title: Text(addition
                    ? AppLocalizations.of(context)!.titleDoneMessageFasting
                    : AppLocalizations.of(context)!.titleNotDoneMessageFasting),
                content: Text(
                  addition
                      ? AppLocalizations.of(context)!.contentDoneMessageFasting(
                          getFastingTypeName(prayer.name, context))
                      : AppLocalizations.of(context)!
                          .contentNotDoneMessageFasting(
                              getFastingTypeName(prayer.name, context)),
                  style: const TextStyle(fontSize: 20),
                ),
                actions: [
                  TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: () => Navigator.pop(context)),
                  TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: () async {
                        if (addition) {
                          if (prayer.finished != prayer.total) {
                            prayer.finished += 1;
                          }
                        } else {
                          if (prayer.finished > 0) prayer.finished -= 1;
                        }

                        await box
                            .put(
                                '${prayer.name}:${themeChangeProvider.personName}',
                                prayer)
                            .then((e) => Navigator.pop(context));
                      })
                ],
              ),
            ));
  }
}

class themeButton extends StatelessWidget {
  const themeButton(
      {super.key,
      required this.themeChange,
      required this.lightColorScheme,
      required this.darkColorScheme});

  final TheThemeProvider themeChange;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: themeChange.darkTheme
            ? darkColorScheme.background
            : lightColorScheme.background,
        child: FloatingActionButton.small(
          elevation: 0,
          onPressed: null,
          foregroundColor: themeChange.darkTheme
              ? darkColorScheme.background
              : lightColorScheme.background,
          backgroundColor: themeChange.darkTheme
              ? darkColorScheme.secondary
              : lightColorScheme.secondary,
          child: const Icon(Icons.add),
        ));
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();

  final TextEditingController _fastingDays1Controller = TextEditingController();
  final TextEditingController _fastingMonths1Controller =
      TextEditingController();

  final TextEditingController _fastingDays2Controller = TextEditingController();
  final TextEditingController _fastingMonths2Controller =
      TextEditingController();

  final TextEditingController _fastingDays3Controller = TextEditingController();
  final TextEditingController _fastingMonths3Controller =
      TextEditingController();

  final box = Hive.box<Prayer>(boxName);
  final fastingBox = Hive.box<Prayer>(boxName2);

  final settings = Hive.box(settingsBox);
  final peoplesBox = Hive.box(peopleBox);

  void filltheFields(TheThemeProvider provider) {
    _daysController.text = provider.personName == 'ME'
        ? settings.get('days') ?? ""
        : settings.get('${provider.personName}:days') ?? "";
    _monthsController.text = provider.personName == 'ME'
        ? settings.get('months') ?? ""
        : settings.get('${provider.personName}:months') ?? "";
    _yearsController.text = provider.personName == 'ME'
        ? settings.get('years') ?? ""
        : settings.get('${provider.personName}:years') ?? "";

    _fastingDays1Controller.text = provider.personName == 'ME'
        ? settings.get('fastingDays') ?? ""
        : settings.get('${provider.personName}:fastingDays') ?? "";
    _fastingMonths1Controller.text = provider.personName == 'ME'
        ? settings.get('fastingMonths') ?? ""
        : settings.get('${provider.personName}:fastingMonths') ?? "";
    _fastingDays2Controller.text = provider.personName == 'ME'
        ? settings.get('fastingDays2') ?? ""
        : settings.get('${provider.personName}:fastingDays2') ?? "";
    _fastingMonths2Controller.text = provider.personName == 'ME'
        ? settings.get('fastingMonths2') ?? ""
        : settings.get('${provider.personName}:fastingMonths2') ?? "";
    _fastingDays3Controller.text = provider.personName == 'ME'
        ? settings.get('fastingDays3') ?? ""
        : settings.get('${provider.personName}:fastingDays3') ?? "";
    _fastingMonths3Controller.text = provider.personName == 'ME'
        ? settings.get('fastingMonths3') ?? ""
        : settings.get('${provider.personName}:fastingMonths3') ?? "";
  }

  Future<void> deleteAllItemsForPerson(
      TheThemeProvider themeChangeProvider, boxName) async {
    final box = await Hive.box<Prayer>(boxName);
    final personName = themeChangeProvider.personName;

    // 1. Query and delete (recommended):
    await box.deleteAll(box.keys
        .where((key) => box.get(key)?.whichPerson == personName)
        .toList());

    debugPrint("deleted sccussfully");

    // 2. Alternatively, iterate and delete (less efficient for large datasets):
    // for (var key in box.keys) {
    //   final item = box.get(key);
    //   if (item?.personName == personName) {
    //     await box.delete(key);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<TheThemeProvider>(context);
    filltheFields(themeChangeProvider);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          centerTitle: true,
          actions: [
            Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    themeChangeProvider.personName == "ME" &&
                            themeChangeProvider.language == 'ar'
                        ? "نفسي"
                        : themeChangeProvider.personName,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                color: Theme.of(context).colorScheme.primaryContainer),
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => Directionality(
                            textDirection: themeChangeProvider.language == 'ar'
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: AlertDialog(
                              icon: Icon(Icons.warning_outlined),
                              title: Text(
                                  AppLocalizations.of(context)!.clearTitle),
                              content: Text(
                                AppLocalizations.of(context)!.clearContent,
                                style: const TextStyle(fontSize: 20),
                              ),
                              actions: [
                                TextButton(
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    onPressed: () => Navigator.pop(context)),
                                TextButton(
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    onPressed: () async {
                                      _daysController.text = "";
                                      _monthsController.text = "";

                                      _fastingDays1Controller.text = "";
                                      _fastingMonths1Controller.text = "";

                                      _fastingDays2Controller.text = "";
                                      _fastingMonths2Controller.text = "";

                                      _fastingDays3Controller.text = "";
                                      _fastingMonths3Controller.text = "";
                                      settings.putAll({
                                        'days': '',
                                        'months': '',
                                        'years': '',
                                        'fastingDays': '',
                                        'fastingMonths': '',
                                        'fastingDays2': '',
                                        'fastingMonths2': '',
                                        'fastingDays3': '',
                                        'fastingMonths3': '',
                                      });
                                      settings.putAll({
                                        '${themeChangeProvider.personName}:days':
                                            '',
                                        '${themeChangeProvider.personName}:months':
                                            '',
                                        '${themeChangeProvider.personName}:years':
                                            '',
                                        '${themeChangeProvider.personName}:fastingDays':
                                            '',
                                        '${themeChangeProvider.personName}:fastingMonths':
                                            '',
                                        '${themeChangeProvider.personName}:fastingDays2':
                                            '',
                                        '${themeChangeProvider.personName}:fastingMonths2':
                                            '',
                                        '${themeChangeProvider.personName}:fastingDays3':
                                            '',
                                        '${themeChangeProvider.personName}:fastingMonths3':
                                            '',
                                      });

                                      await fastingBox.clear();
                                      await peoplesBox.clear();
                                      await box
                                          .clear()
                                          .then((e) => Navigator.pop(context));
                                    })
                              ],
                            ),
                          ));
                },
                icon: Icon(Icons.delete_forever_outlined))
          ],
          title: Text(
            AppLocalizations.of(context)!.settings,
            style: TextStyle(
                fontFamily: "Lateef",
                fontSize: themeChangeProvider.fontSize + 5),
          )),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ValueListenableBuilder<Box>(
          valueListenable: Hive.box(settingsBox).listenable(),
          builder: (context, box, _) {
            return ListView(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.prayers,
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(fontSize: 20),
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _daysController.text = "";
                            },
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.numberOfDays,
                            style: TextStyle(
                                fontSize: themeChangeProvider.fontSize - 5),
                          ),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(fontSize: 20),
                      controller: _monthsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _monthsController.text = "";
                            },
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.numberOfMonths,
                            style: TextStyle(
                                fontSize: themeChangeProvider.fontSize - 5),
                          ),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(fontSize: 20),
                      controller: _yearsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _yearsController.text = "";
                            },
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.numberOfYears,
                            style: TextStyle(
                                fontSize: themeChangeProvider.fontSize - 5),
                          ),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: () async {
                        int days = int.parse(_daysController.text.isEmpty
                            ? "0"
                            : _daysController.text);
                        int months = int.parse(_monthsController.text.isEmpty
                            ? "0"
                            : _monthsController.text);
                        int years = int.parse(_yearsController.text.isEmpty
                            ? "0"
                            : _yearsController.text);
                        int numberOfPrayers =
                            days + (months * 30) + (years * 345);
                        if (themeChangeProvider.personName == 'ME') {
                          settings.putAll({
                            'days': _daysController.text,
                            'months': _monthsController.text,
                            'years': _yearsController.text
                          });
                        } else {
                          settings.putAll({
                            '${themeChangeProvider.personName}:days':
                                _daysController.text,
                            '${themeChangeProvider.personName}:months':
                                _monthsController.text,
                            '${themeChangeProvider.personName}:years':
                                _yearsController.text
                          });
                        }

                        await deleteAllItemsForPerson(
                            themeChangeProvider, boxName);

                        if (numberOfPrayers > 0) {
                          await Hive.box<Prayer>(boxName).putAll({
                            "1-الصبح:${themeChangeProvider.personName}": Prayer(
                                "الصبح",
                                numberOfPrayers,
                                0,
                                themeChangeProvider.personName),
                            "2-الظهر:${themeChangeProvider.personName}": Prayer(
                                "الظهر",
                                numberOfPrayers,
                                0,
                                themeChangeProvider.personName),
                            "3-العصر:${themeChangeProvider.personName}": Prayer(
                                "العصر",
                                numberOfPrayers,
                                0,
                                themeChangeProvider.personName),
                            "4-المغرب:${themeChangeProvider.personName}":
                                Prayer("المغرب", numberOfPrayers, 0,
                                    themeChangeProvider.personName),
                            "5-العشاء:${themeChangeProvider.personName}":
                                Prayer("العشاء", numberOfPrayers, 0,
                                    themeChangeProvider.personName),
                          }).then((value) => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .successSnackBarMessagePrayers(
                                            themeChangeProvider.personName ==
                                                        'ME' &&
                                                    themeChangeProvider
                                                            .language ==
                                                        'ar'
                                                ? 'نفسي'
                                                : themeChangeProvider
                                                    .personName),
                                    style: TextStyle(fontSize: 20),
                                  ))));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      icon: const Icon(Icons.calculate),
                      label: Text(
                          "${AppLocalizations.of(context)!.calculateBtn} ${AppLocalizations.of(context)!.prayers}",
                          style: TextStyle(
                              fontSize: themeChangeProvider.fontSize - 8))),
                  const SizedBox(height: 40),
                  Text(AppLocalizations.of(context)!.fasting,
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 22),
                  ExpansionTile(
                    title: Text(
                        AppLocalizations.of(context)!
                            .fastingTypes(AppLocalizations.of(context)!.alqada),
                        style: TextStyle(
                            fontSize: themeChangeProvider.fontSize + 5)),
                    children: [
                      const SizedBox(height: 15),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingDays1Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingDays1Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfDays,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingMonths1Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingMonths1Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfMonths,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                          onPressed: () async {
                            int fastingDays = int.parse(
                                _fastingDays1Controller.text.isEmpty
                                    ? "0"
                                    : _fastingDays1Controller.text);
                            int fastingMonths = int.parse(
                                _fastingMonths1Controller.text.isEmpty
                                    ? "0"
                                    : _fastingMonths1Controller.text);

                            int numberOfFastingDays =
                                fastingDays + (fastingMonths * 30);
                            if (themeChangeProvider.personName == 'ME') {
                              settings.putAll({
                                'fastingDays': _fastingDays1Controller.text,
                                'fastingMonths': _fastingMonths1Controller.text,
                              });
                            } else {
                              settings.putAll({
                                '${themeChangeProvider.personName}:fastingDays':
                                    _fastingDays1Controller.text,
                                '${themeChangeProvider.personName}:fastingMonths':
                                    _fastingMonths1Controller.text,
                              });
                            }

                            if (numberOfFastingDays > 0) {
                              await Hive.box<Prayer>(boxName2)
                                  .put(
                                      'قضاء:${themeChangeProvider.personName}',
                                      Prayer("قضاء", numberOfFastingDays, 0,
                                          themeChangeProvider.personName))
                                  .then((value) => ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .successSnackBarMessage(
                                                    themeChangeProvider
                                                                .personName ==
                                                            'ME'
                                                        ? 'نفسي'
                                                        : themeChangeProvider
                                                            .personName,
                                                    AppLocalizations.of(
                                                            context)!
                                                        .fastingTypes(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .alqada)),
                                            style: TextStyle(fontSize: 20),
                                          ))));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                          icon: const Icon(Icons.calculate),
                          label: Text(
                              AppLocalizations.of(context)!.calculateFastingBtn(
                                  AppLocalizations.of(context)!.alqada),
                              style: TextStyle(
                                  fontSize: themeChangeProvider.fontSize - 8))),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                        AppLocalizations.of(context)!.fastingTypes(
                            AppLocalizations.of(context)!.alnadhar),
                        style: TextStyle(
                            fontSize: themeChangeProvider.fontSize + 5)),
                    children: [
                      const SizedBox(height: 15),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingDays2Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingDays2Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfDays,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingMonths2Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingMonths2Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfMonths,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                          onPressed: () async {
                            int fastingDays2 = int.parse(
                                _fastingDays2Controller.text.isEmpty
                                    ? "0"
                                    : _fastingDays2Controller.text);
                            int fastingMonths2 = int.parse(
                                _fastingMonths2Controller.text.isEmpty
                                    ? "0"
                                    : _fastingMonths2Controller.text);

                            int numberOfFastingDays2 =
                                fastingDays2 + (fastingMonths2 * 30);
                            if (themeChangeProvider.personName == 'ME') {
                              settings.putAll({
                                'fastingDays2': _fastingDays2Controller.text,
                                'fastingMonths2':
                                    _fastingMonths2Controller.text,
                              });
                            } else {
                              settings.putAll({
                                '${themeChangeProvider.personName}:fastingDays2':
                                    _fastingDays2Controller.text,
                                '${themeChangeProvider.personName}:fastingMonths2':
                                    _fastingMonths2Controller.text,
                              });
                            }

                            if (numberOfFastingDays2 > 0) {
                              await Hive.box<Prayer>(boxName2)
                                  .put(
                                      'نذر:${themeChangeProvider.personName}',
                                      Prayer("نذر", numberOfFastingDays2, 0,
                                          themeChangeProvider.personName))
                                  .then((value) => ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .successSnackBarMessage(
                                                    themeChangeProvider
                                                                .personName ==
                                                            'ME'
                                                        ? 'نفسي'
                                                        : themeChangeProvider
                                                            .personName,
                                                    AppLocalizations.of(
                                                            context)!
                                                        .fastingTypes(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .alnadhar)),
                                            style: TextStyle(fontSize: 20),
                                          ))));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                          icon: const Icon(Icons.calculate),
                          label: Text(
                              AppLocalizations.of(context)!.calculateFastingBtn(
                                  AppLocalizations.of(context)!.alnadhar),
                              style: TextStyle(
                                  fontSize: themeChangeProvider.fontSize - 8))),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                        AppLocalizations.of(context)!.fastingTypes(
                            AppLocalizations.of(context)!.alkafaara),
                        style: TextStyle(
                            fontSize: themeChangeProvider.fontSize + 5)),
                    children: [
                      const SizedBox(height: 15),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingDays3Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingDays3Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfDays,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: 20),
                          controller: _fastingMonths3Controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _fastingMonths3Controller.text = "";
                                },
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.numberOfMonths,
                                style: TextStyle(
                                    fontSize: themeChangeProvider.fontSize - 5),
                              ),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                          onPressed: () async {
                            int fastingDays3 = int.parse(
                                _fastingDays3Controller.text.isEmpty
                                    ? "0"
                                    : _fastingDays3Controller.text);
                            int fastingMonths3 = int.parse(
                                _fastingMonths3Controller.text.isEmpty
                                    ? "0"
                                    : _fastingMonths3Controller.text);

                            int numberOfFastingDays3 =
                                fastingDays3 + (fastingMonths3 * 30);
                            if (themeChangeProvider.personName == 'ME') {
                              settings.putAll({
                                'fastingDays3': _fastingDays3Controller.text,
                                'fastingMonths3':
                                    _fastingMonths3Controller.text,
                              });
                            } else {
                              settings.putAll({
                                '${themeChangeProvider.personName}:fastingDays3':
                                    _fastingDays3Controller.text,
                                '${themeChangeProvider.personName}:fastingMonths3':
                                    _fastingMonths3Controller.text,
                              });
                            }

                            if (numberOfFastingDays3 > 0) {
                              await Hive.box<Prayer>(boxName2)
                                  .put(
                                      'كفارة:${themeChangeProvider.personName}',
                                      Prayer("كفارة", numberOfFastingDays3, 0,
                                          themeChangeProvider.personName))
                                  .then((value) => ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .successSnackBarMessage(
                                                    themeChangeProvider
                                                                .personName ==
                                                            'ME'
                                                        ? 'نفسي'
                                                        : themeChangeProvider
                                                            .personName,
                                                    AppLocalizations.of(
                                                            context)!
                                                        .fastingTypes(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .alkafaara)),
                                            style: TextStyle(fontSize: 20),
                                          ))));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                          icon: const Icon(Icons.calculate),
                          label: Text(
                              AppLocalizations.of(context)!.calculateFastingBtn(
                                  AppLocalizations.of(context)!.alkafaara),
                              style: TextStyle(
                                  fontSize: themeChangeProvider.fontSize - 8))),
                    ],
                  ),
                  const SizedBox(height: 20)
                ]);
          },
        ),
      ),
    );
  }
}
