import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/data/key.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      apiKey,
      'shopping-list.json',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later ';
        });
      }
      debugPrint(response.body);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(
        response.body,
      );
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    // _loadItems();
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _showInfoMessage(String name, [IconData icon = Icons.check]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(icon),
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                '${name} has been removed',
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _onRemoveGrocery(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    _showInfoMessage(
      item.name,
    );

    final url = Uri.https(
      apiKey,
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);
    debugPrint(response.statusCode.toString());
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      _showInfoMessage(
        'Failed to remove ${item.name}. Please Try again later,',
        Icons.warning_amber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text('No Grocery item added yet.'),
    );
    if (_groceryItems.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          final item = _groceryItems[index];
          return Dismissible(
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red,
              // decoration: BoxDecoration(
              //   // shape: BoxShape.rectangle,
              //   borderRadius: BorderRadius.circular(16),
              // ),
            ),
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) => _onRemoveGrocery(_groceryItems[index]),
            child: ListTile(
              title: Text(item.name.toString()),
              leading: Container(
                width: 24,
                height: 24,
                color: item.category.color,
              ),
              trailing: Text(item.quantity.toString()),
            ),
          );
        },
      );
    }
    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 147, 229, 250),
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      mainContent = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        elevation: 5,
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: mainContent,
    );
  }
}
