import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DatabaseAdminScreen extends StatefulWidget {
  const DatabaseAdminScreen({super.key});

  @override
  State<DatabaseAdminScreen> createState() => _DatabaseAdminScreenState();
}

class _DatabaseAdminScreenState extends State<DatabaseAdminScreen>
    with SingleTickerProviderStateMixin {
  //late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _allTables = [];
  String _selectedTable = '';
  List<String> _columns = [];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tables = await DatabaseHelper.instance.getAllTables();

      setState(() {
        _allTables = tables;
        if (tables.isNotEmpty) {
          _selectedTable = tables[0];
          _loadTableData(_selectedTable);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل قائمة الجداول: $e');
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _isLoading = true;
      _selectedTable = tableName;
    });

    try {
      final data = await DatabaseHelper.instance.getTableData(tableName);
      final columns = await DatabaseHelper.instance.getTableColumns(tableName);

      setState(() {
        _tableData = data;
        _columns = columns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل بيانات الجدول: $e');
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      await DatabaseHelper.instance.deleteRecordFromTable(_selectedTable, id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السجل بنجاح')),
      );
      _loadTableData(_selectedTable);
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء حذف السجل: $e');
    }
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditRecordDialog(
        record: record,
        columns: _columns,
      ),
    );

    if (result != null) {
      try {
        await DatabaseHelper.instance
            .updateRecordInTable(_selectedTable, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث السجل بنجاح')),
        );
        _loadTableData(_selectedTable);
      } catch (e) {
        _showErrorSnackBar('حدث خطأ أثناء تحديث السجل: $e');
      }
    }
  }

  Future<void> _addNewRecord() async {
    Map<String, dynamic> emptyRecord = {};
    for (String column in _columns) {
      if (column != 'id') {
        emptyRecord[column] = '';
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditRecordDialog(
        record: emptyRecord,
        columns: _columns,
        isNewRecord: true,
      ),
    );

    if (result != null) {
      try {
        await DatabaseHelper.instance
            .insertRecordIntoTable(_selectedTable, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة السجل بنجاح')),
        );
        _loadTableData(_selectedTable);
      } catch (e) {
        _showErrorSnackBar('حدث خطأ أثناء إضافة السجل: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة قاعدة البيانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTableData(_selectedTable),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRecord,
        child: const Icon(Icons.add),
        tooltip: 'إضافة سجل جديد',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTableSelector(),
                Expanded(
                  child: _buildDataTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'اختر الجدول',
          border: OutlineInputBorder(),
        ),
        value: _selectedTable.isEmpty ? null : _selectedTable,
        items: _allTables.map((table) {
          return DropdownMenuItem<String>(
            value: table,
            child: Text(table),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _loadTableData(value);
          }
        },
      ),
    );
  }

  Widget _buildDataTable() {
    if (_tableData.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات في هذا الجدول'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('#')),
            ..._columns.map((column) => DataColumn(label: Text(column))),
            const DataColumn(label: Text('إجراءات')),
          ],
          rows: _tableData.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                ..._columns.map((column) {
                  final value = record[column];
                  return DataCell(
                    Text(value != null ? value.toString() : 'null'),
                  );
                }),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editRecord(record),
                        tooltip: 'تعديل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text(
                                'هل أنت متأكد من حذف هذا السجل؟ لا يمكن التراجع عن هذا الإجراء.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteRecord(record['id']);
                                  },
                                  child: const Text('حذف'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'حذف',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EditRecordDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<String> columns;
  final bool isNewRecord;

  const _EditRecordDialog({
    required this.record,
    required this.columns,
    this.isNewRecord = false,
  });

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
  late Map<String, dynamic> _editedRecord;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _editedRecord = Map.from(widget.record);

    for (String column in widget.columns) {
      if (column != 'id') {
        final value = _editedRecord[column]?.toString() ?? '';
        _controllers[column] = TextEditingController(text: value);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNewRecord ? 'إضافة سجل جديد' : 'تعديل السجل'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.columns.map((column) {
            if (column == 'id' && !widget.isNewRecord) {
              return ListTile(
                title: Text('ID'),
                subtitle: Text(_editedRecord[column]?.toString() ?? ''),
              );
            } else if (column != 'id') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _controllers[column],
                  decoration: InputDecoration(
                    labelText: column,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // حاول تحديد نوع البيانات المناسب (رقم، نص، إلخ)
                    _editedRecord[column] =
                        _tryParseValue(value, _editedRecord[column]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            // حدث القيم النهائية من وحدات التحكم في النص
            for (String column in widget.columns) {
              if (column != 'id') {
                _editedRecord[column] = _tryParseValue(
                  _controllers[column]!.text,
                  _editedRecord[column],
                );
              }
            }
            Navigator.pop(context, _editedRecord);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  // محاولة تحويل القيمة إلى النوع المناسب
  dynamic _tryParseValue(String value, dynamic originalValue) {
    if (value.isEmpty) return value;

    // محاولة تحويل إلى رقم صحيح
    int? intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // محاولة تحويل إلى رقم عشري
    double? doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;

    // محاولة تحويل إلى قيمة منطقية
    if (value.toLowerCase() == 'true') return 1;
    if (value.toLowerCase() == 'false') return 0;

    // إذا كان النوع الأصلي هو قيمة منطقية ولكن كقيمة 0 أو 1
    if (originalValue == 0 || originalValue == 1) {
      int? boolAsInt = int.tryParse(value);
      if (boolAsInt == 0 || boolAsInt == 1) {
        return boolAsInt;
      }
    }

    // محاولة تحويل إلى تاريخ
    DateTime? dateValue = DateTime.tryParse(value);
    if (dateValue != null) return dateValue.toIso8601String();

    // إرجاع كنص إذا لم تتمكن من تحويله إلى أنواع أخرى
    return value;
  }
}
