# SF-SaaS-Billing — Architecture Documentation

## Overview

Mini CRM solution built on Salesforce for a B2B SaaS company managing subscriptions and billing. Salesforce serves as the central CRM hub, integrating with an external billing API for invoice synchronization.

## Data Model

```
┌──────────────┐       ┌───────────────────┐       ┌──────────────────┐
│   Account    │ 1───* │  Subscription__c  │ 1───* │   Invoice__c     │
│  (Standard)  │       │                   │       │                  │
│              │       │ - Status__c       │       │ - Amount__c      │
│              │       │ - Start_Date__c   │       │ - Status__c      │
│              │       │ - End_Date__c     │       │ - Invoice_Date__c│
│              │       │ - Monthly_Amount  │       │ - External_Id__c │
│              │       │ - External_Id__c  │       │ - Raw_Response   │
└──────────────┘       └───────────────────┘       └──────────────────┘
```

### Subscription__c
| Field | Type | Description |
|-------|------|-------------|
| Name | Auto-Number (SUB-{0000}) | Unique identifier |
| Account__c | Lookup(Account) | Parent customer account |
| Status__c | Picklist | Draft, Active, Suspended, Cancelled, Expired |
| Start_Date__c | Date | Subscription start date |
| End_Date__c | Date | Subscription end date |
| Monthly_Amount__c | Currency | Monthly recurring amount |
| External_Id__c | Text(255) | Unique external system identifier |

### Invoice__c
| Field | Type | Description |
|-------|------|-------------|
| Name | Auto-Number (INV-{0000}) | Unique identifier |
| Subscription__c | Lookup(Subscription__c) | Parent subscription |
| Amount__c | Currency | Invoice amount |
| Status__c | Picklist | Paid, Pending, Failed |
| Invoice_Date__c | Date | Invoice date |
| External_Id__c | Text(255) | Unique external system identifier |
| Raw_Response__c | Long Text Area | Raw API response for debugging |

### Validation Rules
- **End_Date_After_Start_Date**: End Date must be after Start Date
- **Monthly_Amount_Positive**: Monthly Amount must be greater than zero
- **Single Active Per Account**: Enforced via Apex trigger (cross-record validation)

## Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                    LWC Components                    │
│  subscriptionDashboard  │  invoiceViewer             │
├─────────────────────────┴───────────────────────────┤
│                  Apex Controllers                    │
│  SubscriptionController  │  InvoiceController        │
├──────────────────────────┴──────────────────────────┤
│                   Service Layer                      │
│  SubscriptionService  │  InvoiceSyncService          │
│                       │  BillingApiService           │
├───────────────────────┴─────────────────────────────┤
│                 Trigger Framework                     │
│  TriggerHandler (abstract)                           │
│  └── SubscriptionTriggerHandler                      │
│  SubscriptionTrigger                                 │
├─────────────────────────────────────────────────────┤
│                  Data Layer                           │
│  Subscription__c  │  Invoice__c  │  Account          │
└─────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Trigger Framework (TriggerHandler)
- **Pattern**: Abstract base class with virtual methods for each trigger event
- **Why**: Separates trigger logic from trigger definition, enables bypass mechanism, prevents recursion
- **Usage**: Each object gets one trigger and one handler class

### 2. Service Layer Pattern
- **Pattern**: Static methods in dedicated service classes
- **Why**: Business logic is reusable across triggers, batch jobs, LWC controllers, and APIs
- **Classes**:
  - `SubscriptionService`: Status management and validation
  - `InvoiceSyncService`: Orchestrates API → Salesforce sync
  - `BillingApiService`: HTTP callout abstraction

### 3. Bulk-Safe Design
- All trigger logic processes `List<SObject>` — no SOQL/DML inside loops
- Collections (Sets, Maps) used for efficient lookups
- Batch class for daily status transitions (handles millions of records)

