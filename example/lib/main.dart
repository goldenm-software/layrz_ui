import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: kAppTitle,
      theme: LayrzThemeData.light(),
      darkTheme: LayrzThemeData.dark(),
      themeMode: LayrzThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ColoredBox(
      color: theme.backgroundColor,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'layrz_ui Example',
                style: theme.textTheme.headlineSmall.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Button taps: $_counter',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _counter++),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                  ),
                  child: Text(
                    'Tap me',
                    style: theme.textTheme.labelLarge.copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Brightness: ${theme.brightness.name}',
                style: theme.textTheme.bodySmall.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
