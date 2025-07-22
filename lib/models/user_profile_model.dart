enum UserRole { admin, driver }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl; // Optional

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  // Helper to get user initials for the avatar
  String getInitials() {
    if (name.isEmpty) return 'U';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else {
      return parts[0].substring(0, 2).toUpperCase();
    }
  }
}