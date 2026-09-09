import '../network/api_client.dart';
import '../marketplace/marketplace_models.dart';
import '../profile/profile_models.dart';
import '../verification/verification_models.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _client;

  const AuthRepository(this._client);

  Future<List<AuthRole>> roles() async {
    final response = await _client.get('/roles');
    return (response['data'] as List<dynamic>)
        .map((item) => AuthRole.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> bootstrap() {
    return _client.get('/app/bootstrap');
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
    required String initialRole,
    required String termsVersion,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'display_name': displayName,
        'initial_role': initialRole,
        'terms_version': termsVersion,
      },
    );
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthSession.fromJson(response);
  }

  Future<void> logout(String refreshToken) {
    return _client.post('/auth/logout', body: {'refresh_token': refreshToken});
  }

  Future<void> forgotPassword(String email) {
    return _client.post('/auth/password/forgot', body: {'email': email});
  }

  Future<AuthUser> me() async {
    final response = await _client.get('/me');
    return AuthUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> setPrimaryRole(String roleCode) async {
    final response = await _client.patch(
      '/me/primary-role',
      body: {'role': roleCode},
    );
    return AuthUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UploadTicket> presignUpload({
    required String purpose,
    required String mimeType,
    required String originalName,
    required int sizeBytes,
  }) async {
    final response = await _client.post(
      '/uploads/presign',
      body: {
        'purpose': purpose,
        'mime_type': mimeType,
        'original_name': originalName,
        'size_bytes': sizeBytes,
      },
    );
    return UploadTicket.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UploadedFile> completeUpload({
    required String uploadSessionId,
    required int sizeBytes,
    required String checksumSha256,
  }) async {
    final response = await _client.post(
      '/uploads/$uploadSessionId/complete',
      body: {
        'size_bytes': sizeBytes,
        'checksum_sha256': checksumSha256,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return UploadedFile.fromJson(data['file'] as Map<String, dynamic>);
  }

  Future<KycSubmission> createKycSubmission({
    required String roleCode,
    required List<KycDocumentDraft> documents,
  }) async {
    final response = await _client.post(
      '/kyc/submissions',
      body: {
        'role': roleCode,
        'documents': documents.map((item) => item.toJson()).toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return KycSubmission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  Future<KycSubmission> submitKycSubmission(String publicId) async {
    final response = await _client.post('/kyc/submissions/$publicId/submit');
    final data = response['data'] as Map<String, dynamic>;
    return KycSubmission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  Future<List<KycSubmission>> myKycSubmissions() async {
    final response = await _client.get('/me/kyc');
    final data = response['data'] as Map<String, dynamic>;
    return (data['submissions'] as List<dynamic>? ?? const [])
        .map((item) => KycSubmission.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<KycSubmission>> adminKycSubmissions({
    String status = 'pending',
  }) async {
    final response = await _client.get('/admin/kyc/submissions?status=$status');
    final data = response['data'] as Map<String, dynamic>;
    return (data['submissions'] as List<dynamic>? ?? const [])
        .map((item) => KycSubmission.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<KycSubmission> adminKycSubmission(String publicId) async {
    final response = await _client.get('/admin/kyc/submissions/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return KycSubmission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  Future<KycSubmission> adminKycDecision({
    required String publicId,
    required String decision,
    String? reason,
  }) async {
    final response = await _client.post(
      '/admin/kyc/submissions/$publicId/decision',
      body: {
        'decision': decision,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return KycSubmission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  Future<List<ProfileCity>> cities() async {
    final response = await _client.get('/cities');
    final data = response['data'] as Map<String, dynamic>;
    return (data['cities'] as List<dynamic>? ?? const [])
        .map((item) => ProfileCity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> myProfile() async {
    final response = await _client.get('/me/profile');
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateMyProfile({
    required String bio,
    required String? cityId,
    String visibility = 'public',
    String? websiteUrl,
    Map<String, dynamic>? socialLinks,
    String? avatarFileId,
    String? coverFileId,
  }) async {
    final response = await _client.patch(
      '/me/profile',
      body: {
        'bio': bio,
        if (cityId != null) 'city_id': cityId,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (socialLinks != null) 'social_links': socialLinks,
        'profile_visibility': visibility,
        if (avatarFileId != null) 'avatar_file_id': avatarFileId,
        if (coverFileId != null) 'cover_file_id': coverFileId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  Future<TalentProfile> talentProfile() async {
    final response = await _client.get('/talent/profile');
    final data = response['data'] as Map<String, dynamic>;
    return TalentProfile.fromJson(
      data['talent_profile'] as Map<String, dynamic>?,
    );
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
    List<String>? availabilityCategories,
  }) async {
    final response = await _client.patch(
      '/talent/profile',
      body: {
        'screen_name': screenName,
        if (availabilityStatus != null)
          'availability_status': availabilityStatus,
        if (currency != null) 'currency': currency,
        if (dayRateMinor != null) 'day_rate_minor': dayRateMinor,
        if (ageRange != null) 'age_range': ageRange,
        if (genderIdentity != null) 'gender_identity': genderIdentity,
        if (heightCm != null) 'height_cm': heightCm,
        if (unionNote != null) 'union_note': unionNote,
        if (experienceYears != null) 'experience_years': experienceYears,
        if (resumeFileId != null) 'resume_file_id': resumeFileId,
        if (skills != null) 'skills': skills,
        if (accents != null) 'accents': accents,
        if (specialAbilities != null) 'special_abilities': specialAbilities,
        if (physicalDetails != null) 'physical_details': physicalDetails,
        if (credits != null) 'credits': credits,
        if (training != null) 'training': training,
        if (representation != null) 'representation': representation,
        if (socialLinks != null) 'social_links': socialLinks,
        if (availabilityCategories != null)
          'availability_categories': availabilityCategories,
        if (languages != null)
          'languages': languages.map((item) => item.toJson()).toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return TalentProfile.fromJson(
      data['talent_profile'] as Map<String, dynamic>?,
    );
  }

  Future<List<MarketplaceListing>> marketplaceListings({
    String? type,
    String? query,
  }) async {
    final params = <String, String>{};
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (query != null && query.isNotEmpty) params['q'] = query;
    final suffix = params.isEmpty
        ? ''
        : '?${params.entries.map((item) => '${item.key}=${Uri.encodeComponent(item.value)}').join('&')}';
    final response = await _client.get('/marketplace/listings$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['listings'] as List<dynamic>? ?? const [])
        .map(
            (item) => MarketplaceListing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceListing> marketplaceListing(String publicId) async {
    final response = await _client.get('/marketplace/listings/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return MarketplaceListing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  Future<MarketplaceListing> publishMarketplaceListing({
    required String title,
    required String summary,
    String listingType = 'talent',
    String? cityId,
    List<String> portfolioItemIds = const [],
  }) async {
    final response = await _client.post(
      '/marketplace/listings',
      body: {
        'listing_type': listingType,
        'title': title,
        'summary': summary,
        if (cityId != null) 'city_id': cityId,
        if (portfolioItemIds.isNotEmpty) 'portfolio_item_ids': portfolioItemIds,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplaceListing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  Future<void> createSavedSearch({
    required String name,
    String? listingType,
    String? queryText,
  }) {
    return _client.post(
      '/saved-searches',
      body: {
        'name': name,
        if (listingType != null) 'listing_type': listingType,
        if (queryText != null && queryText.isNotEmpty) 'query_text': queryText,
        'filters': <String, String>{},
      },
    );
  }

  Future<List<MarketplaceSavedSearch>> savedSearches() async {
    final response = await _client.get('/saved-searches');
    final data = response['data'] as Map<String, dynamic>;
    return (data['saved_searches'] as List<dynamic>? ?? const [])
        .map((item) =>
            MarketplaceSavedSearch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteSavedSearch(String publicId) {
    return _client.delete('/saved-searches/$publicId');
  }

  Future<List<MarketplaceShortlist>> shortlists() async {
    final response = await _client.get('/shortlists');
    final data = response['data'] as Map<String, dynamic>;
    return (data['shortlists'] as List<dynamic>? ?? const [])
        .map((item) =>
            MarketplaceShortlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceShortlist> createShortlist({
    required String name,
    String? projectId,
    String? requirementId,
  }) async {
    final response = await _client.post(
      '/shortlists',
      body: {
        'name': name,
        if (projectId != null) 'project_id': projectId,
        if (requirementId != null) 'requirement_id': requirementId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplaceShortlist.fromJson(
      data['shortlist'] as Map<String, dynamic>,
    );
  }

  Future<MarketplaceShortlistItem> addShortlistItem({
    required String shortlistId,
    required String listingId,
    String? notes,
  }) async {
    final response = await _client.post(
      '/shortlists/$shortlistId/items',
      body: {
        'listing_id': listingId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplaceShortlistItem.fromJson(
      data['item'] as Map<String, dynamic>,
    );
  }

  Future<MarketplaceShortlistItem> addToProjectShortlist({
    required String listingId,
    required String projectId,
    required String projectTitle,
    String? requirementId,
  }) async {
    final boards = await shortlists();
    MarketplaceShortlist? board;
    for (final candidate in boards) {
      if (candidate.projectId == projectId &&
          candidate.requirementId == requirementId) {
        board = candidate;
        break;
      }
    }
    board ??= await createShortlist(
      name: '$projectTitle shortlist',
      projectId: projectId,
      requirementId: requirementId,
    );
    return addShortlistItem(
      shortlistId: board.publicId,
      listingId: listingId,
    );
  }

  Future<MarketplaceShortlistItem> updateShortlistItem({
    required String publicId,
    int? rank,
    String? status,
    String? notes,
  }) async {
    final response = await _client.patch(
      '/shortlist-items/$publicId',
      body: {
        if (rank != null) 'rank': rank,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplaceShortlistItem.fromJson(
      data['item'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteShortlistItem(String publicId) {
    return _client.delete('/shortlist-items/$publicId');
  }

  Future<MarketplaceShortlistBundle> shortlistBundle() async {
    final searches = await savedSearches();
    final boards = await shortlists();
    return MarketplaceShortlistBundle(
      savedSearches: searches,
      shortlists: boards,
    );
  }

  Future<List<MarketplacePortfolioItem>> portfolioItems({
    String profileType = 'talent',
  }) async {
    final response = await _client.get(
      '/portfolio?profile_type=${Uri.encodeComponent(profileType)}',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) =>
            MarketplacePortfolioItem.fromJson(item as Map<String, dynamic>))
        .toList();
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
  }) async {
    final response = await _client.post(
      '/portfolio',
      body: {
        'profile_type': profileType,
        'title': title,
        'category': category,
        'file_id': fileId,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'status': status,
        'is_cover': isCover,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplacePortfolioItem.fromJson(
      data['item'] as Map<String, dynamic>,
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
  }) async {
    final response = await _client.patch(
      '/portfolio/$publicId',
      body: {
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (fileId != null) 'file_id': fileId,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (status != null) 'status': status,
        if (isCover != null) 'is_cover': isCover,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return MarketplacePortfolioItem.fromJson(
      data['item'] as Map<String, dynamic>,
    );
  }

  Future<void> deletePortfolioItem(String publicId) {
    return _client.delete('/portfolio/$publicId');
  }

  Future<void> addToDefaultShortlist(String listingId) async {
    final listResponse = await _client.get('/shortlists');
    final listData = listResponse['data'] as Map<String, dynamic>;
    final boards = listData['shortlists'] as List<dynamic>? ?? const [];
    String boardId;
    if (boards.isEmpty) {
      final created = await _client.post(
        '/shortlists',
        body: {'name': 'Marketplace shortlist'},
      );
      final data = created['data'] as Map<String, dynamic>;
      final board = data['shortlist'] as Map<String, dynamic>;
      boardId = board['public_id'] as String;
    } else {
      final board = boards.first as Map<String, dynamic>;
      boardId = board['public_id'] as String;
    }
    await _client.post(
      '/shortlists/$boardId/items',
      body: {'listing_id': listingId},
    );
  }
}
