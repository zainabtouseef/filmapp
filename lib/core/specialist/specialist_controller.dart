import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'specialist_models.dart';
import 'specialist_repository.dart';

class SpecialistController extends ChangeNotifier {
  final SpecialistRepository _repository;

  AgencyProfileDto? _agencyProfile;
  BrandProfileDto? _brandProfile;
  ModelProfileDto? _modelProfile;
  DistributionProfileDto? _distributionProfile;

  List<AgencyInvitationDto>? _agencyInvitations;
  List<AgencyTalentDto>? _agencyRoster;
  List<AuditionDto>? _auditions;
  List<AgencyCommissionDto>? _agencyCommissions;
  List<BrandOpportunityDto>? _brandOpportunities;
  List<BrandApplicationDto>? _brandApplications;
  List<CampaignDeliverableDto>? _campaignDeliverables;
  List<ModelUsageRightDto>? _modelUsageRights;
  List<ModelUsageRateDto>? _modelUsageRates;
  List<ModelRestrictedCategoryDto>? _modelRestricted;
  List<DistributionProjectDto>? _distributionProjects;
  List<DistributorContactDto>? _distributorContacts;
  List<DistributionReportDto>? _distributionReports;

  SpecialistController({required SpecialistRepository repository})
      : _repository = repository;

  factory SpecialistController.fromClient(ApiClient client) {
    return SpecialistController(repository: SpecialistRepository(client));
  }

  BrandProfileDto? get cachedBrandProfile => _brandProfile;
  List<BrandOpportunityDto>? get cachedBrandOpportunities =>
      _brandOpportunities;
  List<BrandApplicationDto>? get cachedBrandApplications => _brandApplications;
  List<CampaignDeliverableDto>? get cachedCampaignDeliverables =>
      _campaignDeliverables;

  Future<AgencyProfileDto?> agencyProfile({bool force = false}) async {
    if (!force && _agencyProfile != null) return _agencyProfile;
    _agencyProfile = await _repository.agencyProfile();
    notifyListeners();
    return _agencyProfile;
  }

  Future<AgencyProfileDto> upsertAgencyProfile(
      Map<String, dynamic> body) async {
    _agencyProfile = await _repository.upsertAgencyProfile(body);
    notifyListeners();
    return _agencyProfile!;
  }

  Future<List<AgencyInvitationDto>> agencyInvitations({
    bool force = false,
  }) async {
    if (!force && _agencyInvitations != null) return _agencyInvitations!;
    _agencyInvitations = await _repository.agencyInvitations();
    notifyListeners();
    return _agencyInvitations!;
  }

  Future<AgencyInvitationDto> createAgencyInvitation(
      Map<String, dynamic> body) async {
    final invitation = await _repository.createAgencyInvitation(body);
    await agencyInvitations(force: true);
    return invitation;
  }

  Future<List<AgencyTalentDto>> agencyRoster({
    String? agencyId,
    bool force = false,
  }) async {
    final id = agencyId ?? (await agencyProfile())?.publicId;
    if (id == null || id.isEmpty) return const [];
    if (!force && _agencyRoster != null) return _agencyRoster!;
    _agencyRoster = await _repository.agencyRoster(id);
    notifyListeners();
    return _agencyRoster!;
  }

  Future<List<AuditionDto>> auditions({bool force = false}) async {
    if (!force && _auditions != null) return _auditions!;
    _auditions = await _repository.auditions();
    notifyListeners();
    return _auditions!;
  }

  Future<AuditionDto> updateAuditionStatus(
      String auditionId, String status) async {
    final audition = await _repository.updateAudition(
      auditionId,
      {'status': status},
    );
    await auditions(force: true);
    return audition;
  }

  Future<List<AgencyCommissionDto>> agencyCommissions({
    String? agencyId,
    bool force = false,
  }) async {
    final id = agencyId ?? (await agencyProfile())?.publicId;
    if (id == null || id.isEmpty) return const [];
    if (!force && _agencyCommissions != null) return _agencyCommissions!;
    _agencyCommissions = await _repository.agencyCommissions(id);
    notifyListeners();
    return _agencyCommissions!;
  }

  Future<BrandProfileDto?> brandProfile({bool force = false}) async {
    if (!force && _brandProfile != null) return _brandProfile;
    _brandProfile = await _repository.brandProfile();
    notifyListeners();
    return _brandProfile;
  }

