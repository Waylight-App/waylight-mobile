import 'package:waylight_mobile/domain/models/todo.dart';

/// Example to-dos for the gallery preview (#251): one overdue, one due
/// [today], one tomorrow and one without a date.
List<Todo> exampleTodos(DateTime today) => [
  const Todo(id: 'e1', title: 'Tax return', overdue: true),
  Todo(id: 'e2', title: 'Water the plants', due: today),
  Todo(
    id: 'e3',
    title: 'Book the car service',
    due: DateTime(today.year, today.month, today.day + 1),
  ),
  const Todo(id: 'e4', title: 'Call grandma'),
];
