class Location {
  final String name;

  Location(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Location &&
              runtimeType == other.runtimeType &&
              name == other.name;

  @override
  int get hashCode => name.hashCode;
}