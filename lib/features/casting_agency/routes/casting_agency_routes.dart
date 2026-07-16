class CastingAgencyRoutes {
  CastingAgencyRoutes._();

  static const home = '/agency';
  static const roster = '/agency/roster';
  static const auditions = '/agency/auditions';
  static const shortlist = '/agency/shortlist';
  static const selfTapes = '/agency/self-tapes';
  static const notes = '/agency/selection-notes';
  static const commission = '/agency/commission';
  static const records = '/agency/records';

  static const primaryNav = [
    home,
    roster,
    auditions,
    selfTapes,
    records,
  ];

  static const allRoutes = [
    home,
    roster,
    auditions,
    shortlist,
    selfTapes,
    notes,
    commission,
    records,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Agency Dashboard',
      roster => 'Talent Roster Manager',
      auditions => 'Audition Request Inbox',
      shortlist => 'Candidate Shortlist Builder',
      selfTapes => 'Self-Tape Collection',
      notes => 'Interview & Selection Notes',
      commission => 'Commission Settings & Records',
      records => 'Agency Booking Records',
      _ => 'Casting Agency',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'CA-01',
      roster => 'CA-02',
      auditions => 'CA-03',
      shortlist => 'CA-04',
      selfTapes => 'CA-05',
      notes => 'CA-06',
      commission => 'CA-07',
      records => 'CA-08',
      _ => 'CA',
    };
  }
}
