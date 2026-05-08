import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_entity.dart';
import '../../../../data/local/app_database.dart';

/// Local service for managing categories in SQLite database
class CategoryLocalService {
  // Database table name
  static const String tableName = 'categories';

  /// Get all categories from database
  Future<List<CategoryEntity>> getAllCategories() async {
    try {
      final db = await AppDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'is_deleted = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => CategoryEntity.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting categories: $e');
      return [];
    }
  }

  /// Get category by ID
  Future<CategoryEntity?> getCategoryById(String id) async {
    try {
      final db = await AppDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ? AND is_deleted = ?',
        whereArgs: [id, 0],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return CategoryEntity.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting category by ID: $e');
      return null;
    }
  }

  /// Insert new category
  Future<void> insertCategory(CategoryEntity category) async {
    try {
      final db = await AppDatabase.database;
      await db.insert(
        tableName,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Category inserted: ${category.name}');
    } catch (e) {
      debugPrint('❌ Error inserting category: $e');
      rethrow;
    }
  }

  /// Update existing category
  Future<void> updateCategory(CategoryEntity category) async {
    try {
      final db = await AppDatabase.database;
      await db.update(
        tableName,
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      debugPrint('✅ Category updated: ${category.name}');
    } catch (e) {
      debugPrint('❌ Error updating category: $e');
      rethrow;
    }
  }

  /// Delete category (soft delete)
  Future<void> deleteCategory(String id) async {
    try {
      final db = await AppDatabase.database;
      await db.update(
        tableName,
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Category deleted (soft): $id');
    } catch (e) {
      debugPrint('❌ Error deleting category: $e');
      rethrow;
    }
  }

  /// Search categories by name
  Future<List<CategoryEntity>> searchCategories(String query) async {
    try {
      final db = await AppDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'name LIKE ? AND is_deleted = ?',
        whereArgs: ['%$query%', 0],
        orderBy: 'name ASC',
      );

      return maps.map((map) => CategoryEntity.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error searching categories: $e');
      return [];
    }
  }

  /// Get total categories count
  Future<int> getCategoriesCount() async {
    try {
      final db = await AppDatabase.database;
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE is_deleted = ?',
              [0],
            ),
          ) ??
          0;
    } catch (e) {
      debugPrint('❌ Error getting categories count: $e');
      return 0;
    }
  }

  /// Initialize database with sample data if empty
  Future<void> initializeSampleData() async {
    try {
      final count = await getCategoriesCount();
      if (count == 0) {
        debugPrint('📦 Initializing sample categories...');

        final sampleCategories = [
          CategoryEntity(
            id: '1',
            name: 'Central Components',
            subtitle: '12 products',
            imagePath: 'assets/icons/cpu.png',
            productCount: 12,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoryEntity(
            id: '2',
            name: 'Peripherals',
            subtitle: '8 products',
            imagePath: 'assets/icons/peripheral.png',
            productCount: 8,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoryEntity(
            id: '3',
            name: 'Connectors',
            subtitle: '15 products',
            imagePath: 'assets/icons/connector.png',
            productCount: 15,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoryEntity(
            id: '4',
            name: 'Body',
            subtitle: '6 products',
            imagePath: 'assets/icons/body.png',
            productCount: 6,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoryEntity(
            id: '5',
            name: 'Sensors',
            subtitle: '10 products',
            imagePath: 'assets/icons/sensor.png',
            productCount: 10,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoryEntity(
            id: '6',
            name: 'Tools',
            subtitle: '9 products',
            imagePath: 'assets/icons/tools.png',
            productCount: 9,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        for (final category in sampleCategories) {
          await insertCategory(category);
        }

        debugPrint(
          '✅ Sample categories initialized: ${sampleCategories.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing sample data: $e');
    }
  }
}
