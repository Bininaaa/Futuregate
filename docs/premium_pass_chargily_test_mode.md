You are working on my existing FutureGate Flutter + Firebase + Cloudflare Workers app.

I want you to integrate a complete Phase 1 Premium Student Pass system.

The premium system must include:

1. Early access
2. Premium badge
3. Application priority
4. More saved opportunities
5. Chargily Pay v2 payment integration for Algeria

Important:
Do not create a random separate design style.
Study the existing app design first, then design every new screen and edited screen in a modern, attractive, creative way that fits the current FutureGate theme.
Implement clean, production-ready screens and flows.

==================================================
MAIN BUSINESS RULE
==================================================

This is not a monthly auto-renew subscription.

Implement it as:

Premium Semester Pass
One payment gives the student premium access for one semester.
The duration must be configurable, but the default business idea is a semester pass.

Use Chargily Pay v2 checkout payment flow.

The app must never trust local payment status.
Premium activation must happen only after the backend receives and verifies Chargily webhook payment confirmation.

==================================================
PREMIUM FEATURES
==================================================

A. Early Access

Early access posts are visible to all students.

Premium students:
- Can see early access posts
- Can open details
- Can apply immediately

Free students:
- Can see early access posts
- Can open details
- Cannot apply until the public visible date / delay ends
- When trying to apply, they should see a beautiful upgrade modal explaining that premium students can apply now and free students can apply later

Do not hide early access posts from free users.
Only block the apply action during the early access period.

