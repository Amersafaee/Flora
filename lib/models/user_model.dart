class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String avatarUrl;
  final int plantCount;
  final String zone;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.plantCount,
    required this.zone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'plantCount': plantCount,
      'zone': zone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      plantCount: map['plantCount'] ?? 0,
      zone: map['zone'] ?? '',
    );
  }
}

