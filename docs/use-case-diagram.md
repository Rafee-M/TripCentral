# TripCentral — Use Case Diagram

## Rendering Instructions

The diagram below is written in **PlantUML** syntax.

**Free websites to render the diagram:**

| Website | URL |
|---------|-----|
| **PlantUML Online Server** | <https://www.plantuml.com/plantuml/uml> |
| **PlantText** | <https://www.planttext.com> |

Copy the entire code block from the [PlantUML Code](#plantuml-code) section, paste it into
any of the websites above, and click **Submit / Render** to get the diagram image.

---

## Actors

| # | Actor | Type | Description |
|---|-------|------|-------------|
| 1 | **Guest** | Primary | An unauthenticated visitor who can browse public lists and view location details but cannot create content or connect with users. |
| 2 | **Authenticated User** | Primary | A registered, email-verified user who can create lists, add locations, connect with friends, submit reviews, and share lists. |
| 3 | **Friend / Connected User** | Secondary | An authenticated user who has an approved connection with another user. Can view shared non-public lists, collaborate, and receive notifications. |
| 4 | **System** | Automated | The backend system that triggers email verification, dispatches notifications, aggregates reviews, and ranks public lists. |

---

## Use Cases

### User Management & Socials
1. Sign Up
2. Log In
3. Verify Email (extends Sign Up — triggered by System)
4. View / Edit Profile
5. Search Users
6. Send Friend Request
7. Accept / Reject Friend Request
8. Receive Notifications

### Mapping & Lists
9. Search Locations (Google Maps)
10. View Location Details
11. Create List
12. Add Place to List
13. Manage List Sections
14. Reorder List Items
15. Save Route

### Collaboration & Community
16. Share List (Private)
17. Invite User to Collaborate
18. Chat with Collaborators
19. Propose Changes
20. Approve / Reject Changes
21. Make List Public
22. Browse Public Lists
23. Rate a List
24. Submit Place Review

---

## PlantUML Code

```plantuml
@startuml TripCentral_UseCaseDiagram

left to right direction
scale 1.5

skinparam packageStyle rectangle
skinparam usecaseBackgroundColor White
skinparam usecaseBorderColor Black
skinparam rectangleBorderColor Black
skinparam rectangleBackgroundColor White
skinparam packageBorderColor Black
skinparam packageBackgroundColor #FAFAFA
skinparam arrowColor Black
skinparam actorBorderColor Black
skinparam defaultFontSize 14
skinparam usecaseFontSize 12
skinparam actorFontSize 14
skinparam nodesep 14
skinparam ranksep 50

' ══════════════════════════════════════════════════════════
' LEFT ACTORS  (Primary / Secondary — Human)
' ══════════════════════════════════════════════════════════
actor "Guest" as Guest
actor "Authenticated\nUser" as AuthUser
actor "Friend /\nConnected User" as Friend

' ── Generalization (Friend inherits AuthUser) ──────────
Friend --|> AuthUser

' ══════════════════════════════════════════════════════════
' SYSTEM BOUNDARY
' ══════════════════════════════════════════════════════════
rectangle "TripCentral" {

  package "User Management & Socials" {
    usecase "Sign Up" as UC1
    usecase "Log In" as UC2
    usecase "Verify Email" as UC3
    usecase "View / Edit Profile" as UC4
    usecase "Search Users" as UC5
    usecase "Send Friend Request" as UC6
    usecase "Accept / Reject\nFriend Request" as UC7
    usecase "Receive Notifications" as UC8
  }

  package "Mapping & Lists" {
    usecase "Search Locations" as UC9
    usecase "View Location Details" as UC10
    usecase "Create List" as UC11
    usecase "Add Place to List" as UC12
    usecase "Manage List Sections" as UC13
    usecase "Reorder List Items" as UC14
    usecase "Save Route" as UC15
  }

  package "Collaboration & Community" {
    usecase "Share List (Private)" as UC16
    usecase "Invite User\nto Collaborate" as UC17
    usecase "Chat with\nCollaborators" as UC18
    usecase "Propose Changes" as UC19
    usecase "Approve / Reject\nChanges" as UC20
    usecase "Make List Public" as UC21
    usecase "Browse Public Lists" as UC22
    usecase "Rate a List" as UC23
    usecase "Submit Place Review" as UC24
  }
}

' ══════════════════════════════════════════════════════════
' RIGHT ACTOR  (Automated)
' ══════════════════════════════════════════════════════════
actor "System" as System

' ── Guest Associations ─────────────────────────────────
Guest -- UC1
Guest -- UC2
Guest -- UC10
Guest -- UC22

' ── Authenticated User Associations ────────────────────
AuthUser -- UC2
AuthUser -- UC4
AuthUser -- UC5
AuthUser -- UC6
AuthUser -- UC8
AuthUser -- UC9
AuthUser -- UC10
AuthUser -- UC11
AuthUser -- UC12
AuthUser -- UC13
AuthUser -- UC14
AuthUser -- UC15
AuthUser -- UC16
AuthUser -- UC17
AuthUser -- UC21
AuthUser -- UC22
AuthUser -- UC23
AuthUser -- UC24

' ── Friend / Connected User Associations ───────────────
Friend -- UC7
Friend -- UC8
Friend -- UC18
Friend -- UC19
Friend -- UC20

' ── System Associations (from right side) ──────────────
UC3 -- System
UC8 -- System

' ── <<include>> Relationships ──────────────────────────
UC11 ..> UC12 : <<include>>
UC12 ..> UC9  : <<include>>
UC17 ..> UC8  : <<include>>
UC6  ..> UC8  : <<include>>

' ── <<extend>> Relationships ──────────────────────────
UC1  ..> UC3  : <<extend>>
UC19 ..> UC20 : <<extend>>

@enduml
```

---

## How to Read the Diagram

- **Actor placement** — Primary and secondary human actors (*Guest*,
  *Authenticated User*, *Friend*) are on the **left**; the automated *System*
  actor is on the **right**.  This keeps association lines flowing in one
  direction and avoids arrow collisions.
- **Solid lines** from an actor to an oval (use case) indicate that the actor
  can initiate or participate in that use case.
- **`<<include>>`** (dashed arrow) means the base use case *always* triggers the
  included use case (e.g., "Create List" always includes "Add Place to List").
- **`<<extend>>`** (dashed arrow) means the extending use case *optionally*
  triggers under certain conditions (e.g., "Sign Up" may extend to
  "Verify Email" when triggered by the System).
- **Generalization arrow** (solid triangle) from *Friend* to *Authenticated User*
  means a Friend inherits all capabilities of an Authenticated User.
- **Printing** — The diagram is scaled at 1.5× for clear A3 printing.  When
  rendering via PlantUML Online or PlantText, export as **SVG** or **PNG** for
  the best print quality.
