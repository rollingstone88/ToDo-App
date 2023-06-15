import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'todo_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE todos(id INTEGER PRIMARY KEY, task TEXT, isCompleted INTEGER)',
      );
    },
    version: 1,
  );

  runApp(TodoApp(database: database));
}

class TodoApp extends StatelessWidget {
  final Future<Database> database;

  TodoApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoScreen(database: database),
    );
  }
}

class TodoScreen extends StatefulWidget {
  final Future<Database> database;

  TodoScreen({required this.database});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> todos = [];
  List<Todo> completedTodos = [];

  final TextEditingController _textEditingController =
  TextEditingController();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final db = await widget.database;
    final List<Map<String, dynamic>> todoMaps = await db.query('todos');

    setState(() {
      todos = todoMaps
          .where((todo) => todo['isCompleted'] == 0)
          .map((todo) => Todo.fromMap(todo))
          .toList();

      completedTodos = todoMaps
          .where((todo) => todo['isCompleted'] == 1)
          .map((todo) => Todo.fromMap(todo))
          .toList();
    });
  }

  void _addTodo() async {
    final String task = _textEditingController.text;
    final db = await widget.database;
    final Todo newTodo = Todo(task: task, isCompleted: 0);
    final id = await db.insert('todos', newTodo.toMap());

    setState(() {
      newTodo.id = id;
      todos.add(newTodo);
      _textEditingController.clear();
    });
  }

  void _completeTodo(int index) async {
    final db = await widget.database;
    final completedTodo = todos[index].copyWith(isCompleted: 1);
    await db.update(
      'todos',
      completedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [completedTodo.id],
    );

    setState(() {
      completedTodos.add(completedTodo);
      todos.removeAt(index);
    });
  }

  void _deleteTodoFromList(int index) async {
    final db = await widget.database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [todos[index].id],
    );

    setState(() {
      todos.removeAt(index);
    });
  }

  void _deleteTodoFromCompleted(int index) async {
    final db = await widget.database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [completedTodos[index].id],
    );

    setState(() {
      completedTodos.removeAt(index);
    });
  }

  Widget _buildTodoList() {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(todos[index].task),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () => _completeTodo(index),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteTodoFromList(index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTodoList() {
    return ListView.builder(
      itemCount: completedTodos.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(completedTodos[index].task),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteTodoFromCompleted(index),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Todos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.done_all),
          label: 'Completed',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return _buildTodoList();
    } else {
      return _buildCompletedTodoList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Todo'),
                content: TextField(
                  controller: _textEditingController,
                ),
                actions: [
                  TextButton(
                    child: Text('Add'),
                    onPressed: () {
                      _addTodo();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Todo {
  int id;
  String task;
  int isCompleted;

  Todo({
    required this.task,
    required this.isCompleted,
    this.id = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isCompleted': isCompleted,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      task: map['task'],
      isCompleted: map['isCompleted'],
    );
  }

  Todo copyWith({
    int? id,
    String? task,
    int? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
