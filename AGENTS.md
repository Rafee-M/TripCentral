# Project: TripCentral
A collaborative trip planning app built with Flutter and Supabase.

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Maps/Places:** google_places_sdk_plus package
- **Database Schema:** `supabase/supabase.md` (Contains full schemas, RLS rules, triggers, storage policies). Always reference this doc when adding Supabase-related features.
- **Databse Quick Outline:** `supabase/supabase_quick_outline.md` (A brief overview of core tables and patterns for quick reference during development).

---

## Architecture Rules
1. Never call Supabase directly from a Widget. Always route calls through a Service class (e.g., `lib/features/{feature}/services/`).
2. Adhere to clear feature-first or domain-first architecture boundaries.
3. Models reside in `lib/shared/models/` and should implement a `.fromJson()` factory constructor for robust serialization.
4. Always handle DB errors securely by catching `PostgrestException` instead of generic `Exception`.
5. For external integrations (e.g., Google Maps), avoid saving transient image URLs in the DB; instead, store photo reference strings in metadata JSONB.

---

## Authentication & User Lifecycle
Supabase Auth naturally manages user sessions. Access the current user seamlessly:
```dart
final user = Supabase.instance.client.auth.currentUser;
final userId = user!.id; // UUID matching `public.profiles`
```

During Signup, attach `username` and `display_name` to the user's raw metadata. The `handle_new_user` Postgres trigger auto-creates a record in `public.profiles`.
```dart
await supabase.auth.signUp(
  email: email, password: password,
  data: {'username': 'johndoe', 'display_name': 'John Doe'}
);
```

**Key RPC Validation:** 
Invoke `is_username_available(p_username TEXT)` via RPC to validate unique usernames before the user registers.

---

## Core Database Patterns
Read `supabase/supabase_quick_outline.md` for a brief structural overview:
- **`trip_lists` & `trip_locations`**: Form the core backbone. Locations can be reordered manually via `rpc('reorder_locations')`.
- **`trip_list_collaborators` & `trip_list_invitations`**: Robust invite system. Use the `accept_invitation` RPC to securely join trips. 
- **Chat Modules (`chat_rooms` / `chat_messages`)**: Trip creation automatically triggers the `create_chat_room_for_trip` DB script. Chat lists must subscribe to `Supabase Realtime` channels.
- **Role-Based Security**: Access checks map directly explicitly through postgres roles/functions (`can_access_trip` / `can_edit_trip`).

### Software Engineering Patterns Mentioned
When coding, strive to adapt these underlying core patterns where necessary:
- **Observer/Realtime:** Supabase `onPostgresChanges` subscriptions for live Chat updates.
- **Singleton:** Supabase instance lifecycle.
- **Facade:** Creating simple service wrappers inside Flutter to shield components from complex DB structures (e.g., mapping Postgres triggers/RPC calls safely).
- **Strategy:** For handling different trip list types (public vs private) or location types (manual vs API-fetched).
- **Proxy/Decorator:** For implementing RLS checks transparently in service methods without exposing them to the UI layer.
- **Adapter:** For integrating the Google Places API responses into our internal data models without coupling the UI to external data formats.
- **Builder:** For constructing complex trip list objects that may require multiple steps (e.g., creating a trip list, adding locations, inviting collaborators).
- **Factory:** For creating instances of services or models based on certain conditions (e.g., creating a specific type of trip list based on user input).
---

## Coding Workflow & Development Habits
- **Simplicity & UI:** Use Material 3 theming heavily to offer a dynamic robust UX natively supported by Flutter. Keep the layout logic simple.
- **Security:** Do not commit `google_places` or `supabase_anon_key` inside standard code strings without env/config loading!
- **State & Service:** Define clear layers (UI -> Logic/Notifier -> Services/API). Don't tightly couple view classes to data sources!

