# In depth details:

Initial pre-table setup. Setup enum permissions to be used later

## Update: New Supabase Chat System SQL Query:

```sql
CREATE TABLE public.chat_rooms (
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
name                TEXT NOT NULL,
description         TEXT,                               -- Room description
avatar_url          TEXT,                               -- Room profile picture
is_private          BOOLEAN DEFAULT false,
pinned_message_id   UUID,                               -- Added: Reference for a pinned message
created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
created_by          UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- Note: We add the Foreign Key constraint AFTER chat_messages is created
-- to avoid a circular reference error during initial table creation.

CREATE TABLE public.chat_messages (
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
chat_room_id        UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
user_id             UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
reply_to_message_id UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL,
content             TEXT NOT NULL,
type                public.chat_message_type NOT NULL DEFAULT 'text',
created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
deleted_at          TIMESTAMPTZ DEFAULT NULL            -- Added: For soft deletes
);

-- Indexing for high-performance retrieval
CREATE INDEX idx_chat_messages_room_history ON public.chat_messages(chat_room_id, created_at DESC);
CREATE INDEX idx_chat_messages_reply_lookup ON public.chat_messages(reply_to_message_id);

-- Link the pinned_message_id back now that the table exists
ALTER TABLE public.chat_rooms
ADD CONSTRAINT fk_pinned_message
FOREIGN KEY (pinned_message_id) REFERENCES public.chat_messages(id) ON DELETE SET NULL;

CREATE TABLE public.chat_room_members (
chat_room_id  UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
permission    public.trip_permission DEFAULT 'viewer',
joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
last_read_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),    -- Added: Read receipt tracking
PRIMARY KEY (chat_room_id, user_id)
);

-- Trigger for Rooms
CREATE TRIGGER set_chat_rooms_updated_at
BEFORE UPDATE ON public.chat_rooms
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger for Messages
CREATE TRIGGER set_chat_messages_updated_at
BEFORE UPDATE ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
```

## Part 1
-- Permission level for collaborators and invitations
CREATE TYPE public.trip_permission AS ENUM ('viewer', 'editor');

-- Chat message types (extensible)
CREATE TYPE public.chat_message_type AS ENUM (
  'text',       -- plain text message
  'image',      -- image uploaded directly in chat
  'note_ref',   -- a reference to a trip note (renders as card. Note type will differentiate type)
  'system'      -- system events: "Alice joined", "Bob changed the title"
);

-- Invitation lifecycle
CREATE TYPE public.invitation_status AS ENUM (
  'pending',
  'accepted',
  'declined',
  'expired'
);


-- SHARED TRIGGER: auto-set updated_at on any table
- It will be called before an UPDATE on a table that has an `updated_at` column.

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

## Part - 2 Profiles

