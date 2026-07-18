class ExpenseModel {
  final int? id;
  final String name;
  final double value;
  final DateTime? date_start;
  final DateTime? date_end;
  final String type;
  final bool isCredit;
  final bool status;

  ExpenseModel({
    this.id,
    required this.name,
    required this.value,
    this.date_start,
    this.date_end,
    required this.type,
    this.isCredit = false,
    this.status = true,
  });

  // 'Object' to 'Map'
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();

    if (id != null) {
      map['id'] = id;
    }

    map['name'] = name;
    map['value'] = value;
    map['date_start'] = date_start?.millisecondsSinceEpoch;
    map['date_end'] = date_end?.millisecondsSinceEpoch;

    map['type'] = type;
    map['is_credit'] = isCredit == true ? 1 : 0;

    return map;
  }

  // 'Map' to 'Object'
  factory ExpenseModel.fromJson(Map<String, dynamic> data) => ExpenseModel(
    id: data['id'],
    name: data['name'],
    value: data['value'],
    date_start: data['date_start'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['date_start'])
        : null,
    date_end: data['date_end'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['date_end'])
        : null,
    type: data['type'],
    isCredit: data['is_credit'] == 1,
  );
}
