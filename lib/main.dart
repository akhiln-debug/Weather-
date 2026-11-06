import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'models/weather.dart';
import 'services/weather_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherNowApp());
}

class WeatherNowApp extends StatefulWidget {
  const WeatherNowApp({super.key});

  @override
  State<WeatherNowApp> createState() => _WeatherNowAppState();
}

class _WeatherNowAppState extends State<WeatherNowApp> {
  bool fahrenheit = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherNow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3978E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6FC),
      ),
      home: WeatherHome(
        fahrenheit: fahrenheit,
        onUnitChanged: (value) {
          setState(() => fahrenheit = value);
        },
      ),
    );
  }
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear Sky';
  if (code <= 3) return 'Partly Cloudy';
  if (code <= 48) return 'Foggy';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rainy';
  if (code <= 77) return 'Snowy';
  if (code <= 82) return 'Rain Showers';
  if (code <= 86) return 'Snow Showers';
  if (code <= 99) return 'Thunderstorm';
  return 'Unknown';
}

IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.cloud_queue;
  if (code <= 48) return Icons.foggy;
  if (code <= 67) return Icons.water_drop;
  if (code <= 77) return Icons.ac_unit;
  if (code <= 82) return Icons.grain;
  return Icons.thunderstorm;
}

double displayTemp(double value, bool fahrenheit) {
  return fahrenheit ? (value * 9 / 5) + 32 : value;
}

String tempText(double value, bool fahrenheit) {
  return '${displayTemp(value, fahrenheit).round()}°'
      '${fahrenheit ? 'F' : 'C'}';
}

class WeatherHome extends StatefulWidget {
  final bool fahrenheit;
  final ValueChanged<bool> onUnitChanged;

  const WeatherHome({
    super.key,
    required this.fahrenheit,
    required this.onUnitChanged,
  });

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  WeatherData? weather;
  bool loading = false;
  String error = '';
  String city = 'Hyderabad';

  final searchController = TextEditingController();

  int selectedIndex = 0;
  List<String> savedCities = [];

