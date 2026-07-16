import 'package:flutter/material.dart';

import '../models/casting_agency_models.dart';
import '../routes/casting_agency_routes.dart';

class CastingAgencyDemoData {
  CastingAgencyDemoData._();

  static const agencyName = 'FrameOne Casting Bureau';
  static const agencyImage =
      'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1400&q=80';

  static const metrics = [
    AgencyMetric(
      label: 'Roster',
      value: '86',
      delta: '12 available now',
      icon: Icons.people_alt_outlined,
      tone: AgencyTone.blue,
      route: CastingAgencyRoutes.roster,
    ),
    AgencyMetric(
      label: 'Auditions',
      value: '12',
      delta: '5 urgent requests',
      icon: Icons.local_activity_outlined,
      tone: AgencyTone.gold,
      route: CastingAgencyRoutes.auditions,
    ),
    AgencyMetric(
      label: 'Submissions',
      value: '28',
      delta: '7 tapes due today',
      icon: Icons.video_collection_outlined,
      tone: AgencyTone.purple,
      route: CastingAgencyRoutes.selfTapes,
    ),
    AgencyMetric(
      label: 'Commission',
      value: '3.4M',
      delta: 'PKR verified quarter',
      icon: Icons.percent_outlined,
      tone: AgencyTone.green,
      route: CastingAgencyRoutes.commission,
    ),
  ];

  static const tasks = [
    AgencyTask(
      id: 'task-shortlist',
      title: 'Submit shortlist for River Lights',
      subtitle: 'Director expects 6 candidates before 6 PM.',
      route: CastingAgencyRoutes.shortlist,
      icon: Icons.view_kanban_outlined,
      tone: AgencyTone.gold,
    ),
    AgencyTask(
      id: 'task-tapes',
      title: 'Review new self-tapes',
      subtitle: 'Three uploads are ready for forwarding.',
      route: CastingAgencyRoutes.selfTapes,
      icon: Icons.play_circle_outline_rounded,
      tone: AgencyTone.purple,
    ),
    AgencyTask(
      id: 'task-commission',
      title: 'Confirm commission split',
      subtitle: 'Metro Hearts advance has partial verification.',
      route: CastingAgencyRoutes.commission,
      icon: Icons.account_balance_wallet_outlined,
      tone: AgencyTone.green,
    ),
    AgencyTask(
      id: 'task-roster',
      title: 'Refresh roster availability',
      subtitle: 'Six linked talent profiles need calendar sync.',
      route: CastingAgencyRoutes.roster,
      icon: Icons.event_available_outlined,
      tone: AgencyTone.blue,
    ),
  ];

  static const roster = [
    AgencyTalent(
      id: 'tal-ayesha',
      name: 'Ayesha Khan',
      category: 'Lead actor',
      city: 'Lahore',
      ageRange: '24-32',
      availability: 'Available Jul 19-28',
      bookings: '14 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?auto=format&fit=crop&w=900&q=80',
      linkedAccount: true,
      status: AgencyStatus.active,
    ),
    AgencyTalent(
      id: 'tal-minal',
      name: 'Minal Raza',
      category: 'Model / TVC',
      city: 'Karachi',
      ageRange: '21-28',
      availability: 'Tentative Jul 22',
      bookings: '9 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
      linkedAccount: true,
      status: AgencyStatus.shortlisted,
    ),
    AgencyTalent(
      id: 'tal-zarar',
      name: 'Zarar Malik',
      category: 'Teen actor',
      city: 'Islamabad',
      ageRange: '15-19',
      availability: 'Parent approval ready',
      bookings: '6 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=900&q=80',
      linkedAccount: false,
      status: AgencyStatus.pending,
    ),
    AgencyTalent(
      id: 'tal-hira',
      name: 'Hira Shah',
      category: 'Dancer / actor',
      city: 'Lahore',
      ageRange: '23-30',
      availability: 'Available weekends',
      bookings: '18 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=80',
      linkedAccount: true,
      status: AgencyStatus.selfTapeReceived,
    ),
    AgencyTalent(
      id: 'tal-daniyal',
      name: 'Daniyal Ahmed',
      category: 'Voice / character',
      city: 'Karachi',
      ageRange: '30-42',
      availability: 'Booked Jul 17',
      bookings: '22 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
      linkedAccount: true,
      status: AgencyStatus.booked,
    ),
    AgencyTalent(
      id: 'tal-saira',
      name: 'Saira Noor',
      category: 'Senior actor',
      city: 'Lahore',
      ageRange: '45-60',
      availability: 'Available after Jul 21',
      bookings: '31 bookings',
      imageUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=900&q=80',
      linkedAccount: false,
      status: AgencyStatus.active,
    ),
  ];

