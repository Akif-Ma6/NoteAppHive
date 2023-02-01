import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('Note_box');
  await Hive.openBox('Note_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes.com',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _notes = [];

  final _noteBox = Hive.box('Note_box');

  @override
  void initState() {
    super.initState();
    _refreshNotes(); // Load data when app starts
  }

  // Get all items from the database
  void _refreshNotes() {
    final data = _noteBox.keys.map((key) {
      final value = _noteBox.get(key);
      return {"key": key, "title": value["title"], "New Note": value['New Note']};
    }).toList();

    setState(() {
      _notes = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // Create new note
  Future<void> _createNote(Map<String, dynamic> newNote) async {
    await _noteBox.add(newNote);
    _refreshNotes(); // update the UI
  }

  // Retrieve a single note from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> _readNote(int key) {
    final note = _noteBox.get(key);
    return note;
  }

  // Update a single note
  Future<void> _updateNote(int noteKey, Map<String, dynamic> note) async {
    await _noteBox.put(noteKey, note);
    _refreshNotes(); // Update the UI
  }

  // Delete a single note
  Future<void> _deleteNote(int noteKey) async {
    await _noteBox.delete(noteKey);
    _refreshNotes(); // update the UI

    // Display a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An note has been deleted')));
  }

  // TextFields' controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an note
  void _showForm(BuildContext ctx, int? noteKey) async {
    // noteKey == null -> create new note
    // noteKey != null -> update an existing note

    if (noteKey != null) {
      final existingItem =
          _notes.firstWhere((element) => element['key'] == noteKey);
      _titleController.text = existingItem['title'];
      _noteController.text = existingItem['New Note'];
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _noteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Note'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new note
                      if (noteKey == null) {
                        _createNote({
                          "title": _titleController.text,
                          "New Note": _noteController.text
                        });
                      }

                      // update an existing note
                      if (noteKey != null) {
                        _updateNote(noteKey, {
                          'title': _titleController.text.trim(),
                          'New Note': _noteController.text.trim()
                        });
                      }

                      // Clear the text fields
                      _titleController.text = '';
                      _noteController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(noteKey == null ? 'Create New' : 'Update'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes.com'),
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: _notes.length,
              itemBuilder: (_, index) {
                final currentItem = _notes[index];
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                      title: Text(currentItem['title']),
                      subtitle: Text(currentItem['New Note'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showForm(context, currentItem['key'])),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteNote(currentItem['key']),
                          ),
                        ],
                      )),
                );
              }),
      // Add new note button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
