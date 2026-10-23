class DemoAccount {
  final String publicId;
  final String displayName;
  final String email;
  final String status;
  final bool canLogin;

  const DemoAccount({
    required this.publicId,
    required this.displayName,
    required this.email,
    required this.status,
    required this.canLogin,
  });

  factory DemoAccount.fromJson(Map<String, dynamic> json) => DemoAccount(
        publicId: json['public_id'] as String,
        displayName: json['display_name'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
        canLogin: json['can_login'] as bool,
      );
}

class DemoAccountCategory {
  final String code;
  final String name;
  final List<DemoAccount> accounts;

  const DemoAccountCategory({
    required this.code,
    required this.name,
    required this.accounts,
  });

  factory DemoAccountCategory.fromJson(Map<String, dynamic> json) =>
      DemoAccountCategory(
        code: json['code'] as String,
        name: json['name'] as String,
        accounts: (json['accounts'] as List<dynamic>)
            .map((row) => DemoAccount.fromJson(row as Map<String, dynamic>))
            .toList(),
      );
}

class DemoAccountDirectory {
  final int totalAccounts;
  final List<DemoAccountCategory> categories;

  const DemoAccountDirectory({
    required this.totalAccounts,
    required this.categories,
  });

  factory DemoAccountDirectory.fromJson(Map<String, dynamic> json) =>
      DemoAccountDirectory(
        totalAccounts: json['total_accounts'] as int,
        categories: (json['categories'] as List<dynamic>)
            .map((row) =>
                DemoAccountCategory.fromJson(row as Map<String, dynamic>))
            .toList(),
      );
}