```sql
CREATE TABLE public.profiles (

  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  username      TEXT UNIQUE NOT NULL,

  display_name  TEXT,

  avatar_url    TEXT,

  bio           TEXT,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  

  -- Username rules: 3-30 chars, only lowercase letters, digits, underscores

  CONSTRAINT username_length  CHECK (char_length(username) BETWEEN 3 AND 30),

  CONSTRAINT username_format  CHECK (username ~ '^[a-z0-9_]+$')

);

  

CREATE TRIGGER set_profiles_updated_at

  BEFORE UPDATE ON public.profiles

  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  

-- AUTO-CREATE PROFILE ON SIGNUP

-- This fires after a new row is inserted into auth.users.

-- Your Flutter signup call should pass username in options.data:

--   supabase.auth.signUp(email: email, password: password,

--     data: {'username': 'johndoe', 'display_name': 'John Doe'})
-- basically called by on_auth_user_created after a new user is inserted. 
-- from the signn up call there will be normal auth details. Extra data will be in data:
-- users will have to fill out information during sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()

	RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$

DECLARE

  _username TEXT;

  _display  TEXT;

  _counter  INT := 0;

  _candidate TEXT;

BEGIN

  -- Read from metadata, fall back to email prefix

  _display  := COALESCE(NEW.raw_user_meta_data->>'display_name',

                        SPLIT_PART(NEW.email, '@', 1));

  

  _candidate := COALESCE(

    NEW.raw_user_meta_data->>'username',

    LOWER(REGEXP_REPLACE(SPLIT_PART(NEW.email, '@', 1), '[^a-z0-9_]', '_', 'g'))

  );

  

  -- Ensure uniqueness: append _1, _2, ... if the username is taken

  _username := _candidate;

  LOOP

    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE username = _username);

    _counter  := _counter + 1;

    _username := _candidate || '_' || _counter;

  END LOOP;

  

  INSERT INTO public.profiles (id, username, display_name, avatar_url)

  VALUES (

    NEW.id,

    _username,

    _display,

    NEW.raw_user_meta_data->>'avatar_url'

  );

  

  RETURN NEW;

END;

$$;

  
-- calls the above trigger
CREATE TRIGGER on_auth_user_created

  AFTER INSERT ON auth.users

  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

  

-- Helper RPC: check username availability BEFORE signup (call from Flutter). This handfles the race condition if 2 users are signing up at the same time

CREATE OR REPLACE FUNCTION public.is_username_available(p_username TEXT)

RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$

  SELECT NOT EXISTS (SELECT 1 FROM public.profiles WHERE username = LOWER(p_username));

$$;

  

-- RLS

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

  

CREATE POLICY "Profiles readable by anyone"

  ON public.profiles FOR SELECT USING (true);

  

CREATE POLICY "User updates own profile"

  ON public.profiles FOR UPDATE

  USING (auth.uid() = id)

  WITH CHECK (auth.uid() = id);```
 -- checks signed in user's uuid in the auth table.
 -- example req: `supabase.auth.signInWithPassword(...)`. On success, the Supabase client lib storews a JWT token. When calling the db anytime with auth table connected, it sends JWT token. 
 -- eg: await supabase
 --.from('profiles')
 -- .update({'bio': 'New bio', 'display_name': 'New Name'})
 -- .eq('id', supabase.auth.currentUser!.id);

```
## Part 3 - Trip Lists

```sql
-- ============================================================
-- PART 3: TRIP LISTS
-- ============================================================

CREATE TABLE public.trip_lists (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  cover_image_url TEXT,
  is_public       BOOLEAN NOT NULL DEFAULT FALSE,
  start_date      DATE,
  end_date        DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,  -- soft delete; NULL means active

  CONSTRAINT valid_date_range CHECK (
    start_date IS NULL OR end_date IS NULL OR end_date >= start_date
  )
);

CREATE TRIGGER set_trip_lists_updated_at
  BEFORE UPDATE ON public.trip_lists
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Performance indexes
CREATE INDEX idx_trip_lists_owner      ON public.trip_lists (owner_id)         WHERE deleted_at IS NULL;
CREATE INDEX idx_trip_lists_public     ON public.trip_lists (is_public)         WHERE is_public = TRUE AND deleted_at IS NULL;
CREATE INDEX idx_trip_lists_dates      ON public.trip_lists (start_date, end_date) WHERE deleted_at IS NULL;

-- ============================================================
-- COLLABORATORS
-- ============================================================

CREATE TABLE public.trip_list_collaborators (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id  UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  permission    public.trip_permission NOT NULL DEFAULT 'viewer',
  invited_by    UUID REFERENCES public.profiles(id),
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (trip_list_id, user_id)
);

CREATE INDEX idx_collaborators_user    ON public.trip_list_collaborators (user_id);
CREATE INDEX idx_collaborators_trip    ON public.trip_list_collaborators (trip_list_id);

-- ============================================================
-- CENTRALISED ACCESS HELPERS
-- These are called by ALL downstream RLS policies.
-- SECURITY DEFINER lets them bypass RLS internally — critical for
-- avoiding infinite recursion inside policies.
-- ============================================================
-- Essentially creates a functiion that returns T/F when checking if a user can access a trip. Faster than creating RLS bypass. SECURITY DEFINER runs as admin and STABLE ensures nothing is modified. Got it?