Early access must apply to opportunities ( jobs , interships , sponsored ) where the current app architecture supports them.
If the app uses separate models/providers/screens for  opportunities ( ( jobs , interships , sponsored ), update both carefully.

B. Premium Badge

When a student has active premium:
- Show a premium badge on the student profile
- Show a premium badge in company applicant lists
- Show a premium badge in application details
- Show a premium badge in chat/profile preview only if those screens already exist and can be safely edited

The badge must only appear when the premium pass is active.

C. Application Priority

Premium students should have application priority.

When a premium student applies:
- Store a priority snapshot on the application document
- Store whether the student was premium at the time of application
- Company applicant lists must sort priority applications first
- Priority applications must be visually highlighted
- Do not only show a badge; the sorting must actually prioritize premium applications

Important:
If a student was premium at the moment of applying, keep the application priority snapshot for that application.
Do not make old applications lose priority just because the subscription expires later, unless there is already a business rule in the project saying otherwise.

D. More Saved Opportunities

Free students must have a saved-items limit.
Premium students can save more or unlimited saved items, depending on a configurable app setting.

Do not hardcode the limit in many places.
Use a central config/service so the limit can be changed later.

When a free student reaches the save limit:
- Do not crash
- Do not silently fail
- Show a modern upgrade modal
- Explain that Premium Pass allows more saved opportunities

Apply this to saved opportunities  ( jobs , interships , sponsored )  if the app has both.

==================================================
COMPANY + ADMIN EARLY ACCESS CONTROL
==================================================

Companies must not be able to force early access directly.

Company behavior:
- When creating or editing a post, the company can request early access.
- The company sees the request status.
- The company cannot approve early access by itself.

Admin behavior:
- Admin has final control.
- Admin can approve early access.
- Admin can reject early access.
- Admin can change the delay before approval.
- Admin can make a post normal/free.
- Admin can remove early access.
- Admin can see pending early access requests.
- Admin can filter and manage company early access posts.

Required early access statuses:
- none
- pending
- approved
- rejected
- expired

Use consistent naming in models and Firestore.

==================================================
STATISTICS REQUIRED
==================================================

Add statistics so admin can control the system.

Track per post:
- views count
- applications count
- premium applications count
- free applications count
- locked apply clicks
- upgrade modal views
- upgrade clicks
- early access status
- company id
- company name
- public visible date

Admin dashboard should show:
- total posts
- normal posts
- early access pending requests
- approved early access posts
- rejected early access posts
- expired early access posts
- companies with most early access requests
- companies with most approvals
- companies with most rejections
- percentage of posts using early access
- premium applications vs free applications
- locked apply clicks
- upgrade conversion indicators

Company dashboard should show only its own data:
- total posts
- normal posts
- pending early access requests
- approved early access posts
- rejected early access posts
- expired early access posts
- views
- applications
- premium applications
- free applications
- public visible date
- early access status

Company must never see:
- global platform revenue
- other companies’ statistics
- private student analytics unrelated to its own applications

==================================================
FIRESTORE DATA MODEL
==================================================

Inspect the existing Firestore structure and adapt cleanly.
Do not break existing documents.

Add or extend the following concepts:

1. subscriptions collection

Use one document per student:

subscriptions/{studentUid}

Fields should include:
- uid
- role
- plan
- status
- provider
- amount
- currency
- startedAt
- expiresAt
- checkoutId
- paymentId
- lastVerifiedAt
- createdAt
- updatedAt

Provider for this implementation:
chargily

Status values:
- active
- expired
- cancelled
- pending
- failed

2. payments collection

payments/{paymentId or checkoutId}

Fields should include:
- uid
- provider
- checkoutId
- checkoutUrl
- status
- amount
- currency
- plan
- createdAt
- paidAt
- failedAt
- rawProviderStatus
- metadata
- livemode

3. opportunities ( jobs , interships , sponsored )

Add fields safely:
- earlyAccessRequested
- earlyAccessStatus
- premiumEarlyAccess
- requestedEarlyAccessAt
- earlyAccessReviewedBy
- earlyAccessReviewedAt
- earlyAccessRejectedReason
- earlyAccessDurationHours
- publicVisibleAt
- viewsCount
- applicationsCount
- premiumApplicationsCount
- freeApplicationsCount
- lockedApplyClicks
- upgradeModalViews
- upgradeClicks

4. applications

Add fields safely:
- isPremiumAtApply
- priorityApplication
- subscriptionSnapshot
- appliedAt
- applicantUid
- companyId
- opportunityId ( jobs , interships , sponsored )

5. app config

Create or use existing remote config/settings collection for:
- premium pass price
- premium pass duration
- free saved items limit
- early access default delay
- max early access percentage warning
- feature toggles

Do not scatter these values inside many widgets.

==================================================
FLUTTER ARCHITECTURE
==================================================

Follow the existing architecture.
The project uses Provider, so integrate with Provider unless the existing code has migrated.

Add or update:

Models:
- SubscriptionModel
- PaymentModel
- PremiumConfigModel if useful
- Update UserModel safely with premium helpers if needed
- Update OpportunityModel ( jobs , interships , sponsored ) Model safely
- Update ApplicationModel safely

Services:
- SubscriptionService
- PremiumService
- PaymentService or ChargilyPaymentService
- AnalyticsTrackingService if useful
- Update OpportunityService ( jobs , interships , sponsored )
- Update ApplicationService
- Update SavedItemsService

Providers:
- PremiumProvider
- SubscriptionProvider
- Update existing AuthProvider to refresh subscription state after login
- Update OpportunityProvider ( jobs , interships , sponsored ) where needed
- Update StudentProvider if saved items are handled there

Screens:
- Premium Pass screen
- Subscription status screen or section
- Payment result screen
- Payment pending screen
- Payment failed screen
- Admin early access management screen
- Admin early access statistics section
- Company early access status/statistics section if company dashboard exists

Widgets:
- PremiumBadge
- PremiumUpgradeModal
- EarlyAccessLabel
- PremiumPassCard
- SubscriptionStatusCard
- PriorityApplicationBadge
- LockedApplyButton state
- SavedLimitUpgradeModal

Edit existing screens:
- Student dashboard
- Opportunity cards ( jobs , interships , sponsored )
- Opportunity details ( jobs , interships , sponsored )
- Apply flow
- Saved items screen
- Student profile/settings
- Company applicant list
- Company application details
- Company post create/edit screen
- Company dashboard stats
- Admin content moderation screens
- Admin company posts management
- Admin statistics dashboard

Do not duplicate logic.
Create reusable helper methods:
- hasActivePremium()
- canApplyNow()
- isEarlyAccessLockedForUser()
- getRemainingEarlyAccessTime()
- canSaveMoreItems()
- shouldShowPremiumBadge()
- shouldPrioritizeApplication()

==================================================
CHARGILY PAY V2 INTEGRATION
==================================================

Use Cloudflare Worker as backend.

Never put Chargily API secret key in Flutter.

Flutter flow:
1. Student opens Premium Pass screen
2. Student clicks Upgrade
3. Flutter calls Cloudflare Worker endpoint with Firebase ID token
4. Worker verifies Firebase ID token
5. Worker creates Chargily checkout
6. Worker stores a pending payment in Firestore
7. Worker returns checkout_url to Flutter
8. Flutter opens checkout_url using a safe external browser/custom tab flow
9. Student pays
10. Chargily sends webhook to Worker
11. Worker verifies webhook signature
12. Worker checks event type and checkout status
13. Worker activates subscription in Firestore only when payment is confirmed
14. Flutter refreshes subscription state when app resumes or when user returns

Required Worker routes:

POST /api/subscriptions/chargily/create-checkout
POST /api/webhooks/chargily
GET /api/subscriptions/me
POST /api/subscriptions/sync
GET /api/subscriptions/config

Optional but useful:
POST /api/subscriptions/chargily/expire-checkout
GET /api/payments/{checkoutId}

Chargily requirements:
- Create checkout server-side
- Use DZD currency
- Use supported payment methods from Chargily Pay v2
- Provide success_url
- Provide failure_url
- Provide webhook_endpoint
- Include metadata with uid, plan, and internal payment id
- Verify webhook signature on backend
- Do not activate premium from success_url alone
- Use webhook confirmation as source of truth

Payment result handling:
- success_url only shows “payment processing / checking status”
- failure_url shows failed/canceled message
- webhook updates the real subscription status
- app should refresh from Firestore/backend after return

==================================================
CLOUDFLARE WORKER REQUIREMENTS
==================================================

Implement Worker code cleanly.

Use environment variables / secrets:

CHARGILY_SECRET_KEY
CHARGILY_BASE_URL
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
ALLOWED_ORIGINS
APP_BASE_URL
FUTUREGATE_SUCCESS_URL
FUTUREGATE_FAILURE_URL
CHARGILY_WEBHOOK_URL

If this project already has Firebase Admin logic in Worker, reuse it.
If not, implement a clean Firebase Admin REST/JWT helper or use the existing project pattern.

Worker must:
- Validate HTTP method
- Validate CORS using ALLOWED_ORIGINS
- Verify Firebase Auth ID token for user endpoints
- Check that user role is student before creating checkout
- Prevent duplicate active purchases when user already has active premium
- Create payment document as pending
- Create Chargily checkout using secret key
- Store checkoutId and checkoutUrl
- Return checkoutUrl to Flutter
- Verify Chargily webhook signature
- Handle checkout.paid
- Handle failed/canceled events if provided by webhook payload
- Be idempotent: same webhook repeated must not duplicate subscription or corrupt data
- Use server timestamps
- Log safely without exposing secrets

Important security:
- Do not log CHARGILY_SECRET_KEY
- Do not accept uid from client as trusted without verifying Firebase token
- Use metadata only as helper, not as sole proof
- Confirm payment status from webhook payload and/or retrieve checkout if needed
- Only Worker/Admin can write subscriptions and payments

==================================================
FIREBASE SECURITY RULES
==================================================

Update Firestore rules safely.

Required rules concept:

subscriptions:
- Student can read only their own subscription
- Student cannot write subscription directly
- Admin can read/manage if existing admin rules allow
- Worker writes through Firebase Admin SDK, bypassing rules

payments:
- Student can read only their own payment documents
- Student cannot mark payment paid
- Student cannot write payment status directly
- Admin can read payment summaries if needed
- Worker writes through Firebase Admin SDK

opportunities ( jobs , interships , sponsored ):
- Company can request early access only for its own posts
- Company cannot approve early access
- Company cannot set premiumEarlyAccess true directly
- Company cannot set earlyAccessStatus approved directly
- Admin can approve/reject/change early access
- Students can read published posts
- Students cannot edit early access fields

applications:
- Student can create application only if canApplyNow rule is satisfied where possible
- Because complex time/premium logic may be hard in rules, backend/service must enforce too
- Student cannot manually set priorityApplication true unless server/app logic validates premium
- Prefer server-side application creation for early access posts if current rules cannot safely enforce it

saved items:
- Prevent direct bypass of free saved limit if possible
- If not fully possible in Firestore rules, enforce in service and consider moving save action to Worker later
- Premium status must come from trusted subscription document

Important:
If Firestore rules become too complex, write a clear TODO and recommend moving sensitive writes to Cloudflare Worker endpoints.
Do not weaken existing rules.

==================================================
FIREBASE PERMISSIONS / IAM
==================================================

Tell me exactly what I must do manually.

Include:
- Ensure Firebase Authentication is enabled
- Ensure Firestore is enabled
- Ensure the Cloudflare Worker service account has permission to read/write Firestore
- If using Firebase Admin SDK credentials, create or use a service account with the minimum required Firestore permissions
- Store service account credentials only in Cloudflare Worker secrets
- Do not commit service account JSON to GitHub
- Add/update Firestore indexes required by new queries
- Deploy updated Firestore rules
- Test rules with free student, premium student, company, and admin accounts

Required manual Firebase checks:
- Authentication users have correct roles
- Admin role detection works
- Company role detection works
- Student role detection works
- Existing UserModel remains backward compatible
- Existing applications still load
- Existing saved opportunities still load
- Existing admin stats still load

==================================================
CLOUDFLARE MANUAL SETUP
==================================================

Tell me exactly what to do manually in Cloudflare.

Include:
- Add Worker secrets with wrangler secret put
- Add CHARGILY_SECRET_KEY
- Add Firebase project/service account secrets
- Add allowed origins
- Add production app URLs
- Add webhook route URL
- Deploy Worker
- Test create-checkout endpoint
- Test webhook endpoint
- Verify CORS
- Verify Firebase token validation
- Verify Firestore writes
- Check Worker logs without exposing secrets

==================================================
CHARGILY MANUAL SETUP
==================================================

Tell me exactly what to do manually in Chargily dashboard.

Include:
- Use test mode first
- Add or confirm API keys
- Configure webhook endpoint pointing to Cloudflare Worker
- Use the correct webhook URL
- Test checkout payment
- Confirm webhook reaches Worker
- Confirm Firestore payment changes from pending to paid
- Confirm subscription becomes active
- After testing, switch to live keys carefully
- Replace test secret with live secret in Cloudflare Worker secrets
- Confirm success and failure URLs

==================================================
APP MANUAL SETUP
==================================================

Tell me exactly what I must do manually in Flutter.

Include:
- Add required packages if missing
- Run flutter pub get
- Check Android internet permission
- Configure URL launcher / custom tabs if needed
- Test payment opening
- Test app resume refresh
- Test expired subscription state
- Test free saved limit
- Test early access apply lock
- Test premium apply priority
- Test admin approval
- Test company early access request

==================================================
ADMIN EXPERIENCE
==================================================

Create or update admin screens so admin can control the whole system.

Admin must be able to:
- See all company early access requests
- Approve request
- Reject request with reason
- Change delay
- Make post normal
- See early access statistics
- See company-level early access behavior
- Detect companies requesting too many early access posts
- Filter by company, status, type, date
- See post performance

The admin UI must be modern, clear, and attractive.
Use existing app design patterns.

==================================================
COMPANY EXPERIENCE
==================================================

Company must be able to:
- Request early access when creating a post
- See whether the request is pending, approved, rejected, expired, or normal
- See performance of its own early access posts
- Understand that admin approval is required
- Not bypass admin approval

Update company create/edit screens carefully.
If editing an approved early access post could create abuse, require admin re-review for sensitive changes.

==================================================
STUDENT EXPERIENCE
==================================================

Student must be able to:
- Discover Premium Pass from dashboard/settings
- See premium status
- See active until date
- Upgrade with Chargily Pay
- Return to app after payment
- See payment pending/checking state
- See payment failure state
- See premium badge after activation
- Apply early if premium
- See lock modal if free
- Save more items if premium
- See upgrade modal if free saved limit reached

Premium should be promoted at natural moments:
- Premium Pass screen
- Early access apply click
- Early access post details
- Saved limit reached
- Student profile/settings
- Dashboard banner, not too aggressively

Do not spam the user on every screen.

==================================================
LOCALIZATION
==================================================

If the app uses localization files, add all new strings properly.
Support the existing languages.
Do not hardcode English text inside widgets if the project already uses localization.

Pay special attention to Arabic and French wording.
Do not translate academic/app concepts literally in a wrong way.

==================================================
ERROR HANDLING
==================================================

Handle:
- No internet
- Payment checkout creation failure
- Chargily checkout URL missing
- User already premium
- Webhook duplicate
- Webhook invalid signature
- Webhook unknown event
- Firestore permission errors
- Expired premium
- App closed during payment
- Payment pending
- Payment failed/canceled
- User role is not student
- Admin rejection reason missing

Show user-friendly messages.
Log technical errors safely.

==================================================
TESTING
==================================================

Add tests or at least provide a complete testing checklist.

Test accounts:
- Free student
- Premium student
- Expired premium student
- Company
- Admin

Test flows:
- Free student sees early access post
- Free student cannot apply during delay
- Free student can apply after delay
- Premium student can apply immediately
- Premium application appears first for company
- Premium badge appears correctly
- Free saved limit blocks saving
- Premium can save more
- Company requests early access
- Admin approves
- Admin rejects
- Chargily checkout created
- Chargily webhook activates premium
- Invalid webhook signature rejected
- Duplicate webhook does not duplicate premium/payment
- Existing normal posts still work
- Existing users without subscription documents still work

==================================================
DELIVERABLES
==================================================

After implementation, give me:

1. List of all modified files
2. List of all new files
3. Firestore collections and fields added
4. Firestore indexes required
5. Firebase rules changes
6. Cloudflare Worker routes added
7. Cloudflare secrets I must set
8. Chargily dashboard steps I must do
9. Firebase console steps I must do
10. Flutter commands I must run
11. Full test checklist
12. Any limitations or TODOs
13. Any places where you intentionally avoided unsafe client-side logic

==================================================
IMPORTANT CHARGILY MODE RULE
==================================================

For now, integrate Chargily Pay v2 in TEST MODE ONLY.

Do not configure live mode.
Do not ask me to switch to live mode.
Do not include live deployment steps yet.
Do not use live Chargily API keys.
Do not use live payment credentials.

Use only Chargily test/sandbox API keys and test checkout flow.

The Worker environment must clearly separate test mode from live mode:

CHARGILY_MODE=test
CHARGILY_SECRET_KEY=TEST_SECRET_KEY_ONLY
CHARGILY_BASE_URL=Chargily Pay v2 test/sandbox API base URL if different from production

All payment documents must store:

livemode: false
mode: "test"

The app UI can still behave normally, but all payments must be test payments.

Webhook handling must also be implemented for test mode only.
The webhook must still verify the signature.
The backend must still activate premium only after confirmed test webhook payment.

Do not activate premium from success_url alone.

In the manual setup section, only tell me what to do for Chargily test mode:
- where to put the test API key
- how to configure the test webhook
- how to run a test checkout
- how to confirm Firestore updates
- how to confirm the student becomes premium in test mode

Do not include instructions for switching to live mode yet.

==================================================
IMPORTANT ADDITIONAL RULES
==================================================

For every new or edited screen , widget, modal, button, label, error message, and admin/company/student text added for the Premium Pass and Chargily Pay system:

1. Add proper translations using the existing localization system.
2. Support all current app languages: English, French, and Arabic.
3. Do not hardcode visible text inside widgets if the app already uses localization files.
4. Make Arabic and French translations natural and context-aware, not literal.
5. Add full dark mode support for all new and edited screens and components.
6. Ensure all new Premium, payment, admin, company, and student UI looks good in both light mode and dark mode.
7. Reuse the existing theme system instead of hardcoded colors whenever possible.

==================================================
IMPORTANT FINAL RULES
==================================================

Do not remove existing features.
Do not break existing authentication.
Do not break existing admin/company/student routing.
Do not break current Opportunity ( jobs , interships , sponsored ) application logic.
Keep backward compatibility with old Firestore documents.
Use server-side verification for payments.
Never expose Chargily secret key.
Never activate premium from client-only success URL.
Do not make all posts early access by default.
Early access must be controlled by admin.
Company can request, admin decides.
Free students can still use the app normally.
Premium students get advantage, not exclusive ownership of the app.