  @override
  void initState() {
    super.initState();
    loadSavedCities();
    searchCity('Hyderabad');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      savedCities = prefs.getStringList('savedCities') ?? [];
    });
  }

  Future<void> saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedCities', savedCities);
  }

  Future<void> searchCity(String name) async {
    if (name.trim().isEmpty) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await WeatherService.getWeather(name.trim());

      if (!mounted) return;

      setState(() {
        weather = result;
        city = result.city;
        loading = false;
        searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'City not found or network unavailable.';
      });
    }
  }

  Future<void> toggleSavedCity() async {
    if (weather == null) return;

    setState(() {
      if (savedCities.contains(weather!.city)) {
        savedCities.remove(weather!.city);
      } else {
        savedCities.add(weather!.city);
      }
    });

    await saveCities();
  }

  void removeCity(String name) async {
    setState(() => savedCities.remove(name));
    await saveCities();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      homeScreen(),
      forecastScreen(),
      savedScreen(),
      settingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WeatherNow ☀️',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget homeScreen() {
    return RefreshIndicator(
      onRefresh: () => searchCity(city),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: searchController,
            onSubmitted: searchCity,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => searchCity(searchController.text),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            ),

          if (error.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(error),
              ),
            ),

          if (weather != null && !loading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weather!.city,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: toggleSavedCity,
                  icon: Icon(
                    savedCities.contains(weather!.city)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Card(
              color: const Color(0xFF3978E8),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        weatherIcon(weather!.weatherCode),
                        color: Colors.white,
                        size: 85,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tempText(
                          weather!.temperature,
                          widget.fahrenheit,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weatherDescription(weather!.weatherCode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Feels like ${tempText(weather!.feelsLike, widget.fahrenheit)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Weather Details',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: detailCard(
                    Icons.water_drop,
                    'Humidity',
                    '${weather!.humidity}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: detailCard(
                    Icons.air,
                    'Wind Speed',
                    '${weather!.windSpeed} km/h',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget detailCard(IconData icon, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget forecastScreen() {
    if (weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          '7-Day Forecast',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          weather!.city,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),

        ...weather!.forecast.map((day) {
          final date = DateTime.parse(day.date);

          return Card(
            child: ListTile(
              leading: Icon(
                weatherIcon(day.code),
                color: Colors.blue,
                size: 30,
              ),
              title: Text(DateFormat('EEEE').format(date)),
              subtitle: Text(weatherDescription(day.code)),
              trailing: Text(
                '${tempText(day.max, widget.fahrenheit)} / '
                '${tempText(day.min, widget.fahrenheit)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget savedScreen() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Saved Cities',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        if (savedCities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('No saved cities yet.'),
            ),
          ),

        ...savedCities.map((name) {
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_city,
                color: Colors.blue,
              ),
              title: Text(name),
              onTap: () {
                searchCity(name);
                setState(() => selectedIndex = 0);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => removeCity(name),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget settingsScreen() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Card(
          child: SwitchListTile(
            title: const Text('Fahrenheit'),
            subtitle: Text(
              widget.fahrenheit
                  ? 'Temperature unit: Fahrenheit'
                  : 'Temperature unit: Celsius',
            ),
            value: widget.fahrenheit,
            onChanged: widget.onUnitChanged,
            secondary: const Icon(Icons.thermostat),
          ),
        ),

        Card(
          child: const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About WeatherNow'),
            subtitle: Text('Version 1.0.0'),
          ),
        ),

        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Weather data'),
            subtitle: Text('Powered by Open-Meteo'),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'models/weather.dart';
import 'services/weather_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherNowApp());
}

class WeatherNowApp extends StatefulWidget {
  const WeatherNowApp({super.key});

  @override
  State<WeatherNowApp> createState() => _WeatherNowAppState();
}

class _WeatherNowAppState extends State<WeatherNowApp> {
  bool fahrenheit = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherNow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3978E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6FC),
      ),
      home: WeatherHome(
        fahrenheit: fahrenheit,
        onUnitChanged: (value) {
          setState(() => fahrenheit = value);
        },
      ),
    );
  }
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear Sky';
  if (code <= 3) return 'Partly Cloudy';
  if (code <= 48) return 'Foggy';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rainy';
  if (code <= 77) return 'Snowy';
  if (code <= 82) return 'Rain Showers';
  if (code <= 86) return 'Snow Showers';
  if (code <= 99) return 'Thunderstorm';
  return 'Unknown';
}

IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.cloud_queue;
  if (code <= 48) return Icons.foggy;
  if (code <= 67) return Icons.water_drop;
  if (code <= 77) return Icons.ac_unit;
  if (code <= 82) return Icons.grain;
  return Icons.thunderstorm;
}

double displayTemp(double value, bool fahrenheit) {
  return fahrenheit ? (value * 9 / 5) + 32 : value;
}

String tempText(double value, bool fahrenheit) {
  return '${displayTemp(value, fahrenheit).round()}°'
      '${fahrenheit ? 'F' : 'C'}';
}

class WeatherHome extends StatefulWidget {
  final bool fahrenheit;
  final ValueChanged<bool> onUnitChanged;

  const WeatherHome({
    super.key,
    required this.fahrenheit,
    required this.onUnitChanged,
  });

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  WeatherData? weather;
  bool loading = false;
  String error = '';
  String city = 'Hyderabad';

  final searchController = TextEditingController();

  int selectedIndex = 0;
  List<String> savedCities = [];

  @override
  void initState() {
    super.initState();
    loadSavedCities();
    searchCity('Hyderabad');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      savedCities = prefs.getStringList('savedCities') ?? [];
    });
  }

  Future<void> saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedCities', savedCities);
  }

  Future<void> searchCity(String name) async {
    if (name.trim().isEmpty) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await WeatherService.getWeather(name.trim());

      if (!mounted) return;

      setState(() {
        weather = result;
        city = result.city;
        loading = false;
        searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'City not found or network unavailable.';
      });
    }
  }

  Future<void> toggleSavedCity() async {
    if (weather == null) return;

    setState(() {
      if (savedCities.contains(weather!.city)) {
        savedCities.remove(weather!.city);
      } else {
        savedCities.add(weather!.city);
      }
    });

    await saveCities();
  }

  void removeCity(String name) async {
    setState(() => savedCities.remove(name));
    await saveCities();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      homeScreen(),
      forecastScreen(),
      savedScreen(),
      settingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WeatherNow ☀️',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget homeScreen() {
    return RefreshIndicator(
      onRefresh: () => searchCity(city),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: searchController,
            onSubmitted: searchCity,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => searchCity(searchController.text),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            ),

          if (error.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(error),
              ),
            ),

          if (weather != null && !loading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weather!.city,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: toggleSavedCity,
                  icon: Icon(
                    savedCities.contains(weather!.city)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Card(
              color: const Color(0xFF3978E8),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        weatherIcon(weather!.weatherCode),
                        color: Colors.white,
                        size: 85,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tempText(
                          weather!.temperature,
                          widget.fahrenheit,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weatherDescription(weather!.weatherCode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Feels like ${tempText(weather!.feelsLike, widget.fahrenheit)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Weather Details',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: detailCard(
                    Icons.water_drop,
                    'Humidity',
                    '${weather!.humidity}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: detailCard(
                    Icons.air,
                    'Wind Speed',
                    '${weather!.windSpeed} km/h',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget detailCard(IconData icon, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget forecastScreen() {
    if (weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          '7-Day Forecast',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          weather!.city,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),

        ...weather!.forecast.map((day) {
          final date = DateTime.parse(day.date);

          return Card(
            child: ListTile(
              leading: Icon(
                weatherIcon(day.code),
                color: Colors.blue,
                size: 30,
              ),
              title: Text(DateFormat('EEEE').format(date)),
              subtitle: Text(weatherDescription(day.code)),
              trailing: Text(
                '${tempText(day.max, widget.fahrenheit)} / '
                '${tempText(day.min, widget.fahrenheit)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget savedScreen() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Saved Cities',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        if (savedCities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('No saved cities yet.'),
            ),
          ),

        ...savedCities.map((name) {
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_city,
                color: Colors.blue,
              ),
              title: Text(name),
              onTap: () {
                searchCity(name);
                setState(() => selectedIndex = 0);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => removeCity(name),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget settingsScreen() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Card(
          child: SwitchListTile(
            title: const Text('Fahrenheit'),
            subtitle: Text(
              widget.fahrenheit
                  ? 'Temperature unit: Fahrenheit'
                  : 'Temperature unit: Celsius',
            ),
            value: widget.fahrenheit,
            onChanged: widget.onUnitChanged,
            secondary: const Icon(Icons.thermostat),
          ),
        ),

        Card(
          child: const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About WeatherNow'),
            subtitle: Text('Version 1.0.0'),
          ),
        ),

        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Weather data'),
            subtitle: Text('Powered by Open-Meteo'),
          ),
        ),
      ],
    );
  }
}