CREATE OR REPLACE FUNCTION public.can_access_trip(p_trip_id UUID, p_user_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_lists tl
    WHERE tl.id = p_trip_id
      AND tl.deleted_at IS NULL
      AND (
        tl.owner_id = p_user_id
        OR tl.is_public = TRUE
        OR EXISTS (
          SELECT 1 FROM public.trip_list_collaborators tlc
          WHERE tlc.trip_list_id = p_trip_id AND tlc.user_id = p_user_id
        )
        -- ADDED: Allows pending invitees to view the basic trip details (solves "Unknown Trip" GUI bug)
        OR EXISTS (
          SELECT 1 FROM public.trip_list_invitations tli
          WHERE tli.trip_list_id = p_trip_id AND tli.invited_user_id = p_user_id AND tli.status = 'pending'
        )
      )
  );
$$;
-- Same thing as above, just checks if user can do edits. Could have been implemented in strategy?
CREATE OR REPLACE FUNCTION public.can_edit_trip(p_trip_id UUID, p_user_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_lists tl
    WHERE tl.id = p_trip_id
      AND tl.deleted_at IS NULL
      AND (
        tl.owner_id = p_user_id
        OR EXISTS (
          SELECT 1 FROM public.trip_list_collaborators tlc
          WHERE tlc.trip_list_id = p_trip_id
            AND tlc.user_id = p_user_id
            AND tlc.permission = 'editor'
        )
      )
  );
$$;

-- RLS for trip_lists
ALTER TABLE public.trip_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trip visible to owner, collaborators, or public"
  ON public.trip_lists FOR SELECT
  USING (public.can_access_trip(id, auth.uid()));

CREATE POLICY "Create own trip lists"
  ON public.trip_lists FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owner updates their trip"
  ON public.trip_lists FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Owner deletes their trip"
  ON public.trip_lists FOR DELETE
  USING (owner_id = auth.uid());

-- RLS for collaborators
ALTER TABLE public.trip_list_collaborators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Collaborators visible to trip members"
  ON public.trip_list_collaborators FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

CREATE POLICY "Owner adds collaborators"
  ON public.trip_list_collaborators FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trip_lists
      WHERE id = trip_list_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Owner changes permissions or user removes self"
  ON public.trip_list_collaborators FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.trip_lists
      WHERE id = trip_list_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Owner updates permission levels"
  ON public.trip_list_collaborators FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.trip_lists
      WHERE id = trip_list_id AND owner_id = auth.uid()
    )
  );
```
## Part 4 - Trip Location, Invitation, Reviews

### SQL
```sql
-- ============================================================
-- PART 4A: INVITATIONS
-- ============================================================

CREATE TABLE public.trip_list_invitations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id    UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  invited_by      UUID NOT NULL REFERENCES public.profiles(id),
  invited_user_id UUID NOT NULL REFERENCES public.profiles(id),
  permission      public.trip_permission NOT NULL DEFAULT 'viewer',
  status          public.invitation_status NOT NULL DEFAULT 'pending',
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

);

CREATE UNIQUE INDEX idx_active_invite_unique
	ON public.trip_list_invitations (trip_list_id, invited_user_id)
	WHERE status = 'pending';
CREATE INDEX idx_invitations_user       ON public.trip_list_invitations (invited_user_id) WHERE invited_user_id IS NOT NULL;

