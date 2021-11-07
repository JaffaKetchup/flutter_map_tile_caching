import 'package:flutter/material.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

Widget buildFloatingSearchBar(BuildContext context) {
  final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

  return FloatingSearchBar(
    hint: 'Command Palette',
    borderRadius: BorderRadius.circular(24),
    transitionDuration: const Duration(milliseconds: 500),
    transitionCurve: Curves.easeInOut,
    physics: const BouncingScrollPhysics(),
    scrollPadding: const EdgeInsets.all(0),
    axisAlignment: isPortrait ? 0.0 : -1.0,
    openAxisAlignment: 0.0,
    width: isPortrait ? 600 : 500,
    debounceDelay: const Duration(milliseconds: 500),
    onQueryChanged: (query) {
      // Call your model, bloc, controller here.
    },
    // Specify a custom transition to be used for
    // animating between opened and closed stated.
    transition: ExpandingFloatingSearchBarTransition(),
    actions: [
      FloatingSearchBarAction(
        showIfOpened: false,
        child: CircularButton(
          icon: const Icon(Icons.place),
          onPressed: () {},
        ),
      ),
      FloatingSearchBarAction.searchToClear(
        showIfClosed: false,
      ),
    ],
    builder: (context, transition) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Material(
          color: Colors.white,
          elevation: 4.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Colors.accents.map((color) {
              return Container(height: 112, color: color);
            }).toList(),
          ),
        ),
      );
    },
  );
}
