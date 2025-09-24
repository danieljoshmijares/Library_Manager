import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // ← ADD THIS IMPORT
import 'dart:convert';  // ← ADD THIS IMPORT for JSON encoding

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Library Transaction System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Library Transaction System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Map<String, String> _library = {};
  final TextEditingController _searchController = TextEditingController();
  
  // Track text field content for clear buttons
  String _searchText = '';
  String _dialogIdText = '';
  String _dialogTitleText = '';
  
  // Search functionality state
  String _searchQuery = '';
  Map<String, String> get _displayedBooks {
    if (_searchQuery.isEmpty) {
      return _library;
    }
    return _library.entries.where((entry) {
      return entry.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.value.toLowerCase().contains(_searchQuery.toLowerCase());
    }).fold<Map<String, String>>({}, (map, entry) {
      map[entry.key] = entry.value;
      return map;
    });
  }

  // ← ADD THIS METHOD: Load books when app starts
  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  // ← ADD THIS METHOD: Load books from storage
  Future<void> _loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString('library_books');
      if (booksJson != null) {
        final decoded = jsonDecode(booksJson);
        setState(() {
          _library.clear();
          _library.addAll(Map<String, String>.from(decoded));
        });
      }
    } catch (e) {
      // Silent fail - if loading fails, just start with empty library
    }
  }

  // ← ADD THIS METHOD: Save books to storage
  Future<void> _saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = jsonEncode(_library);
      await prefs.setString('library_books', booksJson);
    } catch (e) {
      // Silent fail - if saving fails, data just won't persist
    }
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _searchText = '';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditBookDialog({String? bookId}) {
    bool isEditing = bookId != null;
    final TextEditingController idController = TextEditingController(text: bookId ?? '');
    final TextEditingController titleController = TextEditingController(
        text: bookId != null ? _library[bookId] : '');

    // Initialize dialog text trackers
    _dialogIdText = idController.text;
    _dialogTitleText = titleController.text;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Book' : 'Add New Book'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: 'Book ID',
                      suffixIcon: _dialogIdText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                idController.clear();
                                setDialogState(() {
                                  _dialogIdText = '';
                                });
                              },
                            )
                          : null,
                    ),
                    enabled: !isEditing,
                    onChanged: (value) {
                      setDialogState(() {
                        _dialogIdText = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Book Title',
                      suffixIcon: _dialogTitleText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                titleController.clear();
                                setDialogState(() {
                                  _dialogTitleText = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _dialogTitleText = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {  // ← CHANGED: Added async
                    final String newId = idController.text.trim();
                    final String newTitle = titleController.text.trim();
                    
                    if (newId.isEmpty || newTitle.isEmpty) {
                      _showErrorDialog('Please enter both ID and Title.');
                      return;
                    }

                    // PREVENT DUPLICATE ID WHEN ADDING NEW BOOK
                    if (!isEditing && _library.containsKey(newId)) {
                      _showErrorDialog('Book ID "$newId" already exists. Please use a different ID.');
                      return;
                    }

                    setState(() {
                      if (isEditing && bookId != newId) {
                        _library.remove(bookId);
                      }
                      _library[newId] = newTitle;
                    });

                    await _saveBooks();  // ← ADDED: Save after changes
                    
                    Navigator.of(context).pop();
                    _clearSearch();
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBookActionsDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Book Actions'),
          content: Text('Choose an action for "${_library[bookId]}" (ID: $bookId)'),
          actions: [
            // All actions now use consistent ElevatedButton styling
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddEditBookDialog(bookId: bookId);
              },
              child: const Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(bookId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${_library[bookId]}"?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {  // ← CHANGED: Added async
                setState(() {
                  _library.remove(bookId);
                });

                await _saveBooks();  // ← ADDED: Save after deletion
                
                Navigator.of(context).pop();
                _clearSearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- SEARCH SECTION ---
            const Text(
              'Search Books:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Search by Book ID or Title',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Clear button appears when typing, on the LEFT
                          if (_searchText.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                              padding: const EdgeInsets.only(right: 4),
                            ),
                          // Search icon button (always visible) on the RIGHT
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _performSearch,
                            padding: const EdgeInsets.only(left: 4),
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- BOOKS COUNTER ---
            Row(
              children: [
                const Text(
                  'Books in Library:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Text(
                  '(${_displayedBooks.length} books${_searchQuery.isNotEmpty ? ' found' : ''})',
                  style: TextStyle(
                    color: _searchQuery.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- BOOKS LIST ---
            Expanded(
              child: _displayedBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No books in the library yet.\nStart by adding a book!'
                                : 'No books found for "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _displayedBooks.length,
                      itemBuilder: (context, index) {
                        String bookId = _displayedBooks.keys.elementAt(index);
                        String title = _displayedBooks[bookId]!;
                        
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.book),
                            title: Text(title),
                            subtitle: Text('ID: $bookId'),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showBookActionsDialog(bookId),
                            ),
                            onTap: () {
                              setState(() {
                                _searchController.text = bookId;
                                _searchText = bookId;
                                _performSearch();
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBookDialog(),
        tooltip: 'Add Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}