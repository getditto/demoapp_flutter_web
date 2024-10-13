import 'package:ditto_live_web_alpha/ditto_live_web_alpha.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'task.dart';

class TaskView extends StatelessWidget {
  final Ditto ditto;
  final Task task;

  const TaskView({
    super.key,
    required this.ditto,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(task.description),
      trailing: Checkbox(
        value: task.done,
        onChanged: (value) => ditto.store.execute(
          "UPDATE $collection SET done = $value WHERE _id = '${task.id}'",
        ),
      ),
    );
  }
}
