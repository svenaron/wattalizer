// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AutolapConfigsTable extends AutolapConfigs
    with TableInfo<$AutolapConfigsTable, AutolapConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AutolapConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDeltaWattsMeta =
      const VerificationMeta('startDeltaWatts');
  @override
  late final GeneratedColumn<double> startDeltaWatts = GeneratedColumn<double>(
      'start_delta_watts', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startConfirmSecondsMeta =
      const VerificationMeta('startConfirmSeconds');
  @override
  late final GeneratedColumn<int> startConfirmSeconds = GeneratedColumn<int>(
      'start_confirm_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _startDropoutToleranceMeta =
      const VerificationMeta('startDropoutTolerance');
  @override
  late final GeneratedColumn<int> startDropoutTolerance = GeneratedColumn<int>(
      'start_dropout_tolerance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _endDeltaWattsMeta =
      const VerificationMeta('endDeltaWatts');
  @override
  late final GeneratedColumn<double> endDeltaWatts = GeneratedColumn<double>(
      'end_delta_watts', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endConfirmSecondsMeta =
      const VerificationMeta('endConfirmSeconds');
  @override
  late final GeneratedColumn<int> endConfirmSeconds = GeneratedColumn<int>(
      'end_confirm_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _minEffortSecondsMeta =
      const VerificationMeta('minEffortSeconds');
  @override
  late final GeneratedColumn<int> minEffortSeconds = GeneratedColumn<int>(
      'min_effort_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _preEffortBaselineWindowMeta =
      const VerificationMeta('preEffortBaselineWindow');
  @override
  late final GeneratedColumn<int> preEffortBaselineWindow =
      GeneratedColumn<int>('pre_effort_baseline_window', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(15));
  static const VerificationMeta _inEffortTrailingWindowMeta =
      const VerificationMeta('inEffortTrailingWindow');
  @override
  late final GeneratedColumn<int> inEffortTrailingWindow = GeneratedColumn<int>(
      'in_effort_trailing_window', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        startDeltaWatts,
        startConfirmSeconds,
        startDropoutTolerance,
        endDeltaWatts,
        endConfirmSeconds,
        minEffortSeconds,
        preEffortBaselineWindow,
        inEffortTrailingWindow,
        isDefault
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'autolap_configs';
  @override
  VerificationContext validateIntegrity(Insertable<AutolapConfigRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_delta_watts')) {
      context.handle(
          _startDeltaWattsMeta,
          startDeltaWatts.isAcceptableOrUnknown(
              data['start_delta_watts']!, _startDeltaWattsMeta));
    } else if (isInserting) {
      context.missing(_startDeltaWattsMeta);
    }
    if (data.containsKey('start_confirm_seconds')) {
      context.handle(
          _startConfirmSecondsMeta,
          startConfirmSeconds.isAcceptableOrUnknown(
              data['start_confirm_seconds']!, _startConfirmSecondsMeta));
    }
    if (data.containsKey('start_dropout_tolerance')) {
      context.handle(
          _startDropoutToleranceMeta,
          startDropoutTolerance.isAcceptableOrUnknown(
              data['start_dropout_tolerance']!, _startDropoutToleranceMeta));
    }
    if (data.containsKey('end_delta_watts')) {
      context.handle(
          _endDeltaWattsMeta,
          endDeltaWatts.isAcceptableOrUnknown(
              data['end_delta_watts']!, _endDeltaWattsMeta));
    } else if (isInserting) {
      context.missing(_endDeltaWattsMeta);
    }
    if (data.containsKey('end_confirm_seconds')) {
      context.handle(
          _endConfirmSecondsMeta,
          endConfirmSeconds.isAcceptableOrUnknown(
              data['end_confirm_seconds']!, _endConfirmSecondsMeta));
    }
    if (data.containsKey('min_effort_seconds')) {
      context.handle(
          _minEffortSecondsMeta,
          minEffortSeconds.isAcceptableOrUnknown(
              data['min_effort_seconds']!, _minEffortSecondsMeta));
    }
    if (data.containsKey('pre_effort_baseline_window')) {
      context.handle(
          _preEffortBaselineWindowMeta,
          preEffortBaselineWindow.isAcceptableOrUnknown(
              data['pre_effort_baseline_window']!,
              _preEffortBaselineWindowMeta));
    }
    if (data.containsKey('in_effort_trailing_window')) {
      context.handle(
          _inEffortTrailingWindowMeta,
          inEffortTrailingWindow.isAcceptableOrUnknown(
              data['in_effort_trailing_window']!, _inEffortTrailingWindowMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AutolapConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AutolapConfigRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startDeltaWatts: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}start_delta_watts'])!,
      startConfirmSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}start_confirm_seconds'])!,
      startDropoutTolerance: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}start_dropout_tolerance'])!,
      endDeltaWatts: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}end_delta_watts'])!,
      endConfirmSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}end_confirm_seconds'])!,
      minEffortSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}min_effort_seconds'])!,
      preEffortBaselineWindow: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pre_effort_baseline_window'])!,
      inEffortTrailingWindow: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}in_effort_trailing_window'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
    );
  }

  @override
  $AutolapConfigsTable createAlias(String alias) {
    return $AutolapConfigsTable(attachedDatabase, alias);
  }
}

