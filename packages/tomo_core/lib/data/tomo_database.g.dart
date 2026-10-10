// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tomo_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final int id;
  final String name;
  final int createdAt;
  const ProjectRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory ProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ProjectRow copyWith({int? id, String? name, int? createdAt}) => ProjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> createdAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<ProjectRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? createdAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('todo'),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _estimatedPomodorosMeta =
      const VerificationMeta('estimatedPomodoros');
  @override
  late final GeneratedColumn<int> estimatedPomodoros = GeneratedColumn<int>(
    'estimated_pomodoros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualPomodorosMeta = const VerificationMeta(
    'actualPomodoros',
  );
  @override
  late final GeneratedColumn<int> actualPomodoros = GeneratedColumn<int>(
    'actual_pomodoros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cumulativeFocusMinutesMeta =
      const VerificationMeta('cumulativeFocusMinutes');
  @override
  late final GeneratedColumn<int> cumulativeFocusMinutes = GeneratedColumn<int>(
    'cumulative_focus_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _estimatePromptedAtMeta =
      const VerificationMeta('estimatePromptedAt');
  @override
  late final GeneratedColumn<int> estimatePromptedAt = GeneratedColumn<int>(
    'estimate_prompted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionBonusGrantedAtMeta =
      const VerificationMeta('completionBonusGrantedAt');
  @override
  late final GeneratedColumn<int> completionBonusGrantedAt =
      GeneratedColumn<int>(
        'completion_bonus_granted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFocusedAtMeta = const VerificationMeta(
    'lastFocusedAt',
  );
  @override
  late final GeneratedColumn<int> lastFocusedAt = GeneratedColumn<int>(
    'last_focused_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    notes,
    status,
    estimatedPomodoros,
    actualPomodoros,
    cumulativeFocusMinutes,
    estimatePromptedAt,
    completionBonusGrantedAt,
    createdAt,
    lastFocusedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('estimated_pomodoros')) {
      context.handle(
        _estimatedPomodorosMeta,
        estimatedPomodoros.isAcceptableOrUnknown(
          data['estimated_pomodoros']!,
          _estimatedPomodorosMeta,
        ),
      );
    }
    if (data.containsKey('actual_pomodoros')) {
      context.handle(
        _actualPomodorosMeta,
        actualPomodoros.isAcceptableOrUnknown(
          data['actual_pomodoros']!,
          _actualPomodorosMeta,
        ),
      );
    }
    if (data.containsKey('cumulative_focus_minutes')) {
      context.handle(
        _cumulativeFocusMinutesMeta,
        cumulativeFocusMinutes.isAcceptableOrUnknown(
          data['cumulative_focus_minutes']!,
          _cumulativeFocusMinutesMeta,
        ),
      );
    }
    if (data.containsKey('estimate_prompted_at')) {
      context.handle(
        _estimatePromptedAtMeta,
        estimatePromptedAt.isAcceptableOrUnknown(
          data['estimate_prompted_at']!,
          _estimatePromptedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_bonus_granted_at')) {
      context.handle(
        _completionBonusGrantedAtMeta,
        completionBonusGrantedAt.isAcceptableOrUnknown(
          data['completion_bonus_granted_at']!,
          _completionBonusGrantedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_focused_at')) {
      context.handle(
        _lastFocusedAtMeta,
        lastFocusedAt.isAcceptableOrUnknown(
          data['last_focused_at']!,
          _lastFocusedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      estimatedPomodoros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_pomodoros'],
      ),
      actualPomodoros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_pomodoros'],
      )!,
      cumulativeFocusMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cumulative_focus_minutes'],
      )!,
      estimatePromptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_prompted_at'],
      ),
      completionBonusGrantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_bonus_granted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastFocusedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_focused_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;

  /// Never null: onboarding seeds a project. Deleting it deletes its tasks.
  final int projectId;
  final String title;
  final String? notes;
  final TaskStatus status;

  /// Planned blocks. Null is "no plan".
  final int? estimatedPomodoros;

  /// One more per settle.
  final int actualPomodoros;

  /// The completion bonus scales on this.
  final int cumulativeFocusMinutes;

  /// Set once, never cleared.
  final int? estimatePromptedAt;

  /// Set once, never cleared.
  final int? completionBonusGrantedAt;
  final int createdAt;

  /// Set at settle.
  final int? lastFocusedAt;

  /// Set on entering done, cleared on reopening.
  final int? completedAt;
  const TaskRow({
    required this.id,
    required this.projectId,
    required this.title,
    this.notes,
    required this.status,
    this.estimatedPomodoros,
    required this.actualPomodoros,
    required this.cumulativeFocusMinutes,
    this.estimatePromptedAt,
    this.completionBonusGrantedAt,
    required this.createdAt,
    this.lastFocusedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || estimatedPomodoros != null) {
      map['estimated_pomodoros'] = Variable<int>(estimatedPomodoros);
    }
    map['actual_pomodoros'] = Variable<int>(actualPomodoros);
    map['cumulative_focus_minutes'] = Variable<int>(cumulativeFocusMinutes);
    if (!nullToAbsent || estimatePromptedAt != null) {
      map['estimate_prompted_at'] = Variable<int>(estimatePromptedAt);
    }
    if (!nullToAbsent || completionBonusGrantedAt != null) {
      map['completion_bonus_granted_at'] = Variable<int>(
        completionBonusGrantedAt,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastFocusedAt != null) {
      map['last_focused_at'] = Variable<int>(lastFocusedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      estimatedPomodoros: estimatedPomodoros == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedPomodoros),
      actualPomodoros: Value(actualPomodoros),
      cumulativeFocusMinutes: Value(cumulativeFocusMinutes),
      estimatePromptedAt: estimatePromptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatePromptedAt),
      completionBonusGrantedAt: completionBonusGrantedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completionBonusGrantedAt),
      createdAt: Value(createdAt),
      lastFocusedAt: lastFocusedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFocusedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      estimatedPomodoros: serializer.fromJson<int?>(json['estimatedPomodoros']),
      actualPomodoros: serializer.fromJson<int>(json['actualPomodoros']),
      cumulativeFocusMinutes: serializer.fromJson<int>(
        json['cumulativeFocusMinutes'],
      ),
      estimatePromptedAt: serializer.fromJson<int?>(json['estimatePromptedAt']),
      completionBonusGrantedAt: serializer.fromJson<int?>(
        json['completionBonusGrantedAt'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastFocusedAt: serializer.fromJson<int?>(json['lastFocusedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'estimatedPomodoros': serializer.toJson<int?>(estimatedPomodoros),
      'actualPomodoros': serializer.toJson<int>(actualPomodoros),
      'cumulativeFocusMinutes': serializer.toJson<int>(cumulativeFocusMinutes),
      'estimatePromptedAt': serializer.toJson<int?>(estimatePromptedAt),
      'completionBonusGrantedAt': serializer.toJson<int?>(
        completionBonusGrantedAt,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastFocusedAt': serializer.toJson<int?>(lastFocusedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  TaskRow copyWith({
    int? id,
    int? projectId,
    String? title,
    Value<String?> notes = const Value.absent(),
    TaskStatus? status,
    Value<int?> estimatedPomodoros = const Value.absent(),
    int? actualPomodoros,
    int? cumulativeFocusMinutes,
    Value<int?> estimatePromptedAt = const Value.absent(),
    Value<int?> completionBonusGrantedAt = const Value.absent(),
    int? createdAt,
    Value<int?> lastFocusedAt = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    estimatedPomodoros: estimatedPomodoros.present
        ? estimatedPomodoros.value
        : this.estimatedPomodoros,
    actualPomodoros: actualPomodoros ?? this.actualPomodoros,
    cumulativeFocusMinutes:
        cumulativeFocusMinutes ?? this.cumulativeFocusMinutes,
    estimatePromptedAt: estimatePromptedAt.present
        ? estimatePromptedAt.value
        : this.estimatePromptedAt,
    completionBonusGrantedAt: completionBonusGrantedAt.present
        ? completionBonusGrantedAt.value
        : this.completionBonusGrantedAt,
    createdAt: createdAt ?? this.createdAt,
    lastFocusedAt: lastFocusedAt.present
        ? lastFocusedAt.value
        : this.lastFocusedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      estimatedPomodoros: data.estimatedPomodoros.present
          ? data.estimatedPomodoros.value
          : this.estimatedPomodoros,
      actualPomodoros: data.actualPomodoros.present
          ? data.actualPomodoros.value
          : this.actualPomodoros,
      cumulativeFocusMinutes: data.cumulativeFocusMinutes.present
          ? data.cumulativeFocusMinutes.value
          : this.cumulativeFocusMinutes,
      estimatePromptedAt: data.estimatePromptedAt.present
          ? data.estimatePromptedAt.value
          : this.estimatePromptedAt,
      completionBonusGrantedAt: data.completionBonusGrantedAt.present
          ? data.completionBonusGrantedAt.value
          : this.completionBonusGrantedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastFocusedAt: data.lastFocusedAt.present
          ? data.lastFocusedAt.value
          : this.lastFocusedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('estimatedPomodoros: $estimatedPomodoros, ')
          ..write('actualPomodoros: $actualPomodoros, ')
          ..write('cumulativeFocusMinutes: $cumulativeFocusMinutes, ')
          ..write('estimatePromptedAt: $estimatePromptedAt, ')
          ..write('completionBonusGrantedAt: $completionBonusGrantedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastFocusedAt: $lastFocusedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    notes,
    status,
    estimatedPomodoros,
    actualPomodoros,
    cumulativeFocusMinutes,
    estimatePromptedAt,
    completionBonusGrantedAt,
    createdAt,
    lastFocusedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.estimatedPomodoros == this.estimatedPomodoros &&
          other.actualPomodoros == this.actualPomodoros &&
          other.cumulativeFocusMinutes == this.cumulativeFocusMinutes &&
          other.estimatePromptedAt == this.estimatePromptedAt &&
          other.completionBonusGrantedAt == this.completionBonusGrantedAt &&
          other.createdAt == this.createdAt &&
          other.lastFocusedAt == this.lastFocusedAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> title;
  final Value<String?> notes;
  final Value<TaskStatus> status;
  final Value<int?> estimatedPomodoros;
  final Value<int> actualPomodoros;
  final Value<int> cumulativeFocusMinutes;
  final Value<int?> estimatePromptedAt;
  final Value<int?> completionBonusGrantedAt;
  final Value<int> createdAt;
  final Value<int?> lastFocusedAt;
  final Value<int?> completedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.estimatedPomodoros = const Value.absent(),
    this.actualPomodoros = const Value.absent(),
    this.cumulativeFocusMinutes = const Value.absent(),
    this.estimatePromptedAt = const Value.absent(),
    this.completionBonusGrantedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastFocusedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String title,
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.estimatedPomodoros = const Value.absent(),
    this.actualPomodoros = const Value.absent(),
    this.cumulativeFocusMinutes = const Value.absent(),
    this.estimatePromptedAt = const Value.absent(),
    this.completionBonusGrantedAt = const Value.absent(),
    required int createdAt,
    this.lastFocusedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : projectId = Value(projectId),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? estimatedPomodoros,
    Expression<int>? actualPomodoros,
    Expression<int>? cumulativeFocusMinutes,
    Expression<int>? estimatePromptedAt,
    Expression<int>? completionBonusGrantedAt,
    Expression<int>? createdAt,
    Expression<int>? lastFocusedAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (estimatedPomodoros != null) 'estimated_pomodoros': estimatedPomodoros,
      if (actualPomodoros != null) 'actual_pomodoros': actualPomodoros,
      if (cumulativeFocusMinutes != null)
        'cumulative_focus_minutes': cumulativeFocusMinutes,
      if (estimatePromptedAt != null)
        'estimate_prompted_at': estimatePromptedAt,
      if (completionBonusGrantedAt != null)
        'completion_bonus_granted_at': completionBonusGrantedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastFocusedAt != null) 'last_focused_at': lastFocusedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int>? projectId,
    Value<String>? title,
    Value<String?>? notes,
    Value<TaskStatus>? status,
    Value<int?>? estimatedPomodoros,
    Value<int>? actualPomodoros,
    Value<int>? cumulativeFocusMinutes,
    Value<int?>? estimatePromptedAt,
    Value<int?>? completionBonusGrantedAt,
    Value<int>? createdAt,
    Value<int?>? lastFocusedAt,
    Value<int?>? completedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      actualPomodoros: actualPomodoros ?? this.actualPomodoros,
      cumulativeFocusMinutes:
          cumulativeFocusMinutes ?? this.cumulativeFocusMinutes,
      estimatePromptedAt: estimatePromptedAt ?? this.estimatePromptedAt,
      completionBonusGrantedAt:
          completionBonusGrantedAt ?? this.completionBonusGrantedAt,
      createdAt: createdAt ?? this.createdAt,
      lastFocusedAt: lastFocusedAt ?? this.lastFocusedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (estimatedPomodoros.present) {
      map['estimated_pomodoros'] = Variable<int>(estimatedPomodoros.value);
    }
    if (actualPomodoros.present) {
      map['actual_pomodoros'] = Variable<int>(actualPomodoros.value);
    }
    if (cumulativeFocusMinutes.present) {
      map['cumulative_focus_minutes'] = Variable<int>(
        cumulativeFocusMinutes.value,
      );
    }
    if (estimatePromptedAt.present) {
      map['estimate_prompted_at'] = Variable<int>(estimatePromptedAt.value);
    }
    if (completionBonusGrantedAt.present) {
      map['completion_bonus_granted_at'] = Variable<int>(
        completionBonusGrantedAt.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastFocusedAt.present) {
      map['last_focused_at'] = Variable<int>(lastFocusedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('estimatedPomodoros: $estimatedPomodoros, ')
          ..write('actualPomodoros: $actualPomodoros, ')
          ..write('cumulativeFocusMinutes: $cumulativeFocusMinutes, ')
          ..write('estimatePromptedAt: $estimatePromptedAt, ')
          ..write('completionBonusGrantedAt: $completionBonusGrantedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastFocusedAt: $lastFocusedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $PetsTable extends Pets with TableInfo<$PetsTable, PetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Species, String> species =
      GeneratedColumn<String>(
        'species',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Species>($PetsTable.$converterspecies);
  @override
  late final GeneratedColumnWithTypeConverter<Personality, String> personality =
      GeneratedColumn<String>(
        'personality',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('quiet'),
      ).withConverter<Personality>($PetsTable.$converterpersonality);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hatchedAtMeta = const VerificationMeta(
    'hatchedAt',
  );
  @override
  late final GeneratedColumn<int> hatchedAt = GeneratedColumn<int>(
    'hatched_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expMeta = const VerificationMeta('exp');
  @override
  late final GeneratedColumn<int> exp = GeneratedColumn<int>(
    'exp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    species,
    personality,
    name,
    hatchedAt,
    exp,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('hatched_at')) {
      context.handle(
        _hatchedAtMeta,
        hatchedAt.isAcceptableOrUnknown(data['hatched_at']!, _hatchedAtMeta),
      );
    }
    if (data.containsKey('exp')) {
      context.handle(
        _expMeta,
        exp.isAcceptableOrUnknown(data['exp']!, _expMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      species: $PetsTable.$converterspecies.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}species'],
        )!,
      ),
      personality: $PetsTable.$converterpersonality.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}personality'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      hatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hatched_at'],
      ),
      exp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exp'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PetsTable createAlias(String alias) {
    return $PetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Species, String, String> $converterspecies =
      const EnumNameConverter<Species>(Species.values);
  static JsonTypeConverter2<Personality, String, String> $converterpersonality =
      const EnumNameConverter<Personality>(Personality.values);
}

class PetRow extends DataClass implements Insertable<PetRow> {
  final int id;
  final Species species;
  final Personality personality;

  /// Null until the hatch names it.
  final String? name;

  /// Null is the egg.
  final int? hatchedAt;

  /// The truth. Level and stage are worked out from it, never stored.
  final int exp;
  final int createdAt;
  const PetRow({
    required this.id,
    required this.species,
    required this.personality,
    this.name,
    this.hatchedAt,
    required this.exp,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['species'] = Variable<String>(
        $PetsTable.$converterspecies.toSql(species),
      );
    }
    {
      map['personality'] = Variable<String>(
        $PetsTable.$converterpersonality.toSql(personality),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || hatchedAt != null) {
      map['hatched_at'] = Variable<int>(hatchedAt);
    }
    map['exp'] = Variable<int>(exp);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PetsCompanion toCompanion(bool nullToAbsent) {
    return PetsCompanion(
      id: Value(id),
      species: Value(species),
      personality: Value(personality),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      hatchedAt: hatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchedAt),
      exp: Value(exp),
      createdAt: Value(createdAt),
    );
  }

  factory PetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetRow(
      id: serializer.fromJson<int>(json['id']),
      species: $PetsTable.$converterspecies.fromJson(
        serializer.fromJson<String>(json['species']),
      ),
      personality: $PetsTable.$converterpersonality.fromJson(
        serializer.fromJson<String>(json['personality']),
      ),
      name: serializer.fromJson<String?>(json['name']),
      hatchedAt: serializer.fromJson<int?>(json['hatchedAt']),
      exp: serializer.fromJson<int>(json['exp']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'species': serializer.toJson<String>(
        $PetsTable.$converterspecies.toJson(species),
      ),
      'personality': serializer.toJson<String>(
        $PetsTable.$converterpersonality.toJson(personality),
      ),
      'name': serializer.toJson<String?>(name),
      'hatchedAt': serializer.toJson<int?>(hatchedAt),
      'exp': serializer.toJson<int>(exp),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PetRow copyWith({
    int? id,
    Species? species,
    Personality? personality,
    Value<String?> name = const Value.absent(),
    Value<int?> hatchedAt = const Value.absent(),
    int? exp,
    int? createdAt,
  }) => PetRow(
    id: id ?? this.id,
    species: species ?? this.species,
    personality: personality ?? this.personality,
    name: name.present ? name.value : this.name,
    hatchedAt: hatchedAt.present ? hatchedAt.value : this.hatchedAt,
    exp: exp ?? this.exp,
    createdAt: createdAt ?? this.createdAt,
  );
  PetRow copyWithCompanion(PetsCompanion data) {
    return PetRow(
      id: data.id.present ? data.id.value : this.id,
      species: data.species.present ? data.species.value : this.species,
      personality: data.personality.present
          ? data.personality.value
          : this.personality,
      name: data.name.present ? data.name.value : this.name,
      hatchedAt: data.hatchedAt.present ? data.hatchedAt.value : this.hatchedAt,
      exp: data.exp.present ? data.exp.value : this.exp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetRow(')
          ..write('id: $id, ')
          ..write('species: $species, ')
          ..write('personality: $personality, ')
          ..write('name: $name, ')
          ..write('hatchedAt: $hatchedAt, ')
          ..write('exp: $exp, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, species, personality, name, hatchedAt, exp, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetRow &&
          other.id == this.id &&
          other.species == this.species &&
          other.personality == this.personality &&
          other.name == this.name &&
          other.hatchedAt == this.hatchedAt &&
          other.exp == this.exp &&
          other.createdAt == this.createdAt);
}

class PetsCompanion extends UpdateCompanion<PetRow> {
  final Value<int> id;
  final Value<Species> species;
  final Value<Personality> personality;
  final Value<String?> name;
  final Value<int?> hatchedAt;
  final Value<int> exp;
  final Value<int> createdAt;
  const PetsCompanion({
    this.id = const Value.absent(),
    this.species = const Value.absent(),
    this.personality = const Value.absent(),
    this.name = const Value.absent(),
    this.hatchedAt = const Value.absent(),
    this.exp = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PetsCompanion.insert({
    this.id = const Value.absent(),
    required Species species,
    this.personality = const Value.absent(),
    this.name = const Value.absent(),
    this.hatchedAt = const Value.absent(),
    this.exp = const Value.absent(),
    required int createdAt,
  }) : species = Value(species),
       createdAt = Value(createdAt);
  static Insertable<PetRow> custom({
    Expression<int>? id,
    Expression<String>? species,
    Expression<String>? personality,
    Expression<String>? name,
    Expression<int>? hatchedAt,
    Expression<int>? exp,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (species != null) 'species': species,
      if (personality != null) 'personality': personality,
      if (name != null) 'name': name,
      if (hatchedAt != null) 'hatched_at': hatchedAt,
      if (exp != null) 'exp': exp,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PetsCompanion copyWith({
    Value<int>? id,
    Value<Species>? species,
    Value<Personality>? personality,
    Value<String?>? name,
    Value<int?>? hatchedAt,
    Value<int>? exp,
    Value<int>? createdAt,
  }) {
    return PetsCompanion(
      id: id ?? this.id,
      species: species ?? this.species,
      personality: personality ?? this.personality,
      name: name ?? this.name,
      hatchedAt: hatchedAt ?? this.hatchedAt,
      exp: exp ?? this.exp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(
        $PetsTable.$converterspecies.toSql(species.value),
      );
    }
    if (personality.present) {
      map['personality'] = Variable<String>(
        $PetsTable.$converterpersonality.toSql(personality.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hatchedAt.present) {
      map['hatched_at'] = Variable<int>(hatchedAt.value);
    }
    if (exp.present) {
      map['exp'] = Variable<int>(exp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetsCompanion(')
          ..write('id: $id, ')
          ..write('species: $species, ')
          ..write('personality: $personality, ')
          ..write('name: $name, ')
          ..write('hatchedAt: $hatchedAt, ')
          ..write('exp: $exp, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BlockRecordsTable extends BlockRecords
    with TableInfo<$BlockRecordsTable, BlockRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pets (id)',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utcOffsetMinutesMeta = const VerificationMeta(
    'utcOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> utcOffsetMinutes = GeneratedColumn<int>(
    'utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expGrantedMeta = const VerificationMeta(
    'expGranted',
  );
  @override
  late final GeneratedColumn<int> expGranted = GeneratedColumn<int>(
    'exp_granted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _petExpAfterMeta = const VerificationMeta(
    'petExpAfter',
  );
  @override
  late final GeneratedColumn<int> petExpAfter = GeneratedColumn<int>(
    'pet_exp_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<int> settledAt = GeneratedColumn<int>(
    'settled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    taskId,
    projectId,
    startedAt,
    endedAt,
    minutes,
    localDate,
    utcOffsetMinutes,
    expGranted,
    petExpAfter,
    settledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'block_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('utc_offset_minutes')) {
      context.handle(
        _utcOffsetMinutesMeta,
        utcOffsetMinutes.isAcceptableOrUnknown(
          data['utc_offset_minutes']!,
          _utcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utcOffsetMinutesMeta);
    }
    if (data.containsKey('exp_granted')) {
      context.handle(
        _expGrantedMeta,
        expGranted.isAcceptableOrUnknown(data['exp_granted']!, _expGrantedMeta),
      );
    } else if (isInserting) {
      context.missing(_expGrantedMeta);
    }
    if (data.containsKey('pet_exp_after')) {
      context.handle(
        _petExpAfterMeta,
        petExpAfter.isAcceptableOrUnknown(
          data['pet_exp_after']!,
          _petExpAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_petExpAfterMeta);
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_settledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      utcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_minutes'],
      )!,
      expGranted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exp_granted'],
      )!,
      petExpAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_exp_after'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settled_at'],
      )!,
    );
  }

  @override
  $BlockRecordsTable createAlias(String alias) {
    return $BlockRecordsTable(attachedDatabase, alias);
  }
}

class BlockRecordRow extends DataClass implements Insertable<BlockRecordRow> {
  final int id;
  final int petId;
  final int? taskId;

  /// The project the task had at settle.
  final int? projectId;
  final int startedAt;
  final int endedAt;
  final int minutes;

  /// The local day it ended, `YYYY-MM-DD`.
  final String localDate;

  /// The UTC offset at settle.
  final int utcOffsetMinutes;
  final int expGranted;

  /// `petExpAfter - expGranted == 0` means this block was the hatch.
  final int petExpAfter;
  final int settledAt;
  const BlockRecordRow({
    required this.id,
    required this.petId,
    this.taskId,
    this.projectId,
    required this.startedAt,
    required this.endedAt,
    required this.minutes,
    required this.localDate,
    required this.utcOffsetMinutes,
    required this.expGranted,
    required this.petExpAfter,
    required this.settledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    map['started_at'] = Variable<int>(startedAt);
    map['ended_at'] = Variable<int>(endedAt);
    map['minutes'] = Variable<int>(minutes);
    map['local_date'] = Variable<String>(localDate);
    map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes);
    map['exp_granted'] = Variable<int>(expGranted);
    map['pet_exp_after'] = Variable<int>(petExpAfter);
    map['settled_at'] = Variable<int>(settledAt);
    return map;
  }

  BlockRecordsCompanion toCompanion(bool nullToAbsent) {
    return BlockRecordsCompanion(
      id: Value(id),
      petId: Value(petId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      minutes: Value(minutes),
      localDate: Value(localDate),
      utcOffsetMinutes: Value(utcOffsetMinutes),
      expGranted: Value(expGranted),
      petExpAfter: Value(petExpAfter),
      settledAt: Value(settledAt),
    );
  }

  factory BlockRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockRecordRow(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int>(json['endedAt']),
      minutes: serializer.fromJson<int>(json['minutes']),
      localDate: serializer.fromJson<String>(json['localDate']),
      utcOffsetMinutes: serializer.fromJson<int>(json['utcOffsetMinutes']),
      expGranted: serializer.fromJson<int>(json['expGranted']),
      petExpAfter: serializer.fromJson<int>(json['petExpAfter']),
      settledAt: serializer.fromJson<int>(json['settledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'taskId': serializer.toJson<int?>(taskId),
      'projectId': serializer.toJson<int?>(projectId),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int>(endedAt),
      'minutes': serializer.toJson<int>(minutes),
      'localDate': serializer.toJson<String>(localDate),
      'utcOffsetMinutes': serializer.toJson<int>(utcOffsetMinutes),
      'expGranted': serializer.toJson<int>(expGranted),
      'petExpAfter': serializer.toJson<int>(petExpAfter),
      'settledAt': serializer.toJson<int>(settledAt),
    };
  }

  BlockRecordRow copyWith({
    int? id,
    int? petId,
    Value<int?> taskId = const Value.absent(),
    Value<int?> projectId = const Value.absent(),
    int? startedAt,
    int? endedAt,
    int? minutes,
    String? localDate,
    int? utcOffsetMinutes,
    int? expGranted,
    int? petExpAfter,
    int? settledAt,
  }) => BlockRecordRow(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    taskId: taskId.present ? taskId.value : this.taskId,
    projectId: projectId.present ? projectId.value : this.projectId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    minutes: minutes ?? this.minutes,
    localDate: localDate ?? this.localDate,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    expGranted: expGranted ?? this.expGranted,
    petExpAfter: petExpAfter ?? this.petExpAfter,
    settledAt: settledAt ?? this.settledAt,
  );
  BlockRecordRow copyWithCompanion(BlockRecordsCompanion data) {
    return BlockRecordRow(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      utcOffsetMinutes: data.utcOffsetMinutes.present
          ? data.utcOffsetMinutes.value
          : this.utcOffsetMinutes,
      expGranted: data.expGranted.present
          ? data.expGranted.value
          : this.expGranted,
      petExpAfter: data.petExpAfter.present
          ? data.petExpAfter.value
          : this.petExpAfter,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockRecordRow(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('taskId: $taskId, ')
          ..write('projectId: $projectId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('minutes: $minutes, ')
          ..write('localDate: $localDate, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('expGranted: $expGranted, ')
          ..write('petExpAfter: $petExpAfter, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    taskId,
    projectId,
    startedAt,
    endedAt,
    minutes,
    localDate,
    utcOffsetMinutes,
    expGranted,
    petExpAfter,
    settledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockRecordRow &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.taskId == this.taskId &&
          other.projectId == this.projectId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.minutes == this.minutes &&
          other.localDate == this.localDate &&
          other.utcOffsetMinutes == this.utcOffsetMinutes &&
          other.expGranted == this.expGranted &&
          other.petExpAfter == this.petExpAfter &&
          other.settledAt == this.settledAt);
}

class BlockRecordsCompanion extends UpdateCompanion<BlockRecordRow> {
  final Value<int> id;
  final Value<int> petId;
  final Value<int?> taskId;
  final Value<int?> projectId;
  final Value<int> startedAt;
  final Value<int> endedAt;
  final Value<int> minutes;
  final Value<String> localDate;
  final Value<int> utcOffsetMinutes;
  final Value<int> expGranted;
  final Value<int> petExpAfter;
  final Value<int> settledAt;
  const BlockRecordsCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.minutes = const Value.absent(),
    this.localDate = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.expGranted = const Value.absent(),
    this.petExpAfter = const Value.absent(),
    this.settledAt = const Value.absent(),
  });
  BlockRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    this.taskId = const Value.absent(),
    this.projectId = const Value.absent(),
    required int startedAt,
    required int endedAt,
    required int minutes,
    required String localDate,
    required int utcOffsetMinutes,
    required int expGranted,
    required int petExpAfter,
    required int settledAt,
  }) : petId = Value(petId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       minutes = Value(minutes),
       localDate = Value(localDate),
       utcOffsetMinutes = Value(utcOffsetMinutes),
       expGranted = Value(expGranted),
       petExpAfter = Value(petExpAfter),
       settledAt = Value(settledAt);
  static Insertable<BlockRecordRow> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<int>? taskId,
    Expression<int>? projectId,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? minutes,
    Expression<String>? localDate,
    Expression<int>? utcOffsetMinutes,
    Expression<int>? expGranted,
    Expression<int>? petExpAfter,
    Expression<int>? settledAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (taskId != null) 'task_id': taskId,
      if (projectId != null) 'project_id': projectId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (minutes != null) 'minutes': minutes,
      if (localDate != null) 'local_date': localDate,
      if (utcOffsetMinutes != null) 'utc_offset_minutes': utcOffsetMinutes,
      if (expGranted != null) 'exp_granted': expGranted,
      if (petExpAfter != null) 'pet_exp_after': petExpAfter,
      if (settledAt != null) 'settled_at': settledAt,
    });
  }

  BlockRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<int?>? taskId,
    Value<int?>? projectId,
    Value<int>? startedAt,
    Value<int>? endedAt,
    Value<int>? minutes,
    Value<String>? localDate,
    Value<int>? utcOffsetMinutes,
    Value<int>? expGranted,
    Value<int>? petExpAfter,
    Value<int>? settledAt,
  }) {
    return BlockRecordsCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      minutes: minutes ?? this.minutes,
      localDate: localDate ?? this.localDate,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
      expGranted: expGranted ?? this.expGranted,
      petExpAfter: petExpAfter ?? this.petExpAfter,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (utcOffsetMinutes.present) {
      map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes.value);
    }
    if (expGranted.present) {
      map['exp_granted'] = Variable<int>(expGranted.value);
    }
    if (petExpAfter.present) {
      map['pet_exp_after'] = Variable<int>(petExpAfter.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<int>(settledAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockRecordsCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('taskId: $taskId, ')
          ..write('projectId: $projectId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('minutes: $minutes, ')
          ..write('localDate: $localDate, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('expGranted: $expGranted, ')
          ..write('petExpAfter: $petExpAfter, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }
}

class $FocusCycleTable extends FocusCycle
    with TableInfo<$FocusCycleTable, FocusCycleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusCycleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusMinutesMeta = const VerificationMeta(
    'focusMinutes',
  );
  @override
  late final GeneratedColumn<int> focusMinutes = GeneratedColumn<int>(
    'focus_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakMinutesMeta = const VerificationMeta(
    'breakMinutes',
  );
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
    'break_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoStartMeta = const VerificationMeta(
    'autoStart',
  );
  @override
  late final GeneratedColumn<bool> autoStart = GeneratedColumn<bool>(
    'auto_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_start" IN (0, 1))',
    ),
  );
  static const VerificationMeta _breakStartAtMeta = const VerificationMeta(
    'breakStartAt',
  );
  @override
  late final GeneratedColumn<int> breakStartAt = GeneratedColumn<int>(
    'break_start_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breakSkippedAtMeta = const VerificationMeta(
    'breakSkippedAt',
  );
  @override
  late final GeneratedColumn<int> breakSkippedAt = GeneratedColumn<int>(
    'break_skipped_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockRecordIdMeta = const VerificationMeta(
    'blockRecordId',
  );
  @override
  late final GeneratedColumn<int> blockRecordId = GeneratedColumn<int>(
    'block_record_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES block_records (id)',
    ),
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<int> seenAt = GeneratedColumn<int>(
    'seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    startAt,
    endAt,
    focusMinutes,
    breakMinutes,
    autoStart,
    breakStartAt,
    breakSkippedAt,
    blockRecordId,
    seenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_cycle';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusCycleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('focus_minutes')) {
      context.handle(
        _focusMinutesMeta,
        focusMinutes.isAcceptableOrUnknown(
          data['focus_minutes']!,
          _focusMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_focusMinutesMeta);
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
        _breakMinutesMeta,
        breakMinutes.isAcceptableOrUnknown(
          data['break_minutes']!,
          _breakMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breakMinutesMeta);
    }
    if (data.containsKey('auto_start')) {
      context.handle(
        _autoStartMeta,
        autoStart.isAcceptableOrUnknown(data['auto_start']!, _autoStartMeta),
      );
    } else if (isInserting) {
      context.missing(_autoStartMeta);
    }
    if (data.containsKey('break_start_at')) {
      context.handle(
        _breakStartAtMeta,
        breakStartAt.isAcceptableOrUnknown(
          data['break_start_at']!,
          _breakStartAtMeta,
        ),
      );
    }
    if (data.containsKey('break_skipped_at')) {
      context.handle(
        _breakSkippedAtMeta,
        breakSkippedAt.isAcceptableOrUnknown(
          data['break_skipped_at']!,
          _breakSkippedAtMeta,
        ),
      );
    }
    if (data.containsKey('block_record_id')) {
      context.handle(
        _blockRecordIdMeta,
        blockRecordId.isAcceptableOrUnknown(
          data['block_record_id']!,
          _blockRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusCycleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusCycleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      )!,
      focusMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_minutes'],
      )!,
      breakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_minutes'],
      )!,
      autoStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_start'],
      )!,
      breakStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_start_at'],
      ),
      breakSkippedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_skipped_at'],
      ),
      blockRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_record_id'],
      ),
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_at'],
      ),
    );
  }

  @override
  $FocusCycleTable createAlias(String alias) {
    return $FocusCycleTable(attachedDatabase, alias);
  }
}

class FocusCycleRow extends DataClass implements Insertable<FocusCycleRow> {
  /// Always 1. Not auto-incremented: that would hand the second cycle id 2,
  /// which the check refuses.
  final int id;

  /// The service always ends the cycle before deleting its task (spec §5.4);
  /// RESTRICT is the backstop.
  final int taskId;
  final int startAt;
  final int endAt;
  final int focusMinutes;
  final int breakMinutes;

  /// Snapshotted at block start.
  final bool autoStart;

  /// Written by *Take break*, or as `endAt` under auto-start.
  final int? breakStartAt;

  /// Written by *Skip break*.
  final int? breakSkippedAt;

  /// Not null means the block is credited.
  final int? blockRecordId;

  /// The beat run was had (spec §7.4).
  final int? seenAt;
  const FocusCycleRow({
    required this.id,
    required this.taskId,
    required this.startAt,
    required this.endAt,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.autoStart,
    this.breakStartAt,
    this.breakSkippedAt,
    this.blockRecordId,
    this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['start_at'] = Variable<int>(startAt);
    map['end_at'] = Variable<int>(endAt);
    map['focus_minutes'] = Variable<int>(focusMinutes);
    map['break_minutes'] = Variable<int>(breakMinutes);
    map['auto_start'] = Variable<bool>(autoStart);
    if (!nullToAbsent || breakStartAt != null) {
      map['break_start_at'] = Variable<int>(breakStartAt);
    }
    if (!nullToAbsent || breakSkippedAt != null) {
      map['break_skipped_at'] = Variable<int>(breakSkippedAt);
    }
    if (!nullToAbsent || blockRecordId != null) {
      map['block_record_id'] = Variable<int>(blockRecordId);
    }
    if (!nullToAbsent || seenAt != null) {
      map['seen_at'] = Variable<int>(seenAt);
    }
    return map;
  }

  FocusCycleCompanion toCompanion(bool nullToAbsent) {
    return FocusCycleCompanion(
      id: Value(id),
      taskId: Value(taskId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      focusMinutes: Value(focusMinutes),
      breakMinutes: Value(breakMinutes),
      autoStart: Value(autoStart),
      breakStartAt: breakStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(breakStartAt),
      breakSkippedAt: breakSkippedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(breakSkippedAt),
      blockRecordId: blockRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockRecordId),
      seenAt: seenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(seenAt),
    );
  }

  factory FocusCycleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusCycleRow(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      startAt: serializer.fromJson<int>(json['startAt']),
      endAt: serializer.fromJson<int>(json['endAt']),
      focusMinutes: serializer.fromJson<int>(json['focusMinutes']),
      breakMinutes: serializer.fromJson<int>(json['breakMinutes']),
      autoStart: serializer.fromJson<bool>(json['autoStart']),
      breakStartAt: serializer.fromJson<int?>(json['breakStartAt']),
      breakSkippedAt: serializer.fromJson<int?>(json['breakSkippedAt']),
      blockRecordId: serializer.fromJson<int?>(json['blockRecordId']),
      seenAt: serializer.fromJson<int?>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'startAt': serializer.toJson<int>(startAt),
      'endAt': serializer.toJson<int>(endAt),
      'focusMinutes': serializer.toJson<int>(focusMinutes),
      'breakMinutes': serializer.toJson<int>(breakMinutes),
      'autoStart': serializer.toJson<bool>(autoStart),
      'breakStartAt': serializer.toJson<int?>(breakStartAt),
      'breakSkippedAt': serializer.toJson<int?>(breakSkippedAt),
      'blockRecordId': serializer.toJson<int?>(blockRecordId),
      'seenAt': serializer.toJson<int?>(seenAt),
    };
  }

  FocusCycleRow copyWith({
    int? id,
    int? taskId,
    int? startAt,
    int? endAt,
    int? focusMinutes,
    int? breakMinutes,
    bool? autoStart,
    Value<int?> breakStartAt = const Value.absent(),
    Value<int?> breakSkippedAt = const Value.absent(),
    Value<int?> blockRecordId = const Value.absent(),
    Value<int?> seenAt = const Value.absent(),
  }) => FocusCycleRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    focusMinutes: focusMinutes ?? this.focusMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    autoStart: autoStart ?? this.autoStart,
    breakStartAt: breakStartAt.present ? breakStartAt.value : this.breakStartAt,
    breakSkippedAt: breakSkippedAt.present
        ? breakSkippedAt.value
        : this.breakSkippedAt,
    blockRecordId: blockRecordId.present
        ? blockRecordId.value
        : this.blockRecordId,
    seenAt: seenAt.present ? seenAt.value : this.seenAt,
  );
  FocusCycleRow copyWithCompanion(FocusCycleCompanion data) {
    return FocusCycleRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      focusMinutes: data.focusMinutes.present
          ? data.focusMinutes.value
          : this.focusMinutes,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
      autoStart: data.autoStart.present ? data.autoStart.value : this.autoStart,
      breakStartAt: data.breakStartAt.present
          ? data.breakStartAt.value
          : this.breakStartAt,
      breakSkippedAt: data.breakSkippedAt.present
          ? data.breakSkippedAt.value
          : this.breakSkippedAt,
      blockRecordId: data.blockRecordId.present
          ? data.blockRecordId.value
          : this.blockRecordId,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusCycleRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('autoStart: $autoStart, ')
          ..write('breakStartAt: $breakStartAt, ')
          ..write('breakSkippedAt: $breakSkippedAt, ')
          ..write('blockRecordId: $blockRecordId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    startAt,
    endAt,
    focusMinutes,
    breakMinutes,
    autoStart,
    breakStartAt,
    breakSkippedAt,
    blockRecordId,
    seenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusCycleRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.focusMinutes == this.focusMinutes &&
          other.breakMinutes == this.breakMinutes &&
          other.autoStart == this.autoStart &&
          other.breakStartAt == this.breakStartAt &&
          other.breakSkippedAt == this.breakSkippedAt &&
          other.blockRecordId == this.blockRecordId &&
          other.seenAt == this.seenAt);
}

class FocusCycleCompanion extends UpdateCompanion<FocusCycleRow> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> startAt;
  final Value<int> endAt;
  final Value<int> focusMinutes;
  final Value<int> breakMinutes;
  final Value<bool> autoStart;
  final Value<int?> breakStartAt;
  final Value<int?> breakSkippedAt;
  final Value<int?> blockRecordId;
  final Value<int?> seenAt;
  const FocusCycleCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.autoStart = const Value.absent(),
    this.breakStartAt = const Value.absent(),
    this.breakSkippedAt = const Value.absent(),
    this.blockRecordId = const Value.absent(),
    this.seenAt = const Value.absent(),
  });
  FocusCycleCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int startAt,
    required int endAt,
    required int focusMinutes,
    required int breakMinutes,
    required bool autoStart,
    this.breakStartAt = const Value.absent(),
    this.breakSkippedAt = const Value.absent(),
    this.blockRecordId = const Value.absent(),
    this.seenAt = const Value.absent(),
  }) : taskId = Value(taskId),
       startAt = Value(startAt),
       endAt = Value(endAt),
       focusMinutes = Value(focusMinutes),
       breakMinutes = Value(breakMinutes),
       autoStart = Value(autoStart);
  static Insertable<FocusCycleRow> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<int>? focusMinutes,
    Expression<int>? breakMinutes,
    Expression<bool>? autoStart,
    Expression<int>? breakStartAt,
    Expression<int>? breakSkippedAt,
    Expression<int>? blockRecordId,
    Expression<int>? seenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (focusMinutes != null) 'focus_minutes': focusMinutes,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (autoStart != null) 'auto_start': autoStart,
      if (breakStartAt != null) 'break_start_at': breakStartAt,
      if (breakSkippedAt != null) 'break_skipped_at': breakSkippedAt,
      if (blockRecordId != null) 'block_record_id': blockRecordId,
      if (seenAt != null) 'seen_at': seenAt,
    });
  }

  FocusCycleCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? startAt,
    Value<int>? endAt,
    Value<int>? focusMinutes,
    Value<int>? breakMinutes,
    Value<bool>? autoStart,
    Value<int?>? breakStartAt,
    Value<int?>? breakSkippedAt,
    Value<int?>? blockRecordId,
    Value<int?>? seenAt,
  }) {
    return FocusCycleCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      autoStart: autoStart ?? this.autoStart,
      breakStartAt: breakStartAt ?? this.breakStartAt,
      breakSkippedAt: breakSkippedAt ?? this.breakSkippedAt,
      blockRecordId: blockRecordId ?? this.blockRecordId,
      seenAt: seenAt ?? this.seenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (focusMinutes.present) {
      map['focus_minutes'] = Variable<int>(focusMinutes.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (autoStart.present) {
      map['auto_start'] = Variable<bool>(autoStart.value);
    }
    if (breakStartAt.present) {
      map['break_start_at'] = Variable<int>(breakStartAt.value);
    }
    if (breakSkippedAt.present) {
      map['break_skipped_at'] = Variable<int>(breakSkippedAt.value);
    }
    if (blockRecordId.present) {
      map['block_record_id'] = Variable<int>(blockRecordId.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<int>(seenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusCycleCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('autoStart: $autoStart, ')
          ..write('breakStartAt: $breakStartAt, ')
          ..write('breakSkippedAt: $breakSkippedAt, ')
          ..write('blockRecordId: $blockRecordId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$TomoDatabase extends GeneratedDatabase {
  _$TomoDatabase(QueryExecutor e) : super(e);
  $TomoDatabaseManager get managers => $TomoDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PetsTable pets = $PetsTable(this);
  late final $BlockRecordsTable blockRecords = $BlockRecordsTable(this);
  late final $FocusCycleTable focusCycle = $FocusCycleTable(this);
  late final Index tasksProjectIdStatus = Index(
    'tasks_project_id_status',
    'CREATE INDEX tasks_project_id_status ON tasks (project_id, status)',
  );
  late final Index blockRecordsLocalDate = Index(
    'block_records_local_date',
    'CREATE INDEX block_records_local_date ON block_records (local_date)',
  );
  late final Index blockRecordsTaskId = Index(
    'block_records_task_id',
    'CREATE INDEX block_records_task_id ON block_records (task_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    tasks,
    pets,
    blockRecords,
    focusCycle,
    tasksProjectIdStatus,
    blockRecordsLocalDate,
    blockRecordsTaskId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('block_records', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('block_records', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
  required int createdAt,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> createdAt,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$TomoDatabase, $ProjectsTable, ProjectRow> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<TaskRow>> _tasksRefsTable(
    _$TomoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'projects__id__tasks__project_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BlockRecordsTable, List<BlockRecordRow>>
  _blockRecordsRefsTable(_$TomoDatabase db) => MultiTypedResultKey.fromTable(
    db.blockRecords,
    aliasName: 'projects__id__block_records__project_id',
  );

  $$BlockRecordsTableProcessedTableManager get blockRecordsRefs {
    final manager = $$BlockRecordsTableTableManager(
      $_db,
      $_db.blockRecords,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_blockRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$TomoDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> blockRecordsRefs(
    Expression<bool> Function($$BlockRecordsTableFilterComposer f) f,
  ) {
    final $$BlockRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableFilterComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$TomoDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$TomoDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> blockRecordsRefs<T extends Object>(
    Expression<T> Function($$BlockRecordsTableAnnotationComposer a) f,
  ) {
    final $$BlockRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$TomoDatabase,
          $ProjectsTable,
          ProjectRow,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (ProjectRow, $$ProjectsTableReferences),
          ProjectRow,
          PrefetchHooks Function({bool tasksRefs, bool blockRecordsRefs})
        > {
  $$ProjectsTableTableManager(_$TomoDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) => ProjectsCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int createdAt,
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, ProjectRow>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tasksRefs = false, blockRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tasksRefs) db.tasks,
                    if (blockRecordsRefs) db.blockRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          ProjectRow,
                          $ProjectsTable,
                          TaskRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (blockRecordsRefs)
                        await $_getPrefetchedData<
                          ProjectRow,
                          $ProjectsTable,
                          BlockRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._blockRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).blockRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomoDatabase,
      $ProjectsTable,
      ProjectRow,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRow, $$ProjectsTableReferences),
      ProjectRow,
      PrefetchHooks Function({bool tasksRefs, bool blockRecordsRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required int projectId,
  required String title,
  Value<String?> notes,
  Value<TaskStatus> status,
  Value<int?> estimatedPomodoros,
  Value<int> actualPomodoros,
  Value<int> cumulativeFocusMinutes,
  Value<int?> estimatePromptedAt,
  Value<int?> completionBonusGrantedAt,
  required int createdAt,
  Value<int?> lastFocusedAt,
  Value<int?> completedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> title,
  Value<String?> notes,
  Value<TaskStatus> status,
  Value<int?> estimatedPomodoros,
  Value<int> actualPomodoros,
  Value<int> cumulativeFocusMinutes,
  Value<int?> estimatePromptedAt,
  Value<int?> completionBonusGrantedAt,
  Value<int> createdAt,
  Value<int?> lastFocusedAt,
  Value<int?> completedAt,
});

final class $$TasksTableReferences
    extends BaseReferences<_$TomoDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$TomoDatabase db) =>
      db.projects.createAlias('tasks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BlockRecordsTable, List<BlockRecordRow>>
  _blockRecordsRefsTable(_$TomoDatabase db) => MultiTypedResultKey.fromTable(
    db.blockRecords,
    aliasName: 'tasks__id__block_records__task_id',
  );

  $$BlockRecordsTableProcessedTableManager get blockRecordsRefs {
    final manager = $$BlockRecordsTableTableManager(
      $_db,
      $_db.blockRecords,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_blockRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FocusCycleTable, List<FocusCycleRow>>
  _focusCycleRefsTable(_$TomoDatabase db) => MultiTypedResultKey.fromTable(
    db.focusCycle,
    aliasName: 'tasks__id__focus_cycle__task_id',
  );

  $$FocusCycleTableProcessedTableManager get focusCycleRefs {
    final manager = $$FocusCycleTableTableManager(
      $_db,
      $_db.focusCycle,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusCycleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$TomoDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get estimatedPomodoros => $composableBuilder(
    column: $table.estimatedPomodoros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualPomodoros => $composableBuilder(
    column: $table.actualPomodoros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cumulativeFocusMinutes => $composableBuilder(
    column: $table.cumulativeFocusMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatePromptedAt => $composableBuilder(
    column: $table.estimatePromptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionBonusGrantedAt => $composableBuilder(
    column: $table.completionBonusGrantedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFocusedAt => $composableBuilder(
    column: $table.lastFocusedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> blockRecordsRefs(
    Expression<bool> Function($$BlockRecordsTableFilterComposer f) f,
  ) {
    final $$BlockRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableFilterComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> focusCycleRefs(
    Expression<bool> Function($$FocusCycleTableFilterComposer f) f,
  ) {
    final $$FocusCycleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusCycle,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusCycleTableFilterComposer(
            $db: $db,
            $table: $db.focusCycle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$TomoDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedPomodoros => $composableBuilder(
    column: $table.estimatedPomodoros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualPomodoros => $composableBuilder(
    column: $table.actualPomodoros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cumulativeFocusMinutes => $composableBuilder(
    column: $table.cumulativeFocusMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatePromptedAt => $composableBuilder(
    column: $table.estimatePromptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionBonusGrantedAt => $composableBuilder(
    column: $table.completionBonusGrantedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFocusedAt => $composableBuilder(
    column: $table.lastFocusedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$TomoDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get estimatedPomodoros => $composableBuilder(
    column: $table.estimatedPomodoros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualPomodoros => $composableBuilder(
    column: $table.actualPomodoros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cumulativeFocusMinutes => $composableBuilder(
    column: $table.cumulativeFocusMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatePromptedAt => $composableBuilder(
    column: $table.estimatePromptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionBonusGrantedAt => $composableBuilder(
    column: $table.completionBonusGrantedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastFocusedAt => $composableBuilder(
    column: $table.lastFocusedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> blockRecordsRefs<T extends Object>(
    Expression<T> Function($$BlockRecordsTableAnnotationComposer a) f,
  ) {
    final $$BlockRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> focusCycleRefs<T extends Object>(
    Expression<T> Function($$FocusCycleTableAnnotationComposer a) f,
  ) {
    final $$FocusCycleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusCycle,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusCycleTableAnnotationComposer(
            $db: $db,
            $table: $db.focusCycle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$TomoDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool projectId,
            bool blockRecordsRefs,
            bool focusCycleRefs,
          })
        > {
  $$TasksTableTableManager(_$TomoDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<int?> estimatedPomodoros = const Value.absent(),
                Value<int> actualPomodoros = const Value.absent(),
                Value<int> cumulativeFocusMinutes = const Value.absent(),
                Value<int?> estimatePromptedAt = const Value.absent(),
                Value<int?> completionBonusGrantedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastFocusedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                projectId: projectId,
                title: title,
                notes: notes,
                status: status,
                estimatedPomodoros: estimatedPomodoros,
                actualPomodoros: actualPomodoros,
                cumulativeFocusMinutes: cumulativeFocusMinutes,
                estimatePromptedAt: estimatePromptedAt,
                completionBonusGrantedAt: completionBonusGrantedAt,
                createdAt: createdAt,
                lastFocusedAt: lastFocusedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int projectId,
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<int?> estimatedPomodoros = const Value.absent(),
                Value<int> actualPomodoros = const Value.absent(),
                Value<int> cumulativeFocusMinutes = const Value.absent(),
                Value<int?> estimatePromptedAt = const Value.absent(),
                Value<int?> completionBonusGrantedAt = const Value.absent(),
                required int createdAt,
                Value<int?> lastFocusedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                notes: notes,
                status: status,
                estimatedPomodoros: estimatedPomodoros,
                actualPomodoros: actualPomodoros,
                cumulativeFocusMinutes: cumulativeFocusMinutes,
                estimatePromptedAt: estimatePromptedAt,
                completionBonusGrantedAt: completionBonusGrantedAt,
                createdAt: createdAt,
                lastFocusedAt: lastFocusedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskRow>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                projectId = false,
                blockRecordsRefs = false,
                focusCycleRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (blockRecordsRefs) db.blockRecords,
                    if (focusCycleRefs) db.focusCycle,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$TasksTableReferences
                                ._projectIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._projectIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (blockRecordsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          BlockRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._blockRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).blockRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (focusCycleRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          FocusCycleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._focusCycleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).focusCycleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$TomoDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({
        bool projectId,
        bool blockRecordsRefs,
        bool focusCycleRefs,
      })
    >;
typedef $$PetsTableCreateCompanionBuilder = PetsCompanion Function({
  Value<int> id,
  required Species species,
  Value<Personality> personality,
  Value<String?> name,
  Value<int?> hatchedAt,
  Value<int> exp,
  required int createdAt,
});
typedef $$PetsTableUpdateCompanionBuilder = PetsCompanion Function({
  Value<int> id,
  Value<Species> species,
  Value<Personality> personality,
  Value<String?> name,
  Value<int?> hatchedAt,
  Value<int> exp,
  Value<int> createdAt,
});

final class $$PetsTableReferences
    extends BaseReferences<_$TomoDatabase, $PetsTable, PetRow> {
  $$PetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BlockRecordsTable, List<BlockRecordRow>>
  _blockRecordsRefsTable(_$TomoDatabase db) => MultiTypedResultKey.fromTable(
    db.blockRecords,
    aliasName: 'pets__id__block_records__pet_id',
  );

  $$BlockRecordsTableProcessedTableManager get blockRecordsRefs {
    final manager = $$BlockRecordsTableTableManager(
      $_db,
      $_db.blockRecords,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_blockRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PetsTableFilterComposer extends Composer<_$TomoDatabase, $PetsTable> {
  $$PetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Species, Species, String> get species =>
      $composableBuilder(
        column: $table.species,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Personality, Personality, String>
  get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hatchedAt => $composableBuilder(
    column: $table.hatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exp => $composableBuilder(
    column: $table.exp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> blockRecordsRefs(
    Expression<bool> Function($$BlockRecordsTableFilterComposer f) f,
  ) {
    final $$BlockRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableFilterComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetsTableOrderingComposer extends Composer<_$TomoDatabase, $PetsTable> {
  $$PetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hatchedAt => $composableBuilder(
    column: $table.hatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exp => $composableBuilder(
    column: $table.exp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetsTableAnnotationComposer
    extends Composer<_$TomoDatabase, $PetsTable> {
  $$PetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Species, String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Personality, String> get personality =>
      $composableBuilder(
        column: $table.personality,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get hatchedAt =>
      $composableBuilder(column: $table.hatchedAt, builder: (column) => column);

  GeneratedColumn<int> get exp =>
      $composableBuilder(column: $table.exp, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> blockRecordsRefs<T extends Object>(
    Expression<T> Function($$BlockRecordsTableAnnotationComposer a) f,
  ) {
    final $$BlockRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetsTableTableManager
    extends
        RootTableManager<
          _$TomoDatabase,
          $PetsTable,
          PetRow,
          $$PetsTableFilterComposer,
          $$PetsTableOrderingComposer,
          $$PetsTableAnnotationComposer,
          $$PetsTableCreateCompanionBuilder,
          $$PetsTableUpdateCompanionBuilder,
          (PetRow, $$PetsTableReferences),
          PetRow,
          PrefetchHooks Function({bool blockRecordsRefs})
        > {
  $$PetsTableTableManager(_$TomoDatabase db, $PetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Species> species = const Value.absent(),
                Value<Personality> personality = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> hatchedAt = const Value.absent(),
                Value<int> exp = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => PetsCompanion(
                id: id,
                species: species,
                personality: personality,
                name: name,
                hatchedAt: hatchedAt,
                exp: exp,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Species species,
                Value<Personality> personality = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> hatchedAt = const Value.absent(),
                Value<int> exp = const Value.absent(),
                required int createdAt,
              }) => PetsCompanion.insert(
                id: id,
                species: species,
                personality: personality,
                name: name,
                hatchedAt: hatchedAt,
                exp: exp,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetsTable, PetRow>(table),
                  $$PetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({blockRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (blockRecordsRefs) db.blockRecords],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (blockRecordsRefs)
                    await $_getPrefetchedData<
                      PetRow,
                      $PetsTable,
                      BlockRecordRow
                    >(
                      currentTable: table,
                      referencedTable: $$PetsTableReferences
                          ._blockRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PetsTableReferences(db, table, p0).blockRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.petId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PetsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomoDatabase,
      $PetsTable,
      PetRow,
      $$PetsTableFilterComposer,
      $$PetsTableOrderingComposer,
      $$PetsTableAnnotationComposer,
      $$PetsTableCreateCompanionBuilder,
      $$PetsTableUpdateCompanionBuilder,
      (PetRow, $$PetsTableReferences),
      PetRow,
      PrefetchHooks Function({bool blockRecordsRefs})
    >;
typedef $$BlockRecordsTableCreateCompanionBuilder =
    BlockRecordsCompanion Function({
      Value<int> id,
      required int petId,
      Value<int?> taskId,
      Value<int?> projectId,
      required int startedAt,
      required int endedAt,
      required int minutes,
      required String localDate,
      required int utcOffsetMinutes,
      required int expGranted,
      required int petExpAfter,
      required int settledAt,
    });
typedef $$BlockRecordsTableUpdateCompanionBuilder =
    BlockRecordsCompanion Function({
      Value<int> id,
      Value<int> petId,
      Value<int?> taskId,
      Value<int?> projectId,
      Value<int> startedAt,
      Value<int> endedAt,
      Value<int> minutes,
      Value<String> localDate,
      Value<int> utcOffsetMinutes,
      Value<int> expGranted,
      Value<int> petExpAfter,
      Value<int> settledAt,
    });

final class $$BlockRecordsTableReferences
    extends BaseReferences<_$TomoDatabase, $BlockRecordsTable, BlockRecordRow> {
  $$BlockRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PetsTable _petIdTable(_$TomoDatabase db) =>
      db.pets.createAlias('block_records__pet_id__pets__id');

  $$PetsTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetsTableTableManager(
      $_db,
      $_db.pets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _taskIdTable(_$TomoDatabase db) =>
      db.tasks.createAlias('block_records__task_id__tasks__id');

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<int>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProjectsTable _projectIdTable(_$TomoDatabase db) =>
      db.projects.createAlias('block_records__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FocusCycleTable, List<FocusCycleRow>>
  _focusCycleRefsTable(_$TomoDatabase db) => MultiTypedResultKey.fromTable(
    db.focusCycle,
    aliasName: 'block_records__id__focus_cycle__block_record_id',
  );

  $$FocusCycleTableProcessedTableManager get focusCycleRefs {
    final manager = $$FocusCycleTableTableManager(
      $_db,
      $_db.focusCycle,
    ).filter((f) => f.blockRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusCycleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BlockRecordsTableFilterComposer
    extends Composer<_$TomoDatabase, $BlockRecordsTable> {
  $$BlockRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expGranted => $composableBuilder(
    column: $table.expGranted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get petExpAfter => $composableBuilder(
    column: $table.petExpAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PetsTableFilterComposer get petId {
    final $$PetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableFilterComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> focusCycleRefs(
    Expression<bool> Function($$FocusCycleTableFilterComposer f) f,
  ) {
    final $$FocusCycleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusCycle,
      getReferencedColumn: (t) => t.blockRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusCycleTableFilterComposer(
            $db: $db,
            $table: $db.focusCycle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlockRecordsTableOrderingComposer
    extends Composer<_$TomoDatabase, $BlockRecordsTable> {
  $$BlockRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expGranted => $composableBuilder(
    column: $table.expGranted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get petExpAfter => $composableBuilder(
    column: $table.petExpAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PetsTableOrderingComposer get petId {
    final $$PetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableOrderingComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlockRecordsTableAnnotationComposer
    extends Composer<_$TomoDatabase, $BlockRecordsTable> {
  $$BlockRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expGranted => $composableBuilder(
    column: $table.expGranted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get petExpAfter => $composableBuilder(
    column: $table.petExpAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  $$PetsTableAnnotationComposer get petId {
    final $$PetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableAnnotationComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> focusCycleRefs<T extends Object>(
    Expression<T> Function($$FocusCycleTableAnnotationComposer a) f,
  ) {
    final $$FocusCycleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusCycle,
      getReferencedColumn: (t) => t.blockRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusCycleTableAnnotationComposer(
            $db: $db,
            $table: $db.focusCycle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlockRecordsTableTableManager
    extends
        RootTableManager<
          _$TomoDatabase,
          $BlockRecordsTable,
          BlockRecordRow,
          $$BlockRecordsTableFilterComposer,
          $$BlockRecordsTableOrderingComposer,
          $$BlockRecordsTableAnnotationComposer,
          $$BlockRecordsTableCreateCompanionBuilder,
          $$BlockRecordsTableUpdateCompanionBuilder,
          (BlockRecordRow, $$BlockRecordsTableReferences),
          BlockRecordRow,
          PrefetchHooks Function({
            bool petId,
            bool taskId,
            bool projectId,
            bool focusCycleRefs,
          })
        > {
  $$BlockRecordsTableTableManager(_$TomoDatabase db, $BlockRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> endedAt = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<int> expGranted = const Value.absent(),
                Value<int> petExpAfter = const Value.absent(),
                Value<int> settledAt = const Value.absent(),
              }) => BlockRecordsCompanion(
                id: id,
                petId: petId,
                taskId: taskId,
                projectId: projectId,
                startedAt: startedAt,
                endedAt: endedAt,
                minutes: minutes,
                localDate: localDate,
                utcOffsetMinutes: utcOffsetMinutes,
                expGranted: expGranted,
                petExpAfter: petExpAfter,
                settledAt: settledAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                Value<int?> taskId = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                required int startedAt,
                required int endedAt,
                required int minutes,
                required String localDate,
                required int utcOffsetMinutes,
                required int expGranted,
                required int petExpAfter,
                required int settledAt,
              }) => BlockRecordsCompanion.insert(
                id: id,
                petId: petId,
                taskId: taskId,
                projectId: projectId,
                startedAt: startedAt,
                endedAt: endedAt,
                minutes: minutes,
                localDate: localDate,
                utcOffsetMinutes: utcOffsetMinutes,
                expGranted: expGranted,
                petExpAfter: petExpAfter,
                settledAt: settledAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlockRecordsTable, BlockRecordRow>(table),
                  $$BlockRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                petId = false,
                taskId = false,
                projectId = false,
                focusCycleRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (focusCycleRefs) db.focusCycle],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (petId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.petId,
                            referencedTable: $$BlockRecordsTableReferences
                                ._petIdTable(db),
                            referencedColumn: $$BlockRecordsTableReferences
                                ._petIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (taskId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.taskId,
                            referencedTable: $$BlockRecordsTableReferences
                                ._taskIdTable(db),
                            referencedColumn: $$BlockRecordsTableReferences
                                ._taskIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$BlockRecordsTableReferences
                                ._projectIdTable(db),
                            referencedColumn: $$BlockRecordsTableReferences
                                ._projectIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (focusCycleRefs)
                        await $_getPrefetchedData<
                          BlockRecordRow,
                          $BlockRecordsTable,
                          FocusCycleRow
                        >(
                          currentTable: table,
                          referencedTable: $$BlockRecordsTableReferences
                              ._focusCycleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BlockRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).focusCycleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.blockRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BlockRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomoDatabase,
      $BlockRecordsTable,
      BlockRecordRow,
      $$BlockRecordsTableFilterComposer,
      $$BlockRecordsTableOrderingComposer,
      $$BlockRecordsTableAnnotationComposer,
      $$BlockRecordsTableCreateCompanionBuilder,
      $$BlockRecordsTableUpdateCompanionBuilder,
      (BlockRecordRow, $$BlockRecordsTableReferences),
      BlockRecordRow,
      PrefetchHooks Function({
        bool petId,
        bool taskId,
        bool projectId,
        bool focusCycleRefs,
      })
    >;
typedef $$FocusCycleTableCreateCompanionBuilder = FocusCycleCompanion Function({
  Value<int> id,
  required int taskId,
  required int startAt,
  required int endAt,
  required int focusMinutes,
  required int breakMinutes,
  required bool autoStart,
  Value<int?> breakStartAt,
  Value<int?> breakSkippedAt,
  Value<int?> blockRecordId,
  Value<int?> seenAt,
});
typedef $$FocusCycleTableUpdateCompanionBuilder = FocusCycleCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<int> startAt,
  Value<int> endAt,
  Value<int> focusMinutes,
  Value<int> breakMinutes,
  Value<bool> autoStart,
  Value<int?> breakStartAt,
  Value<int?> breakSkippedAt,
  Value<int?> blockRecordId,
  Value<int?> seenAt,
});

final class $$FocusCycleTableReferences
    extends BaseReferences<_$TomoDatabase, $FocusCycleTable, FocusCycleRow> {
  $$FocusCycleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$TomoDatabase db) =>
      db.tasks.createAlias('focus_cycle__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlockRecordsTable _blockRecordIdTable(_$TomoDatabase db) => db
      .blockRecords
      .createAlias('focus_cycle__block_record_id__block_records__id');

  $$BlockRecordsTableProcessedTableManager? get blockRecordId {
    final $_column = $_itemColumn<int>('block_record_id');
    if ($_column == null) return null;
    final manager = $$BlockRecordsTableTableManager(
      $_db,
      $_db.blockRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blockRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FocusCycleTableFilterComposer
    extends Composer<_$TomoDatabase, $FocusCycleTable> {
  $$FocusCycleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoStart => $composableBuilder(
    column: $table.autoStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakStartAt => $composableBuilder(
    column: $table.breakStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakSkippedAt => $composableBuilder(
    column: $table.breakSkippedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlockRecordsTableFilterComposer get blockRecordId {
    final $$BlockRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockRecordId,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableFilterComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusCycleTableOrderingComposer
    extends Composer<_$TomoDatabase, $FocusCycleTable> {
  $$FocusCycleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoStart => $composableBuilder(
    column: $table.autoStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakStartAt => $composableBuilder(
    column: $table.breakStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakSkippedAt => $composableBuilder(
    column: $table.breakSkippedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlockRecordsTableOrderingComposer get blockRecordId {
    final $$BlockRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockRecordId,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusCycleTableAnnotationComposer
    extends Composer<_$TomoDatabase, $FocusCycleTable> {
  $$FocusCycleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoStart =>
      $composableBuilder(column: $table.autoStart, builder: (column) => column);

  GeneratedColumn<int> get breakStartAt => $composableBuilder(
    column: $table.breakStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakSkippedAt => $composableBuilder(
    column: $table.breakSkippedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlockRecordsTableAnnotationComposer get blockRecordId {
    final $$BlockRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockRecordId,
      referencedTable: $db.blockRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.blockRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusCycleTableTableManager
    extends
        RootTableManager<
          _$TomoDatabase,
          $FocusCycleTable,
          FocusCycleRow,
          $$FocusCycleTableFilterComposer,
          $$FocusCycleTableOrderingComposer,
          $$FocusCycleTableAnnotationComposer,
          $$FocusCycleTableCreateCompanionBuilder,
          $$FocusCycleTableUpdateCompanionBuilder,
          (FocusCycleRow, $$FocusCycleTableReferences),
          FocusCycleRow,
          PrefetchHooks Function({bool taskId, bool blockRecordId})
        > {
  $$FocusCycleTableTableManager(_$TomoDatabase db, $FocusCycleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusCycleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusCycleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusCycleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int> endAt = const Value.absent(),
                Value<int> focusMinutes = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                Value<bool> autoStart = const Value.absent(),
                Value<int?> breakStartAt = const Value.absent(),
                Value<int?> breakSkippedAt = const Value.absent(),
                Value<int?> blockRecordId = const Value.absent(),
                Value<int?> seenAt = const Value.absent(),
              }) => FocusCycleCompanion(
                id: id,
                taskId: taskId,
                startAt: startAt,
                endAt: endAt,
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                autoStart: autoStart,
                breakStartAt: breakStartAt,
                breakSkippedAt: breakSkippedAt,
                blockRecordId: blockRecordId,
                seenAt: seenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required int startAt,
                required int endAt,
                required int focusMinutes,
                required int breakMinutes,
                required bool autoStart,
                Value<int?> breakStartAt = const Value.absent(),
                Value<int?> breakSkippedAt = const Value.absent(),
                Value<int?> blockRecordId = const Value.absent(),
                Value<int?> seenAt = const Value.absent(),
              }) => FocusCycleCompanion.insert(
                id: id,
                taskId: taskId,
                startAt: startAt,
                endAt: endAt,
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                autoStart: autoStart,
                breakStartAt: breakStartAt,
                breakSkippedAt: breakSkippedAt,
                blockRecordId: blockRecordId,
                seenAt: seenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusCycleTable, FocusCycleRow>(table),
                  $$FocusCycleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, blockRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$FocusCycleTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$FocusCycleTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (blockRecordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.blockRecordId,
                        referencedTable: $$FocusCycleTableReferences
                            ._blockRecordIdTable(db),
                        referencedColumn: $$FocusCycleTableReferences
                            ._blockRecordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FocusCycleTableProcessedTableManager =
    ProcessedTableManager<
      _$TomoDatabase,
      $FocusCycleTable,
      FocusCycleRow,
      $$FocusCycleTableFilterComposer,
      $$FocusCycleTableOrderingComposer,
      $$FocusCycleTableAnnotationComposer,
      $$FocusCycleTableCreateCompanionBuilder,
      $$FocusCycleTableUpdateCompanionBuilder,
      (FocusCycleRow, $$FocusCycleTableReferences),
      FocusCycleRow,
      PrefetchHooks Function({bool taskId, bool blockRecordId})
    >;

class $TomoDatabaseManager {
  final _$TomoDatabase _db;
  $TomoDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$PetsTableTableManager get pets => $$PetsTableTableManager(_db, _db.pets);
  $$BlockRecordsTableTableManager get blockRecords =>
      $$BlockRecordsTableTableManager(_db, _db.blockRecords);
  $$FocusCycleTableTableManager get focusCycle =>
      $$FocusCycleTableTableManager(_db, _db.focusCycle);
}
