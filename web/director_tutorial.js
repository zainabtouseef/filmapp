(function () {
  "use strict";

  const GUIDE_VERSION = "6";
  const IDENTITY_KEY = "cineconnect.session_identity";
  const ROUTE_SESSION_KEY = "cineconnect.director_route_session";
  const STORAGE_PREFIX = `cineconnect.director_guide.v${GUIDE_VERSION}.`;
  const DIRECTOR_ROLE = "director_producer";
  const AUTO_START_DELAY_MS = 1500;

  const icon = (name) => {
    const paths = {
      compass:
        '<circle cx="12" cy="12" r="9"></circle><path d="m16 8-2.6 5.4L8 16l2.6-5.4L16 8Z"></path>',
      close: '<path d="M18 6 6 18M6 6l12 12"></path>',
      check:
        '<circle cx="12" cy="12" r="9"></circle><path d="m8.5 12 2.2 2.2 4.8-5"></path>',
      target:
        '<circle cx="12" cy="12" r="8"></circle><circle cx="12" cy="12" r="3"></circle><path d="M12 2v3M12 19v3M2 12h3M19 12h3"></path>',
      route:
        '<circle cx="6" cy="18" r="2"></circle><circle cx="18" cy="6" r="2"></circle><path d="M8 18h3a3 3 0 0 0 3-3V9a3 3 0 0 1 3-3h-1"></path>',
      arrowLeft: '<path d="m15 18-6-6 6-6"></path>',
      arrowRight: '<path d="m9 18 6-6-6-6"></path>',
      pause: '<path d="M8 5v14M16 5v14"></path>',
      skipForward: '<path d="m7 6 8 6-8 6V6ZM18 6v12"></path>',
      eye:
        '<path d="M2.5 12s3.4-6 9.5-6 9.5 6 9.5 6-3.4 6-9.5 6-9.5-6-9.5-6Z"></path><circle cx="12" cy="12" r="2.5"></circle>',
      trophy:
        '<path d="M8 4h8v4a4 4 0 0 1-8 0V4Z"></path><path d="M8 6H5v1a4 4 0 0 0 4 4M16 6h3v1a4 4 0 0 1-4 4M12 12v4M9 20h6M10 16h4"></path>',
      play: '<path d="m9 7 8 5-8 5V7Z"></path><circle cx="12" cy="12" r="9"></circle>',
    };
    return `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">${paths[name]}</svg>`;
  };

  const target = {
    header() {
      return { left: 12, top: 10, width: innerWidth - 24, height: 68 };
    },
    dashboard() {
      if (innerWidth < 700) {
        return { left: 16, top: 132, width: innerWidth - 32, height: Math.min(245, innerHeight * 0.34) };
      }
      return { left: 24, top: 120, width: innerWidth - 48, height: Math.min(245, innerHeight * 0.36) };
    },
    bottomNav() {
      return { left: 0, top: Math.max(0, innerHeight - 102), width: innerWidth, height: 102, radius: 28 };
    },
    bottomTab(index) {
      const tabWidth = innerWidth / 5;
      return {
        left: tabWidth * index + 5,
        top: Math.max(0, innerHeight - 94),
        width: Math.max(48, tabWidth - 10),
        height: 84,
        radius: 18,
      };
    },
    newProject() {
      return {
        left: innerWidth < 700 ? 30 : 34,
        top: innerWidth < 700 ? 238 : 238,
        width: 140,
        height: 66,
        radius: 18,
      };
    },
    topSearch() {
      const left = innerWidth < 700 ? Math.min(188, innerWidth * 0.34) : Math.max(180, innerWidth * 0.2);
      return {
        left,
        top: 14,
        width: Math.max(132, Math.min(innerWidth - left - 86, 360)),
        height: 58,
        radius: 18,
      };
    },
    formFields() {
      return {
        left: 18,
        top: innerWidth < 700 ? 150 : 142,
        width: innerWidth - 36,
        height: Math.min(260, innerHeight * 0.44),
        radius: 18,
      };
    },
    formAction() {
      return {
        left: innerWidth < 700 ? Math.max(18, innerWidth - 190) : Math.max(24, innerWidth - 240),
        top: Math.max(110, innerHeight - 154),
        width: innerWidth < 700 ? 166 : 210,
        height: 66,
        radius: 18,
      };
    },
    primaryAction() {
      if (innerWidth < 700) {
        return { left: Math.max(16, innerWidth - 190), top: 98, width: 174, height: 82 };
      }
      return { left: Math.max(24, innerWidth - 290), top: 86, width: 250, height: 78 };
    },
    filters() {
      return { left: 14, top: innerWidth < 700 ? 135 : 120, width: innerWidth - 28, height: 178 };
    },
    firstCard() {
      return { left: 16, top: innerWidth < 700 ? 300 : 270, width: innerWidth - 32, height: Math.min(240, innerHeight * 0.34) };
    },
    main() {
      return { left: 14, top: 92, width: innerWidth - 28, height: Math.max(250, innerHeight - 190) };
    },
    upperMain() {
      return { left: 14, top: 90, width: innerWidth - 28, height: Math.min(330, innerHeight * 0.5) };
    },
  };

  const steps = [
    {
      chapter: "Start",
      title: "Welcome to your director command center",
      description:
        "This guide walks through the real CineConnect production workflow. It does not create, hire, sign, or pay for anything on your behalf.",
      doThis: "Learn the five missions, then move through each live portal screen at your own pace.",
      checklist: [
        "Build a production-ready project brief",
        "Find and hire every required role",
        "Control contracts, payments, delivery, and support",
      ],
      route: "#/director",
      routeLabel: "Director dashboard",
    },
    {
      chapter: "Start",
      title: "Complete your professional profile first",
      description:
        "Your profile and verification status establish trust with talent, suppliers, agencies, and specialist partners.",
      doThis: "Open More, choose your account/profile controls, add company or production identity details, and finish KYC before sending paid requests.",
      checklist: [
        "Use a professional photo or company mark",
        "Add your production bio and operating city",
        "Confirm identity, phone, and payment details",
      ],
      route: "#/director",
      routeLabel: "More > Profile and verification",
      target: target.bottomNav,
    },
    {
      chapter: "Start",
      title: "Read the action center every day",
      description:
        "The dashboard prioritizes contracts, payment proofs, offers, negotiations, expiring items, and project health.",
      doThis: "Clear urgent and overdue actions before starting new work. Treat red and amber cards as production risks.",
      checklist: [
        "Review signatures and expiring offers",
        "Resolve proof or milestone issues",
        "Open the affected project before responding",
      ],
      route: "#/director",
      routeLabel: "Home > Action required",
      target: target.dashboard,
    },
    {
      chapter: "Start",
      title: "Projects are the source of truth",
      description:
        "Each production should have one project hub for its requirements, people, bookings, schedule, contracts, and financial trail.",
      doThis: "Open Projects and search or filter by production stage. Avoid hiring outside a project because it breaks reporting and approvals.",
      checklist: [
        "One project per film, episode, campaign, or event",
        "Keep status and shooting dates current",
        "Use the project hub for every related action",
      ],
      route: "#/director/projects",
      routeLabel: "Projects",
      target: target.main,
    },
    {
      chapter: "Build the brief",
      title: "Create the project shell",
      description:
        "Start with a clear identity so every candidate and provider understands what they are joining.",
      doThis: "Select New Project, then enter the title, format, genre, logline, production city, and current production stage.",
      checklist: [
        "Use a specific working title",
        "Write a short, non-confidential logline",
        "Choose the correct project type and stage",
      ],
      route: "#/director/projects/create",
      routeLabel: "Projects > New Project",
      target: target.upperMain,
    },
    {
      chapter: "Build the brief",
      title: "Add schedule, budget, and ownership",
      description:
        "Accurate dates and budget ranges make availability, offers, milestones, and reports useful.",
      doThis: "Set prep and shoot dates, expected shoot days, budget range and currency, producer ownership, and the primary decision-maker.",
      checklist: [
        "Leave contingency for weather and reshoots",
        "Use realistic budget ranges before negotiations",
        "Name the person authorized to approve changes",
      ],
      route: "#/director/projects/create",
      routeLabel: "New Project > Plan",
      target: target.main,
    },
    {
      chapter: "Build the brief",
      title: "Save safely before inviting anyone",
      description:
        "A draft lets you validate the brief privately before it becomes visible to candidates or vendors.",
      doThis: "Upload only approved references, save as Draft, reopen the project hub, and check every summary value.",
      checklist: [
        "Remove confidential client or cast information",
        "Confirm dates, city, currency, and owner",
        "Publish only when the hiring brief is ready",
      ],
      route: "#/director/projects/create",
      routeLabel: "New Project > Save Draft",
      target: target.primaryAction,
    },
    {
      chapter: "Build the brief",
      title: "Define every requirement before discovery",
      description:
        "Requirements turn a general project into a measurable hiring plan. Add them from the saved Project Hub.",
      doThis: "Open the saved project, choose Requirements, and create one requirement for each role, service, location, or equipment package.",
      checklist: [
        "Set quantity, city, dates, budget, and deadline",
        "Mark mandatory skills, languages, or permits",
        "Keep private notes separate from public criteria",
      ],
      route: "#/director/projects",
      routeLabel: "Project Hub > Requirements",
      target: target.firstCard,
    },
    {
      chapter: "Build the brief",
      title: "Write casting requirements that can be judged",
      description:
        "Actors, talent, and models need a specific role brief rather than a vague request for a look.",
      doThis: "Create separate requirements for every speaking role, supporting role, model usage, extra group, and influencer deliverable.",
      checklist: [
        "Character range, language, performance skills, and dates",
        "Audition or self-tape instructions and deadline",
        "Model usage rights, territory, term, and media",
      ],
      route: "#/director/projects",
      routeLabel: "Requirements > Casting",
      target: target.main,
    },
    {
      chapter: "Build the brief",
      title: "Break down crew and production services",
      description:
        "Crew hiring works best when departments, seniority, equipment expectations, and call-day coverage are explicit.",
      doThis: "Add requirements for camera, lighting, sound, art, wardrobe, makeup, production, post, transport, catering, and safety as needed.",
      checklist: [
        "Department and exact position or package",
        "Prep, shoot, wrap, travel, and overtime expectations",
        "Deliverables, insurance, and kit inclusions",
      ],
      route: "#/director/projects",
      routeLabel: "Requirements > Crew and services",
      target: target.main,
    },
    {
      chapter: "Build the brief",
      title: "Specify locations, equipment, and partners",
      description:
        "Operational requirements protect the schedule and make quotations comparable.",
      doThis: "Add location, equipment, casting agency, brand, legal, insurance, and distribution requirements that match the production risk.",
      checklist: [
        "Location access, power, sound, parking, permits, and hours",
        "Camera/lighting package, quantities, handover, and return",
        "Legal review, insurance cover, sponsor, and release needs",
      ],
      route: "#/director/projects",
      routeLabel: "Requirements > Operations and partners",
      target: target.main,
    },
    {
      chapter: "Hire the team",
      title: "Search the marketplace from the project brief",
      description:
        "The Marketplace brings talent, models, crew, locations, media/equipment, agencies, and partners into one search surface.",
      doThis: "Choose the matching category, then filter by city, date, price, verification, specialty, and availability.",
      checklist: [
        "Start broad, then add only decision-making filters",
        "Prefer verified profiles for paid or safety-sensitive work",
        "Save searches you will repeat during casting or sourcing",
      ],
      route: "#/director/marketplace",
      routeLabel: "Find > Marketplace",
      target: target.filters,
    },
    {
      chapter: "Hire the team",
      title: "Review actors, talent, and models",
      description:
        "Open the full profile before shortlisting. A thumbnail or day rate is not enough for a safe casting decision.",
      doThis: "Compare portfolio, credits, skills, languages, availability, rates, reputation, and model usage-rights terms.",
      checklist: [
        "Match evidence to each requirement",
        "Check conflicts and availability for every date",
        "Use the Request action only after reviewing the profile",
      ],
      route: "#/director/marketplace",
      routeLabel: "Marketplace > Talent and Models",
      target: target.firstCard,
    },
    {
      chapter: "Hire the team",
      title: "Review crew, locations, and equipment",
      description:
        "Operational hires should be compared on the complete package, not headline price alone.",
      doThis: "Check crew credits and kit, location rules and logistics, and equipment condition, terms, deposits, handover, and return process.",
      checklist: [
        "Confirm what is included and excluded",
        "Ask about overtime, transport, damage, and cancellation",
        "Record technical or scout questions in the request",
      ],
      route: "#/director/marketplace",
      routeLabel: "Marketplace > Crew, Locations, Equipment",
      target: target.firstCard,
    },
    {
      chapter: "Hire the team",
      title: "Bring in agencies and specialist partners",
      description:
        "Casting agencies, brands, legal counsel, insurers, and distributors enter at different stages but should remain tied to the project.",
      doThis: "Review mandate, scope, turnaround, commission or fee, required documents, and named deliverables before requesting work.",
      checklist: [
        "Casting agency roster and commission terms",
        "Brand approvals, legal review, and insurance evidence",
        "Distribution territory, window, assets, and reporting",
      ],
      route: "#/director/marketplace",
      routeLabel: "Marketplace > Agencies and Partners",
      target: target.filters,
    },
    {
      chapter: "Hire the team",
      title: "Use the shortlist as a decision board",
      description:
        "Shortlisting separates serious candidates from search results and gives the production team a consistent comparison set.",
      doThis: "Group candidates by requirement, compare side by side, add private decision notes, and remove anyone who no longer fits.",
      checklist: [
        "Keep two or three viable alternatives per critical role",
        "Compare like-for-like scope and availability",
        "Do not treat a shortlist as a confirmed booking",
      ],
      route: "#/director/shortlist",
      routeLabel: "More > Shortlist",
      target: target.main,
    },
    {
      chapter: "Hire the team",
      title: "Send a complete request",
      description:
        "A request connects a provider to a project and starts the auditable offer process.",
      doThis: "From the selected listing, choose Request, attach the project and requirement, then state dates, scope, amount, deadline, and special terms.",
      checklist: [
        "Never send a blank or generic request",
        "Include the full amount and what it covers",
        "Set an expiry that protects the production schedule",
      ],
      route: "#/director/marketplace",
      routeLabel: "Listing > Request",
      target: target.firstCard,
    },
    {
      chapter: "Hire the team",
      title: "Negotiate without losing the brief",
      description:
        "Bargaining records each move and keeps price, scope, dates, and conditions together.",
      doThis: "Open the negotiation, compare the current offer with the requirement, then accept, counter, or decline before the timer expires.",
      checklist: [
        "If price changes, confirm whether scope changed too",
        "Record travel, overtime, usage, deposits, and cancellation",
        "Escalate material creative or legal changes for approval",
      ],
      route: "#/director/bargaining",
      routeLabel: "Deals > Bargaining",
      target: target.firstCard,
    },
    {
      chapter: "Hire the team",
      title: "Confirm the booking only after final checks",
      description:
        "Acceptance moves the relationship toward a binding contract and payment schedule.",
      doThis: "Recheck the legal name, requirement, dates, amount, currency, milestones, cancellation, and approver before accepting.",
      checklist: [
        "No unresolved date or scope assumptions",
        "Identity and payment recipient match the provider",
        "The project owner has approved the commitment",
      ],
      route: "#/director/contracts",
      routeLabel: "Deals > Accepted bookings",
      target: target.upperMain,
    },
    {
      chapter: "Run production",
      title: "Generate and sign the contract",
      description:
        "Contracts convert accepted commercial terms into a formal record for both sides.",
      doThis: "Generate from the accepted booking, review every clause and attachment, request legal help when needed, then collect signatures.",
      checklist: [
        "Parties, scope, dates, amount, milestones, rights, and cancellation",
        "Safety, confidentiality, insurance, and dispute terms",
        "Do not pay against an unsigned or mismatched contract",
      ],
      route: "#/director/contracts",
      routeLabel: "Deals > Contracts",
      target: target.firstCard,
    },
    {
      chapter: "Run production",
      title: "Control payments by milestone",
      description:
        "Payments should follow the contract schedule and show a verifiable proof trail.",
      doThis: "Review what is Due, upload the correct proof, wait for verification, and resolve rejected proofs before the milestone deadline.",
      checklist: [
        "Match recipient, amount, currency, contract, and milestone",
        "Upload a readable, non-duplicated proof",
        "Use Ledger for the complete financial history",
      ],
      route: "#/director/payments",
      routeLabel: "More > Payments",
      target: target.dashboard,
    },
    {
      chapter: "Run production",
      title: "Keep the schedule operational",
      description:
        "The production schedule should reflect confirmed people, locations, equipment, dependencies, and changes.",
      doThis: "Review dates and conflicts, assign confirmed resources, record call or handover times, and update everyone when plans change.",
      checklist: [
        "Confirm availability before publishing a change",
        "Track location access and equipment handover/return",
        "Preserve an audit trail for critical schedule decisions",
      ],
      route: "#/director/schedule",
      routeLabel: "Project > Schedule",
      target: target.main,
    },
    {
      chapter: "Run production",
      title: "Use the Project Room for team coordination",
      description:
        "The room keeps discussions, files, pins, and production updates connected to the project.",
      doThis: "Post concise updates, pin the current approved file, and keep urgent decisions out of scattered personal chats.",
      checklist: [
        "Use clear file versions and descriptive names",
        "Pin only the current call sheet or approved reference",
        "Never post passwords, card data, or unnecessary identity documents",
      ],
      route: "#/director/room",
      routeLabel: "Project Room",
      target: target.main,
    },
    {
      chapter: "Run production",
      title: "Generate reports before wrap",
      description:
        "Reports expose missing contracts, overdue payments, schedule risk, and incomplete delivery while there is still time to fix them.",
      doThis: "Generate project, budget-risk, contracts, payments, schedule, and delivery reports; export only for authorized stakeholders.",
      checklist: [
        "Resolve pending actions before marking the project complete",
        "Confirm exported files use the right project and date range",
        "Store reports according to production privacy rules",
      ],
      route: "#/director/reports",
      routeLabel: "More > Reports",
      target: target.firstCard,
    },
    {
      chapter: "Finance & support",
      title: "Diagnose finance problems from the ledger",
      description:
        "Most finance issues come from a mismatched contract, milestone, amount, recipient, or unreadable proof.",
      doThis: "Open Ledger, locate the exact milestone, compare contract terms with the proof, and correct the source problem before re-uploading.",
      checklist: [
        "Do not create duplicate proofs to force a result",
        "Capture the rejection reason and corrected evidence",
        "Escalate only after the contract and ledger are reconciled",
      ],
      route: "#/director/payments",
      routeLabel: "Payments > Ledger",
      target: target.primaryAction,
    },
    {
      chapter: "Finance & support",
      title: "Escalate safely when the workflow cannot resolve it",
      description:
        "Support works fastest when the ticket contains one problem, the affected record, evidence, impact, and the result you need.",
      doThis: "Open More, choose Support, select the closest category, attach safe evidence, and include project, booking, contract, or payment IDs.",
      checklist: [
        "Never include passwords, full card details, or private keys",
        "For disputes, preserve messages and contract evidence",
        "For urgent safety issues, stop the activity before filing",
      ],
      route: "#/director",
      routeLabel: "More > Support",
      target: target.bottomNav,
    },
    {
      chapter: "Finance & support",
      title: "Your director workflow is ready",
      description:
        "You can restart this guide at any time from the floating Director Guide button, including while viewing your profile.",
      doThis: "Create one draft project and follow the workflow in order: brief, requirements, discovery, shortlist, request, negotiation, contract, payment, production, report.",
      checklist: [
        "Keep every hire and payment attached to a project",
        "Use requirements as the decision checklist",
        "Pause and ask Support whenever safety or money is unclear",
      ],
      route: "#/director",
      routeLabel: "Director dashboard",
      target: target.dashboard,
      complete: true,
    },
  ];

  // Each mission has one observable action. The guide advances from the user's
  // click or input instead of using a passive Next-only presentation.
  const interactions = [
    { action: "manual", actionLabel: "Start interactive tour" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["More"], target: () => target.bottomTab(4), actionLabel: "Tap More" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["View all", "Active productions"], target: target.dashboard, actionLabel: "Open an action card" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["Productions", "Projects"], target: () => target.bottomTab(1), expectedHash: "#/director/projects", actionLabel: "Tap Productions" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["New Project"], target: target.newProject, preferFallback: true, expectedHash: "#/director/projects/create", actionLabel: "Tap New Project" },
    { action: "input", prepareRoute: "#/director/projects/create", targetLabels: ["Project title", "Working title", "Title", "Production city"], target: target.formFields, actionLabel: "Enter the project details" },
    { action: "click", prepareRoute: "#/director/projects/create", targetLabels: ["Save Draft", "Save draft"], target: target.formAction, actionLabel: "Tap Save Draft" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["Requirements", "Add requirement"], target: target.firstCard, actionLabel: "Open Requirements" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["Casting", "Talent", "Actor"], target: target.firstCard, actionLabel: "Choose Casting" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["Crew", "Services"], target: target.firstCard, actionLabel: "Choose Crew & Services" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["Locations", "Equipment", "Partners"], target: target.firstCard, actionLabel: "Choose an operations requirement" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["Find"], target: () => target.bottomTab(2), expectedHash: "#/director/marketplace", actionLabel: "Tap Find" },
    { action: "click", prepareRoute: "#/director/marketplace", targetLabels: ["Talent", "Models"], target: target.filters, actionLabel: "Choose Talent or Models" },
    { action: "click", prepareRoute: "#/director/marketplace", targetLabels: ["Crew", "Locations", "Equipment"], target: target.filters, actionLabel: "Choose Crew, Locations or Equipment" },
    { action: "click", prepareRoute: "#/director/marketplace", targetLabels: ["Agencies", "Partners"], target: target.filters, actionLabel: "Choose Agencies or Partners" },
    { action: "click", prepareRoute: "#/director/marketplace", targetLabels: ["Shortlist", "Saved"], target: target.header, actionLabel: "Open Shortlist" },
    { action: "click", prepareRoute: "#/director/marketplace", targetLabels: ["Request", "Book"], target: target.firstCard, actionLabel: "Tap Request on a listing" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["Deals"], target: () => target.bottomTab(3), actionLabel: "Tap Deals" },
    { action: "click", prepareRoute: "#/director/bargaining", targetLabels: ["Contracts", "Accepted"], target: target.upperMain, actionLabel: "Open Contracts" },
    { action: "click", prepareRoute: "#/director/contracts", targetLabels: ["Generate contract", "Review contract", "View contract"], target: target.firstCard, actionLabel: "Open a contract action" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["View payments"], target: target.dashboard, actionLabel: "Tap View payments" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["Full schedule", "Schedule"], target: target.dashboard, actionLabel: "Open the schedule" },
    { action: "click", prepareRoute: "#/director/projects", targetLabels: ["Project Room", "Room"], target: target.firstCard, actionLabel: "Open the Project Room" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["More"], target: () => target.bottomTab(4), actionLabel: "Tap More for Reports" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["View payments"], target: target.dashboard, actionLabel: "Open the payment ledger" },
    { action: "click", prepareRoute: "#/director", targetLabels: ["More"], target: () => target.bottomTab(4), actionLabel: "Tap More for Support" },
    { action: "manual", prepareRoute: "#/director", actionLabel: "Finish tutorial" },
  ];

  steps.forEach((step, index) => Object.assign(step, interactions[index] || {}));

  const workflowStep = (config) => Object.assign(
    {
      description: "Follow the highlighted control to continue the production workflow.",
      checklist: [],
      routeLabel: "Director workflow",
    },
    config
  );

  const workflowSteps = [
    workflowStep({
      chapter: "Start",
      title: "Build one complete production from start to finish",
      description: "This tour now follows the real order: create the full project, hire against its requirements, then manage deals, contracts, money, production, and reporting.",
      doThis: "Start the guided production workflow. The tour never submits, signs, hires, or pays on your behalf.",
      checklist: ["Project first", "Hiring second", "Operations and finance last"],
      prepareRoute: "#/console",
      routeLabel: "Production Console",
      action: "manual",
      actionLabel: "Start production workflow",
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Open Productions",
      description: "Every hire, contract, payment, and report must belong to a production.",
      doThis: "Tap Productions.",
      prepareRoute: "#/console",
      routeLabel: "Console > Productions",
      action: "click",
      actionLabel: "Tap Productions",
      targetLabels: ["Productions"],
      expectedHash: "#/director/projects",
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Start a new production",
      description: "Create the production record before searching for actors, crew, locations, or equipment.",
      doThis: "Tap New Project.",
      prepareRoute: "#/director/projects",
      routeLabel: "Productions > New Project",
      action: "click",
      actionLabel: "Tap New Project",
      targetLabels: ["New Project"],
      expectedHash: "#/director/projects/create",
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Choose the correct production type",
      description: "Pick the format that matches the actual job so requirements and reporting stay accurate.",
      doThis: "Choose TVC, Feature Film, Drama, Music Video, Fashion Shoot, or Custom.",
      prepareRoute: "#/director/projects/create",
      routeLabel: "Project setup > Type + Info",
      action: "click",
      actionLabel: "Choose one project type",
      targetLabels: ["TVC", "Feature Film", "Drama", "Music Video", "Fashion Shoot", "Custom"],
      multipleTargets: true,
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Name and describe the production",
      description: "Use a clear working title and a short description of the story, tone, and deliverable.",
      doThis: "Enter the project title and description.",
      prepareRoute: "#/director/projects/create",
      routeLabel: "Project setup > Type + Info",
      action: "input",
      actionLabel: "Enter title and description",
      targetLabels: ["Project title (e.g., Ramadan Telefilm 2027)", "Description / tone"],
      multipleTargets: true,
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Set locations and production dates",
      description: "Cities and dates drive availability, travel, quotations, and scheduling.",
      doThis: "Open Location + Dates.",
      prepareRoute: "#/director/projects/create",
      routeLabel: "Project setup > Location + Dates",
      action: "click",
      actionLabel: "Open Location + Dates",
      targetLabels: ["2. Location + Dates"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Add every production city",
      description: "Add the main city plus travel, studio, or exterior locations that affect hiring.",
      doThis: "Tap City / cities + Add city and add the required cities.",
      routeLabel: "Project setup > Cities",
      action: "click",
      actionLabel: "Add production cities",
      targetLabels: ["City / cities + Add city"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Choose the real date range",
      description: "Use planned prep and shoot dates; mark tentative dates only when they are genuinely unconfirmed.",
      doThis: "Tap the Start / End date-range button and select the dates.",
      routeLabel: "Project setup > Dates",
      action: "click",
      actionLabel: "Select the date range",
      targetLabels: ["Start Select a date range End Select a date range"],
      completionTargetLabels: ["Done"],
      completionReadyPattern: "days selected",
      completionInstruction: "Select a start date and an end date, then tap Done.",
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Set the production budget",
      description: "The budget range becomes the reference point for offers, milestones, and financial reporting.",
      doThis: "Open Budget.",
      routeLabel: "Project setup > Budget",
      action: "click",
      actionLabel: "Open Budget",
      targetLabels: ["3. Budget"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Enter the minimum and maximum budget",
      description: "Use an approved and realistic PKR range, including production contingency.",
      doThis: "Enter both budget values.",
      routeLabel: "Project setup > Budget range",
      action: "input",
      actionLabel: "Enter the budget range",
      targetLabels: ["Budget minimum (PKR)", "Budget maximum (PKR)"],
      multipleTargets: true,
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Add the core production team",
      description: "Record co-producers and department heads who need quick project context.",
      doThis: "Open Team.",
      routeLabel: "Project setup > Team",
      action: "click",
      actionLabel: "Open Team",
      targetLabels: ["4. Team"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Enter a team member",
      description: "Add the responsible producer or department head first.",
      doThis: "Enter the team member name.",
      routeLabel: "Project setup > Team member",
      action: "input",
      actionLabel: "Enter a team member name",
      targetLabels: ["Team member name"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Confirm the team member",
      description: "Use Add so the person appears in the project summary.",
      doThis: "Tap Add.",
      routeLabel: "Project setup > Team",
      action: "click",
      actionLabel: "Add the team member",
      targetLabels: ["Add"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Attach the approved script and files",
      description: "Keep the latest script, treatment, or brief inside the project so invited collaborators receive the correct version.",
      doThis: "Open Script & Files.",
      routeLabel: "Project setup > Script & Files",
      action: "click",
      actionLabel: "Open Script & Files",
      targetLabels: ["5. Script & Files"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Add the current script or brief",
      description: "Upload only approved PDF, DOC, DOCX, or TXT material; this step can be skipped when no approved file exists yet.",
      doThis: "Tap the Script vault upload button.",
      routeLabel: "Project setup > Script vault",
      action: "click",
      actionLabel: "Add a script from the device",
      targetLabels: ["Script vault Upload PDF, DOC, DOCX, or TXT. Scripts stay private to invited team members. No files attached yet Add script from device", "Add script from device"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Define all hiring requirements",
      description: "Requirements are the hiring checklist for this production.",
      doThis: "Open Requirements.",
      routeLabel: "Project setup > Requirements",
      action: "click",
      actionLabel: "Open Requirements",
      targetLabels: ["6. Requirements"],
    }),
  ];

  [
    ["Lead actor", "Add the lead acting role", "Add role range, language, performance skills, dates, audition instructions, and budget."],
    ["Supporting cast", "Add supporting cast", "Separate supporting roles so every offer can be evaluated against a clear brief."],
    ["Editorial model", "Add model requirements", "Specify usage rights, territory, media, term, fitting dates, and deliverables."],
    ["DOP", "Add the camera department lead", "State experience, prep and shoot days, camera package, overtime, and deliverables."],
    ["Location scout", "Add location sourcing", "Include city, access, power, sound, parking, permits, availability, and shoot hours."],
    ["Lighting package", "Add equipment requirements", "List quantities, included crew, delivery, handover, return, damage, and deposit terms."],
    ["Custom requirement", "Add every remaining requirement", "Use separate custom requirements for sound, art, wardrobe, makeup, production, post, transport, catering, safety, agencies, brands, legal, insurance, and distribution."],
  ].forEach(([label, title, description]) => {
    workflowSteps.push(workflowStep({
      chapter: "1 · Create project",
      title,
      description,
      doThis: `Tap ${label}, then complete its fields before continuing.`,
      routeLabel: `Project requirements > ${label}`,
      action: "click",
      actionLabel: `Add ${label}`,
      targetLabels: [label],
    }));
  });

  workflowSteps.push(
    workflowStep({
      chapter: "1 · Create project",
      title: "Review the entire production",
      description: "Confirm type, title, cities, dates, budget, team, files, and every requirement before creating the project.",
      doThis: "Open Review.",
      routeLabel: "Project setup > Review",
      action: "click",
      actionLabel: "Open Review",
      targetLabels: ["7. Review"],
    }),
    workflowStep({
      chapter: "1 · Create project",
      title: "Create the complete project",
      description: "Only create it after the review summary is complete. The guide will not press this button for you.",
      doThis: "Tap Create Project when every section is correct.",
      routeLabel: "Project setup > Create Project",
      action: "click",
      actionLabel: "Create Project",
      targetLabels: ["Create Project"],
      expectedHash: "#/director/projects",
    })
  );

  const hiringCategories = [
    ["Actors", "actors and speaking talent"],
    ["Models", "models and usage-rights work"],
    ["Influencers", "influencers and campaign deliverables"],
    ["Crew", "crew and department specialists"],
    ["Locations", "locations and production spaces"],
    ["Media & Equipment", "camera, lighting, sound, and equipment packages"],
    ["Agencies", "casting agencies and specialist partners"],
  ];

  hiringCategories.forEach(([label, subject]) => {
    workflowSteps.push(
      workflowStep({
        chapter: "2 · Hire the project",
        title: `Find ${subject}`,
        description: `Filter the marketplace to ${label}, then compare verified providers against the saved project requirement.`,
        doThis: `Tap ${label}.`,
        prepareRoute: "#/director/marketplace",
        routeLabel: `Marketplace > ${label}`,
        action: "click",
        actionLabel: `Filter by ${label}`,
        targetLabels: [label],
      }),
      workflowStep({
        chapter: "2 · Hire the project",
        title: `Review a ${label} profile`,
        description: "Check evidence, availability, rates, verification, reputation, inclusions, exclusions, and conflicts before requesting.",
        doThis: "Open one visible Profile.",
        routeLabel: `${label} results > Profile`,
        action: "click",
        actionLabel: "Open one Profile",
        targetLabels: ["Profile"],
        multipleTargets: true,
      }),
      workflowStep({
        chapter: "2 · Hire the project",
        title: `Request the selected ${label} provider`,
        description: "The booking request must be attached to the project and its matching requirement.",
        doThis: "Tap Request on the reviewed provider.",
        routeLabel: `${label} profile > Request`,
        action: "click",
        actionLabel: "Tap Request",
        targetLabels: ["Request"],
        multipleTargets: true,
        expectedHash: "#/director/booking-request",
      }),
      workflowStep({
        chapter: "2 · Hire the project",
        title: `Send the complete ${label} request`,
        description: "Select the project and requirement, confirm dates, scope, amount, expiry, usage or package terms, and a clear message before sending.",
        doThis: "Complete every visible field, then tap Send Request.",
        prepareRoute: "#/director/booking-request",
        routeLabel: "Booking Request > Send",
        action: "click",
        actionLabel: "Send the booking request",
        targetLabels: ["Send Request", "Submit Request", "Send booking request"],
      })
    );
  });

  workflowSteps.push(
    workflowStep({
      chapter: "3 · Close the deal",
      title: "Open bargaining after providers respond",
      description: "Compare every counteroffer with the original project requirement before changing price, scope, dates, rights, or cancellation terms.",
      doThis: "Tap Deals.",
      prepareRoute: "#/console",
      routeLabel: "Console > Deals",
      action: "click",
      actionLabel: "Open Deals",
      targetLabels: ["Deals"],
      expectedHash: "#/director/bargaining",
    }),
    workflowStep({
      chapter: "3 · Close the deal",
      title: "Open Contracts",
      description: "Only generate contracts from accepted commercial terms.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "3 · Close the deal",
      title: "Review and sign contracts",
      description: "Check legal names, scope, dates, milestones, rights, cancellation, safety, confidentiality, insurance, and attachments before signing.",
      doThis: "Tap Contracts.",
      routeLabel: "More > Contracts",
      action: "click",
      actionLabel: "Open Contracts",
      targetLabels: ["Contracts"],
      expectedHash: "#/director/contracts",
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Open milestone payments",
      description: "Pay only against the signed contract and the correct milestone, amount, currency, and recipient.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Verify payments and proofs",
      description: "Use the ledger to resolve rejected proofs, mismatched milestones, duplicate evidence, and overdue amounts.",
      doThis: "Tap Payments.",
      routeLabel: "More > Payments",
      action: "click",
      actionLabel: "Open Payments",
      targetLabels: ["Payments"],
      expectedHash: "#/director/payments",
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Open the production schedule",
      description: "Schedule confirmed people, locations, equipment, call times, handovers, returns, travel, dependencies, and changes.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Maintain the live schedule",
      description: "Update the schedule only after checking availability and alert every affected person when plans change.",
      doThis: "Tap Schedule.",
      routeLabel: "More > Schedule",
      action: "click",
      actionLabel: "Open Schedule",
      targetLabels: ["Schedule"],
      expectedHash: "#/director/schedule",
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Open the Project Room",
      description: "Keep approved files, pinned call sheets, decisions, and concise production updates attached to the project.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "4 · Run production",
      title: "Coordinate in the Project Room",
      description: "Use clear versions and never post passwords, payment secrets, or unnecessary identity documents.",
      doThis: "Tap Room.",
      routeLabel: "More > Room",
      action: "click",
      actionLabel: "Open Room",
      targetLabels: ["Room"],
      expectedHash: "#/director/room",
    }),
    workflowStep({
      chapter: "5 · Review & report",
      title: "Open production reports",
      description: "Reports reveal incomplete contracts, payments, schedules, requirements, and deliveries before wrap.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "5 · Review & report",
      title: "Generate and check reports",
      description: "Export only the correct project and date range for authorized stakeholders, then resolve every pending action before completion.",
      doThis: "Tap Reports.",
      routeLabel: "More > Reports",
      action: "click",
      actionLabel: "Open Reports",
      targetLabels: ["Reports"],
      expectedHash: "#/director/reports",
    }),
    workflowStep({
      chapter: "5 · Review & report",
      title: "Finish account and verification checks",
      description: "Keep company identity, profile, KYC, contact information, and payment details accurate for trusted transactions.",
      doThis: "Tap More.",
      prepareRoute: "#/console",
      routeLabel: "Console > More",
      action: "click",
      actionLabel: "Open More",
      targetLabels: ["More"],
    }),
    workflowStep({
      chapter: "5 · Review & report",
      title: "Open Accounts",
      description: "Review profile and verification details, then return to the Production Console when complete.",
      doThis: "Tap Accounts.",
      routeLabel: "More > Accounts",
      action: "click",
      actionLabel: "Open Accounts",
      targetLabels: ["Accounts"],
    }),
    workflowStep({
      chapter: "Complete",
      title: "The complete director workflow is ready",
      description: "Use this order for every production: create the project, define all requirements, hire by requirement, negotiate, contract, pay by milestone, schedule, coordinate, and report.",
      doThis: "Finish the guide. You can restart it from Director Guide at any time.",
      checklist: ["Everything stays attached to one project", "Every provider is hired against a requirement", "Every payment follows a signed contract"],
      prepareRoute: "#/console",
      routeLabel: "Production Console",
      action: "manual",
      actionLabel: "Finish tutorial",
      complete: true,
    })
  );

  workflowSteps.forEach((step) => {
    if (step.chapter === "1 · Create project" && step.action !== "manual" && step.title !== "Open Productions" && step.title !== "Start a new production") {
      step.prepareRoute = "#/director/projects/create";
      if (step.routeLabel.includes("Type + Info")) step.gateLabels = ["1. Type + Info"];
      if (step.routeLabel.includes("Cities") || step.routeLabel.includes("Dates")) step.gateLabels = ["2. Location + Dates"];
      if (step.routeLabel.includes("Budget range")) step.gateLabels = ["3. Budget"];
      if (step.routeLabel.includes("Team member") || (step.routeLabel.endsWith("> Team") && step.targetLabels && step.targetLabels.includes("Add"))) step.gateLabels = ["4. Team"];
      if (step.routeLabel.includes("Script vault")) step.gateLabels = ["5. Script & Files"];
      if (step.routeLabel.startsWith("Project requirements")) step.gateLabels = ["6. Requirements"];
      if (step.routeLabel.includes("Create Project")) step.gateLabels = ["7. Review"];
    }

    if (step.routeLabel && step.routeLabel.startsWith("More >")) {
      step.prepareRoute = "#/console";
      step.gateLabels = ["More"];
    }

    if (step.chapter === "2 · Hire the project" && step.title.startsWith("Request the selected")) {
      step.prepareRoute = "#/director/marketplace";
    }
  });

  steps.splice(0, steps.length, ...workflowSteps);

  const state = {
    open: false,
    index: 0,
    userKey: null,
    isDirector: false,
    autoTimer: null,
    toastTimer: null,
    lastToken: null,
    lastFocused: null,
    currentRect: null,
    currentRects: [],
    currentTargets: [],
    completedInputKeys: new Set(),
    targetIsGate: false,
    awaitingCompletion: false,
    targetRetryCount: 0,
    geometryFrame: null,
    geometrySignature: "",
    geometryStableFrames: 0,
    layoutTimer: null,
    scrollAttempted: false,
    actionPending: false,
    actionTimer: null,
  };

  let root;
  let launcherDock;
  let launcher;
  let replayButton;
  let launcherProgress;
  let layer;
  let scrim;
  let spotlight;
  let targetTag;
  let card;
  let controls;
  let dockCount;
  let progress;
  let chapter;
  let stepCount;
  let title;
  let description;
  let mission;
  let checklist;
  let routeNote;
  let backButton;
  let exploreButton;
  let skipButton;
  let nextButton;
  let closeButton;
  let toast;
  let actionStatus;

  function readIdentity() {
    try {
      const rawIdentity = window.sessionStorage.getItem(IDENTITY_KEY);
      if (rawIdentity) {
        const identity = JSON.parse(rawIdentity);
        const roles = Array.isArray(identity.roles) ? identity.roles : [];
        if (identity.public_id) {
          return {
            tokenValue: rawIdentity,
            userKey: String(identity.public_id),
            isDirector:
              roles.includes(DIRECTOR_ROLE) || identity.active_role === DIRECTOR_ROLE,
          };
        }
      }

      const route = window.location.hash || "";
      if (route.startsWith("#/director") || route.startsWith("#/console")) {
        window.sessionStorage.setItem(ROUTE_SESSION_KEY, "true");
        return {
          tokenValue: "director-route-session",
          userKey: "director-route-session",
          isDirector: true,
        };
      }

      const directorRouteSeen = window.sessionStorage.getItem(ROUTE_SESSION_KEY) === "true";
      const adjacentRoute =
        route.startsWith("#/settings") ||
        route.startsWith("#/profile/roles") ||
        route.startsWith("#/support") ||
        route.startsWith("#/public/account");
      if (directorRouteSeen && adjacentRoute) {
        return {
          tokenValue: "director-route-session",
          userKey: "director-route-session",
          isDirector: true,
        };
      }
    } catch (_error) {
      return null;
    }
    return null;
  }

  function storageKey() {
    return state.userKey ? `${STORAGE_PREFIX}${state.userKey}` : null;
  }

  function loadProgress() {
    const key = storageKey();
    if (!key) return { index: 0, status: "new" };
    try {
      const stored = JSON.parse(window.localStorage.getItem(key) || "null");
      if (!stored || typeof stored !== "object") return { index: 0, status: "new" };
      const safeIndex = Math.max(0, Math.min(steps.length - 1, Number(stored.index) || 0));
      return { index: safeIndex, status: stored.status || "started" };
    } catch (_error) {
      return { index: 0, status: "new" };
    }
  }

  function saveProgress(status) {
    const key = storageKey();
    if (!key) return;
    try {
      window.localStorage.setItem(
        key,
        JSON.stringify({
          index: state.index,
          status,
          updatedAt: new Date().toISOString(),
        })
      );
    } catch (_error) {
      // The guide remains usable when storage is unavailable.
    }
  }

  function buildDom() {
    if (document.getElementById("cc-director-guide-root")) return;
    root = document.createElement("div");
    root.id = "cc-director-guide-root";
    root.innerHTML = `
      <div class="cc-guide-launcher-dock" data-visible="false" data-context="portal" aria-label="Director tutorial actions">
        <button class="cc-guide-replay" type="button" aria-label="Play director demo from the beginning" title="Play director demo from the beginning">
          ${icon("play")}
          <span>Play demo</span>
        </button>
        <button class="cc-guide-launcher" type="button" aria-label="Open Director Guide" title="Open Director Guide">
          ${icon("compass")}
          <span class="cc-guide-launcher-label">Director Guide</span>
          <span class="cc-guide-launcher-progress" aria-hidden="true">1</span>
        </button>
      </div>
      <div class="cc-guide-layer" data-open="false">
        <div class="cc-guide-scrim"></div>
        <div class="cc-guide-spotlight" aria-hidden="true"></div>
        <div class="cc-guide-target-tag" aria-hidden="true">Click here</div>
        <section class="cc-guide-card" role="dialog" aria-modal="false" aria-labelledby="cc-guide-title" aria-describedby="cc-guide-mission-copy">
          <header class="cc-guide-card-header">
            <div>
              <div class="cc-guide-eyebrow">
                <span class="cc-guide-chapter"></span>
                <span class="cc-guide-step-count"></span>
              </div>
              <h2 class="cc-guide-title" id="cc-guide-title"></h2>
            </div>
            <button class="cc-guide-close" type="button" aria-label="Pause tutorial" title="Pause tutorial">
              ${icon("close")}
            </button>
          </header>
          <div class="cc-guide-body">
            <p class="cc-guide-description" id="cc-guide-description"></p>
            <div class="cc-guide-mission">
              <div class="cc-guide-mission-label">${icon("target")} Do this now</div>
              <p id="cc-guide-mission-copy"></p>
            </div>
            <details class="cc-guide-details">
              <summary>Why this matters</summary>
              <p class="cc-guide-details-description"></p>
              <ul class="cc-guide-checklist"></ul>
            </details>
            <div class="cc-guide-route-note">${icon("route")}<span></span></div>
          </div>
        </section>
        <nav class="cc-guide-controls cc-guide-footer" data-placement="bottom-center" aria-label="Tutorial controls">
          <button class="cc-guide-button cc-guide-button-secondary cc-guide-explore" type="button" aria-label="Pause tutorial" title="Pause tutorial">
            ${icon("close")}<span class="cc-guide-control-label">Pause</span>
          </button>
          <button class="cc-guide-button cc-guide-back" type="button" aria-label="Previous tutorial step" title="Previous step">
            ${icon("arrowLeft")}<span class="cc-guide-control-label">Back</span>
          </button>
          <span class="cc-guide-dock-count" aria-label="Tutorial progress">1 / ${steps.length}</span>
          <span class="cc-guide-action-status" role="status" aria-live="polite">Click the highlighted control</span>
          <button class="cc-guide-button cc-guide-button-secondary cc-guide-skip" type="button" aria-label="Skip this tutorial step" title="Skip step">
            ${icon("skipForward")}<span class="cc-guide-control-label">Skip</span>
          </button>
          <button class="cc-guide-button cc-guide-button-primary cc-guide-next" type="button">
            <span>Start</span>${icon("arrowRight")}
          </button>
          <div class="cc-guide-progress-track" role="progressbar" aria-label="Tutorial progress" aria-valuemin="1" aria-valuemax="${steps.length}">
            <div class="cc-guide-progress-value"></div>
          </div>
        </nav>
      </div>
      <div class="cc-guide-toast" role="status" aria-live="polite">
        ${icon("compass")}<span>Tutorial paused. Use Director Guide to resume.</span>
      </div>
    `;
    document.body.appendChild(root);

    launcherDock = root.querySelector(".cc-guide-launcher-dock");
    launcher = root.querySelector(".cc-guide-launcher");
    replayButton = root.querySelector(".cc-guide-replay");
    launcherProgress = root.querySelector(".cc-guide-launcher-progress");
    layer = root.querySelector(".cc-guide-layer");
    scrim = root.querySelector(".cc-guide-scrim");
    spotlight = root.querySelector(".cc-guide-spotlight");
    targetTag = root.querySelector(".cc-guide-target-tag");
    card = root.querySelector(".cc-guide-card");
    controls = root.querySelector(".cc-guide-controls");
    dockCount = root.querySelector(".cc-guide-dock-count");
    progress = root.querySelector(".cc-guide-progress-value");
    chapter = root.querySelector(".cc-guide-chapter");
    stepCount = root.querySelector(".cc-guide-step-count");
    title = root.querySelector(".cc-guide-title");
    description = root.querySelector(".cc-guide-description");
    mission = root.querySelector(".cc-guide-mission p");
    checklist = root.querySelector(".cc-guide-checklist");
    routeNote = root.querySelector(".cc-guide-route-note span");
    backButton = root.querySelector(".cc-guide-back");
    exploreButton = root.querySelector(".cc-guide-explore");
    skipButton = root.querySelector(".cc-guide-skip");
    nextButton = root.querySelector(".cc-guide-next");
    closeButton = root.querySelector(".cc-guide-close");
    toast = root.querySelector(".cc-guide-toast");
    actionStatus = root.querySelector(".cc-guide-action-status");

    launcher.addEventListener("click", () => {
      const stored = loadProgress();
      state.index = stored.status === "completed" ? 0 : stored.index;
      openGuide(false);
    });
    replayButton.addEventListener("click", () => {
      state.index = 0;
      saveProgress("started");
      openGuide(false);
    });
    closeButton.addEventListener("click", () => closeGuide(true));
    backButton.addEventListener("click", () => move(-1));
    nextButton.addEventListener("click", () => move(1));
    exploreButton.addEventListener("click", () => closeGuide(true));
    skipButton.addEventListener("click", () => move(1, true));
    window.addEventListener("resize", scheduleGuideRealign);
    window.addEventListener("hashchange", () => {
      setTimeout(() => {
        if (state.open) {
          const step = steps[state.index];
          if (state.actionPending && step.expectedHash && window.location.hash === step.expectedHash) {
            completeCurrentAction();
          } else {
            renderSpotlight(step);
          }
        }
        updateLauncherContext();
      }, 420);
    });
    document.addEventListener("cineconnect-session-identity", syncIdentity);
    document.addEventListener("keydown", handleKeyboard, true);
    document.addEventListener("pointerup", handleTargetPointer, true);
    document.addEventListener("click", handleTargetPointer, true);
    document.addEventListener("input", handleTargetInput, true);
    document.addEventListener("scroll", restartTargetGeometry, true);
  }

  function handleKeyboard(event) {
    if (!state.open) return;
    if (event.key === "Escape") {
      event.preventDefault();
      closeGuide(true);
      return;
    }
    if (event.key === "ArrowLeft" && !event.metaKey && !event.ctrlKey) {
      event.preventDefault();
      move(-1);
    }
  }

  function goToRoute(step) {
    const route = step.prepareRoute || step.route;
    if (!route || window.location.hash === route) return;
    window.location.hash = route;
  }

  function enableFlutterSemantics() {
    const control = document.querySelector(
      'flt-semantics-placeholder[aria-label="Enable accessibility"], button[aria-label="Enable accessibility"]'
    );
    if (!control) return;
    const previous = document.activeElement;
    try {
      control.focus({ preventScroll: true });
      control.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", code: "Enter", bubbles: true }));
      control.dispatchEvent(new KeyboardEvent("keyup", { key: "Enter", code: "Enter", bubbles: true }));
      if (previous && typeof previous.focus === "function") previous.focus({ preventScroll: true });
    } catch (_error) {
      // Coordinate targets remain available when Flutter semantics cannot be enabled.
    }
  }

  function semanticTargets(labels, multipleTargets) {
    if (!Array.isArray(labels) || labels.length === 0) return [];
    const normalizedLabels = labels.map((label) => String(label).replace(/\s+/g, " ").trim().toLowerCase());
    const nodes = Array.from(
      document.querySelectorAll(
        'flt-semantics, [aria-label], [role="button"], button, input, textarea, select, [contenteditable="true"]'
      )
    );
    const viewportArea = Math.max(1, innerWidth * innerHeight);
    const candidates = [];

    nodes.forEach((node) => {
      if (root && root.contains(node)) return;
      const text = [
        node.getAttribute && node.getAttribute("aria-label"),
        node.getAttribute && node.getAttribute("placeholder"),
        node.textContent,
      ]
        .filter(Boolean)
        .join(" ")
        .replace(/\s+/g, " ")
        .trim()
        .toLowerCase();
      if (!text) return;

      const exactLabel = normalizedLabels.find((label) => text === label);
      const containedLabel = exactLabel || normalizedLabels.find((label) => text.includes(label));
      if (!containedLabel) return;
      const rawRect = node.getBoundingClientRect();
      if (
        rawRect.width < 20 ||
        rawRect.height < 20 ||
        rawRect.bottom <= 0 ||
        rawRect.right <= 0 ||
        rawRect.top >= innerHeight ||
        rawRect.left >= innerWidth
      ) return;

      const area = rawRect.width * rawRect.height;
      const isExact = Boolean(exactLabel);
      // Never outline a broad Flutter container as a button fallback. Exact
      // semantics always win; contained matches must still be button-sized.
      if (!isExact && area / viewportArea > 0.16) return;
      candidates.push({
        node,
        label: containedLabel,
        exact: isExact,
        score: (isExact ? 0 : 1000000) + area + Math.max(0, text.length - containedLabel.length) * 60,
        rect: {
          left: Math.max(0, rawRect.left),
          top: Math.max(0, rawRect.top),
          width: Math.min(innerWidth - Math.max(0, rawRect.left), rawRect.width),
          height: Math.min(innerHeight - Math.max(0, rawRect.top), rawRect.height),
          radius: 14,
        },
      });
    });

    candidates.sort((a, b) => a.score - b.score);
    if (!multipleTargets) return candidates.length ? [candidates[0]] : [];

    const exactCandidates = candidates.filter((candidate) => candidate.exact);
    const source = exactCandidates.length ? exactCandidates : candidates;
    const seen = new Set();
    return source.filter((candidate) => {
      const key = `${Math.round(candidate.rect.left)}:${Math.round(candidate.rect.top)}:${Math.round(candidate.rect.width)}:${Math.round(candidate.rect.height)}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).slice(0, 12);
  }

  function resolveTargets(step) {
    // Actionable missions intentionally use semantic controls only. This keeps
    // the border attached to the real Flutter button at every screen size.
    const isCompletionTarget = Boolean(state.awaitingCompletion && step.completionTargetLabels);
    const labels = isCompletionTarget ? step.completionTargetLabels : step.targetLabels;
    const directTargets = semanticTargets(labels, isCompletionTarget ? false : Boolean(step.multipleTargets));
    if (directTargets.length) return directTargets;
    if (isCompletionTarget) return [];
    return semanticTargets(step.gateLabels, false).map((targetItem) => Object.assign(targetItem, { isGate: true }));
  }

  function clearTargetHighlights() {
    if (state.geometryFrame) cancelAnimationFrame(state.geometryFrame);
    state.geometryFrame = null;
    state.geometrySignature = "";
    state.geometryStableFrames = 0;
    document.querySelectorAll('[data-cc-guide-target="true"]').forEach((node) => {
      node.removeEventListener("click", handleTargetPointer, true);
      node.removeAttribute("data-cc-guide-target");
      node.removeAttribute("data-cc-guide-success");
    });
    layer && layer.querySelectorAll('.cc-guide-spotlight[data-guide-clone="true"]').forEach((node) => node.remove());
    if (spotlight) {
      spotlight.dataset.visible = "false";
      spotlight.dataset.success = "false";
      spotlight.dataset.secondary = "false";
    }
    state.currentRect = null;
    state.currentRects = [];
    state.currentTargets = [];
    state.targetIsGate = false;
  }

  function scheduleGuideRealign() {
    if (!state.open) return;
    clearTimeout(state.layoutTimer);
    state.layoutTimer = setTimeout(() => {
      if (state.open && !state.actionPending) {
        state.scrollAttempted = false;
        renderSpotlight(steps[state.index]);
      }
    }, 140);
  }

  function unionRect(rects) {
    const left = Math.min(...rects.map((rect) => rect.left));
    const top = Math.min(...rects.map((rect) => rect.top));
    const right = Math.max(...rects.map((rect) => rect.left + rect.width));
    const bottom = Math.max(...rects.map((rect) => rect.top + rect.height));
    return { left, top, width: right - left, height: bottom - top, radius: 16 };
  }

  function placeCoachMark(rect) {
    const margin = 12;
    const gap = 18;
    const cardWidth = card.offsetWidth || Math.min(286, innerWidth - margin * 2);
    const cardHeight = card.offsetHeight || 110;
    const controlsRect = controls ? controls.getBoundingClientRect() : null;
    const playerAtTop = controls && controls.dataset.placement === "top-center";
    const availableTop = playerAtTop && controlsRect
      ? controlsRect.bottom + 12
      : margin;
    const availableBottom = !playerAtTop && controlsRect
      ? controlsRect.top - 12
      : innerHeight - margin;
    const spaces = {
      bottom: availableBottom - (rect.top + rect.height),
      top: rect.top - availableTop,
      right: innerWidth - (rect.left + rect.width),
      left: rect.left,
    };

    let placement = "bottom";
    if (spaces.bottom >= cardHeight + gap + margin) placement = "bottom";
    else if (spaces.top >= cardHeight + gap + margin) placement = "top";
    else if (spaces.right >= cardWidth + gap + margin) placement = "right";
    else if (spaces.left >= cardWidth + gap + margin) placement = "left";
    else placement = spaces.top > spaces.bottom ? "top" : "bottom";

    let left = rect.left + rect.width / 2 - cardWidth / 2;
    let top = rect.top + rect.height + gap;
    if (placement === "top") top = rect.top - cardHeight - gap;
    if (placement === "right") {
      left = rect.left + rect.width + gap;
      top = rect.top + rect.height / 2 - cardHeight / 2;
    }
    if (placement === "left") {
      left = rect.left - cardWidth - gap;
      top = rect.top + rect.height / 2 - cardHeight / 2;
    }

    left = Math.max(margin, Math.min(innerWidth - cardWidth - margin, left));
    top = Math.max(availableTop, Math.min(availableBottom - cardHeight, top));
    card.dataset.placement = placement;
    card.style.left = `${left}px`;
    card.style.top = `${top}px`;
    card.style.right = "auto";
    card.style.bottom = "auto";
    card.style.transform = "none";
  }

  function placeControls(rect) {
    if (!controls) return;
    const targetNearBottom = Boolean(
      rect && rect.top + rect.height / 2 > innerHeight * 0.68
    );
    controls.dataset.placement = targetNearBottom
      ? "top-center"
      : "bottom-center";
  }

  function hasCompletionEvidence(step) {
    if (!step.completionReadyPattern) return true;
    const pattern = String(step.completionReadyPattern).toLowerCase();
    return Array.from(document.querySelectorAll("[aria-label], flt-semantics, [role]"))
      .some((node) => {
        if (root && root.contains(node)) return false;
        const text = `${node.getAttribute && node.getAttribute("aria-label") || ""} ${node.textContent || ""}`
          .replace(/\s+/g, " ")
          .trim()
          .toLowerCase();
        return text.includes(pattern);
      });
  }

  function liveTargetRect(node) {
    if (!node || !node.isConnected) return null;
    const rawRect = node.getBoundingClientRect();
    if (
      rawRect.width < 20 ||
      rawRect.height < 20 ||
      rawRect.bottom <= 0 ||
      rawRect.right <= 0 ||
      rawRect.top >= innerHeight ||
      rawRect.left >= innerWidth
    ) return null;
    const left = Math.max(0, rawRect.left);
    const top = Math.max(0, rawRect.top);
    return {
      left,
      top,
      width: Math.max(0, Math.min(innerWidth - left, rawRect.width)),
      height: Math.max(0, Math.min(innerHeight - top, rawRect.height)),
      radius: 14,
    };
  }

  function positionTargetOutline(targetItem) {
    const outline = targetItem.outline;
    const rect = targetItem.rect;
    if (!outline || !rect) return;
    const pad = 4;
    const left = Math.max(0, rect.left - pad);
    const top = Math.max(0, rect.top - pad);
    outline.style.left = `${left}px`;
    outline.style.top = `${top}px`;
    outline.style.width = `${Math.min(innerWidth - left, rect.width + pad * 2)}px`;
    outline.style.height = `${Math.min(innerHeight - top, rect.height + pad * 2)}px`;
    outline.style.borderRadius = `${rect.radius || 14}px`;
    outline.dataset.visible = "true";
  }

  function trackTargetGeometry() {
    if (!state.open || !state.currentTargets.length) return;
    const visibleTargets = [];
    let needsResolve = false;
    state.currentTargets.forEach((targetItem) => {
      const nextRect = liveTargetRect(targetItem.node);
      if (!nextRect) {
        needsResolve = true;
        if (targetItem.outline) targetItem.outline.dataset.visible = "false";
        return;
      }
      targetItem.rect = nextRect;
      positionTargetOutline(targetItem);
      visibleTargets.push(targetItem);
    });

    if (visibleTargets.length) {
      state.currentRects = visibleTargets.map((targetItem) => targetItem.rect);
      state.currentRect = unionRect(state.currentRects);
      const signature = state.currentRects
        .map((rect) => [rect.left, rect.top, rect.width, rect.height].map(Math.round).join(":"))
        .join("|");
      if (signature !== state.geometrySignature) {
        state.geometrySignature = signature;
        state.geometryStableFrames = 0;
        placeControls(state.currentRect);
        placeCoachMark(state.currentRect);
      } else {
        state.geometryStableFrames += 1;
      }
    }
    if (needsResolve) {
      scheduleGuideRealign();
      return;
    }
    if (state.geometryStableFrames >= 45) {
      state.geometryFrame = null;
      return;
    }
    state.geometryFrame = requestAnimationFrame(trackTargetGeometry);
  }

  function restartTargetGeometry() {
    if (!state.open || !state.currentTargets.length || state.geometryFrame) return;
    state.geometryStableFrames = 0;
    state.geometryFrame = requestAnimationFrame(trackTargetGeometry);
  }

  function renderSpotlight(step) {
    clearTargetHighlights();
    const targets = step.action === "manual" ? [] : resolveTargets(step);
    targets.forEach((targetItem, index) => {
      targetItem.key = `${targetItem.label || "target"}:${index}`;
    });
    const rects = targets.map((target) => target.rect);
    state.currentTargets = targets;
    state.currentRects = rects;
    state.currentRect = rects.length ? unionRect(rects) : null;
    state.targetIsGate = targets.some((target) => target.isGate);
    placeControls(state.currentRect);
    if (!rects.length || step.action === "manual") {
      scrim.dataset.spotlight = "false";
      targetTag.dataset.visible = "false";
      card.dataset.placement = "center";
      card.style.left = "50%";
      card.style.top = "calc(50% - 42px)";
      card.style.right = "auto";
      card.style.bottom = "auto";
      card.style.transform = "translate(-50%, -50%)";
      if (step.action !== "manual") {
        actionStatus.textContent = state.awaitingCompletion
          ? "Select both dates, then tap Done"
          : `Waiting for the exact “${step.actionLabel}” control`;
        if (state.targetRetryCount < 6) {
          state.targetRetryCount += 1;
          clearTimeout(state.actionTimer);
          state.actionTimer = setTimeout(() => renderSpotlight(step), 180);
        }
      }
      return;
    }

    if (!state.scrollAttempted) {
      const rawRects = targets.map((targetItem) => targetItem.node.getBoundingClientRect());
      const rawTop = Math.min(...rawRects.map((rect) => rect.top));
      const rawBottom = Math.max(...rawRects.map((rect) => rect.bottom));
      const safeTop = innerHeight < 500 ? 76 : 70;
      const safeBottom = innerHeight - (innerWidth < 700 ? 112 : 24);
      if (rawTop < safeTop || rawBottom > safeBottom) {
        state.scrollAttempted = true;
        targets[0].node.scrollIntoView({ behavior: "auto", block: "center", inline: "nearest" });
        clearTimeout(state.layoutTimer);
        state.layoutTimer = setTimeout(() => state.open && renderSpotlight(step), 260);
        return;
      }
    }

    targets.forEach((targetItem, index) => {
      const outline = index === 0 ? spotlight : spotlight.cloneNode(false);
      if (index > 0) {
        outline.dataset.guideClone = "true";
        outline.dataset.secondary = "true";
        layer.insertBefore(outline, targetTag);
      }
      outline.dataset.success = "false";
      targetItem.outline = outline;
      positionTargetOutline(targetItem);
      targetItem.node.setAttribute("data-cc-guide-target", "true");
      targetItem.node.addEventListener("click", handleTargetPointer, true);
    });

    scrim.dataset.spotlight = "true";
    targetTag.dataset.visible = "false";
    if (state.targetIsGate) {
      mission.textContent = "Open the highlighted section first.";
    } else if (state.awaitingCompletion && step.completionInstruction) {
      mission.textContent = step.completionInstruction;
    } else if (step.action === "input" && targets.length > 1) {
      mission.textContent = `Complete all ${targets.length} highlighted fields.`;
    }
    actionStatus.textContent = state.targetIsGate
      ? "Open the required section first"
      : step.action === "input"
      ? (targets.length > 1 ? `0 of ${targets.length} fields completed` : "Waiting for your input")
      : state.awaitingCompletion
      ? "Select both dates, then tap Done"
      : (step.multipleTargets ? "Choose one highlighted button" : "Click the highlighted button");
    state.geometryFrame = requestAnimationFrame(() => {
      placeCoachMark(state.currentRect);
      trackTargetGeometry();
    });
  }

  function pointIsInsideRect(x, y, rect) {
    return Boolean(
      rect && x >= rect.left && x <= rect.left + rect.width && y >= rect.top && y <= rect.top + rect.height
    );
  }

  function handleTargetPointer(event) {
    if (!state.open || state.actionPending) return;
    restartTargetGeometry();
    const step = steps[state.index];
    if (step.action !== "click" && !state.targetIsGate) return;
    if (root && root.contains(event.target)) return;
    const isDirectTargetEvent = Boolean(
      event.currentTarget &&
      event.currentTarget.getAttribute &&
      event.currentTarget.getAttribute("data-cc-guide-target") === "true"
    );
    const isInsideCurrentTarget = isDirectTargetEvent || state.currentRects.some((rect) =>
      pointIsInsideRect(event.clientX, event.clientY, rect)
    );
    if (!isInsideCurrentTarget) {
      if (state.awaitingCompletion && step.completionTargetLabels) {
        clearTimeout(state.actionTimer);
        state.actionTimer = setTimeout(() => renderSpotlight(step), 90);
      }
      return;
    }

    if (state.targetIsGate) {
      state.actionPending = true;
      actionStatus.textContent = "Opening the required section…";
      clearTimeout(state.actionTimer);
      state.actionTimer = setTimeout(() => {
        state.actionPending = false;
        renderSpotlight(step);
      }, 380);
      return;
    }

    if (step.completionTargetLabels && !state.awaitingCompletion) {
      state.awaitingCompletion = true;
      mission.textContent = step.completionInstruction || "Complete every required selection, then confirm.";
      actionStatus.textContent = "Waiting for the complete selection";
      clearTimeout(state.actionTimer);
      state.actionTimer = setTimeout(() => renderSpotlight(step), 260);
      return;
    }

    if (step.completionTargetLabels && state.awaitingCompletion && !hasCompletionEvidence(step)) {
      mission.textContent = step.completionInstruction || "Complete every required selection, then confirm.";
      actionStatus.textContent = "Select both required values before continuing";
      clearTimeout(state.actionTimer);
      state.actionTimer = setTimeout(() => renderSpotlight(step), 90);
      return;
    }

    state.actionPending = true;
    actionStatus.textContent = step.expectedHash ? "Opening…" : "Action completed";
    card.dataset.actionState = "working";
    if (!step.expectedHash || window.location.hash === step.expectedHash) {
      completeCurrentAction();
      return;
    }

    waitForExpectedRoute(step.expectedHash, Date.now());
  }

  function waitForExpectedRoute(expectedHash, startedAt) {
    clearTimeout(state.actionTimer);
    if (!state.open || !state.actionPending) return;
    if (window.location.hash === expectedHash || Date.now() - startedAt >= 2200) {
      completeCurrentAction();
      return;
    }
    state.actionTimer = setTimeout(() => waitForExpectedRoute(expectedHash, startedAt), 120);
  }

  function handleTargetInput(event) {
    if (!state.open || state.actionPending) return;
    restartTargetGeometry();
    const step = steps[state.index];
    if (step.action !== "input" || (root && root.contains(event.target))) return;
    const inputRect = event.target && typeof event.target.getBoundingClientRect === "function"
      ? event.target.getBoundingClientRect()
      : null;
    const eventLabel = `${event.target && event.target.getAttribute && event.target.getAttribute("aria-label") || ""} ${event.target && event.target.getAttribute && event.target.getAttribute("placeholder") || ""}`
      .replace(/\s+/g, " ")
      .trim()
      .toLowerCase();
    const matchingTargets = state.currentTargets.filter((targetItem) => {
      if (eventLabel) return eventLabel === targetItem.label;
      const nodeContainsInput = Boolean(
        targetItem.node &&
        (targetItem.node === event.target ||
          (typeof targetItem.node.contains === "function" && targetItem.node.contains(event.target)))
      );
      const rectOverlapsInput = Boolean(
        inputRect &&
        inputRect.width > 0 &&
        inputRect.height > 0 &&
        inputRect.right > targetItem.rect.left &&
        inputRect.left < targetItem.rect.left + targetItem.rect.width &&
        inputRect.bottom > targetItem.rect.top &&
        inputRect.top < targetItem.rect.top + targetItem.rect.height
      );
      return nodeContainsInput || rectOverlapsInput;
    });
    if (!matchingTargets.length) return;

    const value = "value" in event.target
      ? String(event.target.value == null ? "" : event.target.value).trim()
      : String(event.target.textContent || "").trim();
    matchingTargets.forEach((targetItem) => {
      if (value) {
        state.completedInputKeys.add(targetItem.key);
        targetItem.node.setAttribute("data-cc-guide-success", "true");
        if (targetItem.outline) targetItem.outline.dataset.success = "true";
      } else {
        state.completedInputKeys.delete(targetItem.key);
        targetItem.node.removeAttribute("data-cc-guide-success");
        if (targetItem.outline) targetItem.outline.dataset.success = "false";
      }
    });

    const requiredCount = step.multipleTargets ? state.currentTargets.length : 1;
    const completedCount = state.currentTargets.filter((targetItem) =>
      state.completedInputKeys.has(targetItem.key)
    ).length;
    if (completedCount < requiredCount) {
      const remaining = requiredCount - completedCount;
      actionStatus.textContent = `${completedCount} of ${requiredCount} fields completed`;
      mission.textContent = `${completedCount} of ${requiredCount} complete — fill ${remaining} more ${remaining === 1 ? "field" : "fields"}.`;
      return;
    }

    state.actionPending = true;
    completeCurrentAction();
  }

  function completeCurrentAction() {
    if (!state.open || !state.actionPending) return;
    clearTimeout(state.actionTimer);
    root.querySelectorAll('.cc-guide-spotlight[data-visible="true"]').forEach((node) => {
      node.dataset.success = "true";
    });
    document.querySelectorAll('[data-cc-guide-target="true"]').forEach((node) => {
      node.setAttribute("data-cc-guide-success", "true");
    });
    card.dataset.actionState = "success";
    actionStatus.textContent = "Completed";
    targetTag.textContent = "Done";
    targetTag.dataset.success = "true";
    state.actionTimer = setTimeout(() => move(1), 520);
  }

  function renderStep(navigate) {
    const step = steps[state.index];
    const desiredRoute = step.prepareRoute || step.route;
    const willNavigate = Boolean(navigate && desiredRoute && window.location.hash !== desiredRoute);
    clearTimeout(state.actionTimer);
    state.actionPending = false;
    state.awaitingCompletion = false;
    state.targetRetryCount = 0;
    state.scrollAttempted = false;
    state.completedInputKeys = new Set();
    clearTargetHighlights();
    targetTag.dataset.visible = "false";
    card.dataset.actionState = "waiting";
    targetTag.dataset.success = "false";
    if (navigate) goToRoute(step);
    chapter.textContent = step.chapter;
    stepCount.textContent = `${state.index + 1} / ${steps.length}`;
    dockCount.textContent = `${state.index + 1} / ${steps.length}`;
    title.textContent = step.title;
    description.textContent = step.description;
    mission.textContent = step.action === "manual"
      ? step.doThis
      : step.actionLabel;
    const detailsDescription = root.querySelector(".cc-guide-details-description");
    if (detailsDescription) detailsDescription.textContent = step.description;
    checklist.innerHTML = step.checklist
      .map((item) => `<li>${icon("check")}<span>${escapeHtml(item)}</span></li>`)
      .join("");
    const details = root.querySelector(".cc-guide-details");
    if (details) details.open = false;
    routeNote.textContent = step.routeLabel;
    backButton.disabled = state.index === 0;
    const nextText = nextButton.querySelector("span");
    nextText.textContent = step.complete ? "Done" : "Next";
    nextButton.setAttribute(
      "aria-label",
      step.complete ? "Finish director tutorial" : "Next tutorial step"
    );
    const needsAction = step.action !== "manual";
    card.dataset.actionMode = needsAction ? "true" : "false";
    nextButton.dataset.visible = needsAction ? "false" : "true";
    skipButton.dataset.visible = needsAction ? "true" : "false";
    actionStatus.dataset.visible = needsAction ? "true" : "false";
    actionStatus.textContent = step.action === "input"
      ? "Waiting for your input"
      : "Click the highlighted control";
    const percent = ((state.index + 1) / steps.length) * 100;
    progress.style.width = `${percent}%`;
    progress.parentElement.setAttribute("aria-valuenow", String(state.index + 1));
    launcherProgress.textContent = String(state.index + 1);
    saveProgress(step.complete ? "started" : "started");

    setTimeout(() => renderSpotlight(step), willNavigate ? 430 : 50);
  }

  function escapeHtml(value) {
    const node = document.createElement("span");
    node.textContent = value;
    return node.innerHTML;
  }

  function setLauncherVisible(visible) {
    const value = visible ? "true" : "false";
    if (launcherDock) launcherDock.dataset.visible = value;
    if (launcher) launcher.dataset.visible = value;
  }

  function openGuide(isAutomatic) {
    if (!state.isDirector && !window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__) return;
    clearTimeout(state.autoTimer);
    state.lastFocused = document.activeElement;
    state.open = true;
    setLauncherVisible(false);
    layer.dataset.open = "true";
    document.documentElement.style.setProperty("--cc-guide-open", "1");
    enableFlutterSemantics();
    renderStep(true);
    setTimeout(() => state.open && renderSpotlight(steps[state.index]), 260);
    saveProgress(isAutomatic ? "started" : "started");
  }

  function closeGuide(showPausedToast) {
    if (!state.open) return;
    state.open = false;
    clearTimeout(state.actionTimer);
    clearTimeout(state.layoutTimer);
    state.actionPending = false;
    clearTargetHighlights();
    layer.dataset.open = "false";
    targetTag.dataset.visible = "false";
    setLauncherVisible(state.isDirector || window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__);
    document.documentElement.style.removeProperty("--cc-guide-open");
    saveProgress("started");
    if (showPausedToast) showToast("Tutorial paused. Use Director Guide to resume.");
    if (state.lastFocused && typeof state.lastFocused.focus === "function") {
      state.lastFocused.focus({ preventScroll: true });
    } else {
      launcher.focus({ preventScroll: true });
    }
  }

  function completeGuide() {
    state.open = false;
    clearTimeout(state.actionTimer);
    clearTimeout(state.layoutTimer);
    state.actionPending = false;
    clearTargetHighlights();
    layer.dataset.open = "false";
    targetTag.dataset.visible = "false";
    setLauncherVisible(true);
    launcherProgress.textContent = "Done";
    saveProgress("completed");
    showToast("Director tutorial complete. You can restart it any time.");
    launcher.setAttribute("aria-label", "Restart Director Guide");
    launcher.setAttribute("title", "Restart Director Guide");
    launcher.focus({ preventScroll: true });
  }

  function move(delta, skipped) {
    if (delta > 0 && steps[state.index].complete) {
      completeGuide();
      return;
    }
    if (delta > 0 && steps[state.index].action !== "manual" && !state.actionPending && !skipped) {
      showToast("Use the highlighted control, or choose Skip step.");
      return;
    }
    state.index = Math.max(0, Math.min(steps.length - 1, state.index + delta));
    renderStep(true);
  }

  function showToast(message) {
    clearTimeout(state.toastTimer);
    toast.querySelector("span").textContent = message;
    toast.dataset.visible = "true";
    state.toastTimer = setTimeout(() => {
      toast.dataset.visible = "false";
    }, 4200);
  }

  function updateLauncherContext() {
    if (!launcher) return;
    const route = window.location.hash;
    const inProfile =
      route.includes("profile") ||
      route.startsWith("#/settings") ||
      route.startsWith("#/public/account");
    launcher.dataset.context = inProfile ? "profile" : "portal";
    if (launcherDock) launcherDock.dataset.context = inProfile ? "profile" : "portal";
    launcher.querySelector(".cc-guide-launcher-label").textContent = inProfile
      ? "Start Tutorial"
      : "Director Guide";
  }

  function syncIdentity() {
    const identity = readIdentity();
    const preview = Boolean(window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__);
    if (!identity && !preview) {
      state.isDirector = false;
      state.userKey = null;
      if (launcher) setLauncherVisible(false);
      if (state.open) closeGuide(false);
      return;
    }
    if (identity && identity.tokenValue === state.lastToken && state.isDirector === identity.isDirector) {
      updateLauncherContext();
      return;
    }
    if (identity) {
      state.lastToken = identity.tokenValue;
      state.userKey = identity.userKey;
      state.isDirector = identity.isDirector;
    } else {
      state.userKey = "preview";
      state.isDirector = preview;
    }

    if (!state.isDirector && !preview) {
      setLauncherVisible(false);
      if (state.open) closeGuide(false);
      return;
    }

    const stored = loadProgress();
    state.index = stored.index;
    setLauncherVisible(!state.open);
    launcherProgress.textContent = stored.status === "completed" ? "Done" : String(stored.index + 1);
    if (stored.status === "completed") {
      launcher.setAttribute("aria-label", "Restart Director Guide");
      launcher.setAttribute("title", "Restart Director Guide");
    }
    updateLauncherContext();
    clearTimeout(state.autoTimer);
    if (stored.status === "new" && !window.location.hash.includes("login")) {
      state.autoTimer = setTimeout(() => openGuide(true), AUTO_START_DELAY_MS);
    }
  }

  function start() {
    buildDom();
    syncIdentity();
    window.setInterval(syncIdentity, 1200);
  }

  window.CineConnectDirectorGuide = {
    start() {
      window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__ = true;
      state.isDirector = true;
      state.userKey = "preview";
      state.index = 0;
      setLauncherVisible(true);
      openGuide(false);
    },
    openAt(stepNumber) {
      window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__ = true;
      state.isDirector = true;
      state.userKey = "preview";
      state.index = Math.max(0, Math.min(steps.length - 1, Number(stepNumber) - 1 || 0));
      openGuide(false);
    },
    close() {
      closeGuide(false);
    },
    get totalSteps() {
      return steps.length;
    },
  };

  // DOM event hook used by automated visual QA. It changes presentation only
  // and does not grant access to any director data or API.
  document.addEventListener("cineconnect-director-guide-preview", (event) => {
    window.__CINECONNECT_DIRECTOR_GUIDE_PREVIEW__ = true;
    state.isDirector = true;
    state.userKey = "preview";
    const requestedStep = Number(event.detail && event.detail.step) || 1;
    state.index = Math.max(0, Math.min(steps.length - 1, requestedStep - 1));
    setLauncherVisible(true);
    openGuide(false);
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }
})();