-- RPC: Accept by invitation ID, verified against the logged-in user.
CREATE OR REPLACE FUNCTION public.accept_invitation(p_invitation_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _inv  public.trip_list_invitations%ROWTYPE;
  _uid  UUID := auth.uid();
BEGIN
-- Find the invitation AND verify it belongs to the logged-in user
  SELECT * INTO _inv
  FROM public.trip_list_invitations
  WHERE id = p_invitation_id 
    AND invited_user_id = _uid -- this is the only check we need 
    AND status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or already actioned');
  END IF;

  -- Add collaborator (on conflict: upgrade permission if higher)
  INSERT INTO public.trip_list_collaborators (trip_list_id, user_id, permission, invited_by)
  VALUES (_inv.trip_list_id, _uid, _inv.permission, _inv.invited_by)
  ON CONFLICT (trip_list_id, user_id)
  DO UPDATE SET permission = EXCLUDED.permission;

  -- Mark invitation as accepted
  UPDATE public.trip_list_invitations
  SET status = 'accepted'
  WHERE id = p_invitation_id;

  RETURN jsonb_build_object('success', true, 'trip_list_id', _inv.trip_list_id);
END;
$$;

ALTER TABLE public.trip_list_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Inviter views own invitations"
  ON public.trip_list_invitations FOR SELECT
  USING (invited_by = auth.uid() OR invited_user_id = auth.uid());

CREATE POLICY "Editors create invitations"
  ON public.trip_list_invitations FOR INSERT
  WITH CHECK (
    public.can_edit_trip(trip_list_id, auth.uid())
    AND invited_by = auth.uid()
  );

-- Token-based lookup (needed for accept_invitation RPC) is handled
-- by SECURITY DEFINER above — no public SELECT by token needed.

-- ============================================================
-- PART 4B: REVIEWS (public trips only)
-- ============================================================

CREATE TABLE public.trip_list_reviews (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id  UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  reviewer_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating        SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One review per user per trip
  UNIQUE (trip_list_id, reviewer_id)
);

CREATE TRIGGER set_reviews_updated_at
  BEFORE UPDATE ON public.trip_list_reviews
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX idx_reviews_trip ON public.trip_list_reviews (trip_list_id);

ALTER TABLE public.trip_list_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviews visible on accessible trips"
  ON public.trip_list_reviews FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

CREATE POLICY "Authenticated user reviews public trips (not own)"
  ON public.trip_list_reviews FOR INSERT
  WITH CHECK (
    reviewer_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.trip_lists
      WHERE id = trip_list_id
        AND is_public = TRUE
        AND owner_id != auth.uid()
    )
  );

CREATE POLICY "User updates own review"
  ON public.trip_list_reviews FOR UPDATE
  USING (reviewer_id = auth.uid());

CREATE POLICY "User deletes own review"
  ON public.trip_list_reviews FOR DELETE
  USING (reviewer_id = auth.uid());

-- Convenience view: average rating per trip (used by Flutter to show star rating)
CREATE OR REPLACE VIEW public.trip_list_avg_ratings AS
SELECT
  trip_list_id,
  ROUND(AVG(rating)::NUMERIC, 1) AS avg_rating,
  COUNT(*) AS review_count
FROM public.trip_list_reviews
GROUP BY trip_list_id;

-- ============================================================
-- PART 4C: TRIP LOCATIONS
-- ============================================================

CREATE TABLE public.trip_locations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id    UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  added_by        UUID NOT NULL REFERENCES public.profiles(id),
  name            TEXT NOT NULL,
  description     TEXT,
  address         TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  place_id        TEXT,             -- Google Maps Place ID (stable key)
  place_type      TEXT,             -- 'restaurant' | 'hotel' | 'attraction' | etc.
  google_maps_url TEXT,
  website_url     TEXT,
  phone_number    TEXT,
  order_index     INT NOT NULL DEFAULT 0,
  visit_date      DATE,
  visit_time      TIME,
  duration_hours  NUMERIC(5,2),     -- estimated dwell time
  is_manual       BOOLEAN NOT NULL DEFAULT TRUE,
  metadata        JSONB DEFAULT '{}', -- raw Google Places API payload
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_locations_updated_at
  BEFORE UPDATE ON public.trip_locations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX idx_locations_trip     ON public.trip_locations (trip_list_id, order_index);
CREATE INDEX idx_locations_geo      ON public.trip_locations (latitude, longitude);
CREATE INDEX idx_locations_place_id ON public.trip_locations (place_id) WHERE place_id IS NOT NULL;
CREATE INDEX idx_locations_date     ON public.trip_locations (trip_list_id, visit_date) WHERE visit_date IS NOT NULL;

