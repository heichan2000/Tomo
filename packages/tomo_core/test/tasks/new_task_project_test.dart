import 'package:test/test.dart';
import 'package:tomo_core/tasks/new_task_project.dart';
import 'package:tomo_core/tasks/task.dart';

/// Where the task picker's *New task* goes (spec §8.1, §6.3).
void main() {
  final epoch = DateTime.utc(2026);
  final thesis = Project(id: 1, name: 'Thesis', createdAt: epoch);
  final moving = Project(id: 2, name: 'Moving flat', createdAt: epoch);

  test('the last-used project', () {
    expect(newTaskProject([thesis, moving], lastUsedId: 2), moving);
  });

  test('none used yet: the most recently active project', () {
    expect(newTaskProject([thesis, moving], lastUsedId: null), thesis);
  });

  test('the last-used project has been deleted: the most recently active', () {
    expect(newTaskProject([thesis, moving], lastUsedId: 9), thesis);
  });

  test('no projects at all: nowhere yet', () {
    expect(newTaskProject(const [], lastUsedId: 1), isNull);
  });
}
