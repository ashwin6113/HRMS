import 'package:flutter/material.dart';
import 'package:hrms/widgets/widgets.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "HomeScreen",
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: Column(
        children: [
          Text("This is the home screen"),
        ],
      )),
    );
  }
}