  Future<BrandProfileDto> upsertBrandProfile(Map<String, dynamic> body) async {
    _brandProfile = await _repository.upsertBrandProfile(body);
    notifyListeners();
    return _brandProfile!;
  }

  Future<List<BrandOpportunityDto>> brandOpportunities({
    bool mine = true,
    bool force = false,
  }) async {
    if (!force && _brandOpportunities != null) return _brandOpportunities!;
    _brandOpportunities = await _repository.brandOpportunities(mine: mine);
    notifyListeners();
    return _brandOpportunities!;
  }

  Future<BrandOpportunityDto> createBrandOpportunity(
      Map<String, dynamic> body) async {
    final opportunity = await _repository.createBrandOpportunity(body);
    await brandOpportunities(force: true);
    return opportunity;
  }

  Future<BrandOpportunityDto> updateBrandOpportunity(
    String opportunityId,
    Map<String, dynamic> body,
  ) async {
    final opportunity =
        await _repository.updateBrandOpportunity(opportunityId, body);
    await brandOpportunities(force: true);
    return opportunity;
  }

  Future<List<BrandApplicationDto>> ownerBrandApplications({
    String? opportunityId,
    bool force = false,
  }) async {
    if (opportunityId == null && !force && _brandApplications != null) {
      return _brandApplications!;
    }
    final rows = await _repository.ownerBrandApplications(
      opportunityId: opportunityId,
    );
    if (opportunityId == null) {
      _brandApplications = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<BrandApplicationDto> brandApplication(String applicationId) {
    return _repository.brandApplication(applicationId);
  }

  Future<BrandApplicationDto> updateBrandApplication(
    String applicationId,
    Map<String, dynamic> body,
  ) async {
    final application =
        await _repository.updateBrandApplication(applicationId, body);
    await ownerBrandApplications(force: true);
    await brandOpportunities(force: true);
    return application;
  }

  Future<BrandApplicationDto> createBrandTerms(
    String applicationId,
    Map<String, dynamic> body,
  ) async {
    final application = await _repository.createBrandTerms(applicationId, body);
    await ownerBrandApplications(force: true);
    return application;
  }

  Future<String> ensureBrandApplicationConversation(String applicationId) {
    return _repository.ensureBrandApplicationConversation(applicationId);
  }

  Future<List<CampaignDeliverableDto>> campaignDeliverables({
    String? opportunityId,
    bool force = false,
  }) async {
    if (opportunityId == null && !force && _campaignDeliverables != null) {
      return _campaignDeliverables!;
    }
    final rows = await _repository.campaignDeliverables(
      opportunityId: opportunityId,
    );
    if (opportunityId == null) {
      _campaignDeliverables = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<CampaignDeliverableDto> createCampaignDeliverable(
    Map<String, dynamic> body,
  ) async {
    final deliverable = await _repository.createCampaignDeliverable(body);
    await campaignDeliverables(force: true);
    return deliverable;
  }

  Future<CampaignDeliverableDto> updateCampaignDeliverable(
    String deliverableId,
    Map<String, dynamic> body,
  ) async {
    final deliverable =
        await _repository.updateCampaignDeliverable(deliverableId, body);
    await campaignDeliverables(force: true);
    return deliverable;
  }

  Future<CampaignDeliverableDto> approveCampaignDeliverable(
      String deliverableId) async {
    final deliverable =
        await _repository.approveCampaignDeliverable(deliverableId);
    await campaignDeliverables(force: true);
    return deliverable;
  }

  Future<CampaignDeliverableDto> createCampaignMetric(
    Map<String, dynamic> body,
  ) async {
    final deliverable = await _repository.createCampaignMetric(body);
    await campaignDeliverables(force: true);
    return deliverable;
  }

  Future<ModelProfileDto?> modelProfile({bool force = false}) async {
    if (!force && _modelProfile != null) return _modelProfile;
    _modelProfile = await _repository.modelProfile();
    notifyListeners();
    return _modelProfile;
  }

  Future<ModelProfileDto> upsertModelProfile(Map<String, dynamic> body) async {
    _modelProfile = await _repository.upsertModelProfile(body);
    notifyListeners();
    return _modelProfile!;
  }

  Future<ModelProfileDto> updateModelCampaignCategories(
      List<Map<String, dynamic>> categories) async {
    _modelProfile = await _repository.updateModelCampaignCategories(categories);
    notifyListeners();
    return _modelProfile!;
  }

  Future<List<ModelUsageRightDto>> modelUsageRights({
    bool force = false,
  }) async {
    if (!force && _modelUsageRights != null) return _modelUsageRights!;
    _modelUsageRights = await _repository.modelUsageRights();
    notifyListeners();
    return _modelUsageRights!;
  }

  Future<ModelUsageRightDto> createModelUsageRight(
      Map<String, dynamic> body) async {
    final right = await _repository.createModelUsageRight(body);
    await modelUsageRights(force: true);
    return right;
  }

  Future<ModelUsageRightDto> updateModelUsageRight(
      String rightId, Map<String, dynamic> body) async {
    final right = await _repository.updateModelUsageRight(rightId, body);
    await modelUsageRights(force: true);
    return right;
  }

  Future<List<ModelUsageRateDto>> modelUsageRates({bool force = false}) async {
    if (!force && _modelUsageRates != null) return _modelUsageRates!;
    _modelUsageRates = await _repository.modelUsageRates();
    notifyListeners();
    return _modelUsageRates!;
  }

  Future<ModelUsageRateDto> createModelUsageRate(
      Map<String, dynamic> body) async {
    final rate = await _repository.createModelUsageRate(body);
    await modelUsageRates(force: true);
    return rate;
  }

  Future<ModelUsageRateDto> updateModelUsageRate(
      String rateId, Map<String, dynamic> body) async {
    final rate = await _repository.updateModelUsageRate(rateId, body);
    await modelUsageRates(force: true);
    return rate;
  }

  Future<List<ModelRestrictedCategoryDto>> modelRestrictedCategories({
    bool force = false,
  }) async {
    if (!force && _modelRestricted != null) return _modelRestricted!;
    _modelRestricted = await _repository.modelRestrictedCategories();
    notifyListeners();
    return _modelRestricted!;
  }

  Future<ModelProfileDto> updateModelRestrictedCategories(
      List<Map<String, dynamic>> categories) async {
    _modelProfile =
        await _repository.updateModelRestrictedCategories(categories);
    _modelRestricted = _modelProfile!.restrictedCategories;
    notifyListeners();
    return _modelProfile!;
  }

  Future<DistributionProfileDto?> distributionProfile({
    bool force = false,
  }) async {
    if (!force && _distributionProfile != null) return _distributionProfile;
    _distributionProfile = await _repository.distributionProfile();
    notifyListeners();
    return _distributionProfile;
  }

  Future<DistributionProfileDto> upsertDistributionProfile(
      Map<String, dynamic> body) async {
    _distributionProfile = await _repository.upsertDistributionProfile(body);
    notifyListeners();
    return _distributionProfile!;
  }

  Future<List<DistributionProjectDto>> distributionProjects({
    bool force = false,
  }) async {
    if (!force && _distributionProjects != null) {
      return _distributionProjects!;
    }
    _distributionProjects = await _repository.distributionProjects();
    notifyListeners();
    return _distributionProjects!;
  }

  Future<DistributionProjectDto> updateDistributionProject(
    String projectId,
    Map<String, dynamic> body,
  ) async {
    final project =
        await _repository.updateDistributionProject(projectId, body);
    await distributionProjects(force: true);
    return project;
  }

  Future<List<DistributorContactDto>> distributorContacts({
    bool force = false,
  }) async {
    if (!force && _distributorContacts != null) return _distributorContacts!;
    _distributorContacts = await _repository.distributorContacts();
    notifyListeners();
    return _distributorContacts!;
  }

  Future<DistributorContactDto> createDistributorContact(
      Map<String, dynamic> body) async {
    final contact = await _repository.createDistributorContact(body);
    await distributorContacts(force: true);
    return contact;
  }

  Future<List<DistributionReportDto>> distributionReports({
    String? distributionProjectId,
    bool force = false,
  }) async {
    if (!force && _distributionReports != null) return _distributionReports!;
    _distributionReports = await _repository.distributionReports(
      distributionProjectId: distributionProjectId,
    );
    notifyListeners();
    return _distributionReports!;
  }
}

class SpecialistScope extends InheritedNotifier<SpecialistController> {
  const SpecialistScope({
    super.key,
    required SpecialistController controller,
    required super.child,
  }) : super(notifier: controller);

  static SpecialistController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SpecialistScope>();
    assert(scope != null, 'SpecialistScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static SpecialistController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SpecialistScope>()
        ?.notifier;
  }
}
