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
      // UI MODERNIZATION: Updated theme with blue color scheme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // CHANGED: Purple to blue
          brightness: Brightness.light,
          // UI MODERNIZATION: Enhanced color palette
          primary: Colors.blue, // CHANGED: Purple to blue
          secondary: Colors.amber,
          // FIX: Replace deprecated 'background' with 'surface'
          surface: Colors.grey[50],
        ),
        useMaterial3: true,
        // UI MODERNIZATION: Better typography
        typography: Typography.material2021(),
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.blue.shade800, // CHANGED: Purple to blue
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        // UI MODERNIZATION: Enhanced card theme
        // FIX: Change CardTheme to CardThemeData
        cardTheme: CardThemeData(
          elevation: 2,
          // FIX: Replace deprecated withOpacity with color manipulation
          shadowColor: Color.alphaBlend(
            Colors.blue.withAlpha((0.1 * 255).round()), // CHANGED: Purple to blue
            Colors.transparent
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        // UI MODERNIZATION: Better input decoration
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2), // CHANGED: Purple to blue
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
  
  // NEW: Sorting functionality state
  String _sortBy = 'id'; // 'id', 'title'
  bool _sortAscending = true;
  
  // NEW: Get displayed books with sorting applied
  Map<String, String> get _displayedBooks {
    Map<String, String> books;
    if (_searchQuery.isEmpty) {
      books = Map.from(_library);
    } else {
      books = _library.entries.where((entry) {
        return entry.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.value.toLowerCase().contains(_searchQuery.toLowerCase());
      }).fold<Map<String, String>>({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      });
    }
    
    // NEW: Apply sorting
    final entries = books.entries.toList();
    entries.sort((a, b) {
      int result;
      if (_sortBy == 'id') {
        // Sort by ID (alphanumeric)
        result = a.key.compareTo(b.key);
      } else {
        // Sort by Title (alphabetical)
        result = a.value.compareTo(b.value);
      }
      return _sortAscending ? result : -result;
    });
    
    return Map.fromEntries(entries);
  }

  // ← ADD THIS METHOD: Load books when app starts
  @override
  void initState() {
    super.initState();
    _loadBooks();
    
    // FIX: Add listener for real-time search
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // FIX: Dispose the controller properly
    _searchController.dispose();
    super.dispose();
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

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _searchText = '';
    });
  }

  // NEW: Toggle sorting method
  void _toggleSortBy(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        // Toggle direction if same sort method
        _sortAscending = !_sortAscending;
      } else {
        // Change sort method and reset to ascending
        _sortBy = newSortBy;
        _sortAscending = true;
      }
    });
  }

  // NEW: Get sort icon based on current state
  IconData _getSortIcon(String sortType) {
    if (_sortBy != sortType) {
      return Icons.sort;
    }
    return _sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // UI MODERNIZATION: Enhanced dialog styling
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox( // FIX: Consistent dialog size
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // UI MODERNIZATION: Better error icon
                  Icon(Icons.error_outline, size: 48, color: Colors.amber[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // CHANGED: Purple to blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    builder: (BuildContext dialogContext) {   // ← renamed to dialogContext
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // UI MODERNIZATION: Modern dialog design
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox( // FIX: Consistent dialog size
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UI MODERNIZATION: Better header with icon
                    Row(
                      children: [
                        Icon(
                          isEditing ? Icons.edit : Icons.add_circle,
                          size: 28,
                          color: Colors.blue, // CHANGED: Purple to blue
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Edit Book' : 'Add New Book',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        labelText: 'Book ID',
                        prefixIcon: const Icon(Icons.numbers),
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Book Title',
                        prefixIcon: const Icon(Icons.title),
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
                    const SizedBox(height: 24),
                    
                    // FIX: Consistent button layout - horizontal
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
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

                              // Save the changes first
                              final Map<String, String> newLibrary = Map.from(_library);
                              if (isEditing && bookId != newId) {
                                newLibrary.remove(bookId);
                              }
                              newLibrary[newId] = newTitle;

                              // Update state and save to storage
                              if (mounted) {
                                setState(() {
                                  _library.clear();
                                  _library.addAll(newLibrary);
                                });
                                await _saveBooks();
                              }
                              
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                _clearSearch();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(isEditing ? 'Update' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  void _showBookActionsDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // UI MODERNIZATION: Enhanced actions dialog
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox( // FIX: Consistent dialog size
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // UI MODERNIZATION: Better header
                  Text(
                    'Book Actions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${_library[bookId]}"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'ID: $bookId',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // FIX: Consistent vertical button layout
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _showAddEditBookDialog(bookId: bookId);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _showDeleteConfirmationDialog(bookId);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // UI MODERNIZATION: Enhanced delete confirmation
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox( // FIX: Consistent dialog size
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 48, color: Colors.orange[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Confirm Delete',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${_library[bookId]}"?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // FIX: Consistent horizontal button layout
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _library.remove(bookId);
                            });
                            
                            await _saveBooks();
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              _clearSearch();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI MODERNIZATION: Enhanced AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue, // CHANGED: Purple to blue
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        // UI MODERNIZATION: Better AppBar styling
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Container(
        // UI MODERNIZATION: Background color
        color: Colors.grey[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // UI MODERNIZATION: Enhanced search section
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Search Books',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter book ID or title...',
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                          _searchQuery = value.trim();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FIX: Add Book button in same row as Books counter
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Books in Library:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _searchQuery.isNotEmpty ? Colors.blue[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_displayedBooks.length} book${_displayedBooks.length != 1 ? 's' : ''}${_searchQuery.isNotEmpty ? ' found' : ''}',
                              style: TextStyle(
                                color: _searchQuery.isNotEmpty ? Colors.blue[700] : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // FIX: Add Book button placed here in the same row
                Card(
                  elevation: 2,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _showAddEditBookDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Add Book',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // NEW: Sorting controls - CLEAN VERSION
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort by ID button
                    OutlinedButton.icon(
                      onPressed: () => _toggleSortBy('id'),
                      icon: Icon(
                        _getSortIcon('id'),
                        size: 16,
                        color: _sortBy == 'id' ? Colors.blue : Colors.grey,
                      ),
                      label: Text(
                        'ID',
                        style: TextStyle(
                          color: _sortBy == 'id' ? Colors.blue : Colors.grey,
                          fontWeight: _sortBy == 'id' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort by Title button
                    OutlinedButton.icon(
                      onPressed: () => _toggleSortBy('title'),
                      icon: Icon(
                        _getSortIcon('title'),
                        size: 16,
                        color: _sortBy == 'title' ? Colors.blue : Colors.grey,
                      ),
                      label: Text(
                        'Title',
                        style: TextStyle(
                          color: _sortBy == 'title' ? Colors.blue : Colors.grey,
                          fontWeight: _sortBy == 'title' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Sort order indicator - CLEAN EXPLICIT LABEL
                    Text(
                      _sortAscending ? 'Ascending' : 'Descending',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // UI MODERNIZATION: Enhanced books list
            Expanded(
              child: _displayedBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No books in the library yet'
                                : 'No books found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tap the + button to add your first book!'
                                : 'Try a different search term',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.book, color: Colors.blue),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'ID: $bookId',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.more_vert, size: 18),
                              ),
                              onPressed: () => _showBookActionsDialog(bookId),
                            ),
                            onTap: () {
                              setState(() {
                                _searchController.text = bookId;
                                _searchText = bookId;
                                _searchQuery = bookId;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}