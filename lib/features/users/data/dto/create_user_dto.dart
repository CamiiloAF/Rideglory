class CreateUserDto {
  const CreateUserDto({required this.fullName, required this.email});

  final String fullName;
  final String email;

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'email': email};
  }
}
