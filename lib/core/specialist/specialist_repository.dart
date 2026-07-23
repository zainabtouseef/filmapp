import '../network/api_client.dart';
import 'specialist_models.dart';

class SpecialistRepository {
  final ApiClient _client;

  const SpecialistRepository(this._client);

  Future<AgencyProfileDto?> agencyProfile() async {
    final response = await _client.get('/agencies/profile');
    final data = response['data'] as Map<String, dynamic>;
    final agency = data['agency'] as Map<String, dynamic>?;
    return agency == null ? null : AgencyProfileDto.fromJson(agency);
  }

  Future<AgencyProfileDto> upsertAgencyProfile(
      Map<String, dynamic> body) async {
    final response = await _client.patch('/agencies/profile', body: body);
    return AgencyProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['agency']
          as Map<String, dynamic>,
    );
  }

  Future<AgencyInvitationDto> createAgencyInvitation(
      Map<String, dynamic> body) async {
    final response = await _client.post('/agency-invitations', body: body);
    return AgencyInvitationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['invitation']
          as Map<String, dynamic>,
    );
  }

  Future<List<AgencyInvitationDto>> agencyInvitations() async {
    final response = await _client.get('/agency-invitations');
    final data = response['data'] as Map<String, dynamic>;
    return (data['invitations'] as List<dynamic>? ?? const [])
        .map((item) =>
            AgencyInvitationDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AgencyTalentDto>> agencyRoster(String agencyId) async {
    final response = await _client.get('/agencies/$agencyId/talent');
    final data = response['data'] as Map<String, dynamic>;
    return (data['talent'] as List<dynamic>? ?? const [])
        .map((item) => AgencyTalentDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuditionDto>> auditions() async {
    final response = await _client.get('/auditions');
    final data = response['data'] as Map<String, dynamic>;
    return (data['auditions'] as List<dynamic>? ?? const [])
        .map((item) => AuditionDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AuditionDto> createAudition(Map<String, dynamic> body) async {
    final response = await _client.post('/auditions', body: body);
    return AuditionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['audition']
          as Map<String, dynamic>,
    );
  }

  Future<AuditionDto> updateAudition(
      String auditionId, Map<String, dynamic> body) async {
    final response = await _client.patch('/auditions/$auditionId', body: body);
    return AuditionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['audition']
          as Map<String, dynamic>,
    );
  }

  Future<AuditionDto> addAuditionCandidate(
      String auditionId, Map<String, dynamic> body) async {
    final response =
        await _client.post('/auditions/$auditionId/candidates', body: body);
    return AuditionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['audition']
          as Map<String, dynamic>,
    );
  }

  Future<AuditionCandidateDto> updateAuditionCandidate(
      String candidateId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/audition-candidates/$candidateId', body: body);
    return AuditionCandidateDto.fromJson(
      (response['data'] as Map<String, dynamic>)['candidate']
          as Map<String, dynamic>,
    );
  }

  Future<AuditionCandidateDto> addSelectionNote(
      String candidateId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/audition-candidates/$candidateId/notes',
      body: body,
    );
    return AuditionCandidateDto.fromJson(
      (response['data'] as Map<String, dynamic>)['candidate']
          as Map<String, dynamic>,
    );
  }

  Future<AgencyCommissionDto> createAgencyCommission(
      Map<String, dynamic> body) async {
    final response = await _client.post('/agency-commissions', body: body);
    return AgencyCommissionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['commission']
          as Map<String, dynamic>,
    );
  }

  Future<List<AgencyCommissionDto>> agencyCommissions(String agencyId) async {
    final response = await _client.get('/agencies/$agencyId/commissions');
    final data = response['data'] as Map<String, dynamic>;
    return (data['commissions'] as List<dynamic>? ?? const [])
        .map((item) =>
            AgencyCommissionDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BrandProfileDto?> brandProfile() async {
    final response = await _client.get('/brands/profile');
    final data = response['data'] as Map<String, dynamic>;
    final brand = data['brand'] as Map<String, dynamic>?;
    return brand == null ? null : BrandProfileDto.fromJson(brand);
  }

  Future<BrandProfileDto> upsertBrandProfile(Map<String, dynamic> body) async {
    final response = await _client.patch('/brands/profile', body: body);
    return BrandProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['brand']
          as Map<String, dynamic>,
    );
  }

  Future<BrandOpportunityDto> createBrandOpportunity(
      Map<String, dynamic> body) async {
    final response = await _client.post('/brand-opportunities', body: body);
    return BrandOpportunityDto.fromJson(
      (response['data'] as Map<String, dynamic>)['opportunity']
          as Map<String, dynamic>,
    );
  }

  Future<BrandOpportunityDto> updateBrandOpportunity(
    String opportunityId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/brand-opportunities/$opportunityId',
      body: body,
    );
    return BrandOpportunityDto.fromJson(
      (response['data'] as Map<String, dynamic>)['opportunity']
          as Map<String, dynamic>,
    );
  }

  Future<List<BrandOpportunityDto>> brandOpportunities({
    bool mine = true,
  }) async {
    final response =
        await _client.get('/brand-opportunities${mine ? '?mine=1' : ''}');
    final data = response['data'] as Map<String, dynamic>;
    return (data['opportunities'] as List<dynamic>? ?? const [])
        .map((item) =>
            BrandOpportunityDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BrandOpportunityDto> brandOpportunity(String opportunityId) async {
    final response = await _client.get('/brand-opportunities/$opportunityId');
    return BrandOpportunityDto.fromJson(
      (response['data'] as Map<String, dynamic>)['opportunity']
          as Map<String, dynamic>,
    );
  }

  Future<BrandApplicationDto> createBrandApplication(
    String opportunityId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/brand-opportunities/$opportunityId/applications',
      body: body,
    );
    return BrandApplicationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['application']
          as Map<String, dynamic>,
    );
  }

  Future<List<BrandApplicationDto>> brandApplications(
      String opportunityId) async {
    final response =
        await _client.get('/brand-opportunities/$opportunityId/applications');
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map((item) =>
            BrandApplicationDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<BrandApplicationDto>> ownerBrandApplications({
    String? opportunityId,
  }) async {
    final suffix = opportunityId == null || opportunityId.isEmpty
        ? ''
        : '?opportunity_id=${Uri.encodeComponent(opportunityId)}';
    final response = await _client.get('/brand-applications$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map((item) =>
            BrandApplicationDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BrandApplicationDto> brandApplication(String applicationId) async {
    final response = await _client.get('/brand-applications/$applicationId');
    return BrandApplicationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['application']
          as Map<String, dynamic>,
    );
  }

  Future<BrandApplicationDto> updateBrandApplication(
      String applicationId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/brand-applications/$applicationId', body: body);
    return BrandApplicationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['application']
          as Map<String, dynamic>,
    );
  }

  Future<BrandApplicationDto> createBrandTerms(
      String applicationId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/brand-applications/$applicationId/terms',
      body: body,
    );
    return BrandApplicationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['application']
          as Map<String, dynamic>,
    );
  }

  Future<String> ensureBrandApplicationConversation(
      String applicationId) async {
    final response = await _client.post(
      '/brand-applications/$applicationId/conversation',
    );
    return (response['data'] as Map<String, dynamic>)['conversation_id']
        as String;
  }

  Future<CampaignDeliverableDto> createCampaignDeliverable(
      Map<String, dynamic> body) async {
    final response = await _client.post('/campaign-deliverables', body: body);
    return CampaignDeliverableDto.fromJson(
      (response['data'] as Map<String, dynamic>)['deliverable']
          as Map<String, dynamic>,
    );
  }

  Future<List<CampaignDeliverableDto>> campaignDeliverables({
    String? opportunityId,
  }) async {
    final suffix =
        opportunityId == null ? '' : '?opportunity_id=$opportunityId';
    final response = await _client.get('/campaign-deliverables$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['deliverables'] as List<dynamic>? ?? const [])
        .map((item) =>
            CampaignDeliverableDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CampaignDeliverableDto> approveCampaignDeliverable(
      String deliverableId) async {
    final response =
        await _client.post('/campaign-deliverables/$deliverableId/approve');
    return CampaignDeliverableDto.fromJson(
      (response['data'] as Map<String, dynamic>)['deliverable']
          as Map<String, dynamic>,
    );
  }

  Future<CampaignDeliverableDto> updateCampaignDeliverable(
    String deliverableId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/campaign-deliverables/$deliverableId',
      body: body,
    );
    return CampaignDeliverableDto.fromJson(
      (response['data'] as Map<String, dynamic>)['deliverable']
          as Map<String, dynamic>,
    );
  }

  Future<CampaignDeliverableDto> createCampaignMetric(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post('/campaign-metrics', body: body);
    return CampaignDeliverableDto.fromJson(
      (response['data'] as Map<String, dynamic>)['deliverable']
          as Map<String, dynamic>,
    );
  }

  Future<ModelProfileDto?> modelProfile() async {
    final response = await _client.get('/model/profile');
    final data = response['data'] as Map<String, dynamic>;
    final profile = data['model_profile'] as Map<String, dynamic>?;
    return profile == null ? null : ModelProfileDto.fromJson(profile);
  }

  Future<ModelProfileDto> upsertModelProfile(Map<String, dynamic> body) async {
    final response = await _client.patch('/model/profile', body: body);
    return ModelProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['model_profile']
          as Map<String, dynamic>,
    );
  }

  Future<ModelProfileDto> modelCampaignCategories() async {
    final response = await _client.get('/model/campaign-categories');
    return ModelProfileDto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ModelProfileDto> updateModelCampaignCategories(
      List<Map<String, dynamic>> categories) async {
    final response = await _client.patch(
      '/model/campaign-categories',
      body: {'categories': categories},
    );
    return ModelProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['model_profile']
          as Map<String, dynamic>,
    );
  }

  Future<List<ModelUsageRightDto>> modelUsageRights() async {
    final response = await _client.get('/model/usage-rights');
    final data = response['data'] as Map<String, dynamic>;
    return (data['usage_rights'] as List<dynamic>? ?? const [])
        .map(
            (item) => ModelUsageRightDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ModelUsageRightDto> createModelUsageRight(
      Map<String, dynamic> body) async {
    final response = await _client.post('/model/usage-rights', body: body);
    return ModelUsageRightDto.fromJson(
      (response['data'] as Map<String, dynamic>)['usage_right']
          as Map<String, dynamic>,
    );
  }

  Future<ModelUsageRightDto> updateModelUsageRight(
      String rightId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/model/usage-rights/$rightId', body: body);
    return ModelUsageRightDto.fromJson(
      (response['data'] as Map<String, dynamic>)['usage_right']
          as Map<String, dynamic>,
    );
  }

  Future<List<ModelUsageRateDto>> modelUsageRates() async {
    final response = await _client.get('/model/usage-rates');
    final data = response['data'] as Map<String, dynamic>;
    return (data['usage_rates'] as List<dynamic>? ?? const [])
        .map((item) => ModelUsageRateDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ModelUsageRateDto> createModelUsageRate(
      Map<String, dynamic> body) async {
    final response = await _client.post('/model/usage-rates', body: body);
    return ModelUsageRateDto.fromJson(
      (response['data'] as Map<String, dynamic>)['usage_rate']
          as Map<String, dynamic>,
    );
  }

  Future<ModelUsageRateDto> updateModelUsageRate(
      String rateId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/model/usage-rates/$rateId', body: body);
    return ModelUsageRateDto.fromJson(
      (response['data'] as Map<String, dynamic>)['usage_rate']
          as Map<String, dynamic>,
    );
  }

  Future<List<ModelRestrictedCategoryDto>> modelRestrictedCategories() async {
    final response = await _client.get('/model/restricted-categories');
    final data = response['data'] as Map<String, dynamic>;
    return (data['restricted_categories'] as List<dynamic>? ?? const [])
        .map((item) =>
            ModelRestrictedCategoryDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ModelProfileDto> updateModelRestrictedCategories(
      List<Map<String, dynamic>> categories) async {
    final response = await _client.patch(
      '/model/restricted-categories',
      body: {'categories': categories},
    );
    return ModelProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['model_profile']
          as Map<String, dynamic>,
    );
  }

  Future<DistributionProfileDto?> distributionProfile() async {
    final response = await _client.get('/distribution/profile');
    final data = response['data'] as Map<String, dynamic>;
    final partner = data['partner'] as Map<String, dynamic>?;
    return partner == null ? null : DistributionProfileDto.fromJson(partner);
  }

  Future<DistributionProfileDto> upsertDistributionProfile(
      Map<String, dynamic> body) async {
    final response = await _client.patch('/distribution/profile', body: body);
    return DistributionProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['partner']
          as Map<String, dynamic>,
    );
  }

  Future<DistributionProjectDto> createDistributionProject(
      Map<String, dynamic> body) async {
    final response = await _client.post('/distribution-projects', body: body);
    return DistributionProjectDto.fromJson(
      (response['data'] as Map<String, dynamic>)['distribution_project']
          as Map<String, dynamic>,
    );
  }

  Future<List<DistributionProjectDto>> distributionProjects() async {
    final response = await _client.get('/distribution-projects');
    final data = response['data'] as Map<String, dynamic>;
    return (data['distribution_projects'] as List<dynamic>? ?? const [])
        .map((item) =>
            DistributionProjectDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DistributionProjectDto> updateDistributionProject(
      String projectId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/distribution-projects/$projectId', body: body);
    return DistributionProjectDto.fromJson(
      (response['data'] as Map<String, dynamic>)['distribution_project']
          as Map<String, dynamic>,
    );
  }

  Future<DistributionProjectDto> createReleaseWindow(
      String projectId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/distribution-projects/$projectId/release-windows',
      body: body,
    );
    return DistributionProjectDto.fromJson(
      (response['data'] as Map<String, dynamic>)['distribution_project']
          as Map<String, dynamic>,
    );
  }

  Future<DistributionProjectDto> createHandoverItem(
      String projectId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/distribution-projects/$projectId/handover-items',
      body: body,
    );
    return DistributionProjectDto.fromJson(
      (response['data'] as Map<String, dynamic>)['distribution_project']
          as Map<String, dynamic>,
    );
  }

  Future<DistributorContactDto> createDistributorContact(
      Map<String, dynamic> body) async {
    final response = await _client.post('/distributor-contacts', body: body);
    return DistributorContactDto.fromJson(
      (response['data'] as Map<String, dynamic>)['contact']
          as Map<String, dynamic>,
    );
  }

  Future<List<DistributorContactDto>> distributorContacts() async {
    final response = await _client.get('/distributor-contacts');
    final data = response['data'] as Map<String, dynamic>;
    return (data['contacts'] as List<dynamic>? ?? const [])
        .map((item) =>
            DistributorContactDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DistributorContactDto> updateDistributorContact(
      String contactId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/distributor-contacts/$contactId', body: body);
    return DistributorContactDto.fromJson(
      (response['data'] as Map<String, dynamic>)['contact']
          as Map<String, dynamic>,
    );
  }

  Future<DistributionReportDto> createDistributionReport(
      Map<String, dynamic> body) async {
    final response = await _client.post('/distribution-reports', body: body);
    return DistributionReportDto.fromJson(
      (response['data'] as Map<String, dynamic>)['report']
          as Map<String, dynamic>,
    );
  }

  Future<List<DistributionReportDto>> distributionReports({
    String? distributionProjectId,
  }) async {
    final suffix = distributionProjectId == null
        ? ''
        : '?distribution_project_id=$distributionProjectId';
    final response = await _client.get('/distribution-reports$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['reports'] as List<dynamic>? ?? const [])
        .map((item) =>
            DistributionReportDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