### 4. Security (CRUD/FLS)
- `Security.stripInaccessible()` in controllers for graceful FLS enforcement
- `WITH SECURITY_ENFORCED` on internal service queries
- `with sharing` keyword on all classes (respects org-wide defaults and sharing rules)
- Named Credential for external API — no hardcoded endpoints or credentials
- Permission Set `SaaS_Billing_User` for controlled access

### 5. External Integration
- **Named Credential**: `Billing_API` — stores endpoint URL securely
- **HTTP Callout**: GET request with JSON response parsing
- **Upsert via External ID**: Idempotent sync — same API call can run multiple times safely
- **Error Handling**: Custom `BillingApiException`, `SyncResult` wrapper with success/error details

## Component Details

### LWC: subscriptionDashboard
- **Target**: Account record page
- **Features**: MRR calculation, active count, subscription list with datatable
- **Data**: Wire service with `@AuraEnabled(cacheable=true)` for automatic caching

### LWC: invoiceViewer
- **Target**: Child component (modal) of subscriptionDashboard
- **Features**: Invoice list, total paid calculation, sync button
- **Data**: Wire for read, imperative call for sync (callout cannot be cached)

### Batch: SubscriptionBatchSchedulable
- **Schedule**: Daily (recommended: `0 0 1 * * ?` — 1 AM)
- **Logic**: Activates Draft subs (Start_Date <= today), expires Active subs (End_Date < today)
- **Batch Size**: 200 records per execution

## File Structure

```
force-app/main/default/
├── classes/
│   ├── TriggerHandler.cls                    # Abstract trigger framework
│   ├── SubscriptionTriggerHandler.cls        # Subscription trigger handler
│   ├── SubscriptionService.cls               # Subscription business logic
│   ├── SubscriptionBatchSchedulable.cls      # Daily batch/schedulable
│   ├── BillingApiService.cls                 # External API callout
│   ├── InvoiceSyncService.cls                # Invoice sync orchestration
│   ├── SubscriptionController.cls            # LWC controller
│   ├── InvoiceController.cls                 # LWC controller
│   ├── TestDataFactory.cls                   # Test data factory
│   ├── BillingApiMock.cls                    # HTTP callout mock
│   ├── SubscriptionServiceTest.cls           # Service tests
│   ├── SubscriptionTriggerHandlerTest.cls    # Trigger tests
│   ├── BillingApiServiceTest.cls             # API callout tests
│   ├── InvoiceSyncServiceTest.cls            # Sync tests
│   ├── SubscriptionControllerTest.cls        # Controller tests
│   ├── InvoiceControllerTest.cls             # Controller tests
│   └── SubscriptionBatchSchedulableTest.cls  # Batch tests
├── triggers/
│   └── SubscriptionTrigger.trigger
├── objects/
│   ├── Subscription__c/
│   │   ├── fields/ (6 fields)
│   │   └── validationRules/ (2 rules)
│   └── Invoice__c/
│       └── fields/ (6 fields)
├── lwc/
│   ├── subscriptionDashboard/
│   └── invoiceViewer/
├── tabs/ (2 tabs)
├── permissionsets/
│   └── SaaS_Billing_User.permissionset-meta.xml
└── namedCredentials/
    └── Billing_API.namedCredential-meta.xml
```

## Deployment

```bash
# Deploy to org
sf project deploy start --target-org orgfarm

# Run all tests with coverage
sf apex run test --target-org orgfarm --code-coverage --result-format human

# Schedule the daily batch (via Execute Anonymous)
System.schedule('Daily Subscription Status Update', '0 0 1 * * ?', new SubscriptionBatchSchedulable());
```

## Testing Strategy

- **Unit Tests**: 8 test classes covering all business logic
- **Target Coverage**: > 85%
- **Mock Strategy**: `BillingApiMock` implements `HttpCalloutMock` for API tests
- **Bulk Testing**: 200+ record tests in `SubscriptionServiceTest`
- **Negative Testing**: Error scenarios, validation rule enforcement, API failures
