---
date: 2023-02-03
status: Accepted
author: @jstvz
---

# 1. Record architecture decisions

## Context and Problem Statement

We need to record the architectural decisions made on this project, but we lack a centralized location for storing them. This makes it difficult to find previous decisions. Moreover, we lack a shared vocabulary to discuss and a process to refine such decisions.

### Assumptions

1. A process for Requests for Comment exists in this repository or elsewhere.
2. We define "architectural decision" as any software design choice that addresses a functional or non-functional requirement that is architecturally significant, for example:
    - Which web framework to use
    - Whether to denormalize a database table
    - Whether or not to abandon a third-party test coverage aggregator

## Decision

### Options Considered

1. Status Quo
    1. Good: No changes to our process required
    2. Bad: It can be difficult to find the reasons for our choices because there
       are lots of places to look.
2. Architectural Decision Records (ADRs)
    1. Good: ADRs provide:
        1. a centralized log of the decisions for our projects
        2. a structured process for adopting decisions using pull requests
        3. a lower barrier of entry for documenting a decision
        4. a reference for teammates and community members
        5. a shared understanding of a problem and its proposed solution
        6. an ecosystem of existing tooling for managing and publishing ADRs
    2. Bad:
        1. Detailed discussions can expose spirited debates to public view
        2. ADRs add a third place to search in addition to Quip and Confluence
        3. ADRs add to the documentation burden

### Decision Outcome

We will use Architecture Decision Records, as [described at adr.github.io](https://adr.github.io/). This is a lightweight process is that is consistent with our existing code review workflow. Because these records are code, we can apply automation to lint files, automatically assign reviewers, and publish decisions to other repositories or the web.

## Consequences

We'll need additional discussions and RFCs to decide:

1. the best way to organize the decision log,
2. whether to retroactively record major decisions, or only future ones,
3. whether to include decision records in our documentation.

## References

More information:

-   [Decisions](https://atlas.sfdc.sh/decisions): Salesforce Architecture Library articles on RFCs and decision records.
-   [ADR GitHub organization](https://adr.github.io/): References to more information on tooling and the reasons to adopt ADRs
-   [Share the Load: Distribute Design Authority with Architecture Decision Records](https://www.agilealliance.org/resources/experience-reports/distribute-design-authority-with-architecture-decision-records): A case study about the adoption of ADRs by a microservices team at IBM.
-   Zimmerman, et al., [_Architectural decision guidance across projects: problem space modeling, decision backlog management and cloud computing knowledge_](https://www.ifs.hsr.ch/fileadmin/user_upload/customers/ifs.hsr.ch/Home/projekte/ADMentor-WICSA2015ubmissionv11nc.pdf): Conference paper describing a theoretical framework for systematically reusing architectural knowledge across projects.

Examples:

-   [Timestamp format](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/examples/timestamp-format/index.md)
-   [ADR process (internal Confluence)](https://confluence.internal.salesforce.com/pages/viewpage.action?pageId=349650878) Describes the ADR process for SFDC's Business Technology's Network Architecture team.
-   [User Facing Configuration](https://github.com/arachne-framework/architecture/blob/master/adr-005-user-facing-config.md)
