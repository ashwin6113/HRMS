import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../widgets/custom_search_bar.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Search"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            StaticSearchBar(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search...',
            ),
            SizedBox(height: 16),
            Center(child: Text("Search Screen")),
          ],
        ),
      ),
    );
  }
}