-- RPC: reorder locations (drag-and-drop in UI)
CREATE OR REPLACE FUNCTION public.reorder_locations(
  p_trip_list_id UUID,
  p_ordered_ids  UUID[]
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.can_edit_trip(p_trip_list_id, auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE public.trip_locations
  SET order_index = idx.pos
  FROM (
    SELECT unnest(p_ordered_ids) AS id, generate_subscripts(p_ordered_ids, 1) AS pos
  ) idx
  WHERE trip_locations.id = idx.id
    AND trip_locations.trip_list_id = p_trip_list_id;
END;
$$;

ALTER TABLE public.trip_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Locations visible to trip members"
  ON public.trip_locations FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

CREATE POLICY "Editors add locations"
  ON public.trip_locations FOR INSERT
  WITH CHECK (public.can_edit_trip(trip_list_id, auth.uid()) AND added_by = auth.uid());

CREATE POLICY "Editors update locations"
  ON public.trip_locations FOR UPDATE
  USING (public.can_edit_trip(trip_list_id, auth.uid()));

CREATE POLICY "Editors delete locations"
  ON public.trip_locations FOR DELETE
  USING (public.can_edit_trip(trip_list_id, auth.uid()));

-- ============================================================
-- PART 4D: TRIP NOTES & NOTE IMAGES
-- ============================================================

CREATE TABLE public.trip_notes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id  UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  author_id     UUID NOT NULL REFERENCES public.profiles(id),
  title         TEXT NOT NULL,
  body          TEXT,
  -- tag_key: a short slug used for @referencing in chat. E.g. "hotel-info" or "packing-list"
  -- Must be unique within a trip.
  tag_key       TEXT,
  is_pinned     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- tag_key unique per trip (not globally)
CREATE UNIQUE INDEX idx_notes_tag_key
  ON public.trip_notes (trip_list_id, tag_key)
  WHERE tag_key IS NOT NULL;

CREATE INDEX idx_notes_trip ON public.trip_notes (trip_list_id);

CREATE TRIGGER set_notes_updated_at
  BEFORE UPDATE ON public.trip_notes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.trip_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Notes visible to trip members"
  ON public.trip_notes FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

CREATE POLICY "Editors create notes"
  ON public.trip_notes FOR INSERT
  WITH CHECK (public.can_edit_trip(trip_list_id, auth.uid()) AND author_id = auth.uid());

CREATE POLICY "Editors update notes"
  ON public.trip_notes FOR UPDATE
  USING (public.can_edit_trip(trip_list_id, auth.uid()));

CREATE POLICY "Editors delete notes"
  ON public.trip_notes FOR DELETE
  USING (public.can_edit_trip(trip_list_id, auth.uid()));

-- Note images (trip_list_id denormalized for efficient RLS)
CREATE TABLE public.note_images (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id       UUID NOT NULL REFERENCES public.trip_notes(id) ON DELETE CASCADE,
  trip_list_id  UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  storage_path  TEXT NOT NULL,   -- e.g. "note-images/{trip_id}/{note_id}/{uuid}.jpg"
  filename      TEXT NOT NULL,   -- original filename used for @tagging in chat
  caption       TEXT,
  uploaded_by   UUID NOT NULL REFERENCES public.profiles(id),
  order_index   INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_note_images_note     ON public.note_images (note_id, order_index);
-- filename search within a trip (powers the @mention autocomplete in chat)
CREATE INDEX idx_note_images_filename ON public.note_images (trip_list_id, filename);

ALTER TABLE public.note_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Note images visible to trip members"
  ON public.note_images FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

CREATE POLICY "Editors upload note images"
  ON public.note_images FOR INSERT
  WITH CHECK (public.can_edit_trip(trip_list_id, auth.uid()) AND uploaded_by = auth.uid());

CREATE POLICY "Editors delete note images"
  ON public.note_images FOR DELETE
  USING (public.can_edit_trip(trip_list_id, auth.uid()));
```

### Info on Maps SDK and Places API


## Part 5 - Group Chat (kind of deprecated, check the schema at the beginning for reference)

### SQL
```sql
-- ============================================================
-- PART 5: CHAT ROOMS + MESSAGES + REACTIONS
-- ============================================================

CREATE TABLE public.chat_rooms (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_list_id  UUID NOT NULL UNIQUE REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create a chat room every time a new trip list is created
CREATE OR REPLACE FUNCTION public.create_chat_room_for_trip()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.chat_rooms (trip_list_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_trip_list_created
  AFTER INSERT ON public.trip_lists
  FOR EACH ROW EXECUTE FUNCTION public.create_chat_room_for_trip();

ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chat room visible to trip members"
  ON public.chat_rooms FOR SELECT
  USING (public.can_access_trip(trip_list_id, auth.uid()));

-- ============================================================
-- CHAT MESSAGES
-- ============================================================

CREATE TABLE public.chat_messages (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id             UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  -- Denormalized for O(1) RLS checks without joining through chat_rooms:
  trip_list_id        UUID NOT NULL REFERENCES public.trip_lists(id) ON DELETE CASCADE,
  sender_id           UUID NOT NULL REFERENCES public.profiles(id),
  content             TEXT,
  message_type        public.chat_message_type NOT NULL DEFAULT 'text',

  -- For note_ref messages: which note or image is being referenced
  referenced_note_id  UUID REFERENCES public.trip_notes(id) ON DELETE SET NULL,
  referenced_image_id UUID REFERENCES public.note_images(id) ON DELETE SET NULL,

  -- For image messages: path in chat-images storage bucket
  storage_path        TEXT,

  -- Threading
  reply_to_id         UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL,

  -- Edit / soft-delete
  is_edited           BOOLEAN NOT NULL DEFAULT FALSE,
  is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT text_or_ref CHECK (
    content IS NOT NULL
    OR storage_path IS NOT NULL
    OR referenced_note_id IS NOT NULL
    OR referenced_image_id IS NOT NULL
  )
);

CREATE TRIGGER set_messages_updated_at
  BEFORE UPDATE ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Critical index: paginating messages for a room
CREATE INDEX idx_messages_room    ON public.chat_messages (room_id, created_at DESC);
CREATE INDEX idx_messages_sender  ON public.chat_messages (sender_id);
CREATE INDEX idx_messages_note_ref ON public.chat_messages (referenced_note_id) WHERE referenced_note_id IS NOT NULL;

-- ENABLE REALTIME on this table
-- (Also enable it in the Supabase Dashboard: Table Editor > chat_messages > Enable Realtime)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages visible to invited members only"

  ON public.chat_messages FOR SELECT

  USING (

    EXISTS (

      SELECT 1 FROM public.trip_lists

      WHERE id = trip_list_id AND owner_id = auth.uid()

    )

    OR

    EXISTS (

      SELECT 1 FROM public.trip_list_collaborators

      WHERE trip_list_id = chat_messages.trip_list_id

        AND user_id = auth.uid()

    )

  );

  

-- Final chat INSERT policy: explicit invite only

CREATE POLICY "Invited members send messages"

  ON public.chat_messages FOR INSERT

  WITH CHECK (

    sender_id = auth.uid()

    AND (

      EXISTS (

        SELECT 1 FROM public.trip_lists

        WHERE id = trip_list_id AND owner_id = auth.uid()

      )

      OR

      EXISTS (

        SELECT 1 FROM public.trip_list_collaborators

        WHERE trip_list_id = chat_messages.trip_list_id

          AND user_id = auth.uid()

      )

    )

  );

CREATE POLICY "Sender edits own messages"
  ON public.chat_messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());
```
# Part 6 - Buckets
```sql
-- ============================================================
-- PART 6: STORAGE RLS POLICIES
-- Run AFTER creating the four buckets in the dashboard.
-- ============================================================

-- AVATARS (public bucket — only need upload/delete control)
CREATE POLICY "Anyone reads avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "User uploads their own avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "User replaces their own avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "User deletes their own avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- TRIP COVERS (public bucket)
CREATE POLICY "Anyone reads trip covers"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'trip-covers');

CREATE POLICY "Trip editors upload covers"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'trip-covers'
    -- Path structure: trip-covers/{trip_list_id}/{filename}
    AND public.can_edit_trip(
      (storage.foldername(name))[1]::uuid,
      auth.uid()
    )
  );

CREATE POLICY "Trip editors delete covers"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'trip-covers'
    AND public.can_edit_trip(
      (storage.foldername(name))[1]::uuid,
      auth.uid()
    )
  );

-- NOTE IMAGES (private bucket — signed URLs required)
CREATE POLICY "Trip members read note images"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'note-images'
    AND (
      EXISTS (
        SELECT 1 FROM public.trip_lists
        WHERE id = (storage.foldername(name))[1]::uuid
          AND owner_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.trip_list_collaborators
        WHERE trip_list_id = (storage.foldername(name))[1]::uuid
          AND user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Trip editors upload note images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'note-images'
    AND public.can_edit_trip(
      (storage.foldername(name))[1]::uuid,
      auth.uid()
    )
  );

CREATE POLICY "Trip editors delete note images"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'note-images'
    AND public.can_edit_trip(
      (storage.foldername(name))[1]::uuid,
      auth.uid()
    )
  );

-- CHAT IMAGES (private bucket)
CREATE POLICY "Only invited members read chat images"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (
      EXISTS (
        SELECT 1 FROM public.trip_lists
        WHERE id = (storage.foldername(name))[1]::uuid
          AND owner_id = auth.uid()
      )
      OR
      EXISTS (
        SELECT 1 FROM public.trip_list_collaborators
        WHERE trip_list_id = (storage.foldername(name))[1]::uuid
          AND user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Only invited members upload chat images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-images'
    AND (
      EXISTS (
        SELECT 1 FROM public.trip_lists
        WHERE id = (storage.foldername(name))[1]::uuid
          AND owner_id = auth.uid()
      )
      OR
      EXISTS (
        SELECT 1 FROM public.trip_list_collaborators
        WHERE trip_list_id = (storage.foldername(name))[1]::uuid
          AND user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Sender deletes own chat images"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[2] IN (
      -- Only delete if you are the sender of the message with that ID
      SELECT cm.id::text FROM public.chat_messages cm
      WHERE cm.sender_id = auth.uid()
    )
  );
```

# Flutter Realtime chat subscription
```dart
// In your ChatService or ChatNotifier class:

final _supabase = Supabase.instance.client;
late RealtimeChannel _channel;

void subscribeToRoom(String roomId, String tripListId) {
  _channel = _supabase
    .channel('room:$roomId')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        final newMessage = payload.newRecord;
        // Add to local state / Riverpod provider
        ref.read(messagesProvider(roomId).notifier).addMessage(newMessage);
      },
    )
    .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        // Handle edits and soft-deletes
        ref.read(messagesProvider(roomId).notifier).updateMessage(payload.newRecord);
      },
    )
    .subscribe();
}

// Paginated history load (call on screen open)
Future<List<Map<String, dynamic>>> fetchMessages(
  String roomId, {
  int limit = 50,
  DateTime? before,
}) async {
  var query = _supabase
    .from('chat_messages')
    .select('''
      *,
      sender:profiles!sender_id(username, avatar_url),
      reply_to:chat_messages!reply_to_id(id, content, sender:profiles!sender_id(username)),
      referenced_note:trip_notes!referenced_note_id(id, title, tag_key),
      referenced_image:note_images!referenced_image_id(id, filename, storage_path)
    ''')
    .eq('room_id', roomId)
    .eq('is_deleted', false)
    .order('created_at', ascending: false)
    .limit(limit);

  if (before != null) {
    query = query.lt('created_at', before.toIso8601String());
  }

  return await query;
}

void unsubscribe() => _channel.unsubscribe();
```
You’ll need to call `supabase.storage.from(bucket).createSignedUrl(path)` in the UI. The AI agent should be told about that.




