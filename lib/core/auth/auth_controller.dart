import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../director/director_dashboard_models.dart';
import '../director/director_discovery_models.dart';
import '../director/director_repository.dart';
import '../marketplace/marketplace_models.dart';
import '../profile/profile_models.dart';
import '../uploads/upload_repository.dart';
import '../verification/verification_models.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'role_mapper.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  final ApiClient _client;
  final TokenStore _tokenStore;

  AuthUser? _user;
  String? _refreshToken;
  bool _ready = false;
  String? _kycStatus;

  AuthController({
    required AuthRepository repository,
    required ApiClient client,
    required TokenStore tokenStore,
  })  : _repository = repository,
        _client = client,
        _tokenStore = tokenStore {
    _client.onUnauthorized = _handleUnauthorized;
  }

  /// Wired into [ApiClient.onUnauthorized] so every screen sharing this
  /// client silently recovers from an expired access token instead of each
  /// independently rendering its own "could not load" error.
  Future<String?> _handleUnauthorized() async {
    final token = _refreshToken;
    if (token == null) return null;
    try {
      final session = await _repository.refresh(token);
      await _acceptSession(session);
      return session.tokens.accessToken;
    } on ApiException {
      await clearSession();
      return null;
    }
  }

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null && _refreshToken != null;
  bool get ready => _ready;
  ApiClient get apiClient => _client;

  /// Cached latest KYC submission status: `null` until fetched,
  /// `'not_started'` when the user has no submission yet, otherwise
  /// `'pending' | 'needs_resubmission' | 'rejected' | 'approved'`.
  String? get kycStatus => _kycStatus;
  bool get isKycApproved => _kycStatus == 'approved';

  /// Fetches and caches the user's latest KYC submission status. Safe to
  /// call repeatedly (e.g. from every portal shell build) — callers should
  /// treat `kycStatus == null` as "not yet known" rather than "incomplete".
  Future<String> refreshKycStatus() async {
    if (!isAuthenticated) {
      _kycStatus = null;
      return 'not_started';
    }
    try {
      final submissions = await _repository.myKycSubmissions();
      final status =
          submissions.isEmpty ? 'not_started' : submissions.first.status;
      _kycStatus = status;
      notifyListeners();
      return status;
    } on ApiException {
      // Leave the previous cached value in place on a transient failure.
      return _kycStatus ?? 'not_started';
    }
  }

  String get initialAuthenticatedRoute {
    final roleCode = _user?.primaryRole?.code;
    return RoleMapper.portalRouteForCode(roleCode ?? '') ?? '/portal/dashboard';
  }

  Future<void> initialize() async {
    final access = await _tokenStore.readAccessToken();
    final refresh = await _tokenStore.readRefreshToken();
    _client.accessToken = access;
    _refreshToken = refresh;
    if (refresh != null) {
      try {
        final session = await _repository.refresh(refresh);
        await _acceptSession(session);
      } on ApiException {
        await clearSession();
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bootstrap() {
    return _repository.bootstrap();
  }

  Future<List<AuthRole>> roles() {
    return _repository.roles();
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    await _acceptSession(session);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String initialRole,
  }) async {
    final session = await _repository.register(
      email: email,
      password: password,
      displayName: displayName,
      initialRole: initialRole,
      termsVersion: '2026-07',
    );
    await _acceptSession(session);
  }

  Future<void> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }

  Future<void> logout() async {
    final token = _refreshToken;
    if (token != null) {
      await _repository.logout(token);
    }
    await clearSession();
  }

  Future<void> setPrimaryRole(String roleCode) async {
    _user = await _repository.setPrimaryRole(roleCode);
    notifyListeners();
  }

  Future<UploadedFile> completeDemoUpload({
    required String purpose,
    required String mimeType,
    required String originalName,
    required int sizeBytes,
  }) async {
    final seed = originalName.codeUnits.isEmpty ? [0] : originalName.codeUnits;
    final bytes = Uint8List.fromList(
      List<int>.generate(sizeBytes, (index) => seed[index % seed.length]),
    );
    return uploadFile(
      purpose: purpose,
      file: PickedFileData(
        name: originalName,
        mimeType: mimeType,
        bytes: bytes,
      ),
    );
  }

  Future<UploadedFile> uploadFile({
    required String purpose,
    required PickedFileData file,
    void Function(int sentBytes, int totalBytes)? onProgress,
    void Function(String status)? onStatus,
  }) {
    return UploadRepository(_client).uploadFile(
      purpose: purpose,
      file: file,
      onProgress: onProgress,
      onStatus: onStatus,
    );
  }

  Future<String> authorizedDownloadUrl(String fileId) async {
    final response = await _client.post('/files/$fileId/download-link');
    final data = response['data'] as Map<String, dynamic>;
    return _client.resolve(data['url'] as String).toString();
  }

  Future<KycSubmission> createAndSubmitKyc({
    required String roleCode,
    required List<KycDocumentDraft> documents,
  }) async {
    final created = await _repository.createKycSubmission(
      roleCode: roleCode,
      documents: documents,
    );
    return _repository.submitKycSubmission(created.publicId);
  }

  Future<List<KycSubmission>> myKycSubmissions() {
    return _repository.myKycSubmissions();
  }

  /// Same fetch as [myKycSubmissions], but also updates [kycStatus] from
  /// the result — use this on the verification-status screen (initial
  /// load and "Check Status") so a fresh decision is reflected by the
  /// [kycStatus]-driven banner/guard elsewhere in the app immediately,
  /// instead of only on this one screen until the next login.
  Future<List<KycSubmission>> myKycSubmissionsAndRefreshStatus() async {
    final submissions = await _repository.myKycSubmissions();
    _kycStatus = submissions.isEmpty ? 'not_started' : submissions.first.status;
    notifyListeners();
    return submissions;
  }

  Future<List<KycSubmission>> adminKycSubmissions({String status = 'pending'}) {
    return _repository.adminKycSubmissions(status: status);
  }

  Future<KycSubmission> adminKycSubmission(String publicId) {
    return _repository.adminKycSubmission(publicId);
  }

  Future<KycSubmission> adminKycDecision({
    required String publicId,
    required String decision,
    String? reason,
  }) {
    return _repository.adminKycDecision(
      publicId: publicId,
      decision: decision,
      reason: reason,
    );
  }

  Future<List<ProfileCity>> cities() {
    return _repository.cities();
  }

  Future<UserProfile> myProfile() {
    return _repository.myProfile();
  }

  Future<UserProfile> updateMyProfile({
    required String bio,
    required String? cityId,
    String visibility = 'public',
    String? websiteUrl,
    Map<String, dynamic>? socialLinks,
    String? avatarFileId,
    String? coverFileId,
  }) {
    return _repository.updateMyProfile(
      bio: bio,
      cityId: cityId,
      visibility: visibility,
      websiteUrl: websiteUrl,
      socialLinks: socialLinks,
      avatarFileId: avatarFileId,
      coverFileId: coverFileId,
    );
  }

  Future<TalentProfile> talentProfile() {
    return _repository.talentProfile();
  }

  Future<TalentProfile> updateTalentProfile({
    required String screenName,
    List<TalentLanguage>? languages,
    int? dayRateMinor,
    String? availabilityStatus,
    String? currency,
    String? ageRange,
    String? genderIdentity,
    int? heightCm,
    String? unionNote,
    int? experienceYears,
    String? resumeFileId,
    List<String>? skills,
    List<String>? accents,
    List<String>? specialAbilities,
    Map<String, dynamic>? physicalDetails,
    List<Map<String, dynamic>>? credits,
    List<Map<String, dynamic>>? training,
    Map<String, dynamic>? representation,
    Map<String, dynamic>? socialLinks,
  }) {
    return _repository.updateTalentProfile(
      screenName: screenName,
      languages: languages,
      dayRateMinor: dayRateMinor,
      availabilityStatus: availabilityStatus,
      currency: currency,
      ageRange: ageRange,
      genderIdentity: genderIdentity,
      heightCm: heightCm,
      unionNote: unionNote,
      experienceYears: experienceYears,
      resumeFileId: resumeFileId,
      skills: skills,
      accents: accents,
      specialAbilities: specialAbilities,
      physicalDetails: physicalDetails,
      credits: credits,
      training: training,
      representation: representation,
      socialLinks: socialLinks,
    );
  }

  Future<List<MarketplaceListing>> marketplaceListings({
    String? type,
    String? query,
  }) {
    return _repository.marketplaceListings(type: type, query: query);
  }

  Future<MarketplaceListing> marketplaceListing(String publicId) {
    return _repository.marketplaceListing(publicId);
  }

  Future<MarketplaceListing> publishMarketplaceListing({
    required String title,
    required String summary,
    String? cityId,
    List<String> portfolioItemIds = const [],
  }) {
    return _repository.publishMarketplaceListing(
      title: title,
      summary: summary,
      cityId: cityId,
      portfolioItemIds: portfolioItemIds,
    );
  }

  Future<void> createSavedSearch({
    required String name,
    String? listingType,
    String? queryText,
  }) {
    return _repository.createSavedSearch(
      name: name,
      listingType: listingType,
      queryText: queryText,
    );
  }

  Future<MarketplaceShortlistBundle> shortlistBundle() {
    return _repository.shortlistBundle();
  }

  Future<void> deleteSavedSearch(String publicId) {
    return _repository.deleteSavedSearch(publicId);
  }

  Future<MarketplaceShortlistItem> updateShortlistItem({
    required String publicId,
    int? rank,
    String? status,
    String? notes,
  }) {
    return _repository.updateShortlistItem(
      publicId: publicId,
      rank: rank,
      status: status,
      notes: notes,
    );
  }

  Future<void> deleteShortlistItem(String publicId) {
    return _repository.deleteShortlistItem(publicId);
  }

  Future<List<MarketplacePortfolioItem>> portfolioItems({
    String profileType = 'talent',
  }) {
    return _repository.portfolioItems(profileType: profileType);
  }

  Future<MarketplacePortfolioItem> createPortfolioItem({
    String profileType = 'talent',
    required String title,
    required String category,
    required String fileId,
    int? durationSeconds,
    String status = 'published',
    bool isCover = false,
    int? sortOrder,
  }) {
    return _repository.createPortfolioItem(
      profileType: profileType,
      title: title,
      category: category,
      fileId: fileId,
      durationSeconds: durationSeconds,
      status: status,
      isCover: isCover,
      sortOrder: sortOrder,
    );
  }

  Future<MarketplacePortfolioItem> updatePortfolioItem({
    required String publicId,
    String? title,
    String? category,
    String? fileId,
    int? durationSeconds,
    String? status,
    bool? isCover,
    int? sortOrder,
  }) {
    return _repository.updatePortfolioItem(
      publicId: publicId,
      title: title,
      category: category,
      fileId: fileId,
      durationSeconds: durationSeconds,
      status: status,
      isCover: isCover,
      sortOrder: sortOrder,
    );
  }

  Future<void> deletePortfolioItem(String publicId) {
    return _repository.deletePortfolioItem(publicId);
  }

  Future<void> addToDefaultShortlist(String listingId) {
    return _repository.addToDefaultShortlist(listingId);
  }

  Future<DirectorDashboard> directorDashboard() {
    return DirectorRepository(_client).dashboard();
  }

  Future<DirectorSchedule> directorSchedule({String? projectId}) {
    return DirectorRepository(_client).schedule(projectId: projectId);
  }

  Future<DirectorDiscoveryBundle> directorDiscovery({
    String? category,
    String? query,
  }) {
    return DirectorRepository(_client).discovery(
      category: category,
      query: query,
    );
  }

  Future<DirectorDiscoveryItem> directorDiscoveryItem({
    required String kind,
    required String publicId,
  }) {
    return DirectorRepository(_client).discoveryItem(
      kind: kind,
      publicId: publicId,
    );
  }

  Future<void> clearSession() async {
    _user = null;
    _refreshToken = null;
    _kycStatus = null;
    _client.accessToken = null;
    await _tokenStore.clear();
    notifyListeners();
  }

  Future<void> _acceptSession(AuthSession session) async {
    _user = session.user;
    _refreshToken = session.tokens.refreshToken;
    _client.accessToken = session.tokens.accessToken;
    await _tokenStore.save(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
    );
    notifyListeners();
    // Fire-and-forget: don't hold up login/register/session-restore on this.
    unawaited(refreshKycStatus());
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }
}