  static const auditions = [
    AgencyAudition(
      id: 'aud-river',
      project: 'River Lights',
      director: 'Maha Productions',
      role: 'Female lead, understated drama, age 25-34',
      dueDate: 'Today 6 PM',
      budget: 'PKR 850K',
      city: 'Lahore',
      status: AgencyStatus.newRequest,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80',
    ),
    AgencyAudition(
      id: 'aud-metro',
      project: 'Metro Hearts',
      director: 'Northstar Films',
      role: 'Two ensemble faces for streaming drama',
      dueDate: 'Jul 18',
      budget: 'PKR 1.2M',
      city: 'Karachi',
      status: AgencyStatus.reviewing,
      imageUrl:
          'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?auto=format&fit=crop&w=1400&q=80',
    ),
    AgencyAudition(
      id: 'aud-nova',
      project: 'Nova Cola Launch',
      director: 'Orbit Ads',
      role: 'Athletic models, dance comfort required',
      dueDate: 'Jul 20',
      budget: 'PKR 540K',
      city: 'Islamabad',
      status: AgencyStatus.selfTapePending,
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1400&q=80',
    ),
    AgencyAudition(
      id: 'aud-northern',
      project: 'Northern Sky',
      director: 'Indus Pictures',
      role: 'Father role and teen supporting actor',
      dueDate: 'Jul 24',
      budget: 'PKR 760K',
      city: 'Hunza',
      status: AgencyStatus.shortlisted,
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const tapes = [
    AgencyTape(
      id: 'tape-ayesha',
      talentId: 'tal-ayesha',
      talentName: 'Ayesha Khan',
      project: 'River Lights',
      duration: '02:18',
      dueDate: 'Ready',
      status: AgencyStatus.selfTapeReceived,
      imageUrl:
          'https://images.unsplash.com/photo-1526948128573-703ee1aeb6fa?auto=format&fit=crop&w=1200&q=80',
      transcript: 'Quiet argument scene with two emotional beats.',
    ),
    AgencyTape(
      id: 'tape-minal',
      talentId: 'tal-minal',
      talentName: 'Minal Raza',
      project: 'Nova Cola Launch',
      duration: '01:06',
      dueDate: 'Due today',
      status: AgencyStatus.selfTapePending,
      imageUrl:
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=1200&q=80',
      transcript: 'Dance intro plus product reaction line.',
    ),
    AgencyTape(
      id: 'tape-zarar',
      talentId: 'tal-zarar',
      talentName: 'Zarar Malik',
      project: 'Northern Sky',
      duration: '01:44',
      dueDate: 'Ready',
      status: AgencyStatus.selfTapeReceived,
      imageUrl:
          'https://images.unsplash.com/photo-1518929458119-e5bf444c30f4?auto=format&fit=crop&w=1200&q=80',
      transcript: 'Teen monologue with Urdu-English switch.',
    ),
    AgencyTape(
      id: 'tape-hira',
      talentId: 'tal-hira',
      talentName: 'Hira Shah',
      project: 'Metro Hearts',
      duration: '02:03',
      dueDate: 'Forwarded',
      status: AgencyStatus.shortlisted,
      imageUrl:
          'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1200&q=80',
      transcript: 'Ensemble chemistry read with movement cue.',
    ),
  ];

  static const notes = [
    AgencySelectionNote(
      id: 'note-ayesha',
      talentId: 'tal-ayesha',
      talentName: 'Ayesha Khan',
      project: 'River Lights',
      note: 'Strong restraint, excellent close-up control.',
      directorFeedback: 'Keep in top three; request wardrobe stills.',
      score: 94,
      status: AgencyStatus.selected,
    ),
    AgencySelectionNote(
      id: 'note-minal',
      talentId: 'tal-minal',
      talentName: 'Minal Raza',
      project: 'Nova Cola Launch',
      note: 'Commercial energy is strong; dance cue needs retake.',
      directorFeedback: 'Ask for one wider framing self-tape.',
      score: 82,
      status: AgencyStatus.reviewing,
    ),
    AgencySelectionNote(
      id: 'note-zarar',
      talentId: 'tal-zarar',
      talentName: 'Zarar Malik',
      project: 'Northern Sky',
      note: 'Natural screen presence and clear guardian approval path.',
      directorFeedback: 'Shortlist pending school schedule.',
      score: 88,
      status: AgencyStatus.shortlisted,
    ),
    AgencySelectionNote(
      id: 'note-daniyal',
      talentId: 'tal-daniyal',
      talentName: 'Daniyal Ahmed',
      project: 'Metro Hearts',
      note: 'Performance skews older than brief.',
      directorFeedback: 'Hold as backup for alternate role.',
      score: 72,
      status: AgencyStatus.rejected,
    ),
  ];

  static const commission = [
    AgencyCommissionItem(
      id: 'com-river',
      talentName: 'Ayesha Khan',
      project: 'River Lights',
      gross: 'PKR 850K',
      commission: 'PKR 127K',
      dueDate: 'Jul 19',
      status: AgencyStatus.paymentPending,
    ),
    AgencyCommissionItem(
      id: 'com-metro',
      talentName: 'Hira Shah',
      project: 'Metro Hearts',
      gross: 'PKR 1.2M',
      commission: 'PKR 180K',
      dueDate: 'Verified',
      status: AgencyStatus.paid,
    ),
    AgencyCommissionItem(
      id: 'com-nova',
      talentName: 'Minal Raza',
      project: 'Nova Cola Launch',
      gross: 'PKR 540K',
      commission: 'PKR 81K',
      dueDate: 'Partial',
      status: AgencyStatus.disputed,
    ),
    AgencyCommissionItem(
      id: 'com-northern',
      talentName: 'Zarar Malik',
      project: 'Northern Sky',
      gross: 'PKR 760K',
      commission: 'PKR 114K',
      dueDate: 'Jul 28',
      status: AgencyStatus.paymentPending,
    ),
  ];

  static const records = [
    AgencyBookingRecord(
      id: 'rec-river',
      talentName: 'Ayesha Khan',
      project: 'River Lights',
      value: 'PKR 850K',
      commission: 'PKR 127K',
      date: 'Jul 19',
      status: AgencyStatus.booked,
    ),
    AgencyBookingRecord(
      id: 'rec-metro',
      talentName: 'Hira Shah',
      project: 'Metro Hearts',
      value: 'PKR 1.2M',
      commission: 'PKR 180K',
      date: 'Jul 12',
      status: AgencyStatus.closed,
    ),
    AgencyBookingRecord(
      id: 'rec-nova',
      talentName: 'Minal Raza',
      project: 'Nova Cola Launch',
      value: 'PKR 540K',
      commission: 'PKR 81K',
      date: 'Jul 21',
      status: AgencyStatus.paymentPending,
    ),
    AgencyBookingRecord(
      id: 'rec-northern',
      talentName: 'Zarar Malik',
      project: 'Northern Sky',
      value: 'PKR 760K',
      commission: 'PKR 114K',
      date: 'Jul 28',
      status: AgencyStatus.shortlisted,
    ),
  ];

  static String statusLabel(AgencyStatus status) {
    return switch (status) {
      AgencyStatus.active => 'Active',
      AgencyStatus.pending => 'Pending',
      AgencyStatus.newRequest => 'New',
      AgencyStatus.reviewing => 'Reviewing',
      AgencyStatus.shortlisted => 'Shortlisted',
      AgencyStatus.selfTapePending => 'Tape Due',
      AgencyStatus.selfTapeReceived => 'Tape Ready',
      AgencyStatus.selected => 'Selected',
      AgencyStatus.rejected => 'Rejected',
      AgencyStatus.booked => 'Booked',
      AgencyStatus.closed => 'Closed',
      AgencyStatus.paymentPending => 'Payment Due',
      AgencyStatus.paid => 'Paid',
      AgencyStatus.disputed => 'Issue',
    };
  }
}

class CastingAgencyDemoStore extends ChangeNotifier {
  CastingAgencyDemoStore._()
      : notes = List.of(CastingAgencyDemoData.notes),
        _selectedTalentIdsByAudition = {
          'aud-river': {
            CastingAgencyDemoData.roster.first.id,
            CastingAgencyDemoData.roster[1].id,
          },
        },
        _auditionStatuses = {
          for (final item in CastingAgencyDemoData.auditions)
            item.id: item.status,
        },
        _tapeStatuses = {
          for (final item in CastingAgencyDemoData.tapes) item.id: item.status,
        },
        _noteStatuses = {
          for (final item in CastingAgencyDemoData.notes) item.id: item.status,
        },
        _commissionStatuses = {
          for (final item in CastingAgencyDemoData.commission)
            item.id: item.status,
        },
        _recordStatuses = {
          for (final item in CastingAgencyDemoData.records)
            item.id: item.status,
        };

  static final instance = CastingAgencyDemoStore._();

  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Set<String> _submittedAuditionIds = {};
  final Map<String, Set<String>> _selectedTalentIdsByAudition;
  final Map<String, String> _shortlistDraftNotes = {};
  final Map<String, AgencyStatus> _auditionStatuses;
  final Map<String, AgencyStatus> _tapeStatuses;
  final Map<String, AgencyStatus> _noteStatuses;
  final Map<String, AgencyStatus> _commissionStatuses;
  final Map<String, AgencyStatus> _recordStatuses;
  List<AgencySelectionNote> notes;

  String rosterFilter = 'All';
  String auditionFilter = 'All';
  String selectedAuditionId = 'aud-river';
  int submittedShortlists = 3;
  int commissionPercent = 15;

  Set<String> get selectedTalentIds =>
      _selectedTalentIdsByAudition.putIfAbsent(selectedAuditionId, () => {});

  bool get currentAuditionSubmitted =>
      _submittedAuditionIds.contains(selectedAuditionId);

  String draftNoteFor(String auditionId) =>
      _shortlistDraftNotes[auditionId] ?? '';

  List<AgencyTask> get activeTasks => CastingAgencyDemoData.tasks
      .where((task) => !completedTasks.contains(task.id))
      .where((task) => !snoozedTasks.contains(task.id))
      .toList();

  AgencyAudition get selectedAudition => CastingAgencyDemoData.auditions
      .firstWhere((item) => item.id == selectedAuditionId);

  AgencyStatus auditionStatus(AgencyAudition audition) {
    return _auditionStatuses[audition.id] ?? audition.status;
  }

  AgencyStatus tapeStatus(AgencyTape tape) {
    return _tapeStatuses[tape.id] ?? tape.status;
  }

  AgencyStatus noteStatus(AgencySelectionNote note) {
    return _noteStatuses[note.id] ?? note.status;
  }

  AgencyStatus commissionStatus(AgencyCommissionItem item) {
    return _commissionStatuses[item.id] ?? item.status;
  }

  AgencyStatus recordStatus(AgencyBookingRecord record) {
    return _recordStatuses[record.id] ?? record.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setRosterFilter(String filter) {
    rosterFilter = filter;
    notifyListeners();
  }

  void setAuditionFilter(String filter) {
    auditionFilter = filter;
    notifyListeners();
  }

  void selectAudition(String id) {
    selectedAuditionId = id;
    notifyListeners();
  }

  void toggleTalent(String id) {
    final set = selectedTalentIds;
    if (!set.remove(id)) set.add(id);
    notifyListeners();
  }

  void reviewAudition(String id) {
    _auditionStatuses[id] = AgencyStatus.reviewing;
    notifyListeners();
  }

  void declineAudition(String id) {
    _auditionStatuses[id] = AgencyStatus.rejected;
    notifyListeners();
  }

  void submitShortlist({bool includeTapes = false}) {
    submittedShortlists++;
    _auditionStatuses[selectedAuditionId] = AgencyStatus.shortlisted;
    _submittedAuditionIds.add(selectedAuditionId);
    if (includeTapes) {
      for (final tape in CastingAgencyDemoData.tapes) {
        if (selectedTalentIds.contains(tape.talentId) &&
            tapeStatus(tape) == AgencyStatus.selfTapeReceived) {
          _tapeStatuses[tape.id] = AgencyStatus.shortlisted;
        }
      }
    }
    notifyListeners();
  }

  void saveShortlistDraft(String auditionId, String note) {
    _shortlistDraftNotes[auditionId] = note;
    notifyListeners();
  }

  void addNote({
    required String talentName,
    required String project,
    required String note,
  }) {
    final id = 'note-custom-${notes.length + 1}';
    notes = [
      ...notes,
      AgencySelectionNote(
        id: id,
        talentId: id,
        talentName: talentName,
        project: project,
        note: note,
        directorFeedback: 'Awaiting director review.',
        score: 75,
        status: AgencyStatus.reviewing,
      ),
    ];
    notifyListeners();
  }

  void requestTape(String id) {
    _tapeStatuses[id] = AgencyStatus.selfTapePending;
    notifyListeners();
  }

  void forwardTape(String id) {
    _tapeStatuses[id] = AgencyStatus.shortlisted;
    notifyListeners();
  }

  void updateNoteStatus(String id, AgencyStatus status) {
    _noteStatuses[id] = status;
    notifyListeners();
  }

  void updateCommissionPercent(int value) {
    commissionPercent = value.clamp(5, 25);
    notifyListeners();
  }

  void verifyCommission(String id) {
    _commissionStatuses[id] = AgencyStatus.paid;
    notifyListeners();
  }

  void flagCommission(String id) {
    _commissionStatuses[id] = AgencyStatus.disputed;
    notifyListeners();
  }

  void closeRecord(String id) {
    _recordStatuses[id] = AgencyStatus.closed;
    notifyListeners();
  }
}
