-- schema.sql

-- Drop tables and types if they exist (for development/re-running script)
-- In a production migration, you'd typically use ALTER TABLE or more sophisticated migration tools
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.group_hierarchies CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.groups CASCADE;
DROP TABLE IF EXISTS public.courses CASCADE;
DROP TABLE IF EXISTS public.course_group_members CASCADE;
DROP TABLE IF EXISTS public.rooms CASCADE;
DROP TYPE IF EXISTS room_type_enum CASCADE;
DROP TYPE IF EXISTS group_type_enum CASCADE;
DROP TYPE IF EXISTS role_type_enum CASCADE;


BEGIN;

-- ENUM Type for group types
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'group_type_enum') THEN
        CREATE TYPE group_type_enum AS ENUM ('organizational_unit', 'root', 'user_list', 'course_list');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type_enum') THEN
        CREATE TYPE role_type_enum AS ENUM ('admin','teacher','student');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'room_type_enum') THEN
        CREATE TYPE room_type_enum AS ENUM ('lecture_hall','lab');
    END IF;

END
$$;

-- Users Table
CREATE TABLE IF NOT EXISTS public.users
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    google_sub_id VARCHAR(255) UNIQUE,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    role role_type_enum NOT NULL DEFAULT 'student',
    admission_year SMALLINT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Index for faster lookups by email (crucial for authentication flow)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower ON public.users (LOWER(email)) WHERE deleted_at IS NULL;

-- Courses Table
CREATE TABLE IF NOT EXISTS public.courses
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Groups Table
CREATE TABLE IF NOT EXISTS public.groups
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    type group_type_enum NOT NULL DEFAULT 'organizational_unit',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Group Hierarchies Table (Parent-Child relationships)
CREATE TABLE IF NOT EXISTS public.group_hierarchies
(
    child_group_id UUID PRIMARY KEY, -- Child can only have one parent
    parent_group_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_child_group
        FOREIGN KEY (child_group_id)
        REFERENCES public.groups (id)
        ON DELETE CASCADE,

    CONSTRAINT FK_parent_group
        FOREIGN KEY (parent_group_id)
        REFERENCES public.groups (id)
        ON DELETE CASCADE
);


-- Group Members Table (Many-to-Many between users and groups)
CREATE TABLE IF NOT EXISTS public.group_members
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role_in_group VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT UQ_group_member UNIQUE (group_id, user_id)
);

-- Foreign Key: group_id references public.groups
ALTER TABLE IF EXISTS public.group_members
    ADD CONSTRAINT FK_group_members_group FOREIGN KEY (group_id)
    REFERENCES public.groups (id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- Foreign Key: user_id references public.users
ALTER TABLE IF EXISTS public.group_members
    ADD CONSTRAINT FK_group_members_user FOREIGN KEY (user_id)
    REFERENCES public.users (id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;


-- course_group_ members Table (Many-to-Many Between courses and groups)
CREATE TABLE IF NOT EXISTS public.course_group_members
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL,
    group_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT UQ_course_group_member UNIQUE (course_id, group_id)
);

-- Rooms table
CREATE TABLE IF NOT EXISTS public.rooms
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    room_type room_type_enum NOT NULL DEFAULT 'lecture_hall', -- e.g., 'lecture_hall', 'lab', 'meeting_room'
    description TEXT,
    capacity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);



ALTER TABLE IF EXISTS public.course_group_members
    ADD CONSTRAINT fk_course_group_members_course FOREIGN KEY (course_id)
    REFERENCES public.courses (id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.course_group_members
    ADD CONSTRAINT fk_course_group_members_group FOREIGN KEY (group_id)
    REFERENCES public.groups (id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

COMMIT;