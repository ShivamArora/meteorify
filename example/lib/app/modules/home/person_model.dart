class PersonModel {
  String id;
  String username;
  String name;
  String lastName;
  bool status;

  PersonModel({this.id, this.username, this.name, this.lastName, this.status});

  PersonModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    username = json['username'];
    name = json['name'];
    lastName = json['lastName'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['username'] = this.username;
    data['name'] = this.name;
    data['lastName'] = this.lastName;
    data['status'] = this.status;
    return data;
  }
}