class AutolapConfigRow extends DataClass
    implements Insertable<AutolapConfigRow> {
  final String id;
  final String name;
  final double startDeltaWatts;
  final int startConfirmSeconds;
  final int startDropoutTolerance;
  final double endDeltaWatts;
  final int endConfirmSeconds;
  final int minEffortSeconds;
  final int preEffortBaselineWindow;
  final int inEffortTrailingWindow;
  final bool isDefault;
  const AutolapConfigRow(
      {required this.id,
      required this.name,
      required this.startDeltaWatts,
      required this.startConfirmSeconds,
      required this.startDropoutTolerance,
      required this.endDeltaWatts,
      required this.endConfirmSeconds,
      required this.minEffortSeconds,
      required this.preEffortBaselineWindow,
      required this.inEffortTrailingWindow,
      required this.isDefault});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_delta_watts'] = Variable<double>(startDeltaWatts);
    map['start_confirm_seconds'] = Variable<int>(startConfirmSeconds);
    map['start_dropout_tolerance'] = Variable<int>(startDropoutTolerance);
    map['end_delta_watts'] = Variable<double>(endDeltaWatts);
    map['end_confirm_seconds'] = Variable<int>(endConfirmSeconds);
    map['min_effort_seconds'] = Variable<int>(minEffortSeconds);
    map['pre_effort_baseline_window'] = Variable<int>(preEffortBaselineWindow);
    map['in_effort_trailing_window'] = Variable<int>(inEffortTrailingWindow);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  AutolapConfigsCompanion toCompanion(bool nullToAbsent) {
    return AutolapConfigsCompanion(
      id: Value(id),
      name: Value(name),
      startDeltaWatts: Value(startDeltaWatts),
      startConfirmSeconds: Value(startConfirmSeconds),
      startDropoutTolerance: Value(startDropoutTolerance),
      endDeltaWatts: Value(endDeltaWatts),
      endConfirmSeconds: Value(endConfirmSeconds),
      minEffortSeconds: Value(minEffortSeconds),
      preEffortBaselineWindow: Value(preEffortBaselineWindow),
      inEffortTrailingWindow: Value(inEffortTrailingWindow),
      isDefault: Value(isDefault),
    );
  }

  factory AutolapConfigRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AutolapConfigRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDeltaWatts: serializer.fromJson<double>(json['startDeltaWatts']),
      startConfirmSeconds:
          serializer.fromJson<int>(json['startConfirmSeconds']),
      startDropoutTolerance:
          serializer.fromJson<int>(json['startDropoutTolerance']),
      endDeltaWatts: serializer.fromJson<double>(json['endDeltaWatts']),
      endConfirmSeconds: serializer.fromJson<int>(json['endConfirmSeconds']),
      minEffortSeconds: serializer.fromJson<int>(json['minEffortSeconds']),
      preEffortBaselineWindow:
          serializer.fromJson<int>(json['preEffortBaselineWindow']),
      inEffortTrailingWindow:
          serializer.fromJson<int>(json['inEffortTrailingWindow']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startDeltaWatts': serializer.toJson<double>(startDeltaWatts),
      'startConfirmSeconds': serializer.toJson<int>(startConfirmSeconds),
      'startDropoutTolerance': serializer.toJson<int>(startDropoutTolerance),
      'endDeltaWatts': serializer.toJson<double>(endDeltaWatts),
      'endConfirmSeconds': serializer.toJson<int>(endConfirmSeconds),
      'minEffortSeconds': serializer.toJson<int>(minEffortSeconds),
      'preEffortBaselineWindow':
          serializer.toJson<int>(preEffortBaselineWindow),
      'inEffortTrailingWindow': serializer.toJson<int>(inEffortTrailingWindow),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  AutolapConfigRow copyWith(
          {String? id,
          String? name,
          double? startDeltaWatts,
          int? startConfirmSeconds,
          int? startDropoutTolerance,
          double? endDeltaWatts,
          int? endConfirmSeconds,
          int? minEffortSeconds,
          int? preEffortBaselineWindow,
          int? inEffortTrailingWindow,
          bool? isDefault}) =>
      AutolapConfigRow(
        id: id ?? this.id,
        name: name ?? this.name,
        startDeltaWatts: startDeltaWatts ?? this.startDeltaWatts,
        startConfirmSeconds: startConfirmSeconds ?? this.startConfirmSeconds,
        startDropoutTolerance:
            startDropoutTolerance ?? this.startDropoutTolerance,
        endDeltaWatts: endDeltaWatts ?? this.endDeltaWatts,
        endConfirmSeconds: endConfirmSeconds ?? this.endConfirmSeconds,
        minEffortSeconds: minEffortSeconds ?? this.minEffortSeconds,
        preEffortBaselineWindow:
            preEffortBaselineWindow ?? this.preEffortBaselineWindow,
        inEffortTrailingWindow:
            inEffortTrailingWindow ?? this.inEffortTrailingWindow,
        isDefault: isDefault ?? this.isDefault,
      );
  AutolapConfigRow copyWithCompanion(AutolapConfigsCompanion data) {
    return AutolapConfigRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDeltaWatts: data.startDeltaWatts.present
          ? data.startDeltaWatts.value
          : this.startDeltaWatts,
      startConfirmSeconds: data.startConfirmSeconds.present
          ? data.startConfirmSeconds.value
          : this.startConfirmSeconds,
      startDropoutTolerance: data.startDropoutTolerance.present
          ? data.startDropoutTolerance.value
          : this.startDropoutTolerance,
      endDeltaWatts: data.endDeltaWatts.present
          ? data.endDeltaWatts.value
          : this.endDeltaWatts,
      endConfirmSeconds: data.endConfirmSeconds.present
          ? data.endConfirmSeconds.value
          : this.endConfirmSeconds,
      minEffortSeconds: data.minEffortSeconds.present
          ? data.minEffortSeconds.value
          : this.minEffortSeconds,
      preEffortBaselineWindow: data.preEffortBaselineWindow.present
          ? data.preEffortBaselineWindow.value
          : this.preEffortBaselineWindow,
      inEffortTrailingWindow: data.inEffortTrailingWindow.present
          ? data.inEffortTrailingWindow.value
          : this.inEffortTrailingWindow,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AutolapConfigRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDeltaWatts: $startDeltaWatts, ')
          ..write('startConfirmSeconds: $startConfirmSeconds, ')
          ..write('startDropoutTolerance: $startDropoutTolerance, ')
          ..write('endDeltaWatts: $endDeltaWatts, ')
          ..write('endConfirmSeconds: $endConfirmSeconds, ')
          ..write('minEffortSeconds: $minEffortSeconds, ')
          ..write('preEffortBaselineWindow: $preEffortBaselineWindow, ')
          ..write('inEffortTrailingWindow: $inEffortTrailingWindow, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      startDeltaWatts,
      startConfirmSeconds,
      startDropoutTolerance,
      endDeltaWatts,
      endConfirmSeconds,
      minEffortSeconds,
      preEffortBaselineWindow,
      inEffortTrailingWindow,
      isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutolapConfigRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDeltaWatts == this.startDeltaWatts &&
          other.startConfirmSeconds == this.startConfirmSeconds &&
          other.startDropoutTolerance == this.startDropoutTolerance &&
          other.endDeltaWatts == this.endDeltaWatts &&
          other.endConfirmSeconds == this.endConfirmSeconds &&
          other.minEffortSeconds == this.minEffortSeconds &&
          other.preEffortBaselineWindow == this.preEffortBaselineWindow &&
          other.inEffortTrailingWindow == this.inEffortTrailingWindow &&
          other.isDefault == this.isDefault);
}

class AutolapConfigsCompanion extends UpdateCompanion<AutolapConfigRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> startDeltaWatts;
  final Value<int> startConfirmSeconds;
  final Value<int> startDropoutTolerance;
  final Value<double> endDeltaWatts;
  final Value<int> endConfirmSeconds;
  final Value<int> minEffortSeconds;
  final Value<int> preEffortBaselineWindow;
  final Value<int> inEffortTrailingWindow;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const AutolapConfigsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDeltaWatts = const Value.absent(),
    this.startConfirmSeconds = const Value.absent(),
    this.startDropoutTolerance = const Value.absent(),
    this.endDeltaWatts = const Value.absent(),
    this.endConfirmSeconds = const Value.absent(),
    this.minEffortSeconds = const Value.absent(),
    this.preEffortBaselineWindow = const Value.absent(),
    this.inEffortTrailingWindow = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AutolapConfigsCompanion.insert({
    required String id,
    required String name,
    required double startDeltaWatts,
    this.startConfirmSeconds = const Value.absent(),
    this.startDropoutTolerance = const Value.absent(),
    required double endDeltaWatts,
    this.endConfirmSeconds = const Value.absent(),
    this.minEffortSeconds = const Value.absent(),
    this.preEffortBaselineWindow = const Value.absent(),
    this.inEffortTrailingWindow = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        startDeltaWatts = Value(startDeltaWatts),
        endDeltaWatts = Value(endDeltaWatts);
  static Insertable<AutolapConfigRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? startDeltaWatts,
    Expression<int>? startConfirmSeconds,
    Expression<int>? startDropoutTolerance,
    Expression<double>? endDeltaWatts,
    Expression<int>? endConfirmSeconds,
    Expression<int>? minEffortSeconds,
    Expression<int>? preEffortBaselineWindow,
    Expression<int>? inEffortTrailingWindow,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDeltaWatts != null) 'start_delta_watts': startDeltaWatts,
      if (startConfirmSeconds != null)
        'start_confirm_seconds': startConfirmSeconds,
      if (startDropoutTolerance != null)
        'start_dropout_tolerance': startDropoutTolerance,
      if (endDeltaWatts != null) 'end_delta_watts': endDeltaWatts,
      if (endConfirmSeconds != null) 'end_confirm_seconds': endConfirmSeconds,
      if (minEffortSeconds != null) 'min_effort_seconds': minEffortSeconds,
      if (preEffortBaselineWindow != null)
        'pre_effort_baseline_window': preEffortBaselineWindow,
      if (inEffortTrailingWindow != null)
        'in_effort_trailing_window': inEffortTrailingWindow,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AutolapConfigsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? startDeltaWatts,
      Value<int>? startConfirmSeconds,
      Value<int>? startDropoutTolerance,
      Value<double>? endDeltaWatts,
      Value<int>? endConfirmSeconds,
      Value<int>? minEffortSeconds,
      Value<int>? preEffortBaselineWindow,
      Value<int>? inEffortTrailingWindow,
      Value<bool>? isDefault,
      Value<int>? rowid}) {
    return AutolapConfigsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDeltaWatts: startDeltaWatts ?? this.startDeltaWatts,
      startConfirmSeconds: startConfirmSeconds ?? this.startConfirmSeconds,
      startDropoutTolerance:
          startDropoutTolerance ?? this.startDropoutTolerance,
      endDeltaWatts: endDeltaWatts ?? this.endDeltaWatts,
      endConfirmSeconds: endConfirmSeconds ?? this.endConfirmSeconds,
      minEffortSeconds: minEffortSeconds ?? this.minEffortSeconds,
      preEffortBaselineWindow:
          preEffortBaselineWindow ?? this.preEffortBaselineWindow,
      inEffortTrailingWindow:
          inEffortTrailingWindow ?? this.inEffortTrailingWindow,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDeltaWatts.present) {
      map['start_delta_watts'] = Variable<double>(startDeltaWatts.value);
    }
    if (startConfirmSeconds.present) {
      map['start_confirm_seconds'] = Variable<int>(startConfirmSeconds.value);
    }
    if (startDropoutTolerance.present) {
      map['start_dropout_tolerance'] =
          Variable<int>(startDropoutTolerance.value);
    }
    if (endDeltaWatts.present) {
      map['end_delta_watts'] = Variable<double>(endDeltaWatts.value);
    }
    if (endConfirmSeconds.present) {
      map['end_confirm_seconds'] = Variable<int>(endConfirmSeconds.value);
    }
    if (minEffortSeconds.present) {
      map['min_effort_seconds'] = Variable<int>(minEffortSeconds.value);
    }
    if (preEffortBaselineWindow.present) {
      map['pre_effort_baseline_window'] =
          Variable<int>(preEffortBaselineWindow.value);
    }
    if (inEffortTrailingWindow.present) {
      map['in_effort_trailing_window'] =
          Variable<int>(inEffortTrailingWindow.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AutolapConfigsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDeltaWatts: $startDeltaWatts, ')
          ..write('startConfirmSeconds: $startConfirmSeconds, ')
          ..write('startDropoutTolerance: $startDropoutTolerance, ')
          ..write('endDeltaWatts: $endDeltaWatts, ')
          ..write('endConfirmSeconds: $endConfirmSeconds, ')
          ..write('minEffortSeconds: $minEffortSeconds, ')
          ..write('preEffortBaselineWindow: $preEffortBaselineWindow, ')
          ..write('inEffortTrailingWindow: $inEffortTrailingWindow, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RidesTable extends Rides with TableInfo<$RidesTable, RideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RidesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _autoLapConfigIdMeta =
      const VerificationMeta('autoLapConfigId');
  @override
  late final GeneratedColumn<String> autoLapConfigId = GeneratedColumn<String>(
      'auto_lap_config_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES autolap_configs (id)'));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _activeDurationSecondsMeta =
      const VerificationMeta('activeDurationSeconds');
  @override
  late final GeneratedColumn<int> activeDurationSeconds = GeneratedColumn<int>(
      'active_duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _avgPowerMeta =
      const VerificationMeta('avgPower');
  @override
  late final GeneratedColumn<double> avgPower = GeneratedColumn<double>(
      'avg_power', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxPowerMeta =
      const VerificationMeta('maxPower');
  @override
  late final GeneratedColumn<double> maxPower = GeneratedColumn<double>(
      'max_power', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgHeartRateMeta =
      const VerificationMeta('avgHeartRate');
  @override
  late final GeneratedColumn<int> avgHeartRate = GeneratedColumn<int>(
      'avg_heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxHeartRateMeta =
      const VerificationMeta('maxHeartRate');
  @override
  late final GeneratedColumn<int> maxHeartRate = GeneratedColumn<int>(
      'max_heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _avgCadenceMeta =
      const VerificationMeta('avgCadence');
  @override
  late final GeneratedColumn<double> avgCadence = GeneratedColumn<double>(
      'avg_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalKilojoulesMeta =
      const VerificationMeta('totalKilojoules');
  @override
  late final GeneratedColumn<double> totalKilojoules = GeneratedColumn<double>(
      'total_kilojoules', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgLeftRightBalanceMeta =
      const VerificationMeta('avgLeftRightBalance');
  @override
  late final GeneratedColumn<double> avgLeftRightBalance =
      GeneratedColumn<double>('avg_left_right_balance', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _readingCountMeta =
      const VerificationMeta('readingCount');
  @override
  late final GeneratedColumn<int> readingCount = GeneratedColumn<int>(
      'reading_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _effortCountMeta =
      const VerificationMeta('effortCount');
  @override
  late final GeneratedColumn<int> effortCount = GeneratedColumn<int>(
      'effort_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startTime,
        endTime,
        notes,
        source,
        autoLapConfigId,
        durationSeconds,
        activeDurationSeconds,
        avgPower,
        maxPower,
        avgHeartRate,
        maxHeartRate,
        avgCadence,
        totalKilojoules,
        avgLeftRightBalance,
        readingCount,
        effortCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rides';
  @override
  VerificationContext validateIntegrity(Insertable<RideRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('auto_lap_config_id')) {
      context.handle(
          _autoLapConfigIdMeta,
          autoLapConfigId.isAcceptableOrUnknown(
              data['auto_lap_config_id']!, _autoLapConfigIdMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('active_duration_seconds')) {
      context.handle(
          _activeDurationSecondsMeta,
          activeDurationSeconds.isAcceptableOrUnknown(
              data['active_duration_seconds']!, _activeDurationSecondsMeta));
    } else if (isInserting) {
      context.missing(_activeDurationSecondsMeta);
    }
    if (data.containsKey('avg_power')) {
      context.handle(_avgPowerMeta,
          avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta));
    } else if (isInserting) {
      context.missing(_avgPowerMeta);
    }
    if (data.containsKey('max_power')) {
      context.handle(_maxPowerMeta,
          maxPower.isAcceptableOrUnknown(data['max_power']!, _maxPowerMeta));
    } else if (isInserting) {
      context.missing(_maxPowerMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
          _avgHeartRateMeta,
          avgHeartRate.isAcceptableOrUnknown(
              data['avg_heart_rate']!, _avgHeartRateMeta));
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
          _maxHeartRateMeta,
          maxHeartRate.isAcceptableOrUnknown(
              data['max_heart_rate']!, _maxHeartRateMeta));
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
          _avgCadenceMeta,
          avgCadence.isAcceptableOrUnknown(
              data['avg_cadence']!, _avgCadenceMeta));
    }
    if (data.containsKey('total_kilojoules')) {
      context.handle(
          _totalKilojoulesMeta,
          totalKilojoules.isAcceptableOrUnknown(
              data['total_kilojoules']!, _totalKilojoulesMeta));
    } else if (isInserting) {
      context.missing(_totalKilojoulesMeta);
    }
    if (data.containsKey('avg_left_right_balance')) {
      context.handle(
          _avgLeftRightBalanceMeta,
          avgLeftRightBalance.isAcceptableOrUnknown(
              data['avg_left_right_balance']!, _avgLeftRightBalanceMeta));
    }
    if (data.containsKey('reading_count')) {
      context.handle(
          _readingCountMeta,
          readingCount.isAcceptableOrUnknown(
              data['reading_count']!, _readingCountMeta));
    } else if (isInserting) {
      context.missing(_readingCountMeta);
    }
    if (data.containsKey('effort_count')) {
      context.handle(
          _effortCountMeta,
          effortCount.isAcceptableOrUnknown(
              data['effort_count']!, _effortCountMeta));
    } else if (isInserting) {
      context.missing(_effortCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      autoLapConfigId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}auto_lap_config_id']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      activeDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}active_duration_seconds'])!,
      avgPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_power'])!,
      maxPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_power'])!,
      avgHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avg_heart_rate']),
      maxHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_heart_rate']),
      avgCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_cadence']),
      totalKilojoules: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_kilojoules'])!,
      avgLeftRightBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_left_right_balance']),
      readingCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reading_count'])!,
      effortCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}effort_count'])!,
    );
  }

  @override
  $RidesTable createAlias(String alias) {
    return $RidesTable(attachedDatabase, alias);
  }
}

class RideRow extends DataClass implements Insertable<RideRow> {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final String source;
  final String? autoLapConfigId;
  final int durationSeconds;
  final int activeDurationSeconds;
  final double avgPower;
  final double maxPower;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? avgCadence;
  final double totalKilojoules;
  final double? avgLeftRightBalance;
  final int readingCount;
  final int effortCount;
  const RideRow(
      {required this.id,
      required this.startTime,
      this.endTime,
      this.notes,
      required this.source,
      this.autoLapConfigId,
      required this.durationSeconds,
      required this.activeDurationSeconds,
      required this.avgPower,
      required this.maxPower,
      this.avgHeartRate,
      this.maxHeartRate,
      this.avgCadence,
      required this.totalKilojoules,
      this.avgLeftRightBalance,
      required this.readingCount,
      required this.effortCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || autoLapConfigId != null) {
      map['auto_lap_config_id'] = Variable<String>(autoLapConfigId);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['active_duration_seconds'] = Variable<int>(activeDurationSeconds);
    map['avg_power'] = Variable<double>(avgPower);
    map['max_power'] = Variable<double>(maxPower);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<double>(avgCadence);
    }
    map['total_kilojoules'] = Variable<double>(totalKilojoules);
    if (!nullToAbsent || avgLeftRightBalance != null) {
      map['avg_left_right_balance'] = Variable<double>(avgLeftRightBalance);
    }
    map['reading_count'] = Variable<int>(readingCount);
    map['effort_count'] = Variable<int>(effortCount);
    return map;
  }

  RidesCompanion toCompanion(bool nullToAbsent) {
    return RidesCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      source: Value(source),
      autoLapConfigId: autoLapConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(autoLapConfigId),
      durationSeconds: Value(durationSeconds),
      activeDurationSeconds: Value(activeDurationSeconds),
      avgPower: Value(avgPower),
      maxPower: Value(maxPower),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      totalKilojoules: Value(totalKilojoules),
      avgLeftRightBalance: avgLeftRightBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(avgLeftRightBalance),
      readingCount: Value(readingCount),
      effortCount: Value(effortCount),
    );
  }

  factory RideRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideRow(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      autoLapConfigId: serializer.fromJson<String?>(json['autoLapConfigId']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      activeDurationSeconds:
          serializer.fromJson<int>(json['activeDurationSeconds']),
      avgPower: serializer.fromJson<double>(json['avgPower']),
      maxPower: serializer.fromJson<double>(json['maxPower']),
      avgHeartRate: serializer.fromJson<int?>(json['avgHeartRate']),
      maxHeartRate: serializer.fromJson<int?>(json['maxHeartRate']),
      avgCadence: serializer.fromJson<double?>(json['avgCadence']),
      totalKilojoules: serializer.fromJson<double>(json['totalKilojoules']),
      avgLeftRightBalance:
          serializer.fromJson<double?>(json['avgLeftRightBalance']),
      readingCount: serializer.fromJson<int>(json['readingCount']),
      effortCount: serializer.fromJson<int>(json['effortCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'autoLapConfigId': serializer.toJson<String?>(autoLapConfigId),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'activeDurationSeconds': serializer.toJson<int>(activeDurationSeconds),
      'avgPower': serializer.toJson<double>(avgPower),
      'maxPower': serializer.toJson<double>(maxPower),
      'avgHeartRate': serializer.toJson<int?>(avgHeartRate),
      'maxHeartRate': serializer.toJson<int?>(maxHeartRate),
      'avgCadence': serializer.toJson<double?>(avgCadence),
      'totalKilojoules': serializer.toJson<double>(totalKilojoules),
      'avgLeftRightBalance': serializer.toJson<double?>(avgLeftRightBalance),
      'readingCount': serializer.toJson<int>(readingCount),
      'effortCount': serializer.toJson<int>(effortCount),
    };
  }

  RideRow copyWith(
          {String? id,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? source,
          Value<String?> autoLapConfigId = const Value.absent(),
          int? durationSeconds,
          int? activeDurationSeconds,
          double? avgPower,
          double? maxPower,
          Value<int?> avgHeartRate = const Value.absent(),
          Value<int?> maxHeartRate = const Value.absent(),
          Value<double?> avgCadence = const Value.absent(),
          double? totalKilojoules,
          Value<double?> avgLeftRightBalance = const Value.absent(),
          int? readingCount,
          int? effortCount}) =>
      RideRow(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        notes: notes.present ? notes.value : this.notes,
        source: source ?? this.source,
        autoLapConfigId: autoLapConfigId.present
            ? autoLapConfigId.value
            : this.autoLapConfigId,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        activeDurationSeconds:
            activeDurationSeconds ?? this.activeDurationSeconds,
        avgPower: avgPower ?? this.avgPower,
        maxPower: maxPower ?? this.maxPower,
        avgHeartRate:
            avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
        maxHeartRate:
            maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
        avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
        totalKilojoules: totalKilojoules ?? this.totalKilojoules,
        avgLeftRightBalance: avgLeftRightBalance.present
            ? avgLeftRightBalance.value
            : this.avgLeftRightBalance,
        readingCount: readingCount ?? this.readingCount,
        effortCount: effortCount ?? this.effortCount,
      );
  RideRow copyWithCompanion(RidesCompanion data) {
    return RideRow(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      autoLapConfigId: data.autoLapConfigId.present
          ? data.autoLapConfigId.value
          : this.autoLapConfigId,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      activeDurationSeconds: data.activeDurationSeconds.present
          ? data.activeDurationSeconds.value
          : this.activeDurationSeconds,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      maxPower: data.maxPower.present ? data.maxPower.value : this.maxPower,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      avgCadence:
          data.avgCadence.present ? data.avgCadence.value : this.avgCadence,
      totalKilojoules: data.totalKilojoules.present
          ? data.totalKilojoules.value
          : this.totalKilojoules,
      avgLeftRightBalance: data.avgLeftRightBalance.present
          ? data.avgLeftRightBalance.value
          : this.avgLeftRightBalance,
      readingCount: data.readingCount.present
          ? data.readingCount.value
          : this.readingCount,
      effortCount:
          data.effortCount.present ? data.effortCount.value : this.effortCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideRow(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('autoLapConfigId: $autoLapConfigId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('activeDurationSeconds: $activeDurationSeconds, ')
          ..write('avgPower: $avgPower, ')
          ..write('maxPower: $maxPower, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalKilojoules: $totalKilojoules, ')
          ..write('avgLeftRightBalance: $avgLeftRightBalance, ')
          ..write('readingCount: $readingCount, ')
          ..write('effortCount: $effortCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      startTime,
      endTime,
      notes,
      source,
      autoLapConfigId,
      durationSeconds,
      activeDurationSeconds,
      avgPower,
      maxPower,
      avgHeartRate,
      maxHeartRate,
      avgCadence,
      totalKilojoules,
      avgLeftRightBalance,
      readingCount,
      effortCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideRow &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.autoLapConfigId == this.autoLapConfigId &&
          other.durationSeconds == this.durationSeconds &&
          other.activeDurationSeconds == this.activeDurationSeconds &&
          other.avgPower == this.avgPower &&
          other.maxPower == this.maxPower &&
          other.avgHeartRate == this.avgHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.avgCadence == this.avgCadence &&
          other.totalKilojoules == this.totalKilojoules &&
          other.avgLeftRightBalance == this.avgLeftRightBalance &&
          other.readingCount == this.readingCount &&
          other.effortCount == this.effortCount);
}

class RidesCompanion extends UpdateCompanion<RideRow> {
  final Value<String> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> autoLapConfigId;
  final Value<int> durationSeconds;
  final Value<int> activeDurationSeconds;
  final Value<double> avgPower;
  final Value<double> maxPower;
  final Value<int?> avgHeartRate;
  final Value<int?> maxHeartRate;
  final Value<double?> avgCadence;
  final Value<double> totalKilojoules;
  final Value<double?> avgLeftRightBalance;
  final Value<int> readingCount;
  final Value<int> effortCount;
  final Value<int> rowid;
  const RidesCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.autoLapConfigId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.activeDurationSeconds = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.totalKilojoules = const Value.absent(),
    this.avgLeftRightBalance = const Value.absent(),
    this.readingCount = const Value.absent(),
    this.effortCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RidesCompanion.insert({
    required String id,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.notes = const Value.absent(),
    required String source,
    this.autoLapConfigId = const Value.absent(),
    required int durationSeconds,
    required int activeDurationSeconds,
    required double avgPower,
    required double maxPower,
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    required double totalKilojoules,
    this.avgLeftRightBalance = const Value.absent(),
    required int readingCount,
    required int effortCount,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startTime = Value(startTime),
        source = Value(source),
        durationSeconds = Value(durationSeconds),
        activeDurationSeconds = Value(activeDurationSeconds),
        avgPower = Value(avgPower),
        maxPower = Value(maxPower),
        totalKilojoules = Value(totalKilojoules),
        readingCount = Value(readingCount),
        effortCount = Value(effortCount);
  static Insertable<RideRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? autoLapConfigId,
    Expression<int>? durationSeconds,
    Expression<int>? activeDurationSeconds,
    Expression<double>? avgPower,
    Expression<double>? maxPower,
    Expression<int>? avgHeartRate,
    Expression<int>? maxHeartRate,
    Expression<double>? avgCadence,
    Expression<double>? totalKilojoules,
    Expression<double>? avgLeftRightBalance,
    Expression<int>? readingCount,
    Expression<int>? effortCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (autoLapConfigId != null) 'auto_lap_config_id': autoLapConfigId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (activeDurationSeconds != null)
        'active_duration_seconds': activeDurationSeconds,
      if (avgPower != null) 'avg_power': avgPower,
      if (maxPower != null) 'max_power': maxPower,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (totalKilojoules != null) 'total_kilojoules': totalKilojoules,
      if (avgLeftRightBalance != null)
        'avg_left_right_balance': avgLeftRightBalance,
      if (readingCount != null) 'reading_count': readingCount,
      if (effortCount != null) 'effort_count': effortCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RidesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<String?>? notes,
      Value<String>? source,
      Value<String?>? autoLapConfigId,
      Value<int>? durationSeconds,
      Value<int>? activeDurationSeconds,
      Value<double>? avgPower,
      Value<double>? maxPower,
      Value<int?>? avgHeartRate,
      Value<int?>? maxHeartRate,
      Value<double?>? avgCadence,
      Value<double>? totalKilojoules,
      Value<double?>? avgLeftRightBalance,
      Value<int>? readingCount,
      Value<int>? effortCount,
      Value<int>? rowid}) {
    return RidesCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      autoLapConfigId: autoLapConfigId ?? this.autoLapConfigId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      activeDurationSeconds:
          activeDurationSeconds ?? this.activeDurationSeconds,
      avgPower: avgPower ?? this.avgPower,
      maxPower: maxPower ?? this.maxPower,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgCadence: avgCadence ?? this.avgCadence,
      totalKilojoules: totalKilojoules ?? this.totalKilojoules,
      avgLeftRightBalance: avgLeftRightBalance ?? this.avgLeftRightBalance,
      readingCount: readingCount ?? this.readingCount,
      effortCount: effortCount ?? this.effortCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (autoLapConfigId.present) {
      map['auto_lap_config_id'] = Variable<String>(autoLapConfigId.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (activeDurationSeconds.present) {
      map['active_duration_seconds'] =
          Variable<int>(activeDurationSeconds.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<double>(avgPower.value);
    }
    if (maxPower.present) {
      map['max_power'] = Variable<double>(maxPower.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<double>(avgCadence.value);
    }
    if (totalKilojoules.present) {
      map['total_kilojoules'] = Variable<double>(totalKilojoules.value);
    }
    if (avgLeftRightBalance.present) {
      map['avg_left_right_balance'] =
          Variable<double>(avgLeftRightBalance.value);
    }
    if (readingCount.present) {
      map['reading_count'] = Variable<int>(readingCount.value);
    }
    if (effortCount.present) {
      map['effort_count'] = Variable<int>(effortCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RidesCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('autoLapConfigId: $autoLapConfigId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('activeDurationSeconds: $activeDurationSeconds, ')
          ..write('avgPower: $avgPower, ')
          ..write('maxPower: $maxPower, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalKilojoules: $totalKilojoules, ')
          ..write('avgLeftRightBalance: $avgLeftRightBalance, ')
          ..write('readingCount: $readingCount, ')
          ..write('effortCount: $effortCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RideTagsTable extends RideTags
    with TableInfo<$RideTagsTable, RideTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RideTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
      'ride_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES rides (id)'));
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [rideId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ride_tags';
  @override
  VerificationContext validateIntegrity(Insertable<RideTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ride_id')) {
      context.handle(_rideIdMeta,
          rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta));
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rideId, tag};
  @override
  RideTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideTagRow(
      rideId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ride_id'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
    );
  }

  @override
  $RideTagsTable createAlias(String alias) {
    return $RideTagsTable(attachedDatabase, alias);
  }
}

class RideTagRow extends DataClass implements Insertable<RideTagRow> {
  final String rideId;
  final String tag;
  const RideTagRow({required this.rideId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ride_id'] = Variable<String>(rideId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  RideTagsCompanion toCompanion(bool nullToAbsent) {
    return RideTagsCompanion(
      rideId: Value(rideId),
      tag: Value(tag),
    );
  }

  factory RideTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideTagRow(
      rideId: serializer.fromJson<String>(json['rideId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rideId': serializer.toJson<String>(rideId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  RideTagRow copyWith({String? rideId, String? tag}) => RideTagRow(
        rideId: rideId ?? this.rideId,
        tag: tag ?? this.tag,
      );
  RideTagRow copyWithCompanion(RideTagsCompanion data) {
    return RideTagRow(
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideTagRow(')
          ..write('rideId: $rideId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rideId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideTagRow &&
          other.rideId == this.rideId &&
          other.tag == this.tag);
}

class RideTagsCompanion extends UpdateCompanion<RideTagRow> {
  final Value<String> rideId;
  final Value<String> tag;
  final Value<int> rowid;
  const RideTagsCompanion({
    this.rideId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RideTagsCompanion.insert({
    required String rideId,
    required String tag,
    this.rowid = const Value.absent(),
  })  : rideId = Value(rideId),
        tag = Value(tag);
  static Insertable<RideTagRow> custom({
    Expression<String>? rideId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rideId != null) 'ride_id': rideId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RideTagsCompanion copyWith(
      {Value<String>? rideId, Value<String>? tag, Value<int>? rowid}) {
    return RideTagsCompanion(
      rideId: rideId ?? this.rideId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RideTagsCompanion(')
          ..write('rideId: $rideId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EffortsTable extends Efforts with TableInfo<$EffortsTable, EffortRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EffortsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
      'ride_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES rides (id)'));
  static const VerificationMeta _effortNumberMeta =
      const VerificationMeta('effortNumber');
  @override
  late final GeneratedColumn<int> effortNumber = GeneratedColumn<int>(
      'effort_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startOffsetMeta =
      const VerificationMeta('startOffset');
  @override
  late final GeneratedColumn<int> startOffset = GeneratedColumn<int>(
      'start_offset', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endOffsetMeta =
      const VerificationMeta('endOffset');
  @override
  late final GeneratedColumn<int> endOffset = GeneratedColumn<int>(
      'end_offset', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _avgPowerMeta =
      const VerificationMeta('avgPower');
  @override
  late final GeneratedColumn<double> avgPower = GeneratedColumn<double>(
      'avg_power', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakPowerMeta =
      const VerificationMeta('peakPower');
  @override
  late final GeneratedColumn<double> peakPower = GeneratedColumn<double>(
      'peak_power', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgHeartRateMeta =
      const VerificationMeta('avgHeartRate');
  @override
  late final GeneratedColumn<int> avgHeartRate = GeneratedColumn<int>(
      'avg_heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxHeartRateMeta =
      const VerificationMeta('maxHeartRate');
  @override
  late final GeneratedColumn<int> maxHeartRate = GeneratedColumn<int>(
      'max_heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _avgCadenceMeta =
      const VerificationMeta('avgCadence');
  @override
  late final GeneratedColumn<double> avgCadence = GeneratedColumn<double>(
      'avg_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalKilojoulesMeta =
      const VerificationMeta('totalKilojoules');
  @override
  late final GeneratedColumn<double> totalKilojoules = GeneratedColumn<double>(
      'total_kilojoules', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgLeftRightBalanceMeta =
      const VerificationMeta('avgLeftRightBalance');
  @override
  late final GeneratedColumn<double> avgLeftRightBalance =
      GeneratedColumn<double>('avg_left_right_balance', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _restSincePreviousMeta =
      const VerificationMeta('restSincePrevious');
  @override
  late final GeneratedColumn<int> restSincePrevious = GeneratedColumn<int>(
      'rest_since_previous', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rideId,
        effortNumber,
        startOffset,
        endOffset,
        type,
        durationSeconds,
        avgPower,
        peakPower,
        avgHeartRate,
        maxHeartRate,
        avgCadence,
        totalKilojoules,
        avgLeftRightBalance,
        restSincePrevious
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'efforts';
  @override
  VerificationContext validateIntegrity(Insertable<EffortRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ride_id')) {
      context.handle(_rideIdMeta,
          rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta));
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('effort_number')) {
      context.handle(
          _effortNumberMeta,
          effortNumber.isAcceptableOrUnknown(
              data['effort_number']!, _effortNumberMeta));
    } else if (isInserting) {
      context.missing(_effortNumberMeta);
    }
    if (data.containsKey('start_offset')) {
      context.handle(
          _startOffsetMeta,
          startOffset.isAcceptableOrUnknown(
              data['start_offset']!, _startOffsetMeta));
    } else if (isInserting) {
      context.missing(_startOffsetMeta);
    }
    if (data.containsKey('end_offset')) {
      context.handle(_endOffsetMeta,
          endOffset.isAcceptableOrUnknown(data['end_offset']!, _endOffsetMeta));
    } else if (isInserting) {
      context.missing(_endOffsetMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('avg_power')) {
      context.handle(_avgPowerMeta,
          avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta));
    } else if (isInserting) {
      context.missing(_avgPowerMeta);
    }
    if (data.containsKey('peak_power')) {
      context.handle(_peakPowerMeta,
          peakPower.isAcceptableOrUnknown(data['peak_power']!, _peakPowerMeta));
    } else if (isInserting) {
      context.missing(_peakPowerMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
          _avgHeartRateMeta,
          avgHeartRate.isAcceptableOrUnknown(
              data['avg_heart_rate']!, _avgHeartRateMeta));
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
          _maxHeartRateMeta,
          maxHeartRate.isAcceptableOrUnknown(
              data['max_heart_rate']!, _maxHeartRateMeta));
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
          _avgCadenceMeta,
          avgCadence.isAcceptableOrUnknown(
              data['avg_cadence']!, _avgCadenceMeta));
    }
    if (data.containsKey('total_kilojoules')) {
      context.handle(
          _totalKilojoulesMeta,
          totalKilojoules.isAcceptableOrUnknown(
              data['total_kilojoules']!, _totalKilojoulesMeta));
    } else if (isInserting) {
      context.missing(_totalKilojoulesMeta);
    }
    if (data.containsKey('avg_left_right_balance')) {
      context.handle(
          _avgLeftRightBalanceMeta,
          avgLeftRightBalance.isAcceptableOrUnknown(
              data['avg_left_right_balance']!, _avgLeftRightBalanceMeta));
    }
    if (data.containsKey('rest_since_previous')) {
      context.handle(
          _restSincePreviousMeta,
          restSincePrevious.isAcceptableOrUnknown(
              data['rest_since_previous']!, _restSincePreviousMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EffortRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EffortRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rideId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ride_id'])!,
      effortNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}effort_number'])!,
      startOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_offset'])!,
      endOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_offset'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      avgPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_power'])!,
      peakPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peak_power'])!,
      avgHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avg_heart_rate']),
      maxHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_heart_rate']),
      avgCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_cadence']),
      totalKilojoules: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_kilojoules'])!,
      avgLeftRightBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_left_right_balance']),
      restSincePrevious: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}rest_since_previous']),
    );
  }

  @override
  $EffortsTable createAlias(String alias) {
    return $EffortsTable(attachedDatabase, alias);
  }
}

class EffortRow extends DataClass implements Insertable<EffortRow> {
  final String id;
  final String rideId;
  final int effortNumber;
  final int startOffset;
  final int endOffset;
  final String type;
  final int durationSeconds;
  final double avgPower;
  final double peakPower;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? avgCadence;
  final double totalKilojoules;
  final double? avgLeftRightBalance;
  final int? restSincePrevious;
  const EffortRow(
      {required this.id,
      required this.rideId,
      required this.effortNumber,
      required this.startOffset,
      required this.endOffset,
      required this.type,
      required this.durationSeconds,
      required this.avgPower,
      required this.peakPower,
      this.avgHeartRate,
      this.maxHeartRate,
      this.avgCadence,
      required this.totalKilojoules,
      this.avgLeftRightBalance,
      this.restSincePrevious});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ride_id'] = Variable<String>(rideId);
    map['effort_number'] = Variable<int>(effortNumber);
    map['start_offset'] = Variable<int>(startOffset);
    map['end_offset'] = Variable<int>(endOffset);
    map['type'] = Variable<String>(type);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['avg_power'] = Variable<double>(avgPower);
    map['peak_power'] = Variable<double>(peakPower);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<double>(avgCadence);
    }
    map['total_kilojoules'] = Variable<double>(totalKilojoules);
    if (!nullToAbsent || avgLeftRightBalance != null) {
      map['avg_left_right_balance'] = Variable<double>(avgLeftRightBalance);
    }
    if (!nullToAbsent || restSincePrevious != null) {
      map['rest_since_previous'] = Variable<int>(restSincePrevious);
    }
    return map;
  }

  EffortsCompanion toCompanion(bool nullToAbsent) {
    return EffortsCompanion(
      id: Value(id),
      rideId: Value(rideId),
      effortNumber: Value(effortNumber),
      startOffset: Value(startOffset),
      endOffset: Value(endOffset),
      type: Value(type),
      durationSeconds: Value(durationSeconds),
      avgPower: Value(avgPower),
      peakPower: Value(peakPower),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      totalKilojoules: Value(totalKilojoules),
      avgLeftRightBalance: avgLeftRightBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(avgLeftRightBalance),
      restSincePrevious: restSincePrevious == null && nullToAbsent
          ? const Value.absent()
          : Value(restSincePrevious),
    );
  }

  factory EffortRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EffortRow(
      id: serializer.fromJson<String>(json['id']),
      rideId: serializer.fromJson<String>(json['rideId']),
      effortNumber: serializer.fromJson<int>(json['effortNumber']),
      startOffset: serializer.fromJson<int>(json['startOffset']),
      endOffset: serializer.fromJson<int>(json['endOffset']),
      type: serializer.fromJson<String>(json['type']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      avgPower: serializer.fromJson<double>(json['avgPower']),
      peakPower: serializer.fromJson<double>(json['peakPower']),
      avgHeartRate: serializer.fromJson<int?>(json['avgHeartRate']),
      maxHeartRate: serializer.fromJson<int?>(json['maxHeartRate']),
      avgCadence: serializer.fromJson<double?>(json['avgCadence']),
      totalKilojoules: serializer.fromJson<double>(json['totalKilojoules']),
      avgLeftRightBalance:
          serializer.fromJson<double?>(json['avgLeftRightBalance']),
      restSincePrevious: serializer.fromJson<int?>(json['restSincePrevious']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rideId': serializer.toJson<String>(rideId),
      'effortNumber': serializer.toJson<int>(effortNumber),
      'startOffset': serializer.toJson<int>(startOffset),
      'endOffset': serializer.toJson<int>(endOffset),
      'type': serializer.toJson<String>(type),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'avgPower': serializer.toJson<double>(avgPower),
      'peakPower': serializer.toJson<double>(peakPower),
      'avgHeartRate': serializer.toJson<int?>(avgHeartRate),
      'maxHeartRate': serializer.toJson<int?>(maxHeartRate),
      'avgCadence': serializer.toJson<double?>(avgCadence),
      'totalKilojoules': serializer.toJson<double>(totalKilojoules),
      'avgLeftRightBalance': serializer.toJson<double?>(avgLeftRightBalance),
      'restSincePrevious': serializer.toJson<int?>(restSincePrevious),
    };
  }

  EffortRow copyWith(
          {String? id,
          String? rideId,
          int? effortNumber,
          int? startOffset,
          int? endOffset,
          String? type,
          int? durationSeconds,
          double? avgPower,
          double? peakPower,
          Value<int?> avgHeartRate = const Value.absent(),
          Value<int?> maxHeartRate = const Value.absent(),
          Value<double?> avgCadence = const Value.absent(),
          double? totalKilojoules,
          Value<double?> avgLeftRightBalance = const Value.absent(),
          Value<int?> restSincePrevious = const Value.absent()}) =>
      EffortRow(
        id: id ?? this.id,
        rideId: rideId ?? this.rideId,
        effortNumber: effortNumber ?? this.effortNumber,
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        type: type ?? this.type,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        avgPower: avgPower ?? this.avgPower,
        peakPower: peakPower ?? this.peakPower,
        avgHeartRate:
            avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
        maxHeartRate:
            maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
        avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
        totalKilojoules: totalKilojoules ?? this.totalKilojoules,
        avgLeftRightBalance: avgLeftRightBalance.present
            ? avgLeftRightBalance.value
            : this.avgLeftRightBalance,
        restSincePrevious: restSincePrevious.present
            ? restSincePrevious.value
            : this.restSincePrevious,
      );
  EffortRow copyWithCompanion(EffortsCompanion data) {
    return EffortRow(
      id: data.id.present ? data.id.value : this.id,
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      effortNumber: data.effortNumber.present
          ? data.effortNumber.value
          : this.effortNumber,
      startOffset:
          data.startOffset.present ? data.startOffset.value : this.startOffset,
      endOffset: data.endOffset.present ? data.endOffset.value : this.endOffset,
      type: data.type.present ? data.type.value : this.type,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      peakPower: data.peakPower.present ? data.peakPower.value : this.peakPower,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      avgCadence:
          data.avgCadence.present ? data.avgCadence.value : this.avgCadence,
      totalKilojoules: data.totalKilojoules.present
          ? data.totalKilojoules.value
          : this.totalKilojoules,
      avgLeftRightBalance: data.avgLeftRightBalance.present
          ? data.avgLeftRightBalance.value
          : this.avgLeftRightBalance,
      restSincePrevious: data.restSincePrevious.present
          ? data.restSincePrevious.value
          : this.restSincePrevious,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EffortRow(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('effortNumber: $effortNumber, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('type: $type, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('avgPower: $avgPower, ')
          ..write('peakPower: $peakPower, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalKilojoules: $totalKilojoules, ')
          ..write('avgLeftRightBalance: $avgLeftRightBalance, ')
          ..write('restSincePrevious: $restSincePrevious')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      rideId,
      effortNumber,
      startOffset,
      endOffset,
      type,
      durationSeconds,
      avgPower,
      peakPower,
      avgHeartRate,
      maxHeartRate,
      avgCadence,
      totalKilojoules,
      avgLeftRightBalance,
      restSincePrevious);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EffortRow &&
          other.id == this.id &&
          other.rideId == this.rideId &&
          other.effortNumber == this.effortNumber &&
          other.startOffset == this.startOffset &&
          other.endOffset == this.endOffset &&
          other.type == this.type &&
          other.durationSeconds == this.durationSeconds &&
          other.avgPower == this.avgPower &&
          other.peakPower == this.peakPower &&
          other.avgHeartRate == this.avgHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.avgCadence == this.avgCadence &&
          other.totalKilojoules == this.totalKilojoules &&
          other.avgLeftRightBalance == this.avgLeftRightBalance &&
          other.restSincePrevious == this.restSincePrevious);
}

class EffortsCompanion extends UpdateCompanion<EffortRow> {
  final Value<String> id;
  final Value<String> rideId;
  final Value<int> effortNumber;
  final Value<int> startOffset;
  final Value<int> endOffset;
  final Value<String> type;
  final Value<int> durationSeconds;
  final Value<double> avgPower;
  final Value<double> peakPower;
  final Value<int?> avgHeartRate;
  final Value<int?> maxHeartRate;
  final Value<double?> avgCadence;
  final Value<double> totalKilojoules;
  final Value<double?> avgLeftRightBalance;
  final Value<int?> restSincePrevious;
  final Value<int> rowid;
  const EffortsCompanion({
    this.id = const Value.absent(),
    this.rideId = const Value.absent(),
    this.effortNumber = const Value.absent(),
    this.startOffset = const Value.absent(),
    this.endOffset = const Value.absent(),
    this.type = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.peakPower = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.totalKilojoules = const Value.absent(),
    this.avgLeftRightBalance = const Value.absent(),
    this.restSincePrevious = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EffortsCompanion.insert({
    required String id,
    required String rideId,
    required int effortNumber,
    required int startOffset,
    required int endOffset,
    required String type,
    required int durationSeconds,
    required double avgPower,
    required double peakPower,
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    required double totalKilojoules,
    this.avgLeftRightBalance = const Value.absent(),
    this.restSincePrevious = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rideId = Value(rideId),
        effortNumber = Value(effortNumber),
        startOffset = Value(startOffset),
        endOffset = Value(endOffset),
        type = Value(type),
        durationSeconds = Value(durationSeconds),
        avgPower = Value(avgPower),
        peakPower = Value(peakPower),
        totalKilojoules = Value(totalKilojoules);
  static Insertable<EffortRow> custom({
    Expression<String>? id,
    Expression<String>? rideId,
    Expression<int>? effortNumber,
    Expression<int>? startOffset,
    Expression<int>? endOffset,
    Expression<String>? type,
    Expression<int>? durationSeconds,
    Expression<double>? avgPower,
    Expression<double>? peakPower,
    Expression<int>? avgHeartRate,
    Expression<int>? maxHeartRate,
    Expression<double>? avgCadence,
    Expression<double>? totalKilojoules,
    Expression<double>? avgLeftRightBalance,
    Expression<int>? restSincePrevious,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rideId != null) 'ride_id': rideId,
      if (effortNumber != null) 'effort_number': effortNumber,
      if (startOffset != null) 'start_offset': startOffset,
      if (endOffset != null) 'end_offset': endOffset,
      if (type != null) 'type': type,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (avgPower != null) 'avg_power': avgPower,
      if (peakPower != null) 'peak_power': peakPower,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (totalKilojoules != null) 'total_kilojoules': totalKilojoules,
      if (avgLeftRightBalance != null)
        'avg_left_right_balance': avgLeftRightBalance,
      if (restSincePrevious != null) 'rest_since_previous': restSincePrevious,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EffortsCompanion copyWith(
      {Value<String>? id,
      Value<String>? rideId,
      Value<int>? effortNumber,
      Value<int>? startOffset,
      Value<int>? endOffset,
      Value<String>? type,
      Value<int>? durationSeconds,
      Value<double>? avgPower,
      Value<double>? peakPower,
      Value<int?>? avgHeartRate,
      Value<int?>? maxHeartRate,
      Value<double?>? avgCadence,
      Value<double>? totalKilojoules,
      Value<double?>? avgLeftRightBalance,
      Value<int?>? restSincePrevious,
      Value<int>? rowid}) {
    return EffortsCompanion(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      effortNumber: effortNumber ?? this.effortNumber,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      type: type ?? this.type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgPower: avgPower ?? this.avgPower,
      peakPower: peakPower ?? this.peakPower,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgCadence: avgCadence ?? this.avgCadence,
      totalKilojoules: totalKilojoules ?? this.totalKilojoules,
      avgLeftRightBalance: avgLeftRightBalance ?? this.avgLeftRightBalance,
      restSincePrevious: restSincePrevious ?? this.restSincePrevious,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (effortNumber.present) {
      map['effort_number'] = Variable<int>(effortNumber.value);
    }
    if (startOffset.present) {
      map['start_offset'] = Variable<int>(startOffset.value);
    }
    if (endOffset.present) {
      map['end_offset'] = Variable<int>(endOffset.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<double>(avgPower.value);
    }
    if (peakPower.present) {
      map['peak_power'] = Variable<double>(peakPower.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<double>(avgCadence.value);
    }
    if (totalKilojoules.present) {
      map['total_kilojoules'] = Variable<double>(totalKilojoules.value);
    }
    if (avgLeftRightBalance.present) {
      map['avg_left_right_balance'] =
          Variable<double>(avgLeftRightBalance.value);
    }
    if (restSincePrevious.present) {
      map['rest_since_previous'] = Variable<int>(restSincePrevious.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EffortsCompanion(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('effortNumber: $effortNumber, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('type: $type, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('avgPower: $avgPower, ')
          ..write('peakPower: $peakPower, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalKilojoules: $totalKilojoules, ')
          ..write('avgLeftRightBalance: $avgLeftRightBalance, ')
          ..write('restSincePrevious: $restSincePrevious, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MapCurvesTable extends MapCurves
    with TableInfo<$MapCurvesTable, MapCurveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MapCurvesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _effortIdMeta =
      const VerificationMeta('effortId');
  @override
  late final GeneratedColumn<String> effortId = GeneratedColumn<String>(
      'effort_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES efforts (id)'));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bestAvgPowerMeta =
      const VerificationMeta('bestAvgPower');
  @override
  late final GeneratedColumn<double> bestAvgPower = GeneratedColumn<double>(
      'best_avg_power', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _hadNullsMeta =
      const VerificationMeta('hadNulls');
  @override
  late final GeneratedColumn<bool> hadNulls = GeneratedColumn<bool>(
      'had_nulls', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("had_nulls" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _wasEnforcedMeta =
      const VerificationMeta('wasEnforced');
  @override
  late final GeneratedColumn<bool> wasEnforced = GeneratedColumn<bool>(
      'was_enforced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_enforced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [effortId, durationSeconds, bestAvgPower, hadNulls, wasEnforced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'map_curves';
  @override
  VerificationContext validateIntegrity(Insertable<MapCurveRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('effort_id')) {
      context.handle(_effortIdMeta,
          effortId.isAcceptableOrUnknown(data['effort_id']!, _effortIdMeta));
    } else if (isInserting) {
      context.missing(_effortIdMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('best_avg_power')) {
      context.handle(
          _bestAvgPowerMeta,
          bestAvgPower.isAcceptableOrUnknown(
              data['best_avg_power']!, _bestAvgPowerMeta));
    } else if (isInserting) {
      context.missing(_bestAvgPowerMeta);
    }
    if (data.containsKey('had_nulls')) {
      context.handle(_hadNullsMeta,
          hadNulls.isAcceptableOrUnknown(data['had_nulls']!, _hadNullsMeta));
    }
    if (data.containsKey('was_enforced')) {
      context.handle(
          _wasEnforcedMeta,
          wasEnforced.isAcceptableOrUnknown(
              data['was_enforced']!, _wasEnforcedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {effortId, durationSeconds};
  @override
  MapCurveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MapCurveRow(
      effortId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effort_id'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      bestAvgPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}best_avg_power'])!,
      hadNulls: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}had_nulls'])!,
      wasEnforced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_enforced'])!,
    );
  }

  @override
  $MapCurvesTable createAlias(String alias) {
    return $MapCurvesTable(attachedDatabase, alias);
  }
}

class MapCurveRow extends DataClass implements Insertable<MapCurveRow> {
  final String effortId;
  final int durationSeconds;
  final double bestAvgPower;
  final bool hadNulls;
  final bool wasEnforced;
  const MapCurveRow(
      {required this.effortId,
      required this.durationSeconds,
      required this.bestAvgPower,
      required this.hadNulls,
      required this.wasEnforced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['effort_id'] = Variable<String>(effortId);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['best_avg_power'] = Variable<double>(bestAvgPower);
    map['had_nulls'] = Variable<bool>(hadNulls);
    map['was_enforced'] = Variable<bool>(wasEnforced);
    return map;
  }

  MapCurvesCompanion toCompanion(bool nullToAbsent) {
    return MapCurvesCompanion(
      effortId: Value(effortId),
      durationSeconds: Value(durationSeconds),
      bestAvgPower: Value(bestAvgPower),
      hadNulls: Value(hadNulls),
      wasEnforced: Value(wasEnforced),
    );
  }

  factory MapCurveRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MapCurveRow(
      effortId: serializer.fromJson<String>(json['effortId']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      bestAvgPower: serializer.fromJson<double>(json['bestAvgPower']),
      hadNulls: serializer.fromJson<bool>(json['hadNulls']),
      wasEnforced: serializer.fromJson<bool>(json['wasEnforced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'effortId': serializer.toJson<String>(effortId),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'bestAvgPower': serializer.toJson<double>(bestAvgPower),
      'hadNulls': serializer.toJson<bool>(hadNulls),
      'wasEnforced': serializer.toJson<bool>(wasEnforced),
    };
  }

  MapCurveRow copyWith(
          {String? effortId,
          int? durationSeconds,
          double? bestAvgPower,
          bool? hadNulls,
          bool? wasEnforced}) =>
      MapCurveRow(
        effortId: effortId ?? this.effortId,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        bestAvgPower: bestAvgPower ?? this.bestAvgPower,
        hadNulls: hadNulls ?? this.hadNulls,
        wasEnforced: wasEnforced ?? this.wasEnforced,
      );
  MapCurveRow copyWithCompanion(MapCurvesCompanion data) {
    return MapCurveRow(
      effortId: data.effortId.present ? data.effortId.value : this.effortId,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      bestAvgPower: data.bestAvgPower.present
          ? data.bestAvgPower.value
          : this.bestAvgPower,
      hadNulls: data.hadNulls.present ? data.hadNulls.value : this.hadNulls,
      wasEnforced:
          data.wasEnforced.present ? data.wasEnforced.value : this.wasEnforced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MapCurveRow(')
          ..write('effortId: $effortId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('bestAvgPower: $bestAvgPower, ')
          ..write('hadNulls: $hadNulls, ')
          ..write('wasEnforced: $wasEnforced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      effortId, durationSeconds, bestAvgPower, hadNulls, wasEnforced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapCurveRow &&
          other.effortId == this.effortId &&
          other.durationSeconds == this.durationSeconds &&
          other.bestAvgPower == this.bestAvgPower &&
          other.hadNulls == this.hadNulls &&
          other.wasEnforced == this.wasEnforced);
}

class MapCurvesCompanion extends UpdateCompanion<MapCurveRow> {
  final Value<String> effortId;
  final Value<int> durationSeconds;
  final Value<double> bestAvgPower;
  final Value<bool> hadNulls;
  final Value<bool> wasEnforced;
  final Value<int> rowid;
  const MapCurvesCompanion({
    this.effortId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.bestAvgPower = const Value.absent(),
    this.hadNulls = const Value.absent(),
    this.wasEnforced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MapCurvesCompanion.insert({
    required String effortId,
    required int durationSeconds,
    required double bestAvgPower,
    this.hadNulls = const Value.absent(),
    this.wasEnforced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : effortId = Value(effortId),
        durationSeconds = Value(durationSeconds),
        bestAvgPower = Value(bestAvgPower);
  static Insertable<MapCurveRow> custom({
    Expression<String>? effortId,
    Expression<int>? durationSeconds,
    Expression<double>? bestAvgPower,
    Expression<bool>? hadNulls,
    Expression<bool>? wasEnforced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (effortId != null) 'effort_id': effortId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (bestAvgPower != null) 'best_avg_power': bestAvgPower,
      if (hadNulls != null) 'had_nulls': hadNulls,
      if (wasEnforced != null) 'was_enforced': wasEnforced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MapCurvesCompanion copyWith(
      {Value<String>? effortId,
      Value<int>? durationSeconds,
      Value<double>? bestAvgPower,
      Value<bool>? hadNulls,
      Value<bool>? wasEnforced,
      Value<int>? rowid}) {
    return MapCurvesCompanion(
      effortId: effortId ?? this.effortId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      bestAvgPower: bestAvgPower ?? this.bestAvgPower,
      hadNulls: hadNulls ?? this.hadNulls,
      wasEnforced: wasEnforced ?? this.wasEnforced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (effortId.present) {
      map['effort_id'] = Variable<String>(effortId.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (bestAvgPower.present) {
      map['best_avg_power'] = Variable<double>(bestAvgPower.value);
    }
    if (hadNulls.present) {
      map['had_nulls'] = Variable<bool>(hadNulls.value);
    }
    if (wasEnforced.present) {
      map['was_enforced'] = Variable<bool>(wasEnforced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MapCurvesCompanion(')
          ..write('effortId: $effortId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('bestAvgPower: $bestAvgPower, ')
          ..write('hadNulls: $hadNulls, ')
          ..write('wasEnforced: $wasEnforced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingsTable extends Readings
    with TableInfo<$ReadingsTable, ReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
      'ride_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES rides (id)'));
  static const VerificationMeta _offsetSecondsMeta =
      const VerificationMeta('offsetSeconds');
  @override
  late final GeneratedColumn<int> offsetSeconds = GeneratedColumn<int>(
      'offset_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<double> power = GeneratedColumn<double>(
      'power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _leftRightBalanceMeta =
      const VerificationMeta('leftRightBalance');
  @override
  late final GeneratedColumn<double> leftRightBalance = GeneratedColumn<double>(
      'left_right_balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _leftPowerMeta =
      const VerificationMeta('leftPower');
  @override
  late final GeneratedColumn<double> leftPower = GeneratedColumn<double>(
      'left_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rightPowerMeta =
      const VerificationMeta('rightPower');
  @override
  late final GeneratedColumn<double> rightPower = GeneratedColumn<double>(
      'right_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _heartRateMeta =
      const VerificationMeta('heartRate');
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
      'heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cadenceMeta =
      const VerificationMeta('cadence');
  @override
  late final GeneratedColumn<double> cadence = GeneratedColumn<double>(
      'cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _crankTorqueMeta =
      const VerificationMeta('crankTorque');
  @override
  late final GeneratedColumn<double> crankTorque = GeneratedColumn<double>(
      'crank_torque', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accumulatedTorqueMeta =
      const VerificationMeta('accumulatedTorque');
  @override
  late final GeneratedColumn<int> accumulatedTorque = GeneratedColumn<int>(
      'accumulated_torque', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _crankRevolutionsMeta =
      const VerificationMeta('crankRevolutions');
  @override
  late final GeneratedColumn<int> crankRevolutions = GeneratedColumn<int>(
      'crank_revolutions', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastCrankEventTimeMeta =
      const VerificationMeta('lastCrankEventTime');
  @override
  late final GeneratedColumn<int> lastCrankEventTime = GeneratedColumn<int>(
      'last_crank_event_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxForceMagnitudeMeta =
      const VerificationMeta('maxForceMagnitude');
  @override
  late final GeneratedColumn<int> maxForceMagnitude = GeneratedColumn<int>(
      'max_force_magnitude', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minForceMagnitudeMeta =
      const VerificationMeta('minForceMagnitude');
  @override
  late final GeneratedColumn<int> minForceMagnitude = GeneratedColumn<int>(
      'min_force_magnitude', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxTorqueMagnitudeMeta =
      const VerificationMeta('maxTorqueMagnitude');
  @override
  late final GeneratedColumn<int> maxTorqueMagnitude = GeneratedColumn<int>(
      'max_torque_magnitude', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minTorqueMagnitudeMeta =
      const VerificationMeta('minTorqueMagnitude');
  @override
  late final GeneratedColumn<int> minTorqueMagnitude = GeneratedColumn<int>(
      'min_torque_magnitude', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _topDeadSpotAngleMeta =
      const VerificationMeta('topDeadSpotAngle');
  @override
  late final GeneratedColumn<int> topDeadSpotAngle = GeneratedColumn<int>(
      'top_dead_spot_angle', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bottomDeadSpotAngleMeta =
      const VerificationMeta('bottomDeadSpotAngle');
  @override
  late final GeneratedColumn<int> bottomDeadSpotAngle = GeneratedColumn<int>(
      'bottom_dead_spot_angle', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _accumulatedEnergyMeta =
      const VerificationMeta('accumulatedEnergy');
  @override
  late final GeneratedColumn<int> accumulatedEnergy = GeneratedColumn<int>(
      'accumulated_energy', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rrIntervalsMeta =
      const VerificationMeta('rrIntervals');
  @override
  late final GeneratedColumn<String> rrIntervals = GeneratedColumn<String>(
      'rr_intervals', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rideId,
        offsetSeconds,
        power,
        leftRightBalance,
        leftPower,
        rightPower,
        heartRate,
        cadence,
        crankTorque,
        accumulatedTorque,
        crankRevolutions,
        lastCrankEventTime,
        maxForceMagnitude,
        minForceMagnitude,
        maxTorqueMagnitude,
        minTorqueMagnitude,
        topDeadSpotAngle,
        bottomDeadSpotAngle,
        accumulatedEnergy,
        rrIntervals
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(Insertable<ReadingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ride_id')) {
      context.handle(_rideIdMeta,
          rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta));
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('offset_seconds')) {
      context.handle(
          _offsetSecondsMeta,
          offsetSeconds.isAcceptableOrUnknown(
              data['offset_seconds']!, _offsetSecondsMeta));
    } else if (isInserting) {
      context.missing(_offsetSecondsMeta);
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    }
    if (data.containsKey('left_right_balance')) {
      context.handle(
          _leftRightBalanceMeta,
          leftRightBalance.isAcceptableOrUnknown(
              data['left_right_balance']!, _leftRightBalanceMeta));
    }
    if (data.containsKey('left_power')) {
      context.handle(_leftPowerMeta,
          leftPower.isAcceptableOrUnknown(data['left_power']!, _leftPowerMeta));
    }
    if (data.containsKey('right_power')) {
      context.handle(
          _rightPowerMeta,
          rightPower.isAcceptableOrUnknown(
              data['right_power']!, _rightPowerMeta));
    }
    if (data.containsKey('heart_rate')) {
      context.handle(_heartRateMeta,
          heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta));
    }
    if (data.containsKey('cadence')) {
      context.handle(_cadenceMeta,
          cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta));
    }
    if (data.containsKey('crank_torque')) {
      context.handle(
          _crankTorqueMeta,
          crankTorque.isAcceptableOrUnknown(
              data['crank_torque']!, _crankTorqueMeta));
    }
    if (data.containsKey('accumulated_torque')) {
      context.handle(
          _accumulatedTorqueMeta,
          accumulatedTorque.isAcceptableOrUnknown(
              data['accumulated_torque']!, _accumulatedTorqueMeta));
    }
    if (data.containsKey('crank_revolutions')) {
      context.handle(
          _crankRevolutionsMeta,
          crankRevolutions.isAcceptableOrUnknown(
              data['crank_revolutions']!, _crankRevolutionsMeta));
    }
    if (data.containsKey('last_crank_event_time')) {
      context.handle(
          _lastCrankEventTimeMeta,
          lastCrankEventTime.isAcceptableOrUnknown(
              data['last_crank_event_time']!, _lastCrankEventTimeMeta));
    }
    if (data.containsKey('max_force_magnitude')) {
      context.handle(
          _maxForceMagnitudeMeta,
          maxForceMagnitude.isAcceptableOrUnknown(
              data['max_force_magnitude']!, _maxForceMagnitudeMeta));
    }
    if (data.containsKey('min_force_magnitude')) {
      context.handle(
          _minForceMagnitudeMeta,
          minForceMagnitude.isAcceptableOrUnknown(
              data['min_force_magnitude']!, _minForceMagnitudeMeta));
    }
    if (data.containsKey('max_torque_magnitude')) {
      context.handle(
          _maxTorqueMagnitudeMeta,
          maxTorqueMagnitude.isAcceptableOrUnknown(
              data['max_torque_magnitude']!, _maxTorqueMagnitudeMeta));
    }
    if (data.containsKey('min_torque_magnitude')) {
      context.handle(
          _minTorqueMagnitudeMeta,
          minTorqueMagnitude.isAcceptableOrUnknown(
              data['min_torque_magnitude']!, _minTorqueMagnitudeMeta));
    }
    if (data.containsKey('top_dead_spot_angle')) {
      context.handle(
          _topDeadSpotAngleMeta,
          topDeadSpotAngle.isAcceptableOrUnknown(
              data['top_dead_spot_angle']!, _topDeadSpotAngleMeta));
    }
    if (data.containsKey('bottom_dead_spot_angle')) {
      context.handle(
          _bottomDeadSpotAngleMeta,
          bottomDeadSpotAngle.isAcceptableOrUnknown(
              data['bottom_dead_spot_angle']!, _bottomDeadSpotAngleMeta));
    }
    if (data.containsKey('accumulated_energy')) {
      context.handle(
          _accumulatedEnergyMeta,
          accumulatedEnergy.isAcceptableOrUnknown(
              data['accumulated_energy']!, _accumulatedEnergyMeta));
    }
    if (data.containsKey('rr_intervals')) {
      context.handle(
          _rrIntervalsMeta,
          rrIntervals.isAcceptableOrUnknown(
              data['rr_intervals']!, _rrIntervalsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rideId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ride_id'])!,
      offsetSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}offset_seconds'])!,
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}power']),
      leftRightBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}left_right_balance']),
      leftPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}left_power']),
      rightPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}right_power']),
      heartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heart_rate']),
      cadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cadence']),
      crankTorque: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}crank_torque']),
      accumulatedTorque: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accumulated_torque']),
      crankRevolutions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}crank_revolutions']),
      lastCrankEventTime: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_crank_event_time']),
      maxForceMagnitude: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_force_magnitude']),
      minForceMagnitude: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}min_force_magnitude']),
      maxTorqueMagnitude: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_torque_magnitude']),
      minTorqueMagnitude: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}min_torque_magnitude']),
      topDeadSpotAngle: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}top_dead_spot_angle']),
      bottomDeadSpotAngle: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}bottom_dead_spot_angle']),
      accumulatedEnergy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accumulated_energy']),
      rrIntervals: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rr_intervals']),
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  final int id;
  final String rideId;
  final int offsetSeconds;
  final double? power;
  final double? leftRightBalance;
  final double? leftPower;
  final double? rightPower;
  final int? heartRate;
  final double? cadence;
  final double? crankTorque;
  final int? accumulatedTorque;
  final int? crankRevolutions;
  final int? lastCrankEventTime;
  final int? maxForceMagnitude;
  final int? minForceMagnitude;
  final int? maxTorqueMagnitude;
  final int? minTorqueMagnitude;
  final int? topDeadSpotAngle;
  final int? bottomDeadSpotAngle;
  final int? accumulatedEnergy;
  final String? rrIntervals;
  const ReadingRow(
      {required this.id,
      required this.rideId,
      required this.offsetSeconds,
      this.power,
      this.leftRightBalance,
      this.leftPower,
      this.rightPower,
      this.heartRate,
      this.cadence,
      this.crankTorque,
      this.accumulatedTorque,
      this.crankRevolutions,
      this.lastCrankEventTime,
      this.maxForceMagnitude,
      this.minForceMagnitude,
      this.maxTorqueMagnitude,
      this.minTorqueMagnitude,
      this.topDeadSpotAngle,
      this.bottomDeadSpotAngle,
      this.accumulatedEnergy,
      this.rrIntervals});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ride_id'] = Variable<String>(rideId);
    map['offset_seconds'] = Variable<int>(offsetSeconds);
    if (!nullToAbsent || power != null) {
      map['power'] = Variable<double>(power);
    }
    if (!nullToAbsent || leftRightBalance != null) {
      map['left_right_balance'] = Variable<double>(leftRightBalance);
    }
    if (!nullToAbsent || leftPower != null) {
      map['left_power'] = Variable<double>(leftPower);
    }
    if (!nullToAbsent || rightPower != null) {
      map['right_power'] = Variable<double>(rightPower);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || cadence != null) {
      map['cadence'] = Variable<double>(cadence);
    }
    if (!nullToAbsent || crankTorque != null) {
      map['crank_torque'] = Variable<double>(crankTorque);
    }
    if (!nullToAbsent || accumulatedTorque != null) {
      map['accumulated_torque'] = Variable<int>(accumulatedTorque);
    }
    if (!nullToAbsent || crankRevolutions != null) {
      map['crank_revolutions'] = Variable<int>(crankRevolutions);
    }
    if (!nullToAbsent || lastCrankEventTime != null) {
      map['last_crank_event_time'] = Variable<int>(lastCrankEventTime);
    }
    if (!nullToAbsent || maxForceMagnitude != null) {
      map['max_force_magnitude'] = Variable<int>(maxForceMagnitude);
    }
    if (!nullToAbsent || minForceMagnitude != null) {
      map['min_force_magnitude'] = Variable<int>(minForceMagnitude);
    }
    if (!nullToAbsent || maxTorqueMagnitude != null) {
      map['max_torque_magnitude'] = Variable<int>(maxTorqueMagnitude);
    }
    if (!nullToAbsent || minTorqueMagnitude != null) {
      map['min_torque_magnitude'] = Variable<int>(minTorqueMagnitude);
    }
    if (!nullToAbsent || topDeadSpotAngle != null) {
      map['top_dead_spot_angle'] = Variable<int>(topDeadSpotAngle);
    }
    if (!nullToAbsent || bottomDeadSpotAngle != null) {
      map['bottom_dead_spot_angle'] = Variable<int>(bottomDeadSpotAngle);
    }
    if (!nullToAbsent || accumulatedEnergy != null) {
      map['accumulated_energy'] = Variable<int>(accumulatedEnergy);
    }
    if (!nullToAbsent || rrIntervals != null) {
      map['rr_intervals'] = Variable<String>(rrIntervals);
    }
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      rideId: Value(rideId),
      offsetSeconds: Value(offsetSeconds),
      power:
          power == null && nullToAbsent ? const Value.absent() : Value(power),
      leftRightBalance: leftRightBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(leftRightBalance),
      leftPower: leftPower == null && nullToAbsent
          ? const Value.absent()
          : Value(leftPower),
      rightPower: rightPower == null && nullToAbsent
          ? const Value.absent()
          : Value(rightPower),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      cadence: cadence == null && nullToAbsent
          ? const Value.absent()
          : Value(cadence),
      crankTorque: crankTorque == null && nullToAbsent
          ? const Value.absent()
          : Value(crankTorque),
      accumulatedTorque: accumulatedTorque == null && nullToAbsent
          ? const Value.absent()
          : Value(accumulatedTorque),
      crankRevolutions: crankRevolutions == null && nullToAbsent
          ? const Value.absent()
          : Value(crankRevolutions),
      lastCrankEventTime: lastCrankEventTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCrankEventTime),
      maxForceMagnitude: maxForceMagnitude == null && nullToAbsent
          ? const Value.absent()
          : Value(maxForceMagnitude),
      minForceMagnitude: minForceMagnitude == null && nullToAbsent
          ? const Value.absent()
          : Value(minForceMagnitude),
      maxTorqueMagnitude: maxTorqueMagnitude == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTorqueMagnitude),
      minTorqueMagnitude: minTorqueMagnitude == null && nullToAbsent
          ? const Value.absent()
          : Value(minTorqueMagnitude),
      topDeadSpotAngle: topDeadSpotAngle == null && nullToAbsent
          ? const Value.absent()
          : Value(topDeadSpotAngle),
      bottomDeadSpotAngle: bottomDeadSpotAngle == null && nullToAbsent
          ? const Value.absent()
          : Value(bottomDeadSpotAngle),
      accumulatedEnergy: accumulatedEnergy == null && nullToAbsent
          ? const Value.absent()
          : Value(accumulatedEnergy),
      rrIntervals: rrIntervals == null && nullToAbsent
          ? const Value.absent()
          : Value(rrIntervals),
    );
  }

  factory ReadingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<int>(json['id']),
      rideId: serializer.fromJson<String>(json['rideId']),
      offsetSeconds: serializer.fromJson<int>(json['offsetSeconds']),
      power: serializer.fromJson<double?>(json['power']),
      leftRightBalance: serializer.fromJson<double?>(json['leftRightBalance']),
      leftPower: serializer.fromJson<double?>(json['leftPower']),
      rightPower: serializer.fromJson<double?>(json['rightPower']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      cadence: serializer.fromJson<double?>(json['cadence']),
      crankTorque: serializer.fromJson<double?>(json['crankTorque']),
      accumulatedTorque: serializer.fromJson<int?>(json['accumulatedTorque']),
      crankRevolutions: serializer.fromJson<int?>(json['crankRevolutions']),
      lastCrankEventTime: serializer.fromJson<int?>(json['lastCrankEventTime']),
      maxForceMagnitude: serializer.fromJson<int?>(json['maxForceMagnitude']),
      minForceMagnitude: serializer.fromJson<int?>(json['minForceMagnitude']),
      maxTorqueMagnitude: serializer.fromJson<int?>(json['maxTorqueMagnitude']),
      minTorqueMagnitude: serializer.fromJson<int?>(json['minTorqueMagnitude']),
      topDeadSpotAngle: serializer.fromJson<int?>(json['topDeadSpotAngle']),
      bottomDeadSpotAngle:
          serializer.fromJson<int?>(json['bottomDeadSpotAngle']),
      accumulatedEnergy: serializer.fromJson<int?>(json['accumulatedEnergy']),
      rrIntervals: serializer.fromJson<String?>(json['rrIntervals']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rideId': serializer.toJson<String>(rideId),
      'offsetSeconds': serializer.toJson<int>(offsetSeconds),
      'power': serializer.toJson<double?>(power),
      'leftRightBalance': serializer.toJson<double?>(leftRightBalance),
      'leftPower': serializer.toJson<double?>(leftPower),
      'rightPower': serializer.toJson<double?>(rightPower),
      'heartRate': serializer.toJson<int?>(heartRate),
      'cadence': serializer.toJson<double?>(cadence),
      'crankTorque': serializer.toJson<double?>(crankTorque),
      'accumulatedTorque': serializer.toJson<int?>(accumulatedTorque),
      'crankRevolutions': serializer.toJson<int?>(crankRevolutions),
      'lastCrankEventTime': serializer.toJson<int?>(lastCrankEventTime),
      'maxForceMagnitude': serializer.toJson<int?>(maxForceMagnitude),
      'minForceMagnitude': serializer.toJson<int?>(minForceMagnitude),
      'maxTorqueMagnitude': serializer.toJson<int?>(maxTorqueMagnitude),
      'minTorqueMagnitude': serializer.toJson<int?>(minTorqueMagnitude),
      'topDeadSpotAngle': serializer.toJson<int?>(topDeadSpotAngle),
      'bottomDeadSpotAngle': serializer.toJson<int?>(bottomDeadSpotAngle),
      'accumulatedEnergy': serializer.toJson<int?>(accumulatedEnergy),
      'rrIntervals': serializer.toJson<String?>(rrIntervals),
    };
  }

  ReadingRow copyWith(
          {int? id,
          String? rideId,
          int? offsetSeconds,
          Value<double?> power = const Value.absent(),
          Value<double?> leftRightBalance = const Value.absent(),
          Value<double?> leftPower = const Value.absent(),
          Value<double?> rightPower = const Value.absent(),
          Value<int?> heartRate = const Value.absent(),
          Value<double?> cadence = const Value.absent(),
          Value<double?> crankTorque = const Value.absent(),
          Value<int?> accumulatedTorque = const Value.absent(),
          Value<int?> crankRevolutions = const Value.absent(),
          Value<int?> lastCrankEventTime = const Value.absent(),
          Value<int?> maxForceMagnitude = const Value.absent(),
          Value<int?> minForceMagnitude = const Value.absent(),
          Value<int?> maxTorqueMagnitude = const Value.absent(),
          Value<int?> minTorqueMagnitude = const Value.absent(),
          Value<int?> topDeadSpotAngle = const Value.absent(),
          Value<int?> bottomDeadSpotAngle = const Value.absent(),
          Value<int?> accumulatedEnergy = const Value.absent(),
          Value<String?> rrIntervals = const Value.absent()}) =>
      ReadingRow(
        id: id ?? this.id,
        rideId: rideId ?? this.rideId,
        offsetSeconds: offsetSeconds ?? this.offsetSeconds,
        power: power.present ? power.value : this.power,
        leftRightBalance: leftRightBalance.present
            ? leftRightBalance.value
            : this.leftRightBalance,
        leftPower: leftPower.present ? leftPower.value : this.leftPower,
        rightPower: rightPower.present ? rightPower.value : this.rightPower,
        heartRate: heartRate.present ? heartRate.value : this.heartRate,
        cadence: cadence.present ? cadence.value : this.cadence,
        crankTorque: crankTorque.present ? crankTorque.value : this.crankTorque,
        accumulatedTorque: accumulatedTorque.present
            ? accumulatedTorque.value
            : this.accumulatedTorque,
        crankRevolutions: crankRevolutions.present
            ? crankRevolutions.value
            : this.crankRevolutions,
        lastCrankEventTime: lastCrankEventTime.present
            ? lastCrankEventTime.value
            : this.lastCrankEventTime,
        maxForceMagnitude: maxForceMagnitude.present
            ? maxForceMagnitude.value
            : this.maxForceMagnitude,
        minForceMagnitude: minForceMagnitude.present
            ? minForceMagnitude.value
            : this.minForceMagnitude,
        maxTorqueMagnitude: maxTorqueMagnitude.present
            ? maxTorqueMagnitude.value
            : this.maxTorqueMagnitude,
        minTorqueMagnitude: minTorqueMagnitude.present
            ? minTorqueMagnitude.value
            : this.minTorqueMagnitude,
        topDeadSpotAngle: topDeadSpotAngle.present
            ? topDeadSpotAngle.value
            : this.topDeadSpotAngle,
        bottomDeadSpotAngle: bottomDeadSpotAngle.present
            ? bottomDeadSpotAngle.value
            : this.bottomDeadSpotAngle,
        accumulatedEnergy: accumulatedEnergy.present
            ? accumulatedEnergy.value
            : this.accumulatedEnergy,
        rrIntervals: rrIntervals.present ? rrIntervals.value : this.rrIntervals,
      );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      offsetSeconds: data.offsetSeconds.present
          ? data.offsetSeconds.value
          : this.offsetSeconds,
      power: data.power.present ? data.power.value : this.power,
      leftRightBalance: data.leftRightBalance.present
          ? data.leftRightBalance.value
          : this.leftRightBalance,
      leftPower: data.leftPower.present ? data.leftPower.value : this.leftPower,
      rightPower:
          data.rightPower.present ? data.rightPower.value : this.rightPower,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      crankTorque:
          data.crankTorque.present ? data.crankTorque.value : this.crankTorque,
      accumulatedTorque: data.accumulatedTorque.present
          ? data.accumulatedTorque.value
          : this.accumulatedTorque,
      crankRevolutions: data.crankRevolutions.present
          ? data.crankRevolutions.value
          : this.crankRevolutions,
      lastCrankEventTime: data.lastCrankEventTime.present
          ? data.lastCrankEventTime.value
          : this.lastCrankEventTime,
      maxForceMagnitude: data.maxForceMagnitude.present
          ? data.maxForceMagnitude.value
          : this.maxForceMagnitude,
      minForceMagnitude: data.minForceMagnitude.present
          ? data.minForceMagnitude.value
          : this.minForceMagnitude,
      maxTorqueMagnitude: data.maxTorqueMagnitude.present
          ? data.maxTorqueMagnitude.value
          : this.maxTorqueMagnitude,
      minTorqueMagnitude: data.minTorqueMagnitude.present
          ? data.minTorqueMagnitude.value
          : this.minTorqueMagnitude,
      topDeadSpotAngle: data.topDeadSpotAngle.present
          ? data.topDeadSpotAngle.value
          : this.topDeadSpotAngle,
      bottomDeadSpotAngle: data.bottomDeadSpotAngle.present
          ? data.bottomDeadSpotAngle.value
          : this.bottomDeadSpotAngle,
      accumulatedEnergy: data.accumulatedEnergy.present
          ? data.accumulatedEnergy.value
          : this.accumulatedEnergy,
      rrIntervals:
          data.rrIntervals.present ? data.rrIntervals.value : this.rrIntervals,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('offsetSeconds: $offsetSeconds, ')
          ..write('power: $power, ')
          ..write('leftRightBalance: $leftRightBalance, ')
          ..write('leftPower: $leftPower, ')
          ..write('rightPower: $rightPower, ')
          ..write('heartRate: $heartRate, ')
          ..write('cadence: $cadence, ')
          ..write('crankTorque: $crankTorque, ')
          ..write('accumulatedTorque: $accumulatedTorque, ')
          ..write('crankRevolutions: $crankRevolutions, ')
          ..write('lastCrankEventTime: $lastCrankEventTime, ')
          ..write('maxForceMagnitude: $maxForceMagnitude, ')
          ..write('minForceMagnitude: $minForceMagnitude, ')
          ..write('maxTorqueMagnitude: $maxTorqueMagnitude, ')
          ..write('minTorqueMagnitude: $minTorqueMagnitude, ')
          ..write('topDeadSpotAngle: $topDeadSpotAngle, ')
          ..write('bottomDeadSpotAngle: $bottomDeadSpotAngle, ')
          ..write('accumulatedEnergy: $accumulatedEnergy, ')
          ..write('rrIntervals: $rrIntervals')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        rideId,
        offsetSeconds,
        power,
        leftRightBalance,
        leftPower,
        rightPower,
        heartRate,
        cadence,
        crankTorque,
        accumulatedTorque,
        crankRevolutions,
        lastCrankEventTime,
        maxForceMagnitude,
        minForceMagnitude,
        maxTorqueMagnitude,
        minTorqueMagnitude,
        topDeadSpotAngle,
        bottomDeadSpotAngle,
        accumulatedEnergy,
        rrIntervals
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.rideId == this.rideId &&
          other.offsetSeconds == this.offsetSeconds &&
          other.power == this.power &&
          other.leftRightBalance == this.leftRightBalance &&
          other.leftPower == this.leftPower &&
          other.rightPower == this.rightPower &&
          other.heartRate == this.heartRate &&
          other.cadence == this.cadence &&
          other.crankTorque == this.crankTorque &&
          other.accumulatedTorque == this.accumulatedTorque &&
          other.crankRevolutions == this.crankRevolutions &&
          other.lastCrankEventTime == this.lastCrankEventTime &&
          other.maxForceMagnitude == this.maxForceMagnitude &&
          other.minForceMagnitude == this.minForceMagnitude &&
          other.maxTorqueMagnitude == this.maxTorqueMagnitude &&
          other.minTorqueMagnitude == this.minTorqueMagnitude &&
          other.topDeadSpotAngle == this.topDeadSpotAngle &&
          other.bottomDeadSpotAngle == this.bottomDeadSpotAngle &&
          other.accumulatedEnergy == this.accumulatedEnergy &&
          other.rrIntervals == this.rrIntervals);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<int> id;
  final Value<String> rideId;
  final Value<int> offsetSeconds;
  final Value<double?> power;
  final Value<double?> leftRightBalance;
  final Value<double?> leftPower;
  final Value<double?> rightPower;
  final Value<int?> heartRate;
  final Value<double?> cadence;
  final Value<double?> crankTorque;
  final Value<int?> accumulatedTorque;
  final Value<int?> crankRevolutions;
  final Value<int?> lastCrankEventTime;
  final Value<int?> maxForceMagnitude;
  final Value<int?> minForceMagnitude;
  final Value<int?> maxTorqueMagnitude;
  final Value<int?> minTorqueMagnitude;
  final Value<int?> topDeadSpotAngle;
  final Value<int?> bottomDeadSpotAngle;
  final Value<int?> accumulatedEnergy;
  final Value<String?> rrIntervals;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.rideId = const Value.absent(),
    this.offsetSeconds = const Value.absent(),
    this.power = const Value.absent(),
    this.leftRightBalance = const Value.absent(),
    this.leftPower = const Value.absent(),
    this.rightPower = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.cadence = const Value.absent(),
    this.crankTorque = const Value.absent(),
    this.accumulatedTorque = const Value.absent(),
    this.crankRevolutions = const Value.absent(),
    this.lastCrankEventTime = const Value.absent(),
    this.maxForceMagnitude = const Value.absent(),
    this.minForceMagnitude = const Value.absent(),
    this.maxTorqueMagnitude = const Value.absent(),
    this.minTorqueMagnitude = const Value.absent(),
    this.topDeadSpotAngle = const Value.absent(),
    this.bottomDeadSpotAngle = const Value.absent(),
    this.accumulatedEnergy = const Value.absent(),
    this.rrIntervals = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    required String rideId,
    required int offsetSeconds,
    this.power = const Value.absent(),
    this.leftRightBalance = const Value.absent(),
    this.leftPower = const Value.absent(),
    this.rightPower = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.cadence = const Value.absent(),
    this.crankTorque = const Value.absent(),
    this.accumulatedTorque = const Value.absent(),
    this.crankRevolutions = const Value.absent(),
    this.lastCrankEventTime = const Value.absent(),
    this.maxForceMagnitude = const Value.absent(),
    this.minForceMagnitude = const Value.absent(),
    this.maxTorqueMagnitude = const Value.absent(),
    this.minTorqueMagnitude = const Value.absent(),
    this.topDeadSpotAngle = const Value.absent(),
    this.bottomDeadSpotAngle = const Value.absent(),
    this.accumulatedEnergy = const Value.absent(),
    this.rrIntervals = const Value.absent(),
  })  : rideId = Value(rideId),
        offsetSeconds = Value(offsetSeconds);
  static Insertable<ReadingRow> custom({
    Expression<int>? id,
    Expression<String>? rideId,
    Expression<int>? offsetSeconds,
    Expression<double>? power,
    Expression<double>? leftRightBalance,
    Expression<double>? leftPower,
    Expression<double>? rightPower,
    Expression<int>? heartRate,
    Expression<double>? cadence,
    Expression<double>? crankTorque,
    Expression<int>? accumulatedTorque,
    Expression<int>? crankRevolutions,
    Expression<int>? lastCrankEventTime,
    Expression<int>? maxForceMagnitude,
    Expression<int>? minForceMagnitude,
    Expression<int>? maxTorqueMagnitude,
    Expression<int>? minTorqueMagnitude,
    Expression<int>? topDeadSpotAngle,
    Expression<int>? bottomDeadSpotAngle,
    Expression<int>? accumulatedEnergy,
    Expression<String>? rrIntervals,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rideId != null) 'ride_id': rideId,
      if (offsetSeconds != null) 'offset_seconds': offsetSeconds,
      if (power != null) 'power': power,
      if (leftRightBalance != null) 'left_right_balance': leftRightBalance,
      if (leftPower != null) 'left_power': leftPower,
      if (rightPower != null) 'right_power': rightPower,
      if (heartRate != null) 'heart_rate': heartRate,
      if (cadence != null) 'cadence': cadence,
      if (crankTorque != null) 'crank_torque': crankTorque,
      if (accumulatedTorque != null) 'accumulated_torque': accumulatedTorque,
      if (crankRevolutions != null) 'crank_revolutions': crankRevolutions,
      if (lastCrankEventTime != null)
        'last_crank_event_time': lastCrankEventTime,
      if (maxForceMagnitude != null) 'max_force_magnitude': maxForceMagnitude,
      if (minForceMagnitude != null) 'min_force_magnitude': minForceMagnitude,
      if (maxTorqueMagnitude != null)
        'max_torque_magnitude': maxTorqueMagnitude,
      if (minTorqueMagnitude != null)
        'min_torque_magnitude': minTorqueMagnitude,
      if (topDeadSpotAngle != null) 'top_dead_spot_angle': topDeadSpotAngle,
      if (bottomDeadSpotAngle != null)
        'bottom_dead_spot_angle': bottomDeadSpotAngle,
      if (accumulatedEnergy != null) 'accumulated_energy': accumulatedEnergy,
      if (rrIntervals != null) 'rr_intervals': rrIntervals,
    });
  }

  ReadingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? rideId,
      Value<int>? offsetSeconds,
      Value<double?>? power,
      Value<double?>? leftRightBalance,
      Value<double?>? leftPower,
      Value<double?>? rightPower,
      Value<int?>? heartRate,
      Value<double?>? cadence,
      Value<double?>? crankTorque,
      Value<int?>? accumulatedTorque,
      Value<int?>? crankRevolutions,
      Value<int?>? lastCrankEventTime,
      Value<int?>? maxForceMagnitude,
      Value<int?>? minForceMagnitude,
      Value<int?>? maxTorqueMagnitude,
      Value<int?>? minTorqueMagnitude,
      Value<int?>? topDeadSpotAngle,
      Value<int?>? bottomDeadSpotAngle,
      Value<int?>? accumulatedEnergy,
      Value<String?>? rrIntervals}) {
    return ReadingsCompanion(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      offsetSeconds: offsetSeconds ?? this.offsetSeconds,
      power: power ?? this.power,
      leftRightBalance: leftRightBalance ?? this.leftRightBalance,
      leftPower: leftPower ?? this.leftPower,
      rightPower: rightPower ?? this.rightPower,
      heartRate: heartRate ?? this.heartRate,
      cadence: cadence ?? this.cadence,
      crankTorque: crankTorque ?? this.crankTorque,
      accumulatedTorque: accumulatedTorque ?? this.accumulatedTorque,
      crankRevolutions: crankRevolutions ?? this.crankRevolutions,
      lastCrankEventTime: lastCrankEventTime ?? this.lastCrankEventTime,
      maxForceMagnitude: maxForceMagnitude ?? this.maxForceMagnitude,
      minForceMagnitude: minForceMagnitude ?? this.minForceMagnitude,
      maxTorqueMagnitude: maxTorqueMagnitude ?? this.maxTorqueMagnitude,
      minTorqueMagnitude: minTorqueMagnitude ?? this.minTorqueMagnitude,
      topDeadSpotAngle: topDeadSpotAngle ?? this.topDeadSpotAngle,
      bottomDeadSpotAngle: bottomDeadSpotAngle ?? this.bottomDeadSpotAngle,
      accumulatedEnergy: accumulatedEnergy ?? this.accumulatedEnergy,
      rrIntervals: rrIntervals ?? this.rrIntervals,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (offsetSeconds.present) {
      map['offset_seconds'] = Variable<int>(offsetSeconds.value);
    }
    if (power.present) {
      map['power'] = Variable<double>(power.value);
    }
    if (leftRightBalance.present) {
      map['left_right_balance'] = Variable<double>(leftRightBalance.value);
    }
    if (leftPower.present) {
      map['left_power'] = Variable<double>(leftPower.value);
    }
    if (rightPower.present) {
      map['right_power'] = Variable<double>(rightPower.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<double>(cadence.value);
    }
    if (crankTorque.present) {
      map['crank_torque'] = Variable<double>(crankTorque.value);
    }
    if (accumulatedTorque.present) {
      map['accumulated_torque'] = Variable<int>(accumulatedTorque.value);
    }
    if (crankRevolutions.present) {
      map['crank_revolutions'] = Variable<int>(crankRevolutions.value);
    }
    if (lastCrankEventTime.present) {
      map['last_crank_event_time'] = Variable<int>(lastCrankEventTime.value);
    }
    if (maxForceMagnitude.present) {
      map['max_force_magnitude'] = Variable<int>(maxForceMagnitude.value);
    }
    if (minForceMagnitude.present) {
      map['min_force_magnitude'] = Variable<int>(minForceMagnitude.value);
    }
    if (maxTorqueMagnitude.present) {
      map['max_torque_magnitude'] = Variable<int>(maxTorqueMagnitude.value);
    }
    if (minTorqueMagnitude.present) {
      map['min_torque_magnitude'] = Variable<int>(minTorqueMagnitude.value);
    }
    if (topDeadSpotAngle.present) {
      map['top_dead_spot_angle'] = Variable<int>(topDeadSpotAngle.value);
    }
    if (bottomDeadSpotAngle.present) {
      map['bottom_dead_spot_angle'] = Variable<int>(bottomDeadSpotAngle.value);
    }
    if (accumulatedEnergy.present) {
      map['accumulated_energy'] = Variable<int>(accumulatedEnergy.value);
    }
    if (rrIntervals.present) {
      map['rr_intervals'] = Variable<String>(rrIntervals.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('offsetSeconds: $offsetSeconds, ')
          ..write('power: $power, ')
          ..write('leftRightBalance: $leftRightBalance, ')
          ..write('leftPower: $leftPower, ')
          ..write('rightPower: $rightPower, ')
          ..write('heartRate: $heartRate, ')
          ..write('cadence: $cadence, ')
          ..write('crankTorque: $crankTorque, ')
          ..write('accumulatedTorque: $accumulatedTorque, ')
          ..write('crankRevolutions: $crankRevolutions, ')
          ..write('lastCrankEventTime: $lastCrankEventTime, ')
          ..write('maxForceMagnitude: $maxForceMagnitude, ')
          ..write('minForceMagnitude: $minForceMagnitude, ')
          ..write('maxTorqueMagnitude: $maxTorqueMagnitude, ')
          ..write('minTorqueMagnitude: $minTorqueMagnitude, ')
          ..write('topDeadSpotAngle: $topDeadSpotAngle, ')
          ..write('bottomDeadSpotAngle: $bottomDeadSpotAngle, ')
          ..write('accumulatedEnergy: $accumulatedEnergy, ')
          ..write('rrIntervals: $rrIntervals')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) => AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _supportedServicesMeta =
      const VerificationMeta('supportedServices');
  @override
  late final GeneratedColumn<String> supportedServices =
      GeneratedColumn<String>('supported_services', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastConnectedMeta =
      const VerificationMeta('lastConnected');
  @override
  late final GeneratedColumn<DateTime> lastConnected =
      GeneratedColumn<DateTime>('last_connected', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _autoConnectMeta =
      const VerificationMeta('autoConnect');
  @override
  late final GeneratedColumn<bool> autoConnect = GeneratedColumn<bool>(
      'auto_connect', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_connect" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, displayName, supportedServices, lastConnected, autoConnect];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('supported_services')) {
      context.handle(
          _supportedServicesMeta,
          supportedServices.isAcceptableOrUnknown(
              data['supported_services']!, _supportedServicesMeta));
    } else if (isInserting) {
      context.missing(_supportedServicesMeta);
    }
    if (data.containsKey('last_connected')) {
      context.handle(
          _lastConnectedMeta,
          lastConnected.isAcceptableOrUnknown(
              data['last_connected']!, _lastConnectedMeta));
    } else if (isInserting) {
      context.missing(_lastConnectedMeta);
    }
    if (data.containsKey('auto_connect')) {
      context.handle(
          _autoConnectMeta,
          autoConnect.isAcceptableOrUnknown(
              data['auto_connect']!, _autoConnectMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      supportedServices: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}supported_services'])!,
      lastConnected: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_connected'])!,
      autoConnect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_connect'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final String deviceId;
  final String displayName;
  final String supportedServices;
  final DateTime lastConnected;
  final bool autoConnect;
  const DeviceRow(
      {required this.deviceId,
      required this.displayName,
      required this.supportedServices,
      required this.lastConnected,
      required this.autoConnect});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['supported_services'] = Variable<String>(supportedServices);
    map['last_connected'] = Variable<DateTime>(lastConnected);
    map['auto_connect'] = Variable<bool>(autoConnect);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      supportedServices: Value(supportedServices),
      lastConnected: Value(lastConnected),
      autoConnect: Value(autoConnect),
    );
  }

  factory DeviceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      supportedServices: serializer.fromJson<String>(json['supportedServices']),
      lastConnected: serializer.fromJson<DateTime>(json['lastConnected']),
      autoConnect: serializer.fromJson<bool>(json['autoConnect']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'supportedServices': serializer.toJson<String>(supportedServices),
      'lastConnected': serializer.toJson<DateTime>(lastConnected),
      'autoConnect': serializer.toJson<bool>(autoConnect),
    };
  }

  DeviceRow copyWith(
          {String? deviceId,
          String? displayName,
          String? supportedServices,
          DateTime? lastConnected,
          bool? autoConnect}) =>
      DeviceRow(
        deviceId: deviceId ?? this.deviceId,
        displayName: displayName ?? this.displayName,
        supportedServices: supportedServices ?? this.supportedServices,
        lastConnected: lastConnected ?? this.lastConnected,
        autoConnect: autoConnect ?? this.autoConnect,
      );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      supportedServices: data.supportedServices.present
          ? data.supportedServices.value
          : this.supportedServices,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
      autoConnect:
          data.autoConnect.present ? data.autoConnect.value : this.autoConnect,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('supportedServices: $supportedServices, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('autoConnect: $autoConnect')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      deviceId, displayName, supportedServices, lastConnected, autoConnect);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.supportedServices == this.supportedServices &&
          other.lastConnected == this.lastConnected &&
          other.autoConnect == this.autoConnect);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String> supportedServices;
  final Value<DateTime> lastConnected;
  final Value<bool> autoConnect;
  final Value<int> rowid;
  const DevicesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.supportedServices = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.autoConnect = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String deviceId,
    required String displayName,
    required String supportedServices,
    required DateTime lastConnected,
    this.autoConnect = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        displayName = Value(displayName),
        supportedServices = Value(supportedServices),
        lastConnected = Value(lastConnected);
  static Insertable<DeviceRow> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? supportedServices,
    Expression<DateTime>? lastConnected,
    Expression<bool>? autoConnect,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (supportedServices != null) 'supported_services': supportedServices,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (autoConnect != null) 'auto_connect': autoConnect,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? displayName,
      Value<String>? supportedServices,
      Value<DateTime>? lastConnected,
      Value<bool>? autoConnect,
      Value<int>? rowid}) {
    return DevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      supportedServices: supportedServices ?? this.supportedServices,
      lastConnected: lastConnected ?? this.lastConnected,
      autoConnect: autoConnect ?? this.autoConnect,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (supportedServices.present) {
      map['supported_services'] = Variable<String>(supportedServices.value);
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<DateTime>(lastConnected.value);
    }
    if (autoConnect.present) {
      map['auto_connect'] = Variable<bool>(autoConnect.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('supportedServices: $supportedServices, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('autoConnect: $autoConnect, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AutolapConfigsTable autolapConfigs = $AutolapConfigsTable(this);
  late final $RidesTable rides = $RidesTable(this);
  late final $RideTagsTable rideTags = $RideTagsTable(this);
  late final $EffortsTable efforts = $EffortsTable(this);
  late final $MapCurvesTable mapCurves = $MapCurvesTable(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        autolapConfigs,
        rides,
        rideTags,
        efforts,
        mapCurves,
        readings,
        appSettings,
        devices
      ];
}

typedef $$AutolapConfigsTableCreateCompanionBuilder = AutolapConfigsCompanion
    Function({
  required String id,
  required String name,
  required double startDeltaWatts,
  Value<int> startConfirmSeconds,
  Value<int> startDropoutTolerance,
  required double endDeltaWatts,
  Value<int> endConfirmSeconds,
  Value<int> minEffortSeconds,
  Value<int> preEffortBaselineWindow,
  Value<int> inEffortTrailingWindow,
  Value<bool> isDefault,
  Value<int> rowid,
});
typedef $$AutolapConfigsTableUpdateCompanionBuilder = AutolapConfigsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<double> startDeltaWatts,
  Value<int> startConfirmSeconds,
  Value<int> startDropoutTolerance,
  Value<double> endDeltaWatts,
  Value<int> endConfirmSeconds,
  Value<int> minEffortSeconds,
  Value<int> preEffortBaselineWindow,
  Value<int> inEffortTrailingWindow,
  Value<bool> isDefault,
  Value<int> rowid,
});

final class $$AutolapConfigsTableReferences extends BaseReferences<
    _$AppDatabase, $AutolapConfigsTable, AutolapConfigRow> {
  $$AutolapConfigsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RidesTable, List<RideRow>> _ridesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.rides,
          aliasName: $_aliasNameGenerator(
              db.autolapConfigs.id, db.rides.autoLapConfigId));

  $$RidesTableProcessedTableManager get ridesRefs {
    final manager = $$RidesTableTableManager($_db, $_db.rides).filter(
        (f) => f.autoLapConfigId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AutolapConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $AutolapConfigsTable> {
  $$AutolapConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startDeltaWatts => $composableBuilder(
      column: $table.startDeltaWatts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startConfirmSeconds => $composableBuilder(
      column: $table.startConfirmSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDropoutTolerance => $composableBuilder(
      column: $table.startDropoutTolerance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endDeltaWatts => $composableBuilder(
      column: $table.endDeltaWatts, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endConfirmSeconds => $composableBuilder(
      column: $table.endConfirmSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minEffortSeconds => $composableBuilder(
      column: $table.minEffortSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get preEffortBaselineWindow => $composableBuilder(
      column: $table.preEffortBaselineWindow,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inEffortTrailingWindow => $composableBuilder(
      column: $table.inEffortTrailingWindow,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  Expression<bool> ridesRefs(
      Expression<bool> Function($$RidesTableFilterComposer f) f) {
    final $$RidesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.autoLapConfigId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableFilterComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AutolapConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $AutolapConfigsTable> {
  $$AutolapConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startDeltaWatts => $composableBuilder(
      column: $table.startDeltaWatts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startConfirmSeconds => $composableBuilder(
      column: $table.startConfirmSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDropoutTolerance => $composableBuilder(
      column: $table.startDropoutTolerance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endDeltaWatts => $composableBuilder(
      column: $table.endDeltaWatts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endConfirmSeconds => $composableBuilder(
      column: $table.endConfirmSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minEffortSeconds => $composableBuilder(
      column: $table.minEffortSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get preEffortBaselineWindow => $composableBuilder(
      column: $table.preEffortBaselineWindow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inEffortTrailingWindow => $composableBuilder(
      column: $table.inEffortTrailingWindow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));
}

class $$AutolapConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AutolapConfigsTable> {
  $$AutolapConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get startDeltaWatts => $composableBuilder(
      column: $table.startDeltaWatts, builder: (column) => column);

  GeneratedColumn<int> get startConfirmSeconds => $composableBuilder(
      column: $table.startConfirmSeconds, builder: (column) => column);

  GeneratedColumn<int> get startDropoutTolerance => $composableBuilder(
      column: $table.startDropoutTolerance, builder: (column) => column);

  GeneratedColumn<double> get endDeltaWatts => $composableBuilder(
      column: $table.endDeltaWatts, builder: (column) => column);

  GeneratedColumn<int> get endConfirmSeconds => $composableBuilder(
      column: $table.endConfirmSeconds, builder: (column) => column);

  GeneratedColumn<int> get minEffortSeconds => $composableBuilder(
      column: $table.minEffortSeconds, builder: (column) => column);

  GeneratedColumn<int> get preEffortBaselineWindow => $composableBuilder(
      column: $table.preEffortBaselineWindow, builder: (column) => column);

  GeneratedColumn<int> get inEffortTrailingWindow => $composableBuilder(
      column: $table.inEffortTrailingWindow, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> ridesRefs<T extends Object>(
      Expression<T> Function($$RidesTableAnnotationComposer a) f) {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.autoLapConfigId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableAnnotationComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AutolapConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AutolapConfigsTable,
    AutolapConfigRow,
    $$AutolapConfigsTableFilterComposer,
    $$AutolapConfigsTableOrderingComposer,
    $$AutolapConfigsTableAnnotationComposer,
    $$AutolapConfigsTableCreateCompanionBuilder,
    $$AutolapConfigsTableUpdateCompanionBuilder,
    (AutolapConfigRow, $$AutolapConfigsTableReferences),
    AutolapConfigRow,
    PrefetchHooks Function({bool ridesRefs})> {
  $$AutolapConfigsTableTableManager(
      _$AppDatabase db, $AutolapConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AutolapConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AutolapConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AutolapConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> startDeltaWatts = const Value.absent(),
            Value<int> startConfirmSeconds = const Value.absent(),
            Value<int> startDropoutTolerance = const Value.absent(),
            Value<double> endDeltaWatts = const Value.absent(),
            Value<int> endConfirmSeconds = const Value.absent(),
            Value<int> minEffortSeconds = const Value.absent(),
            Value<int> preEffortBaselineWindow = const Value.absent(),
            Value<int> inEffortTrailingWindow = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AutolapConfigsCompanion(
            id: id,
            name: name,
            startDeltaWatts: startDeltaWatts,
            startConfirmSeconds: startConfirmSeconds,
            startDropoutTolerance: startDropoutTolerance,
            endDeltaWatts: endDeltaWatts,
            endConfirmSeconds: endConfirmSeconds,
            minEffortSeconds: minEffortSeconds,
            preEffortBaselineWindow: preEffortBaselineWindow,
            inEffortTrailingWindow: inEffortTrailingWindow,
            isDefault: isDefault,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required double startDeltaWatts,
            Value<int> startConfirmSeconds = const Value.absent(),
            Value<int> startDropoutTolerance = const Value.absent(),
            required double endDeltaWatts,
            Value<int> endConfirmSeconds = const Value.absent(),
            Value<int> minEffortSeconds = const Value.absent(),
            Value<int> preEffortBaselineWindow = const Value.absent(),
            Value<int> inEffortTrailingWindow = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AutolapConfigsCompanion.insert(
            id: id,
            name: name,
            startDeltaWatts: startDeltaWatts,
            startConfirmSeconds: startConfirmSeconds,
            startDropoutTolerance: startDropoutTolerance,
            endDeltaWatts: endDeltaWatts,
            endConfirmSeconds: endConfirmSeconds,
            minEffortSeconds: minEffortSeconds,
            preEffortBaselineWindow: preEffortBaselineWindow,
            inEffortTrailingWindow: inEffortTrailingWindow,
            isDefault: isDefault,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AutolapConfigsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ridesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ridesRefs) db.rides],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ridesRefs)
                    await $_getPrefetchedData<AutolapConfigRow,
                            $AutolapConfigsTable, RideRow>(
                        currentTable: table,
                        referencedTable:
                            $$AutolapConfigsTableReferences._ridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AutolapConfigsTableReferences(db, table, p0)
                                .ridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.autoLapConfigId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AutolapConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AutolapConfigsTable,
    AutolapConfigRow,
    $$AutolapConfigsTableFilterComposer,
    $$AutolapConfigsTableOrderingComposer,
    $$AutolapConfigsTableAnnotationComposer,
    $$AutolapConfigsTableCreateCompanionBuilder,
    $$AutolapConfigsTableUpdateCompanionBuilder,
    (AutolapConfigRow, $$AutolapConfigsTableReferences),
    AutolapConfigRow,
    PrefetchHooks Function({bool ridesRefs})>;
typedef $$RidesTableCreateCompanionBuilder = RidesCompanion Function({
  required String id,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<String?> notes,
  required String source,
  Value<String?> autoLapConfigId,
  required int durationSeconds,
  required int activeDurationSeconds,
  required double avgPower,
  required double maxPower,
  Value<int?> avgHeartRate,
  Value<int?> maxHeartRate,
  Value<double?> avgCadence,
  required double totalKilojoules,
  Value<double?> avgLeftRightBalance,
  required int readingCount,
  required int effortCount,
  Value<int> rowid,
});
typedef $$RidesTableUpdateCompanionBuilder = RidesCompanion Function({
  Value<String> id,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<String?> notes,
  Value<String> source,
  Value<String?> autoLapConfigId,
  Value<int> durationSeconds,
  Value<int> activeDurationSeconds,
  Value<double> avgPower,
  Value<double> maxPower,
  Value<int?> avgHeartRate,
  Value<int?> maxHeartRate,
  Value<double?> avgCadence,
  Value<double> totalKilojoules,
  Value<double?> avgLeftRightBalance,
  Value<int> readingCount,
  Value<int> effortCount,
  Value<int> rowid,
});

final class $$RidesTableReferences
    extends BaseReferences<_$AppDatabase, $RidesTable, RideRow> {
  $$RidesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AutolapConfigsTable _autoLapConfigIdTable(_$AppDatabase db) =>
      db.autolapConfigs.createAlias(
          $_aliasNameGenerator(db.rides.autoLapConfigId, db.autolapConfigs.id));

  $$AutolapConfigsTableProcessedTableManager? get autoLapConfigId {
    final $_column = $_itemColumn<String>('auto_lap_config_id');
    if ($_column == null) return null;
    final manager = $$AutolapConfigsTableTableManager($_db, $_db.autolapConfigs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_autoLapConfigIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RideTagsTable, List<RideTagRow>>
      _rideTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.rideTags,
              aliasName: $_aliasNameGenerator(db.rides.id, db.rideTags.rideId));

  $$RideTagsTableProcessedTableManager get rideTagsRefs {
    final manager = $$RideTagsTableTableManager($_db, $_db.rideTags)
        .filter((f) => f.rideId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rideTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EffortsTable, List<EffortRow>> _effortsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.efforts,
          aliasName: $_aliasNameGenerator(db.rides.id, db.efforts.rideId));

  $$EffortsTableProcessedTableManager get effortsRefs {
    final manager = $$EffortsTableTableManager($_db, $_db.efforts)
        .filter((f) => f.rideId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_effortsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReadingsTable, List<ReadingRow>>
      _readingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.readings,
              aliasName: $_aliasNameGenerator(db.rides.id, db.readings.rideId));

  $$ReadingsTableProcessedTableManager get readingsRefs {
    final manager = $$ReadingsTableTableManager($_db, $_db.readings)
        .filter((f) => f.rideId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RidesTableFilterComposer extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get readingCount => $composableBuilder(
      column: $table.readingCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get effortCount => $composableBuilder(
      column: $table.effortCount, builder: (column) => ColumnFilters(column));

  $$AutolapConfigsTableFilterComposer get autoLapConfigId {
    final $$AutolapConfigsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.autoLapConfigId,
        referencedTable: $db.autolapConfigs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AutolapConfigsTableFilterComposer(
              $db: $db,
              $table: $db.autolapConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> rideTagsRefs(
      Expression<bool> Function($$RideTagsTableFilterComposer f) f) {
    final $$RideTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rideTags,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RideTagsTableFilterComposer(
              $db: $db,
              $table: $db.rideTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> effortsRefs(
      Expression<bool> Function($$EffortsTableFilterComposer f) f) {
    final $$EffortsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.efforts,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EffortsTableFilterComposer(
              $db: $db,
              $table: $db.efforts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> readingsRefs(
      Expression<bool> Function($$ReadingsTableFilterComposer f) f) {
    final $$ReadingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableFilterComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RidesTableOrderingComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get readingCount => $composableBuilder(
      column: $table.readingCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get effortCount => $composableBuilder(
      column: $table.effortCount, builder: (column) => ColumnOrderings(column));

  $$AutolapConfigsTableOrderingComposer get autoLapConfigId {
    final $$AutolapConfigsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.autoLapConfigId,
        referencedTable: $db.autolapConfigs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AutolapConfigsTableOrderingComposer(
              $db: $db,
              $table: $db.autolapConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RidesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds, builder: (column) => column);

  GeneratedColumn<double> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<double> get maxPower =>
      $composableBuilder(column: $table.maxPower, builder: (column) => column);

  GeneratedColumn<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => column);

  GeneratedColumn<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => column);

  GeneratedColumn<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => column);

  GeneratedColumn<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules, builder: (column) => column);

  GeneratedColumn<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance, builder: (column) => column);

  GeneratedColumn<int> get readingCount => $composableBuilder(
      column: $table.readingCount, builder: (column) => column);

  GeneratedColumn<int> get effortCount => $composableBuilder(
      column: $table.effortCount, builder: (column) => column);

  $$AutolapConfigsTableAnnotationComposer get autoLapConfigId {
    final $$AutolapConfigsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.autoLapConfigId,
        referencedTable: $db.autolapConfigs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AutolapConfigsTableAnnotationComposer(
              $db: $db,
              $table: $db.autolapConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> rideTagsRefs<T extends Object>(
      Expression<T> Function($$RideTagsTableAnnotationComposer a) f) {
    final $$RideTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rideTags,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RideTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.rideTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> effortsRefs<T extends Object>(
      Expression<T> Function($$EffortsTableAnnotationComposer a) f) {
    final $$EffortsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.efforts,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EffortsTableAnnotationComposer(
              $db: $db,
              $table: $db.efforts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> readingsRefs<T extends Object>(
      Expression<T> Function($$ReadingsTableAnnotationComposer a) f) {
    final $$ReadingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.rideId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableAnnotationComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RidesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RidesTable,
    RideRow,
    $$RidesTableFilterComposer,
    $$RidesTableOrderingComposer,
    $$RidesTableAnnotationComposer,
    $$RidesTableCreateCompanionBuilder,
    $$RidesTableUpdateCompanionBuilder,
    (RideRow, $$RidesTableReferences),
    RideRow,
    PrefetchHooks Function(
        {bool autoLapConfigId,
        bool rideTagsRefs,
        bool effortsRefs,
        bool readingsRefs})> {
  $$RidesTableTableManager(_$AppDatabase db, $RidesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RidesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RidesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RidesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> autoLapConfigId = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> activeDurationSeconds = const Value.absent(),
            Value<double> avgPower = const Value.absent(),
            Value<double> maxPower = const Value.absent(),
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int?> maxHeartRate = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            Value<double> totalKilojoules = const Value.absent(),
            Value<double?> avgLeftRightBalance = const Value.absent(),
            Value<int> readingCount = const Value.absent(),
            Value<int> effortCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RidesCompanion(
            id: id,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            source: source,
            autoLapConfigId: autoLapConfigId,
            durationSeconds: durationSeconds,
            activeDurationSeconds: activeDurationSeconds,
            avgPower: avgPower,
            maxPower: maxPower,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgCadence: avgCadence,
            totalKilojoules: totalKilojoules,
            avgLeftRightBalance: avgLeftRightBalance,
            readingCount: readingCount,
            effortCount: effortCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String source,
            Value<String?> autoLapConfigId = const Value.absent(),
            required int durationSeconds,
            required int activeDurationSeconds,
            required double avgPower,
            required double maxPower,
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int?> maxHeartRate = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            required double totalKilojoules,
            Value<double?> avgLeftRightBalance = const Value.absent(),
            required int readingCount,
            required int effortCount,
            Value<int> rowid = const Value.absent(),
          }) =>
              RidesCompanion.insert(
            id: id,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            source: source,
            autoLapConfigId: autoLapConfigId,
            durationSeconds: durationSeconds,
            activeDurationSeconds: activeDurationSeconds,
            avgPower: avgPower,
            maxPower: maxPower,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgCadence: avgCadence,
            totalKilojoules: totalKilojoules,
            avgLeftRightBalance: avgLeftRightBalance,
            readingCount: readingCount,
            effortCount: effortCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RidesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {autoLapConfigId = false,
              rideTagsRefs = false,
              effortsRefs = false,
              readingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rideTagsRefs) db.rideTags,
                if (effortsRefs) db.efforts,
                if (readingsRefs) db.readings
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (autoLapConfigId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.autoLapConfigId,
                    referencedTable:
                        $$RidesTableReferences._autoLapConfigIdTable(db),
                    referencedColumn:
                        $$RidesTableReferences._autoLapConfigIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rideTagsRefs)
                    await $_getPrefetchedData<RideRow, $RidesTable, RideTagRow>(
                        currentTable: table,
                        referencedTable:
                            $$RidesTableReferences._rideTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RidesTableReferences(db, table, p0).rideTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.rideId == item.id),
                        typedResults: items),
                  if (effortsRefs)
                    await $_getPrefetchedData<RideRow, $RidesTable, EffortRow>(
                        currentTable: table,
                        referencedTable:
                            $$RidesTableReferences._effortsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RidesTableReferences(db, table, p0).effortsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.rideId == item.id),
                        typedResults: items),
                  if (readingsRefs)
                    await $_getPrefetchedData<RideRow, $RidesTable, ReadingRow>(
                        currentTable: table,
                        referencedTable:
                            $$RidesTableReferences._readingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RidesTableReferences(db, table, p0).readingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.rideId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RidesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RidesTable,
    RideRow,
    $$RidesTableFilterComposer,
    $$RidesTableOrderingComposer,
    $$RidesTableAnnotationComposer,
    $$RidesTableCreateCompanionBuilder,
    $$RidesTableUpdateCompanionBuilder,
    (RideRow, $$RidesTableReferences),
    RideRow,
    PrefetchHooks Function(
        {bool autoLapConfigId,
        bool rideTagsRefs,
        bool effortsRefs,
        bool readingsRefs})>;
typedef $$RideTagsTableCreateCompanionBuilder = RideTagsCompanion Function({
  required String rideId,
  required String tag,
  Value<int> rowid,
});
typedef $$RideTagsTableUpdateCompanionBuilder = RideTagsCompanion Function({
  Value<String> rideId,
  Value<String> tag,
  Value<int> rowid,
});

final class $$RideTagsTableReferences
    extends BaseReferences<_$AppDatabase, $RideTagsTable, RideTagRow> {
  $$RideTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RidesTable _rideIdTable(_$AppDatabase db) => db.rides
      .createAlias($_aliasNameGenerator(db.rideTags.rideId, db.rides.id));

  $$RidesTableProcessedTableManager get rideId {
    final $_column = $_itemColumn<String>('ride_id')!;

    final manager = $$RidesTableTableManager($_db, $_db.rides)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rideIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RideTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RideTagsTable> {
  $$RideTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  $$RidesTableFilterComposer get rideId {
    final $$RidesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableFilterComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RideTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RideTagsTable> {
  $$RideTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  $$RidesTableOrderingComposer get rideId {
    final $$RidesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableOrderingComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RideTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RideTagsTable> {
  $$RideTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$RidesTableAnnotationComposer get rideId {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableAnnotationComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RideTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RideTagsTable,
    RideTagRow,
    $$RideTagsTableFilterComposer,
    $$RideTagsTableOrderingComposer,
    $$RideTagsTableAnnotationComposer,
    $$RideTagsTableCreateCompanionBuilder,
    $$RideTagsTableUpdateCompanionBuilder,
    (RideTagRow, $$RideTagsTableReferences),
    RideTagRow,
    PrefetchHooks Function({bool rideId})> {
  $$RideTagsTableTableManager(_$AppDatabase db, $RideTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RideTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RideTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RideTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> rideId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RideTagsCompanion(
            rideId: rideId,
            tag: tag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String rideId,
            required String tag,
            Value<int> rowid = const Value.absent(),
          }) =>
              RideTagsCompanion.insert(
            rideId: rideId,
            tag: tag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RideTagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({rideId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (rideId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.rideId,
                    referencedTable: $$RideTagsTableReferences._rideIdTable(db),
                    referencedColumn:
                        $$RideTagsTableReferences._rideIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RideTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RideTagsTable,
    RideTagRow,
    $$RideTagsTableFilterComposer,
    $$RideTagsTableOrderingComposer,
    $$RideTagsTableAnnotationComposer,
    $$RideTagsTableCreateCompanionBuilder,
    $$RideTagsTableUpdateCompanionBuilder,
    (RideTagRow, $$RideTagsTableReferences),
    RideTagRow,
    PrefetchHooks Function({bool rideId})>;
typedef $$EffortsTableCreateCompanionBuilder = EffortsCompanion Function({
  required String id,
  required String rideId,
  required int effortNumber,
  required int startOffset,
  required int endOffset,
  required String type,
  required int durationSeconds,
  required double avgPower,
  required double peakPower,
  Value<int?> avgHeartRate,
  Value<int?> maxHeartRate,
  Value<double?> avgCadence,
  required double totalKilojoules,
  Value<double?> avgLeftRightBalance,
  Value<int?> restSincePrevious,
  Value<int> rowid,
});
typedef $$EffortsTableUpdateCompanionBuilder = EffortsCompanion Function({
  Value<String> id,
  Value<String> rideId,
  Value<int> effortNumber,
  Value<int> startOffset,
  Value<int> endOffset,
  Value<String> type,
  Value<int> durationSeconds,
  Value<double> avgPower,
  Value<double> peakPower,
  Value<int?> avgHeartRate,
  Value<int?> maxHeartRate,
  Value<double?> avgCadence,
  Value<double> totalKilojoules,
  Value<double?> avgLeftRightBalance,
  Value<int?> restSincePrevious,
  Value<int> rowid,
});

final class $$EffortsTableReferences
    extends BaseReferences<_$AppDatabase, $EffortsTable, EffortRow> {
  $$EffortsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RidesTable _rideIdTable(_$AppDatabase db) => db.rides
      .createAlias($_aliasNameGenerator(db.efforts.rideId, db.rides.id));

  $$RidesTableProcessedTableManager get rideId {
    final $_column = $_itemColumn<String>('ride_id')!;

    final manager = $$RidesTableTableManager($_db, $_db.rides)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rideIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$MapCurvesTable, List<MapCurveRow>>
      _mapCurvesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.mapCurves,
              aliasName:
                  $_aliasNameGenerator(db.efforts.id, db.mapCurves.effortId));

  $$MapCurvesTableProcessedTableManager get mapCurvesRefs {
    final manager = $$MapCurvesTableTableManager($_db, $_db.mapCurves)
        .filter((f) => f.effortId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mapCurvesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EffortsTableFilterComposer
    extends Composer<_$AppDatabase, $EffortsTable> {
  $$EffortsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get effortNumber => $composableBuilder(
      column: $table.effortNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endOffset => $composableBuilder(
      column: $table.endOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakPower => $composableBuilder(
      column: $table.peakPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSincePrevious => $composableBuilder(
      column: $table.restSincePrevious,
      builder: (column) => ColumnFilters(column));

  $$RidesTableFilterComposer get rideId {
    final $$RidesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableFilterComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> mapCurvesRefs(
      Expression<bool> Function($$MapCurvesTableFilterComposer f) f) {
    final $$MapCurvesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mapCurves,
        getReferencedColumn: (t) => t.effortId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MapCurvesTableFilterComposer(
              $db: $db,
              $table: $db.mapCurves,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EffortsTableOrderingComposer
    extends Composer<_$AppDatabase, $EffortsTable> {
  $$EffortsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get effortNumber => $composableBuilder(
      column: $table.effortNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endOffset => $composableBuilder(
      column: $table.endOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakPower => $composableBuilder(
      column: $table.peakPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSincePrevious => $composableBuilder(
      column: $table.restSincePrevious,
      builder: (column) => ColumnOrderings(column));

  $$RidesTableOrderingComposer get rideId {
    final $$RidesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableOrderingComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EffortsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EffortsTable> {
  $$EffortsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get effortNumber => $composableBuilder(
      column: $table.effortNumber, builder: (column) => column);

  GeneratedColumn<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => column);

  GeneratedColumn<int> get endOffset =>
      $composableBuilder(column: $table.endOffset, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<double> get peakPower =>
      $composableBuilder(column: $table.peakPower, builder: (column) => column);

  GeneratedColumn<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => column);

  GeneratedColumn<int> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => column);

  GeneratedColumn<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => column);

  GeneratedColumn<double> get totalKilojoules => $composableBuilder(
      column: $table.totalKilojoules, builder: (column) => column);

  GeneratedColumn<double> get avgLeftRightBalance => $composableBuilder(
      column: $table.avgLeftRightBalance, builder: (column) => column);

  GeneratedColumn<int> get restSincePrevious => $composableBuilder(
      column: $table.restSincePrevious, builder: (column) => column);

  $$RidesTableAnnotationComposer get rideId {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableAnnotationComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> mapCurvesRefs<T extends Object>(
      Expression<T> Function($$MapCurvesTableAnnotationComposer a) f) {
    final $$MapCurvesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mapCurves,
        getReferencedColumn: (t) => t.effortId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MapCurvesTableAnnotationComposer(
              $db: $db,
              $table: $db.mapCurves,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EffortsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EffortsTable,
    EffortRow,
    $$EffortsTableFilterComposer,
    $$EffortsTableOrderingComposer,
    $$EffortsTableAnnotationComposer,
    $$EffortsTableCreateCompanionBuilder,
    $$EffortsTableUpdateCompanionBuilder,
    (EffortRow, $$EffortsTableReferences),
    EffortRow,
    PrefetchHooks Function({bool rideId, bool mapCurvesRefs})> {
  $$EffortsTableTableManager(_$AppDatabase db, $EffortsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EffortsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EffortsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EffortsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rideId = const Value.absent(),
            Value<int> effortNumber = const Value.absent(),
            Value<int> startOffset = const Value.absent(),
            Value<int> endOffset = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> avgPower = const Value.absent(),
            Value<double> peakPower = const Value.absent(),
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int?> maxHeartRate = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            Value<double> totalKilojoules = const Value.absent(),
            Value<double?> avgLeftRightBalance = const Value.absent(),
            Value<int?> restSincePrevious = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EffortsCompanion(
            id: id,
            rideId: rideId,
            effortNumber: effortNumber,
            startOffset: startOffset,
            endOffset: endOffset,
            type: type,
            durationSeconds: durationSeconds,
            avgPower: avgPower,
            peakPower: peakPower,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgCadence: avgCadence,
            totalKilojoules: totalKilojoules,
            avgLeftRightBalance: avgLeftRightBalance,
            restSincePrevious: restSincePrevious,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rideId,
            required int effortNumber,
            required int startOffset,
            required int endOffset,
            required String type,
            required int durationSeconds,
            required double avgPower,
            required double peakPower,
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int?> maxHeartRate = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            required double totalKilojoules,
            Value<double?> avgLeftRightBalance = const Value.absent(),
            Value<int?> restSincePrevious = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EffortsCompanion.insert(
            id: id,
            rideId: rideId,
            effortNumber: effortNumber,
            startOffset: startOffset,
            endOffset: endOffset,
            type: type,
            durationSeconds: durationSeconds,
            avgPower: avgPower,
            peakPower: peakPower,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgCadence: avgCadence,
            totalKilojoules: totalKilojoules,
            avgLeftRightBalance: avgLeftRightBalance,
            restSincePrevious: restSincePrevious,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EffortsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({rideId = false, mapCurvesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mapCurvesRefs) db.mapCurves],
              addJoins: <
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
                      dynamic>>(state) {
                if (rideId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.rideId,
                    referencedTable: $$EffortsTableReferences._rideIdTable(db),
                    referencedColumn:
                        $$EffortsTableReferences._rideIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mapCurvesRefs)
                    await $_getPrefetchedData<EffortRow, $EffortsTable,
                            MapCurveRow>(
                        currentTable: table,
                        referencedTable:
                            $$EffortsTableReferences._mapCurvesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EffortsTableReferences(db, table, p0)
                                .mapCurvesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.effortId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EffortsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EffortsTable,
    EffortRow,
    $$EffortsTableFilterComposer,
    $$EffortsTableOrderingComposer,
    $$EffortsTableAnnotationComposer,
    $$EffortsTableCreateCompanionBuilder,
    $$EffortsTableUpdateCompanionBuilder,
    (EffortRow, $$EffortsTableReferences),
    EffortRow,
    PrefetchHooks Function({bool rideId, bool mapCurvesRefs})>;
typedef $$MapCurvesTableCreateCompanionBuilder = MapCurvesCompanion Function({
  required String effortId,
  required int durationSeconds,
  required double bestAvgPower,
  Value<bool> hadNulls,
  Value<bool> wasEnforced,
  Value<int> rowid,
});
typedef $$MapCurvesTableUpdateCompanionBuilder = MapCurvesCompanion Function({
  Value<String> effortId,
  Value<int> durationSeconds,
  Value<double> bestAvgPower,
  Value<bool> hadNulls,
  Value<bool> wasEnforced,
  Value<int> rowid,
});

final class $$MapCurvesTableReferences
    extends BaseReferences<_$AppDatabase, $MapCurvesTable, MapCurveRow> {
  $$MapCurvesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EffortsTable _effortIdTable(_$AppDatabase db) => db.efforts
      .createAlias($_aliasNameGenerator(db.mapCurves.effortId, db.efforts.id));

  $$EffortsTableProcessedTableManager get effortId {
    final $_column = $_itemColumn<String>('effort_id')!;

    final manager = $$EffortsTableTableManager($_db, $_db.efforts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_effortIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MapCurvesTableFilterComposer
    extends Composer<_$AppDatabase, $MapCurvesTable> {
  $$MapCurvesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestAvgPower => $composableBuilder(
      column: $table.bestAvgPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hadNulls => $composableBuilder(
      column: $table.hadNulls, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasEnforced => $composableBuilder(
      column: $table.wasEnforced, builder: (column) => ColumnFilters(column));

  $$EffortsTableFilterComposer get effortId {
    final $$EffortsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.effortId,
        referencedTable: $db.efforts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EffortsTableFilterComposer(
              $db: $db,
              $table: $db.efforts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MapCurvesTableOrderingComposer
    extends Composer<_$AppDatabase, $MapCurvesTable> {
  $$MapCurvesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestAvgPower => $composableBuilder(
      column: $table.bestAvgPower,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hadNulls => $composableBuilder(
      column: $table.hadNulls, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasEnforced => $composableBuilder(
      column: $table.wasEnforced, builder: (column) => ColumnOrderings(column));

  $$EffortsTableOrderingComposer get effortId {
    final $$EffortsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.effortId,
        referencedTable: $db.efforts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EffortsTableOrderingComposer(
              $db: $db,
              $table: $db.efforts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MapCurvesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MapCurvesTable> {
  $$MapCurvesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get bestAvgPower => $composableBuilder(
      column: $table.bestAvgPower, builder: (column) => column);

  GeneratedColumn<bool> get hadNulls =>
      $composableBuilder(column: $table.hadNulls, builder: (column) => column);

  GeneratedColumn<bool> get wasEnforced => $composableBuilder(
      column: $table.wasEnforced, builder: (column) => column);

  $$EffortsTableAnnotationComposer get effortId {
    final $$EffortsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.effortId,
        referencedTable: $db.efforts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EffortsTableAnnotationComposer(
              $db: $db,
              $table: $db.efforts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MapCurvesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MapCurvesTable,
    MapCurveRow,
    $$MapCurvesTableFilterComposer,
    $$MapCurvesTableOrderingComposer,
    $$MapCurvesTableAnnotationComposer,
    $$MapCurvesTableCreateCompanionBuilder,
    $$MapCurvesTableUpdateCompanionBuilder,
    (MapCurveRow, $$MapCurvesTableReferences),
    MapCurveRow,
    PrefetchHooks Function({bool effortId})> {
  $$MapCurvesTableTableManager(_$AppDatabase db, $MapCurvesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MapCurvesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MapCurvesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MapCurvesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> effortId = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> bestAvgPower = const Value.absent(),
            Value<bool> hadNulls = const Value.absent(),
            Value<bool> wasEnforced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MapCurvesCompanion(
            effortId: effortId,
            durationSeconds: durationSeconds,
            bestAvgPower: bestAvgPower,
            hadNulls: hadNulls,
            wasEnforced: wasEnforced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String effortId,
            required int durationSeconds,
            required double bestAvgPower,
            Value<bool> hadNulls = const Value.absent(),
            Value<bool> wasEnforced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MapCurvesCompanion.insert(
            effortId: effortId,
            durationSeconds: durationSeconds,
            bestAvgPower: bestAvgPower,
            hadNulls: hadNulls,
            wasEnforced: wasEnforced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MapCurvesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({effortId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (effortId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.effortId,
                    referencedTable:
                        $$MapCurvesTableReferences._effortIdTable(db),
                    referencedColumn:
                        $$MapCurvesTableReferences._effortIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MapCurvesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MapCurvesTable,
    MapCurveRow,
    $$MapCurvesTableFilterComposer,
    $$MapCurvesTableOrderingComposer,
    $$MapCurvesTableAnnotationComposer,
    $$MapCurvesTableCreateCompanionBuilder,
    $$MapCurvesTableUpdateCompanionBuilder,
    (MapCurveRow, $$MapCurvesTableReferences),
    MapCurveRow,
    PrefetchHooks Function({bool effortId})>;
typedef $$ReadingsTableCreateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  required String rideId,
  required int offsetSeconds,
  Value<double?> power,
  Value<double?> leftRightBalance,
  Value<double?> leftPower,
  Value<double?> rightPower,
  Value<int?> heartRate,
  Value<double?> cadence,
  Value<double?> crankTorque,
  Value<int?> accumulatedTorque,
  Value<int?> crankRevolutions,
  Value<int?> lastCrankEventTime,
  Value<int?> maxForceMagnitude,
  Value<int?> minForceMagnitude,
  Value<int?> maxTorqueMagnitude,
  Value<int?> minTorqueMagnitude,
  Value<int?> topDeadSpotAngle,
  Value<int?> bottomDeadSpotAngle,
  Value<int?> accumulatedEnergy,
  Value<String?> rrIntervals,
});
typedef $$ReadingsTableUpdateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  Value<String> rideId,
  Value<int> offsetSeconds,
  Value<double?> power,
  Value<double?> leftRightBalance,
  Value<double?> leftPower,
  Value<double?> rightPower,
  Value<int?> heartRate,
  Value<double?> cadence,
  Value<double?> crankTorque,
  Value<int?> accumulatedTorque,
  Value<int?> crankRevolutions,
  Value<int?> lastCrankEventTime,
  Value<int?> maxForceMagnitude,
  Value<int?> minForceMagnitude,
  Value<int?> maxTorqueMagnitude,
  Value<int?> minTorqueMagnitude,
  Value<int?> topDeadSpotAngle,
  Value<int?> bottomDeadSpotAngle,
  Value<int?> accumulatedEnergy,
  Value<String?> rrIntervals,
});

final class $$ReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow> {
  $$ReadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RidesTable _rideIdTable(_$AppDatabase db) => db.rides
      .createAlias($_aliasNameGenerator(db.readings.rideId, db.rides.id));

  $$RidesTableProcessedTableManager get rideId {
    final $_column = $_itemColumn<String>('ride_id')!;

    final manager = $$RidesTableTableManager($_db, $_db.rides)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rideIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get offsetSeconds => $composableBuilder(
      column: $table.offsetSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get leftRightBalance => $composableBuilder(
      column: $table.leftRightBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get leftPower => $composableBuilder(
      column: $table.leftPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rightPower => $composableBuilder(
      column: $table.rightPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartRate => $composableBuilder(
      column: $table.heartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cadence => $composableBuilder(
      column: $table.cadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get crankTorque => $composableBuilder(
      column: $table.crankTorque, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accumulatedTorque => $composableBuilder(
      column: $table.accumulatedTorque,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get crankRevolutions => $composableBuilder(
      column: $table.crankRevolutions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastCrankEventTime => $composableBuilder(
      column: $table.lastCrankEventTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxForceMagnitude => $composableBuilder(
      column: $table.maxForceMagnitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minForceMagnitude => $composableBuilder(
      column: $table.minForceMagnitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxTorqueMagnitude => $composableBuilder(
      column: $table.maxTorqueMagnitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minTorqueMagnitude => $composableBuilder(
      column: $table.minTorqueMagnitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get topDeadSpotAngle => $composableBuilder(
      column: $table.topDeadSpotAngle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bottomDeadSpotAngle => $composableBuilder(
      column: $table.bottomDeadSpotAngle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accumulatedEnergy => $composableBuilder(
      column: $table.accumulatedEnergy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rrIntervals => $composableBuilder(
      column: $table.rrIntervals, builder: (column) => ColumnFilters(column));

  $$RidesTableFilterComposer get rideId {
    final $$RidesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableFilterComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get offsetSeconds => $composableBuilder(
      column: $table.offsetSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get leftRightBalance => $composableBuilder(
      column: $table.leftRightBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get leftPower => $composableBuilder(
      column: $table.leftPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rightPower => $composableBuilder(
      column: $table.rightPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartRate => $composableBuilder(
      column: $table.heartRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cadence => $composableBuilder(
      column: $table.cadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get crankTorque => $composableBuilder(
      column: $table.crankTorque, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accumulatedTorque => $composableBuilder(
      column: $table.accumulatedTorque,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get crankRevolutions => $composableBuilder(
      column: $table.crankRevolutions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastCrankEventTime => $composableBuilder(
      column: $table.lastCrankEventTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxForceMagnitude => $composableBuilder(
      column: $table.maxForceMagnitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minForceMagnitude => $composableBuilder(
      column: $table.minForceMagnitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxTorqueMagnitude => $composableBuilder(
      column: $table.maxTorqueMagnitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minTorqueMagnitude => $composableBuilder(
      column: $table.minTorqueMagnitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get topDeadSpotAngle => $composableBuilder(
      column: $table.topDeadSpotAngle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bottomDeadSpotAngle => $composableBuilder(
      column: $table.bottomDeadSpotAngle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accumulatedEnergy => $composableBuilder(
      column: $table.accumulatedEnergy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rrIntervals => $composableBuilder(
      column: $table.rrIntervals, builder: (column) => ColumnOrderings(column));

  $$RidesTableOrderingComposer get rideId {
    final $$RidesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableOrderingComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetSeconds => $composableBuilder(
      column: $table.offsetSeconds, builder: (column) => column);

  GeneratedColumn<double> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<double> get leftRightBalance => $composableBuilder(
      column: $table.leftRightBalance, builder: (column) => column);

  GeneratedColumn<double> get leftPower =>
      $composableBuilder(column: $table.leftPower, builder: (column) => column);

  GeneratedColumn<double> get rightPower => $composableBuilder(
      column: $table.rightPower, builder: (column) => column);

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<double> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<double> get crankTorque => $composableBuilder(
      column: $table.crankTorque, builder: (column) => column);

  GeneratedColumn<int> get accumulatedTorque => $composableBuilder(
      column: $table.accumulatedTorque, builder: (column) => column);

  GeneratedColumn<int> get crankRevolutions => $composableBuilder(
      column: $table.crankRevolutions, builder: (column) => column);

  GeneratedColumn<int> get lastCrankEventTime => $composableBuilder(
      column: $table.lastCrankEventTime, builder: (column) => column);

  GeneratedColumn<int> get maxForceMagnitude => $composableBuilder(
      column: $table.maxForceMagnitude, builder: (column) => column);

  GeneratedColumn<int> get minForceMagnitude => $composableBuilder(
      column: $table.minForceMagnitude, builder: (column) => column);

  GeneratedColumn<int> get maxTorqueMagnitude => $composableBuilder(
      column: $table.maxTorqueMagnitude, builder: (column) => column);

  GeneratedColumn<int> get minTorqueMagnitude => $composableBuilder(
      column: $table.minTorqueMagnitude, builder: (column) => column);

  GeneratedColumn<int> get topDeadSpotAngle => $composableBuilder(
      column: $table.topDeadSpotAngle, builder: (column) => column);

  GeneratedColumn<int> get bottomDeadSpotAngle => $composableBuilder(
      column: $table.bottomDeadSpotAngle, builder: (column) => column);

  GeneratedColumn<int> get accumulatedEnergy => $composableBuilder(
      column: $table.accumulatedEnergy, builder: (column) => column);

  GeneratedColumn<String> get rrIntervals => $composableBuilder(
      column: $table.rrIntervals, builder: (column) => column);

  $$RidesTableAnnotationComposer get rideId {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.rideId,
        referencedTable: $db.rides,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RidesTableAnnotationComposer(
              $db: $db,
              $table: $db.rides,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingsTable,
    ReadingRow,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (ReadingRow, $$ReadingsTableReferences),
    ReadingRow,
    PrefetchHooks Function({bool rideId})> {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> rideId = const Value.absent(),
            Value<int> offsetSeconds = const Value.absent(),
            Value<double?> power = const Value.absent(),
            Value<double?> leftRightBalance = const Value.absent(),
            Value<double?> leftPower = const Value.absent(),
            Value<double?> rightPower = const Value.absent(),
            Value<int?> heartRate = const Value.absent(),
            Value<double?> cadence = const Value.absent(),
            Value<double?> crankTorque = const Value.absent(),
            Value<int?> accumulatedTorque = const Value.absent(),
            Value<int?> crankRevolutions = const Value.absent(),
            Value<int?> lastCrankEventTime = const Value.absent(),
            Value<int?> maxForceMagnitude = const Value.absent(),
            Value<int?> minForceMagnitude = const Value.absent(),
            Value<int?> maxTorqueMagnitude = const Value.absent(),
            Value<int?> minTorqueMagnitude = const Value.absent(),
            Value<int?> topDeadSpotAngle = const Value.absent(),
            Value<int?> bottomDeadSpotAngle = const Value.absent(),
            Value<int?> accumulatedEnergy = const Value.absent(),
            Value<String?> rrIntervals = const Value.absent(),
          }) =>
              ReadingsCompanion(
            id: id,
            rideId: rideId,
            offsetSeconds: offsetSeconds,
            power: power,
            leftRightBalance: leftRightBalance,
            leftPower: leftPower,
            rightPower: rightPower,
            heartRate: heartRate,
            cadence: cadence,
            crankTorque: crankTorque,
            accumulatedTorque: accumulatedTorque,
            crankRevolutions: crankRevolutions,
            lastCrankEventTime: lastCrankEventTime,
            maxForceMagnitude: maxForceMagnitude,
            minForceMagnitude: minForceMagnitude,
            maxTorqueMagnitude: maxTorqueMagnitude,
            minTorqueMagnitude: minTorqueMagnitude,
            topDeadSpotAngle: topDeadSpotAngle,
            bottomDeadSpotAngle: bottomDeadSpotAngle,
            accumulatedEnergy: accumulatedEnergy,
            rrIntervals: rrIntervals,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rideId,
            required int offsetSeconds,
            Value<double?> power = const Value.absent(),
            Value<double?> leftRightBalance = const Value.absent(),
            Value<double?> leftPower = const Value.absent(),
            Value<double?> rightPower = const Value.absent(),
            Value<int?> heartRate = const Value.absent(),
            Value<double?> cadence = const Value.absent(),
            Value<double?> crankTorque = const Value.absent(),
            Value<int?> accumulatedTorque = const Value.absent(),
            Value<int?> crankRevolutions = const Value.absent(),
            Value<int?> lastCrankEventTime = const Value.absent(),
            Value<int?> maxForceMagnitude = const Value.absent(),
            Value<int?> minForceMagnitude = const Value.absent(),
            Value<int?> maxTorqueMagnitude = const Value.absent(),
            Value<int?> minTorqueMagnitude = const Value.absent(),
            Value<int?> topDeadSpotAngle = const Value.absent(),
            Value<int?> bottomDeadSpotAngle = const Value.absent(),
            Value<int?> accumulatedEnergy = const Value.absent(),
            Value<String?> rrIntervals = const Value.absent(),
          }) =>
              ReadingsCompanion.insert(
            id: id,
            rideId: rideId,
            offsetSeconds: offsetSeconds,
            power: power,
            leftRightBalance: leftRightBalance,
            leftPower: leftPower,
            rightPower: rightPower,
            heartRate: heartRate,
            cadence: cadence,
            crankTorque: crankTorque,
            accumulatedTorque: accumulatedTorque,
            crankRevolutions: crankRevolutions,
            lastCrankEventTime: lastCrankEventTime,
            maxForceMagnitude: maxForceMagnitude,
            minForceMagnitude: minForceMagnitude,
            maxTorqueMagnitude: maxTorqueMagnitude,
            minTorqueMagnitude: minTorqueMagnitude,
            topDeadSpotAngle: topDeadSpotAngle,
            bottomDeadSpotAngle: bottomDeadSpotAngle,
            accumulatedEnergy: accumulatedEnergy,
            rrIntervals: rrIntervals,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReadingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({rideId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (rideId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.rideId,
                    referencedTable: $$ReadingsTableReferences._rideIdTable(db),
                    referencedColumn:
                        $$ReadingsTableReferences._rideIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReadingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadingsTable,
    ReadingRow,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (ReadingRow, $$ReadingsTableReferences),
    ReadingRow,
    PrefetchHooks Function({bool rideId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String deviceId,
  required String displayName,
  required String supportedServices,
  required DateTime lastConnected,
  Value<bool> autoConnect,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> deviceId,
  Value<String> displayName,
  Value<String> supportedServices,
  Value<DateTime> lastConnected,
  Value<bool> autoConnect,
  Value<int> rowid,
});

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supportedServices => $composableBuilder(
      column: $table.supportedServices,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoConnect => $composableBuilder(
      column: $table.autoConnect, builder: (column) => ColumnFilters(column));
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supportedServices => $composableBuilder(
      column: $table.supportedServices,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoConnect => $composableBuilder(
      column: $table.autoConnect, builder: (column) => ColumnOrderings(column));
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get supportedServices => $composableBuilder(
      column: $table.supportedServices, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => column);

  GeneratedColumn<bool> get autoConnect => $composableBuilder(
      column: $table.autoConnect, builder: (column) => column);
}

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceRow,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceRow, BaseReferences<_$AppDatabase, $DevicesTable, DeviceRow>),
    DeviceRow,
    PrefetchHooks Function()> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> supportedServices = const Value.absent(),
            Value<DateTime> lastConnected = const Value.absent(),
            Value<bool> autoConnect = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            deviceId: deviceId,
            displayName: displayName,
            supportedServices: supportedServices,
            lastConnected: lastConnected,
            autoConnect: autoConnect,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String displayName,
            required String supportedServices,
            required DateTime lastConnected,
            Value<bool> autoConnect = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            deviceId: deviceId,
            displayName: displayName,
            supportedServices: supportedServices,
            lastConnected: lastConnected,
            autoConnect: autoConnect,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceRow,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceRow, BaseReferences<_$AppDatabase, $DevicesTable, DeviceRow>),
    DeviceRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AutolapConfigsTableTableManager get autolapConfigs =>
      $$AutolapConfigsTableTableManager(_db, _db.autolapConfigs);
  $$RidesTableTableManager get rides =>
      $$RidesTableTableManager(_db, _db.rides);
  $$RideTagsTableTableManager get rideTags =>
      $$RideTagsTableTableManager(_db, _db.rideTags);
  $$EffortsTableTableManager get efforts =>
      $$EffortsTableTableManager(_db, _db.efforts);
  $$MapCurvesTableTableManager get mapCurves =>
      $$MapCurvesTableTableManager(_db, _db.mapCurves);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
}
