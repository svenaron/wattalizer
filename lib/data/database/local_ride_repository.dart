import 'package:drift/drift.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

class LocalRideRepository implements RideRepository {
  LocalRideRepository(this._db);
  final AppDatabase _db;

  // --- Transactions ---

  @override
  Future<void> transaction(Future<void> Function() work) async {
    await _db.transaction(work);
  }

  // --- Private Helpers ---

  RideSummary _summaryFromRow(RideRow row) {
    return RideSummary(
      durationSeconds: row.durationSeconds,
      activeDurationSeconds: row.activeDurationSeconds,
      avgPower: row.avgPower,
      maxPower: row.maxPower,
      avgHeartRate: row.avgHeartRate,
      maxHeartRate: row.maxHeartRate,
      avgCadence: row.avgCadence,
      totalKilojoules: row.totalKilojoules,
      avgLeftRightBalance: row.avgLeftRightBalance,
      readingCount: row.readingCount,
      effortCount: row.effortCount,
    );
  }

  Future<List<String>> _getTagsForRide(String rideId) async {
    final rows = await (_db.select(
      _db.rideTags,
    )..where((t) => t.rideId.equals(rideId)))
        .get();
    return rows.map((r) => r.tag).toList();
  }

  /// Returns the set of ride IDs that have ALL of the given tags (AND logic).
  Future<Set<String>> _getRideIdsWithAllTags(Set<String> tags) async {
    final normalized = tags
        .map((t) => t.toLowerCase().trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (normalized.isEmpty) return {};
    final placeholders = normalized.map((_) => '?').join(', ');
    final rows = await _db.customSelect(
      'SELECT ride_id FROM ride_tags '
      'WHERE tag IN ($placeholders) '
      'GROUP BY ride_id '
      'HAVING COUNT(DISTINCT tag) = ?',
      variables: [
        ...normalized.map(Variable.withString),
        Variable.withInt(normalized.length),
      ],
    ).get();
    return rows.map((r) => r.read<String>('ride_id')).toSet();
  }

  Future<List<Effort>> _loadEffortsForRide(String rideId) async {
    final effortRows = await (_db.select(_db.efforts)
          ..where((t) => t.rideId.equals(rideId))
          ..orderBy([(t) => OrderingTerm.asc(t.effortNumber)]))
        .get();
    if (effortRows.isEmpty) return [];

    final effortIds = effortRows.map((e) => e.id).toList();
    final curveRows = await (_db.select(
      _db.mapCurves,
    )..where((t) => t.effortId.isIn(effortIds)))
        .get();

    final curvesByEffort = <String, List<MapCurveRow>>{};
    for (final row in curveRows) {
      curvesByEffort.putIfAbsent(row.effortId, () => []).add(row);
    }

    return effortRows.map((effortRow) {
      final curves = curvesByEffort[effortRow.id] ?? [];
      return Effort.fromRow(effortRow, MapCurve.fromRows(effortRow.id, curves));
    }).toList();
  }

  List<RideTagsCompanion> _buildTagCompanions(
    String rideId,
    List<String> tags,
  ) {
    return tags
        .map((t) => t.toLowerCase().trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .map((t) => RideTagsCompanion.insert(rideId: rideId, tag: t))
        .toList();
  }

  // --- Ride CRUD ---

  @override
  Future<int> getRideCount() async {
    final result =
        await _db.customSelect('SELECT COUNT(*) AS c FROM rides').getSingle();
    return result.read<int>('c');
  }

  @override
  Future<void> saveRide(Ride ride) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.rides).insert(ride.toCompanion());

        final tagCompanions = _buildTagCompanions(ride.id, ride.tags);
        if (tagCompanions.isNotEmpty) {
          await _db.batch((b) {
            b.insertAll(_db.rideTags, tagCompanions);
          });
        }

        // Efforts and map_curves are persisted separately by the caller
        // (e.g. RideSessionManager.end() calls saveEfforts + saveMapCurve).
      });
    } catch (e) {
      throw DatabaseError(operation: 'save_ride', detail: e.toString());
    }
  }

  @override
  Future<void> updateRide(Ride ride) async {
    try {
      await _db.transaction(() async {
        await (_db.update(_db.rides)..where((t) => t.id.equals(ride.id))).write(
          RidesCompanion(
            notes: Value(ride.notes),
            effortCount: Value(ride.summary.effortCount),
            autoLapConfigId: Value.absentIfNull(ride.autoLapConfigId),
          ),
        );

        await (_db.delete(
          _db.rideTags,
        )..where((t) => t.rideId.equals(ride.id)))
            .go();

        final tagCompanions = _buildTagCompanions(ride.id, ride.tags);
        if (tagCompanions.isNotEmpty) {
          await _db.batch((b) {
            b.insertAll(_db.rideTags, tagCompanions);
          });
        }
      });
    } catch (e) {
      throw DatabaseError(operation: 'update_ride', detail: e.toString());
    }
  }

  @override
  Future<Ride?> getRide(String id) async {
    try {
      final row = await (_db.select(
        _db.rides,
      )..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) return null;
      final tags = await _getTagsForRide(id);
      final efforts = await _loadEffortsForRide(id);
      return Ride.fromRow(row, tags, efforts);
    } catch (e) {
      throw DatabaseError(operation: 'get_ride', detail: e.toString());
    }
  }

  @override
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  }) async {
    try {
      Set<String>? allowedRideIds;
      if (tags != null && tags.isNotEmpty) {
        allowedRideIds = await _getRideIdsWithAllTags(tags);
        if (allowedRideIds.isEmpty) return [];
      }

      final query = _db.select(_db.rides)
        ..where((t) {
          final conditions = <Expression<bool>>[];
          if (from != null) {
            conditions.add(t.startTime.isBiggerOrEqualValue(from));
          }
          if (to != null) {
            conditions.add(t.startTime.isSmallerOrEqualValue(to));
          }
          if (allowedRideIds != null) {
            conditions.add(t.id.isIn(allowedRideIds.toList()));
          }
          if (conditions.isEmpty) return const Constant(true);
          return Expression.and(conditions);
        })
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)]);

      if (limit != null) {
        query.limit(limit, offset: offset > 0 ? offset : null);
      } else if (offset > 0) {
        query.limit(-1, offset: offset);
      }

      final rows = await query.get();
      if (rows.isEmpty) return [];

      final rideIds = rows.map((r) => r.id).toList();
      final allTagRows = await (_db.select(
        _db.rideTags,
      )..where((t) => t.rideId.isIn(rideIds)))
          .get();
      final tagsByRide = <String, List<String>>{};
      for (final tagRow in allTagRows) {
        tagsByRide.putIfAbsent(tagRow.rideId, () => []).add(tagRow.tag);
      }

      return rows.map((row) {
        return RideSummaryRow(
          id: row.id,
          startTime: row.startTime,
          tags: tagsByRide[row.id] ?? [],
          summary: _summaryFromRow(row),
        );
      }).toList();
    } catch (e) {
      throw DatabaseError(operation: 'get_rides', detail: e.toString());
    }
  }

  @override
  Future<void> deleteRide(String id) async {
    try {
      await _db.transaction(() async {
        final effortRows = await (_db.select(
          _db.efforts,
        )..where((t) => t.rideId.equals(id)))
            .get();
        final effortIds = effortRows.map((e) => e.id).toList();

        if (effortIds.isNotEmpty) {
          await (_db.delete(
            _db.mapCurves,
          )..where((t) => t.effortId.isIn(effortIds)))
              .go();
        }
        // Delete ride-level PDC stored in map_curves
        // (rideId used as effortId key)
        await (_db.delete(
          _db.mapCurves,
        )..where((t) => t.effortId.equals(id)))
            .go();

        await (_db.delete(
          _db.readings,
        )..where((t) => t.rideId.equals(id)))
            .go();
        await (_db.delete(
          _db.rideTags,
        )..where((t) => t.rideId.equals(id)))
            .go();
        await (_db.delete(_db.efforts)..where((t) => t.rideId.equals(id))).go();
        await (_db.delete(_db.rides)..where((t) => t.id.equals(id))).go();
      });
    } catch (e) {
      throw DatabaseError(operation: 'delete_ride', detail: e.toString());
    }
  }

  // --- Readings ---

  @override
  Future<List<SensorReading>> getReadings(
    String rideId, {
    int? startOffset,
    int? endOffset,
  }) async {
    try {
      final query = _db.select(_db.readings)
        ..where((t) {
          final conditions = <Expression<bool>>[t.rideId.equals(rideId)];
          if (startOffset != null) {
            conditions.add(t.offsetSeconds.isBiggerOrEqualValue(startOffset));
          }
          if (endOffset != null) {
            conditions.add(t.offsetSeconds.isSmallerOrEqualValue(endOffset));
          }
          return Expression.and(conditions);
        })
        ..orderBy([(t) => OrderingTerm.asc(t.offsetSeconds)]);
      final rows = await query.get();
      return rows.map(SensorReading.fromRow).toList();
    } catch (e) {
      throw DatabaseError(operation: 'get_readings', detail: e.toString());
    }
  }

  @override
  Future<void> insertReadings(
    String rideId,
    List<SensorReading> readings,
  ) async {
    try {
      await _db.transaction(() async {
        await _db.batch((b) {
          b.insertAll(
            _db.readings,
            readings.map((r) => r.toCompanion(rideId)).toList(),
          );
        });
      });
    } catch (e) {
      throw DatabaseError(operation: 'insert_readings', detail: e.toString());
    }
  }

  // --- Efforts ---

  @override
  Future<List<Effort>> getEfforts(String rideId) async {
    try {
      return _loadEffortsForRide(rideId);
    } catch (e) {
      throw DatabaseError(operation: 'get_efforts', detail: e.toString());
    }
  }

  @override
  Future<void> saveEfforts(String rideId, List<Effort> efforts) async {
    try {
      await _db.transaction(() async {
        final existing = await (_db.select(
          _db.efforts,
        )..where((t) => t.rideId.equals(rideId)))
            .get();
        final existingIds = existing.map((e) => e.id).toList();

        if (existingIds.isNotEmpty) {
          await (_db.delete(
            _db.mapCurves,
          )..where((t) => t.effortId.isIn(existingIds)))
              .go();
        }
        await (_db.delete(
          _db.efforts,
        )..where((t) => t.rideId.equals(rideId)))
            .go();

        for (final effort in efforts) {
          await _db.into(_db.efforts).insert(effort.toCompanion());
          await _db.batch((b) {
            b.insertAll(_db.mapCurves, effort.mapCurve.toCompanions());
          });
        }
      });
    } catch (e) {
      throw DatabaseError(operation: 'save_efforts', detail: e.toString());
    }
  }

  @override
  Future<void> deleteEfforts(String rideId) async {
    try {
      await _db.transaction(() async {
        final effortRows = await (_db.select(
          _db.efforts,
        )..where((t) => t.rideId.equals(rideId)))
            .get();
        final effortIds = effortRows.map((e) => e.id).toList();

        if (effortIds.isNotEmpty) {
          await (_db.delete(
            _db.mapCurves,
          )..where((t) => t.effortId.isIn(effortIds)))
              .go();
        }
        await (_db.delete(
          _db.efforts,
        )..where((t) => t.rideId.equals(rideId)))
            .go();
      });
    } catch (e) {
      throw DatabaseError(operation: 'delete_efforts', detail: e.toString());
    }
  }

  // --- MAP Curves ---

  @override
  Future<void> saveMapCurve(String entityId, MapCurve curve) async {
    try {
      await _db.batch((b) {
        b.insertAll(_db.mapCurves, curve.toCompanions());
      });
    } catch (e) {
      throw DatabaseError(operation: 'save_map_curve', detail: e.toString());
    }
  }

  @override
  Future<MapCurve?> getMapCurve(String entityId) async {
    try {
      final rows = await (_db.select(
        _db.mapCurves,
      )..where((t) => t.effortId.equals(entityId)))
          .get();
      if (rows.isEmpty) return null;
      return MapCurve.fromRows(entityId, rows);
    } catch (e) {
      throw DatabaseError(operation: 'get_map_curve', detail: e.toString());
    }
  }

  @override
  Future<List<MapCurve>> getMapCurvesForRide(String rideId) async {
    try {
      final effortRows = await (_db.select(
        _db.efforts,
      )..where((t) => t.rideId.equals(rideId)))
          .get();
      if (effortRows.isEmpty) return [];

      final effortIds = effortRows.map((e) => e.id).toList();
      final curveRows = await (_db.select(
        _db.mapCurves,
      )..where((t) => t.effortId.isIn(effortIds)))
          .get();

      final curvesByEffort = <String, List<MapCurveRow>>{};
      for (final row in curveRows) {
        curvesByEffort.putIfAbsent(row.effortId, () => []).add(row);
      }

      return effortIds
          .map((id) => MapCurve.fromRows(id, curvesByEffort[id] ?? []))
          .toList();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_map_curves_for_ride',
        detail: e.toString(),
      );
    }
  }

  @override
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  }) async {
    try {
      Set<String>? allowedRideIds;
      if (tags != null && tags.isNotEmpty) {
        allowedRideIds = await _getRideIdsWithAllTags(tags);
        if (allowedRideIds.isEmpty) return [];
      }

      final join = _db.select(_db.efforts).join([
        innerJoin(_db.rides, _db.rides.id.equalsExp(_db.efforts.rideId)),
      ]);

      final conditions = <Expression<bool>>[];
      if (from != null) {
        conditions.add(_db.rides.startTime.isBiggerOrEqualValue(from));
      }
      if (to != null) {
        conditions.add(_db.rides.startTime.isSmallerOrEqualValue(to));
      }
      if (allowedRideIds != null) {
        conditions.add(_db.efforts.rideId.isIn(allowedRideIds.toList()));
      }
      if (conditions.isNotEmpty) {
        join.where(Expression.and(conditions));
      }

      final joinRows = await join.get();
      if (joinRows.isEmpty) return [];

      final provenanceList = joinRows.map((row) {
        final effort = row.readTable(_db.efforts);
        final ride = row.readTable(_db.rides);
        return (
          effortId: effort.id,
          effortNumber: effort.effortNumber,
          rideId: ride.id,
          rideDate: ride.startTime,
        );
      }).toList();

      final effortIds = provenanceList.map((p) => p.effortId).toList();
      final curveRows = await (_db.select(
        _db.mapCurves,
      )..where((t) => t.effortId.isIn(effortIds)))
          .get();

      final curvesByEffort = <String, List<MapCurveRow>>{};
      for (final row in curveRows) {
        curvesByEffort.putIfAbsent(row.effortId, () => []).add(row);
      }

      return provenanceList
          .where((p) => curvesByEffort.containsKey(p.effortId))
          .map(
            (p) => MapCurveWithProvenance(
              effortId: p.effortId,
              rideId: p.rideId,
              rideDate: p.rideDate,
              effortNumber: p.effortNumber,
              curve: MapCurve.fromRows(p.effortId, curvesByEffort[p.effortId]!),
            ),
          )
          .toList();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_all_effort_curves',
        detail: e.toString(),
      );
    }
  }

  // --- Tags ---

  @override
  Future<List<String>> getAllTags() async {
    try {
      final rows = await _db
          .customSelect('SELECT DISTINCT tag FROM ride_tags ORDER BY tag ASC')
          .get();
      return rows.map((r) => r.read<String>('tag')).toList();
    } catch (e) {
      throw DatabaseError(operation: 'get_all_tags', detail: e.toString());
    }
  }

  // --- Ride-level PDC ---

  @override
  Future<void> saveRidePdc(String rideId, MapCurve curve) async {
    try {
      await _db.transaction(() async {
        // Remove any existing PDC for this ride (rideId used as effortId key)
        await (_db.delete(
          _db.mapCurves,
        )..where((t) => t.effortId.equals(rideId)))
            .go();
        await _db.batch((b) {
          b.insertAll(_db.mapCurves, curve.toCompanions());
        });
      });
    } catch (e) {
      throw DatabaseError(operation: 'save_ride_pdc', detail: e.toString());
    }
  }

  @override
  Future<MapCurve?> getRidePdc(String rideId) async {
    return getMapCurve(rideId);
  }

  // --- AutoLap Config ---

  @override
  Future<List<AutoLapConfig>> getAutoLapConfigs() async {
    try {
      final rows = await _db.select(_db.autolapConfigs).get();
      return rows.map(AutoLapConfig.fromRow).toList();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_autolap_configs',
        detail: e.toString(),
      );
    }
  }

  @override
  Future<AutoLapConfig> getDefaultConfig() async {
    try {
      final row = await (_db.select(
        _db.autolapConfigs,
      )..where((t) => t.isDefault.equals(true)))
          .getSingleOrNull();
      return row != null
          ? AutoLapConfig.fromRow(row)
          : AutoLapConfig.flying200();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_default_config',
        detail: e.toString(),
      );
    }
  }

  @override
  Future<void> saveAutoLapConfig(AutoLapConfig config) async {
    try {
      await _db.transaction(() async {
        if (config.isDefault) {
          await (_db.update(_db.autolapConfigs)
                ..where((t) => t.isDefault.equals(true)))
              .write(const AutolapConfigsCompanion(isDefault: Value(false)));
        }
        await _db
            .into(_db.autolapConfigs)
            .insertOnConflictUpdate(config.toCompanion());
      });
    } catch (e) {
      throw DatabaseError(
        operation: 'save_autolap_config',
        detail: e.toString(),
      );
    }
  }

  // --- Devices ---

  @override
  Future<List<DeviceInfo>> getRememberedDevices() async {
    try {
      final rows = await _db.select(_db.devices).get();
      return rows.map(DeviceInfo.fromRow).toList();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_remembered_devices',
        detail: e.toString(),
      );
    }
  }

  @override
  Future<void> saveDevice(DeviceInfo device) async {
    try {
      await _db.into(_db.devices).insertOnConflictUpdate(device.toCompanion());
    } catch (e) {
      throw DatabaseError(operation: 'save_device', detail: e.toString());
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    try {
      await (_db.delete(
        _db.devices,
      )..where((t) => t.deviceId.equals(deviceId)))
          .go();
    } catch (e) {
      throw DatabaseError(operation: 'delete_device', detail: e.toString());
    }
  }

  @override
  Future<List<DeviceInfo>> getAutoConnectDevices() async {
    try {
      final rows = await (_db.select(
        _db.devices,
      )..where((t) => t.autoConnect.equals(true)))
          .get();
      return rows.map(DeviceInfo.fromRow).toList();
    } catch (e) {
      throw DatabaseError(
        operation: 'get_auto_connect_devices',
        detail: e.toString(),
      );
    }
  }
}
