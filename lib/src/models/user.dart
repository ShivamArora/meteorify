class User{
  String _id;
  String _username;
  List<UserEmail> _emails;
  DateTime _createdAt;
  Map<String, dynamic> _profile;
  Map<String, dynamic> _services;
}

class UserEmail{
  String _address;
  bool _verified;
}