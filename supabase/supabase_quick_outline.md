# Project Idea:
Project Idea:
Trip Planning Android App for Software Engineering We are building an Android app for our Software Engineering course. The core idea: An android app that'll interact with free Google Maps API to fetch location info. It'll enable users to create custom lists that'll easily link to the google maps info cards. Things to be aware of:
1. This is our first entry into Android app development completely. We aim to use flutter, supabase and have to implement at least 6 software engineering design patterns during design and development
2. You must provide guidance on how google maps API work, which ones we can call
3. Provide insight into Anroid app development. Guide beginners through learning and mastering android app development. We wish to implement google's material you theming and design language if it's feasible.
4. always ask clarifying questions before diving deep into any tasks, so that I am aware of what I need better.
5. Always work hard and think long to provide me the best solution and make me happy. 6. App will be open source, so strong importance in needed to ensure that API keys aren't linked
6. VITAL: DO NOT MAKE IT COMPLICATED. KEEP IT SIMPLE, YET COMPLETE.

## Potential Design Patterns:

    Observer / Event listener (the auth.users trigger → automatic profile creation)

    Facade (the is_username_available RPC hiding complex SQL)

    Singleton (the Supabase client instance, though that’s arguably built‑in)

    Proxy / Decorator (Row‑Level Security — every query is intercepted and checked transparently)

Do not go crazy over it. Just a few is one and always apply where it is absolutely relevant.

Also dont go outside the observer, strategy, factory, singleton, facade, proxy, decorator, adapter, builder
# Quick Outline:

### Table: trip_lists
Core entity. One trip list per planning group.
### Table: trip_list_collaborators
Tracks who has access to a trip and at what level.

**Fetch pending invitations for current user (notification inbox):**
```dart
supabase
  .from('trip_list_invitations')
  .select('*, trip:trip_lists(title), inviter:profiles!invited_by(username, avatar_url)')
  .eq('invited_user_id', userId)
  .eq('status', 'pending')
```
### Table: trip_list_reviews
Only for PUBLIC trips. Users cannot review their own trip. One review per user per trip.

### Table: trip_locations
Two types controlled by `is_manual` boolean.

### Table: trip_list_invitations
In-app invitations only (no email links). Owner or editor can invite.

**Reorder RPC:**
```dart
await supabase.rpc('reorder_locations', params: {
  'p_trip_list_id': tripListId,
  'p_ordered_ids': orderedIds, // List UUIDs in new order
});
```

**Calendar query (locations with dates):**
```dart
supabase
  .from('trip_locations')
  .select()
  .eq('trip_list_id', tripId)
  .not('visit_date', 'is', null)
  .gte('visit_date', startDate.toIso8601String())
  .lte('visit_date', endDate.toIso8601String())
  .order('visit_date')
  .order('visit_time')
```
### Table: trip_notes
Rich text notes with optional image attachments. Editors only can create/edit.

### Table: note_images
Images attached to a trip note. Stored in `note-images` private bucket.

### Table: chat_rooms
One room per trip. Auto-created by trigger when trip_list is created.
Never create manually. Fetch via trip_list_id:
```dart
supabase
  .from('chat_rooms')
  .select('id')
  .eq('trip_list_id', tripListId)
  .single()
```

**Standard message fetch (with all joins):**
```dart
supabase.from('chat_messages').select('''
  *,
  sender:profiles!sender_id(username, avatar_url),
  reply_to:chat_messages!reply_to_id(id, content, sender:profiles!sender_id(username)),
  referenced_note:trip_notes!referenced_note_id(id, title, tag_key),
  referenced_image:note_images!referenced_image_id(id, filename, storage_path)
''')
.eq('room_id', roomId)
.eq('is_deleted', false)
.order('created_at', ascending: false)
.limit(50)
```

**Realtime subscription:**
```dart
supabase.channel('room:$roomId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'chat_messages',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'room_id',
      value: roomId,
    ),
    callback: (payload) { /* handle new message */ },
  ).subscribe();
```