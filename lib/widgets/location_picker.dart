import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/fare_service.dart';
import '../theme.dart';

class LocationPicker extends StatelessWidget {
  final String label;
  final Location? value;
  final ValueChanged<Location> onChanged;
  final IconData icon;

  const LocationPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.location_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Autocomplete<Location>(
          initialValue: value != null 
              ? TextEditingValue(text: value!.name) 
              : const TextEditingValue(text: ''),
          displayStringForOption: (Location option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<Location>.empty();
            }
            return FareCalculatorService().searchLocations(textEditingValue.text);
          },
          onSelected: onChanged,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                hintText: "Search location...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: Theme.of(context).cardColor,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Location option = options.elementAt(index);
                      return ListTile(
                        leading: _getIconForType(option.type),
                        title: Text(option.name),
                        subtitle: Text(option.type.name.toUpperCase()),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Icon _getIconForType(LocationType type) {
    switch (type) {
      case LocationType.rank: return const Icon(Icons.local_taxi, size: 20);
      case LocationType.township: return const Icon(Icons.home_work, size: 20);
      case LocationType.mall: return const Icon(Icons.shopping_bag, size: 20);
      default: return const Icon(Icons.place, size: 20);
    }
  }
}
