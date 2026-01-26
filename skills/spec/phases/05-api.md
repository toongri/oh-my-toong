# Phase 5: API Design

## Role

As an API design specialist, systematically design and document the APIs required for the project.

## Principles

- **Scalability**: Design capable of handling traffic growth and feature expansion
- **Reusability**: Identification and abstraction of common patterns
- **Consistency**: Consistent patterns for naming conventions, response formats, and error handling
- **Security**: Authentication, authorization, and data protection mechanisms
- **Performance**: Optimization of response time, throughput, and resource usage

## Process

### Step 1: Context Review

#### 1.1 Input Document Review
- Review: Analyze requirements, architecture, domain modeling, and detailed design documents
- Summarize: Present key points related to API design

#### 1.2 API Scope Identification
- Identify: APIs that need to be added, modified, or deprecated
- Confirm: Get user agreement on scope

#### Checkpoint: Step 1 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 1 Complete`)
- Guide: "Step 1 is complete. Saved to document. Shall we proceed to the next Step?"

### Step 2: Business Context Analysis

#### 2.1 Core Problem Understanding
- Identify: Core problems and solution objectives
- Clarify: Domain rules and business logic affecting API design
- Review: Discuss with user

#### 2.2 API Usage Context Understanding
- Identify: API's position in user workflows and operational processes
- Define: Expected business value and success metrics
- Confirm: Get user agreement

#### Checkpoint: Step 2 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 2 Complete`)
- Guide: "Step 2 is complete. Saved to document. Shall we proceed to the next Step?"

### Step 3: Technical Environment Understanding

#### 3.1 API Consumer Identification
- Identify: API consumers and their characteristics (admin tools, user apps, service-to-service communication)
- Analyze: Usage patterns and traffic expectations
- Review: Discuss with user

#### 3.2 System Context Understanding
- Analyze: Current system architecture and domain boundaries
- Identify: Existing API design patterns and conventions
- Confirm: Get user agreement on technical constraints

#### Checkpoint: Step 3 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 3 Complete`)
- Guide: "Step 3 is complete. Saved to document. Shall we proceed to the next Step?"

### Step 4: API Interface Design

#### 4.1 URI and Method Design
- Design: URI structure and HTTP methods
- Design: Request parameters and body structure
- Review: Discuss with user

#### 4.2 Response Structure Design
- Design: Response structure and data representation
- Ensure: Consistency with existing APIs
- Review: Discuss with user

#### 4.3 Error Handling Design
- Design: Error handling patterns and status code usage
- Define: Error response format and messages
- Confirm: Get user agreement

#### 4.4 Versioning and Compatibility Considerations
- Analyze: Need for versioning and backward compatibility
- Propose: Strategy when major changes are required
- Confirm: Get user agreement

#### Checkpoint: Step 4 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 4 Complete`)
- Guide: "Step 4 is complete. Saved to document. Shall we proceed to the next Step?"

### Step 5: API Change Documentation

#### 5.1 New API Documentation
- Document: New endpoints with full specifications
- Include: Business rules and validation logic
- Review: Discuss with user

#### 5.2 Modified API Documentation (if applicable)
- Document: Changes to existing endpoints
- Analyze: Impact on existing consumers
- Define: Migration strategy if needed
- Confirm: Get user agreement

#### 5.3 Deprecated API Documentation (if applicable)
- Document: APIs being deprecated or removed
- Define: Transition plan and timeline
- Confirm: Get user agreement

#### Checkpoint: Step 5 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 5 Complete`)
- Guide: "Step 5 is complete. Saved to document. Shall we proceed to the next Step?"

### Step 6: Document Generation

#### 6.1 Final Review
- Present: Summary of all API design decisions
- Confirm: Get final approval from user

#### 6.2 Markdown Document Generation
- Generate final document in downloadable markdown format

#### Checkpoint: Step 6 Complete
- Save: Save current content to `.omt/specs/{feature-name}.md`
- Format: Mark progress status at the top of the document (`> **Progress Status**: Phase 5 Step 6 Complete`)
- Guide: "Step 6 is complete. Saved to document. Phase 5 API Design is complete."

## Output Format

```markdown
# API Design Decisions

## 1. Key Design Decisions and Background

### 1.1 Business Context
[Core problems, solution objectives, business requirements addressed by the API]

### 1.2 Major Design Decisions
[Major API design decisions and their rationale]

## 2. API Specifications

### 2.1 [API Name]

**Endpoint**: `[HTTP Method] [Path]`

**Description**: [API function description]

**Request**:
```
[Request parameters or body structure]
```

**Response**:
```json
{
  "field": "value"
}
```

**Business Rules**:
- [Rule 1]
- [Rule 2]

**Error Cases**:

| Condition | HTTP Status | Error Code | Message |
|-----------|-------------|------------|---------|
| ... | ... | ... | ... |

[Repeat for additional APIs as needed]

## 3. API Changes

### 3.1 APIs Being Added

| HTTP Method | Path | Description | Impact |
|-------------|------|-------------|--------|
| ... | ... | ... | ... |

### 3.2 APIs Being Modified (if applicable)

- **Target**: [HTTP Method] [Path]
- **Change Type**: [Field addition/removal/modification, path change, etc.]
- **Change Details**: [Specific change details]
- **Reason for Change**: [Background and reason for change]
- **Backward Compatibility**: [Maintained/Broken]
- **Migration Period**: [Specify if needed]

### 3.3 Deleted/Deprecated APIs (if applicable)

- **Target API**: [HTTP Method] [Path]
- **Action**: [Deletion/Deprecation]
- **Reason**: [Reason for action]
- **Replacement API**: [If a replacement API exists]
- **End of Support Date**: [Date]
```
