import '../../features/director_producer/models/dp_project.dart';
import '../../features/director_producer/models/dp_requirement.dart';
import '../profile/profile_models.dart';
import '../verification/verification_models.dart';

class ProjectSkill {
  final String publicId;
  final String category;
  final String name;
  final bool active;

  const ProjectSkill({
    required this.publicId,
    required this.category,
    required this.name,
    required this.active,
  });

  factory ProjectSkill.fromJson(Map<String, dynamic> json) {
    return ProjectSkill(
      publicId: json['public_id'] as String,
      category: json['category'] as String? ?? 'talent',
      name: json['name'] as String? ?? 'Skill',
      active: json['active'] as bool? ?? true,
    );
  }
}

class ProjectMember {
  final String userId;
  final String displayName;
  final String roleLabel;
  final String status;

  const ProjectMember({
    required this.userId,
    required this.displayName,
    required this.roleLabel,
    required this.status,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return ProjectMember(
      userId: user['public_id'] as String? ?? '',
      displayName: user['display_name'] as String? ?? 'Team member',
      roleLabel: json['role_label'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class ProjectRequirementSkill {
  final ProjectSkill skill;
  final bool required;
  final String? minimumLevel;

  const ProjectRequirementSkill({
    required this.skill,
    required this.required,
    required this.minimumLevel,
  });

  factory ProjectRequirementSkill.fromJson(Map<String, dynamic> json) {
    return ProjectRequirementSkill(
      skill: ProjectSkill.fromJson(json['skill'] as Map<String, dynamic>),
      required: json['required'] as bool? ?? true,
      minimumLevel: json['minimum_level'] as String?,
    );
  }
}

class ProjectRequirement {
  final String publicId;
  final String projectId;
  final String category;
  final String title;
  final String? summary;
  final int? budgetMinMinor;
  final int? budgetMaxMinor;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int candidateCount;
  final List<ProjectRequirementSkill> skills;
  final DateTime? createdAt;

  const ProjectRequirement({
    required this.publicId,
    required this.projectId,
    required this.category,
    required this.title,
    required this.summary,
    required this.budgetMinMinor,
    required this.budgetMaxMinor,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.candidateCount,
    required this.skills,
    required this.createdAt,
  });

  factory ProjectRequirement.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'] as List<dynamic>? ?? const [];
    return ProjectRequirement(
      publicId: json['public_id'] as String,
      projectId: json['project_id'] as String? ?? '',
      category: json['category'] as String? ?? 'talent',
      title: json['title'] as String? ?? 'Untitled requirement',
      summary: json['summary'] as String?,
      budgetMinMinor: json['budget_min_minor'] as int?,
      budgetMaxMinor: json['budget_max_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      startDate: DateTime.tryParse(json['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? ''),
      status: json['status'] as String? ?? 'open',
      candidateCount: json['candidate_count_cache'] as int? ?? 0,
      skills: rawSkills
          .map((item) =>
              ProjectRequirementSkill.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  DpRequirement toDpRequirement() {
    return DpRequirement(
      id: publicId,
      projectId: projectId,
      category: displayCategory,
      title: title,
      summary: summary?.isNotEmpty == true
          ? summary!
          : skills.map((item) => item.skill.name).take(4).join(', '),
      budgetRange: _budgetRange(),
      dates: _dateRange(startDate, endDate),
      candidateCount: candidateCount,
      status: _titleCase(status),
    );
  }

  String get displayCategory {
    return switch (category) {
      'talent' => 'Roles',
      'location' => 'Locations',
      'equipment' => 'Media & Equipment',
      'crew' => 'Crew',
      'service' => 'Crew',
      _ => _titleCase(category),
    };
  }

  String _budgetRange() {
    if (budgetMinMinor == null && budgetMaxMinor == null) {
      return 'Rate TBD';
    }
    final min = budgetMinMinor == null ? null : budgetMinMinor! ~/ 100;
    final max = budgetMaxMinor == null ? null : budgetMaxMinor! ~/ 100;
    if (min != null && max != null) {
      return '$currency ${_short(min)}-${_short(max)}';
    }
    if (min != null) {
      return 'From $currency ${_short(min)}';
    }
    return 'Up to $currency ${_short(max!)}';
  }
}

class Project {
  final String publicId;
  final String title;
  final String projectType;
  final String? description;
  final ProfileCity? city;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int? estimatedBudgetMinor;
  final String currency;
  final String visibility;
  final int progressPercent;
  final int requirementCount;
  final int memberCount;
  final List<ProjectMember> members;
  final List<ProjectRequirement> requirements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.publicId,
    required this.title,
    required this.projectType,
    required this.description,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.estimatedBudgetMinor,
    required this.currency,
    required this.visibility,
    required this.progressPercent,
    required this.requirementCount,
    required this.memberCount,
    required this.members,
    required this.requirements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    final rawRequirements = json['requirements'] as List<dynamic>? ?? const [];
    final cityJson = json['city'] as Map<String, dynamic>?;
    return Project(
      publicId: json['public_id'] as String,
      title: json['title'] as String? ?? 'Untitled project',
      projectType: json['project_type'] as String? ?? 'film',
      description: json['description'] as String?,
      city: cityJson == null ? null : ProfileCity.fromJson(cityJson),
      startDate: DateTime.tryParse(json['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? ''),
      status: json['status'] as String? ?? 'draft',
      estimatedBudgetMinor: json['estimated_budget_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      visibility: json['visibility'] as String? ?? 'private',
      progressPercent: json['progress_percent'] as int? ?? 0,
      requirementCount: json['requirement_count'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? rawMembers.length,
      members: rawMembers
          .map((item) => ProjectMember.fromJson(item as Map<String, dynamic>))
          .toList(),
      requirements: rawRequirements
          .map((item) =>
              ProjectRequirement.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  DpProject toDpProject() {
    final budget =
        estimatedBudgetMinor == null ? 0 : estimatedBudgetMinor! ~/ 100;
    return DpProject(
      id: publicId,
      title: title,
      type: _titleCase(projectType),
      city: city?.name ?? 'Pakistan',
      dateRange: _dateRange(startDate, endDate),
      status: _titleCase(status),
      estimatedBudget: budget,
      confirmedCost: 0,
      budgetHealth: (progressPercent.clamp(0, 100)) / 100,
      pendingActions: requirementCount,
      shootDate: _shortDate(startDate),
      bookingsCount: 0,
      contractsCount: 0,
      paymentsStatus: '$memberCount members',
      team: members.map((item) => item.displayName).toList(),
      progress: (progressPercent.clamp(0, 100)) / 100,
    );
  }
}

class ProjectFile {
  final String publicId;
  final UploadedFile file;
  final String folder;
  final String label;
  final String visibility;
  final int sortOrder;
  final DateTime? createdAt;

  const ProjectFile({
    required this.publicId,
    required this.file,
    required this.folder,
    required this.label,
    required this.visibility,
    required this.sortOrder,
    required this.createdAt,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      publicId: json['public_id'] as String,
      file: UploadedFile.fromJson(json['file'] as Map<String, dynamic>),
      folder: json['folder'] as String? ?? 'briefs',
      label: json['label'] as String? ?? 'Project file',
      visibility: json['visibility'] as String? ?? 'project_members',
      sortOrder: json['sort_order'] as int? ?? 100,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class ProjectRoomItem {
  final String publicId;
  final String itemType;
  final String title;
  final String? body;
  final String? creatorName;
  final DateTime? pinnedAt;
  final DateTime? createdAt;

  const ProjectRoomItem({
    required this.publicId,
    required this.itemType,
    required this.title,
    required this.body,
    required this.creatorName,
    required this.pinnedAt,
    required this.createdAt,
  });

  factory ProjectRoomItem.fromJson(Map<String, dynamic> json) {
    final creator = json['created_by'] as Map<String, dynamic>?;
    return ProjectRoomItem(
      publicId: json['public_id'] as String,
      itemType: json['item_type'] as String? ?? 'note',
      title: json['title'] as String? ?? 'Room item',
      body: json['body'] as String?,
      creatorName: creator?['display_name'] as String?,
      pinnedAt: DateTime.tryParse(json['pinned_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class ProjectRoom {
  final Project project;
  final List<ProjectMember> members;
  final List<ProjectFile> files;
  final List<ProjectRoomItem> items;

  const ProjectRoom({
    required this.project,
    required this.members,
    required this.files,
    required this.items,
  });

  factory ProjectRoom.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    final rawFiles = json['files'] as List<dynamic>? ?? const [];
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ProjectRoom(
      project: Project.fromJson(json['project'] as Map<String, dynamic>),
      members: rawMembers
          .map((item) => ProjectMember.fromJson(item as Map<String, dynamic>))
          .toList(),
      files: rawFiles
          .map((item) => ProjectFile.fromJson(item as Map<String, dynamic>))
          .toList(),
      items: rawItems
          .map((item) => ProjectRoomItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

String _dateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return 'Dates TBD';
  }
  if (start != null && end != null) {
    return '${_shortDate(start)} - ${_shortDate(end)}';
  }
  if (start != null) {
    return 'From ${_shortDate(start)}';
  }
  return 'Until ${_shortDate(end!)}';
}

String _shortDate(DateTime? date) {
  if (date == null) return 'TBD';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _short(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).round()}k';
  return '$value';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
