import 'package:daynightbanner/daynightbanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:nebulous_weather/consts.dart';
import 'package:weather/weather.dart';
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  final TextEditingController _searchController = TextEditingController();
  final SearchController _controller = SearchController();
  
  Weather? _weather;
  String? _locationName;

  var _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    Permission.location.request().then((result) {
      if (result.isGranted) {
        Geolocator.getCurrentPosition().then((position) {
          _wf.currentWeatherByLocation(position.latitude, position.longitude).then((w) {
            setState(() {
              _weather = w;
              _locationName = "${_weather!.areaName!}, ${_weather!.country!}";
            });
          });
        });
      }
      else if (result.isPermanentlyDenied) {
        openAppSettings();
      }
      else {
        SystemChannels.navigation.invokeMethod("SystemNavigator.pop");
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    setState(() {
      _now = DateTime.now();
    });
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));

    _now = DateTime.now();

    
    _wf.currentWeatherByCityName(_weather!.areaName!).then((w) {
      setState(() {
        _weather = w;
        _locationName = "${_weather!.areaName!}, ${_weather!.country!}";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 10.0,
        child: ListView(
          physics: const PageScrollPhysics(),
          children: [
            DayNightBanner(
              hour: TimeOfDay.now().hour,
              backgroundImage: "assets/weather_app_bg.png",
              backgroundImageHeight: MediaQuery.sizeOf(context).height,
              bannerHeight: MediaQuery.sizeOf(context).height,
              child: _buildUI(),
            )
          ]
        )
      ),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.sizeOf(context).width * 0.80,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /*
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
            _searchBar(),
            */
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
            Container(
              decoration: BoxDecoration(color: const Color.fromARGB(102, 50, 52, 58), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _locationHeader(),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.08,
                  ),
                  _dateTimeInfo(),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.05,
                  ),
                  _weatherIcon(),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.02,
                  ),
                  _currentTemp(),
                ]
              ),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
            Container(
              child: _extraInfo(),
            )
          ],
        )
      )
    );
  }

  // Dsiplays the location header.
  Widget _locationHeader() {
    return Text(
      _locationName!,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white
      ),
    );
  }

  // Display the date and time.
  Widget _dateTimeInfo() {
    return Column(
      children: [
        Text(
          DateFormat("h:mm a").format(_now),
          style: const TextStyle(
            fontSize: 30,
            color: Colors.white
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat("EEEE").format(_now),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white
              ),
            ),
            Text(
              "  ${DateFormat("dd/MM/yyyy").format(_now)}",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white
              ),
            ),
          ],
        )
      ],
    );
  }

  // Displays the weather status.
  Widget _weatherIcon() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.20,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: _weatherIconMap[_getDayOrNight()]![_weather!.weatherConditionCode!]!.image
            ),
          ),
        ),
        Text(
          _weather?.weatherDescription ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20
          ),
        )
      ],
    );
  }

  // Displays the current temperature.
  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0)}º C",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 60,
        fontWeight: FontWeight.w500
      ),
    );
  }

  // Displays extra info.
  Widget _extraInfo() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(color: const Color.fromARGB(102, 50, 52, 58), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    "Max: ${_weather!.tempMax!.celsius!.toStringAsFixed(0)}º C",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Min: ${_weather!.tempMin!.celsius!.toStringAsFixed(0)}º C",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    )
                  ),
                ],
              ),
              const Icon(Icons.thermostat_outlined, color: Colors.white)
            ]
          ),
        ),
        SizedBox(width: MediaQuery.sizeOf(context).width * 0.03),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(color: const Color.fromARGB(102, 50, 52, 58), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    "Wind: ${_weather?.windSpeed?.toStringAsFixed(0)}m/s",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    )
                  ),
                  Text(
                    "Humidity: ${_weather?.humidity?.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    )
                  )
                ]
              ),
              const Icon(Icons.cloud, color: Colors.white)
            ]
          )
        )
      ]
    );
  }

  Widget _searchBar() {
    return SearchAnchor(
      searchController: _controller,
      viewHintText: 'Search a location...',
      viewTrailing: [
        IconButton(
          onPressed: () {

          },
          icon: const Icon(Icons.my_location)
        ),
        IconButton(
          onPressed: () {
            _controller.clear();
            _controller.closeView(_searchController.text);
          },
          icon: const Icon(Icons.clear)
        )
      ],
      viewLeading: IconButton(
        onPressed: () {

        },
        icon: const Icon(Icons.search)
      ),
      builder: (context, controller) {
        return SearchBar(
          controller: _searchController,
          hintText: "Search a location...",
          leading: IconButton(
            onPressed: () {

            },
            icon: const Icon(Icons.search)
          ),
          trailing: [
            IconButton(
              onPressed: () {

              },
              icon: const Icon(Icons.my_location)
            ),
          ],
          onTap: () => _controller.openView(),
          //onChanged: () => ,
        );
      },
      suggestionsBuilder: (context, controller) async {
        return [
         
        ];
      },
    );
  }

  final _weatherIconMap = <String, Map<int, Image>> {
    "Day": {
      200: Image.asset("assets/day_rain_thunder.png"),
      201: Image.asset("assets/rain_thunder.png"),
      202: Image.asset("assets/rain_thunder.png"),
      210: Image.asset("assets/thunder.png"),
      211: Image.asset("assets/thunder.png"),
      212: Image.asset("assets/thunder.png"),
      221: Image.asset("assets/thunder.png"),
      230: Image.asset("assets/rain_thunder.png"),
      231: Image.asset("assets/rain_thunder.png"),
      232: Image.asset("assets/rain_thunder.png"),
      300: Image.asset("assets/day_rain.png"),
      301: Image.asset("assets/rain.png"),
      302: Image.asset("assets/rain.png"),
      310: Image.asset("assets/day_rain.png"),
      311: Image.asset("assets/rain.png"),
      312: Image.asset("assets/rain.png"),
      313: Image.asset("assets/rain.png"),
      314: Image.asset("assets/rain.png"),
      321: Image.asset("assets/rain.png"),
      500: Image.asset("assets/day_rain.png"),
      501: Image.asset("assets/rain.png"),
      502: Image.asset("assets/rain.png"),
      503: Image.asset("assets/rain.png"),
      504: Image.asset("assets/rain_thunder.png"),
      511: Image.asset("assets/snow.png"),
      520: Image.asset("assets/day_rain.png"),
      521: Image.asset("assets/rain.png"),
      522: Image.asset("assets/rain.png"),
      531: Image.asset("assets/rain.png"),
      600: Image.asset("assets/day_snow.png"),
      601: Image.asset("assets/snow.png"),
      602: Image.asset("assets/snow.png"),
      611: Image.asset("assets/day_sleet.png"),
      612: Image.asset("assets/sleet.png"),
      613: Image.asset("assets/sleet.png"),
      615: Image.asset("assets/day_snow.png"),
      616: Image.asset("assets/snow.png"),
      620: Image.asset("assets/snow.png"),
      621: Image.asset("assets/snow.png"),
      622: Image.asset("assets/snow.png"),
      701: Image.asset("assets/mist.png"),
      711: Image.asset("assets/mist.png"),
      721: Image.asset("assets/mist.png"),
      731: Image.asset("assets/wind.png"),
      741: Image.asset("assets/fog.png"),
      751: Image.asset("assets/wind.png"),
      761: Image.asset("assets/mist.png"),
      762: Image.asset("assets/angry_clouds.png"),
      771: Image.asset("assets/wind.png"),
      781: Image.asset("assets/tornado.png"),
      800: Image.asset("assets/day_clear.png"),
      801: Image.asset("assets/day_partial_cloud.png"),
      802: Image.asset("assets/cloudy.png"),
      803: Image.asset("assets/angry_clouds.png"),
      804: Image.asset("assets/overcast.png"),
    },
    "Night": {
      200: Image.asset("assets/night_half_moon_rain_thunder.png"),
      201: Image.asset("assets/rain_thunder.png"),
      202: Image.asset("assets/rain_thunder.png"),
      210: Image.asset("assets/thunder.png"),
      211: Image.asset("assets/thunder.png"),
      212: Image.asset("assets/thunder.png"),
      221: Image.asset("assets/thunder.png"),
      230: Image.asset("assets/rain_thunder.png"),
      231: Image.asset("assets/rain_thunder.png"),
      232: Image.asset("assets/rain_thunder.png"),
      300: Image.asset("assets/night_half_moon_rain.png"),
      301: Image.asset("assets/rain.png"),
      302: Image.asset("assets/rain.png"),
      310: Image.asset("assets/night_half_moon_rain.png"),
      311: Image.asset("assets/rain.png"),
      312: Image.asset("assets/rain.png"),
      313: Image.asset("assets/rain.png"),
      314: Image.asset("assets/rain.png"),
      321: Image.asset("assets/rain.png"),
      500: Image.asset("assets/night_half_moon_rain.png"),
      501: Image.asset("assets/rain.png"),
      502: Image.asset("assets/rain.png"),
      503: Image.asset("assets/rain.png"),
      504: Image.asset("assets/night_half_moon_rain_thunder.png"),
      511: Image.asset("assets/snow.png"),
      520: Image.asset("assets/night_half_moon_rain.png"),
      521: Image.asset("assets/rain.png"),
      522: Image.asset("assets/rain.png"),
      531: Image.asset("assets/rain.png"),
      600: Image.asset("assets/night_half_moon_snow.png"),
      601: Image.asset("assets/snow.png"),
      602: Image.asset("assets/snow.png"),
      611: Image.asset("assets/night_half_moon_sleet.png"),
      612: Image.asset("assets/sleet.png"),
      613: Image.asset("assets/sleet.png"),
      615: Image.asset("assets/night_half_moon_snow.png"),
      616: Image.asset("assets/snow.png"),
      620: Image.asset("assets/snow.png"),
      621: Image.asset("assets/snow.png"),
      622: Image.asset("assets/snow.png"),
      701: Image.asset("assets/mist.png"),
      711: Image.asset("assets/mist.png"),
      721: Image.asset("assets/mist.png"),
      731: Image.asset("assets/wind.png"),
      741: Image.asset("assets/fog.png"),
      751: Image.asset("assets/wind.png"),
      761: Image.asset("assets/mist.png"),
      762: Image.asset("assets/angry_clouds.png"),
      771: Image.asset("assets/wind.png"),
      781: Image.asset("assets/tornado.png"),
      800: Image.asset("assets/night_half_moon_clear.png"),
      801: Image.asset("assets/night_half_moon_partial_cloud.png"),
      802: Image.asset("assets/cloudy.png"),
      803: Image.asset("assets/angry_clouds.png"),
      804: Image.asset("assets/overcast.png"),
    }
  };

  String _getDayOrNight() {
    int myHour = TimeOfDay.now().hour;
    return (myHour >= 6 && myHour < 18) ? "Day" : "Night";
  }
}
