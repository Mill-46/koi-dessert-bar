import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String role;
  final int points;
  final String? avatarUrl;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.points,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        id: map['id'] as String,
        fullName: map['full_name'] as String? ?? '',
        role: map['role'] as String? ?? 'customer',
        points: map['points'] as int? ?? 0,
        avatarUrl: map['avatar_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'role': role,
        'points': points,
        'avatar_url': avatarUrl,
      };

  ProfileModel copyWith({
    String? fullName,
    int? points,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role,
      points: points ?? this.points,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, fullName, role, points, avatarUrl];
}
