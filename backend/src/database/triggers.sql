-- triggers.sql

BEGIN;

-- Function to update 'updated_at' timestamp (re-usable)
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
CREATE OR REPLACE TRIGGER update_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Trigger for groups table
CREATE OR REPLACE TRIGGER update_groups_updated_at
BEFORE UPDATE ON public.groups
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Trigger for group_hierarchies table
CREATE OR REPLACE TRIGGER update_group_hierarchies_updated_at
BEFORE UPDATE ON public.group_hierarchies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Trigger for group_members table
CREATE OR REPLACE TRIGGER update_group_members_updated_at
BEFORE UPDATE ON public.group_members
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();


-- Trigger function to enforce a single 'user_list' or 'course_list' child per parent group
CREATE OR REPLACE FUNCTION check_single_list_child()
RETURNS TRIGGER AS $$
DECLARE
    child_type group_type_enum;
    existing_list_count INTEGER;
BEGIN
    -- Get the type of the new child group being added/updated
    SELECT type INTO child_type
    FROM public.groups
    WHERE id = NEW.child_group_id;

    -- If the new child is NOT a 'user_list' or 'course_list' type, no special check is needed.
    IF child_type NOT IN ('user_list', 'course_list') THEN
        RETURN NEW;
    END IF;

    -- If the new child IS a 'user_list' or 'course_list' type, check if the parent already has one of the same type.
    SELECT COUNT(*)
    INTO existing_list_count
    FROM public.group_hierarchies gh
    JOIN public.groups g ON gh.child_group_id = g.id
    WHERE gh.parent_group_id = NEW.parent_group_id
      AND g.type = child_type
      AND gh.child_group_id IS DISTINCT FROM NEW.child_group_id; -- Exclude current row on UPDATE

    -- If another child of the same type already exists for this parent
    IF existing_list_count > 0 THEN
        RAISE EXCEPTION 'A group (ID: %) already has a child of type "%". Only one child of this type is allowed per parent group.', NEW.parent_group_id, child_type;
    END IF;

    RETURN NEW; -- Allow the insert/update to proceed
END;
$$ LANGUAGE plpgsql;

-- Trigger to attach the function to group_hierarchies table
CREATE OR REPLACE TRIGGER enforce_single_list_child
BEFORE INSERT OR UPDATE ON public.group_hierarchies
FOR EACH ROW
EXECUTE FUNCTION check_single_list_child();

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION prevent_group_hierarchy_cycles()
RETURNS TRIGGER AS $$
DECLARE
    is_cycle_detected BOOLEAN;
BEGIN
    -- Check if NEW.child_group_id is an ancestor of NEW.parent_group_id
    -- by traversing upwards from NEW.parent_group_id.
    -- If NEW.child_group_id is found during this traversal, a cycle would be formed.
    SELECT EXISTS (
        WITH RECURSIVE path_finder (group_id) AS (
            -- Anchor member: Start traversing upwards from the new parent group.
            SELECT gh.parent_group_id AS group_id
            FROM public.group_hierarchies gh
            WHERE gh.child_group_id = NEW.parent_group_id -- Find the parent of the new parent

            UNION ALL

            -- Recursive member: Find the parents of the groups found so far.
            SELECT gh.parent_group_id AS group_id
            FROM public.group_hierarchies gh
            JOIN path_finder pf ON gh.child_group_id = pf.group_id
        )
        -- The CYCLE clause detects if group_id is revisited in the path.
        -- We then check if the revisited group_id is NEW.child_group_id.
        CYCLE group_id SET is_cycle_flag TO TRUE DEFAULT FALSE -- is_cycle_flag will be TRUE if a cycle is found
              USING path_trace_column -- This column internally tracks the path to detect cycles

        SELECT 1
        FROM path_finder
        WHERE is_cycle_flag = TRUE -- This indicates an existing cycle was found in the graph
           OR group_id = NEW.child_group_id -- This indicates NEW.child_group_id is an ancestor of NEW.parent_group_id
    ) INTO is_cycle_detected;

    IF is_cycle_detected THEN
        RAISE EXCEPTION 'Circular dependency detected: Group ID % cannot be a parent of % as it would create a cycle.', NEW.child_group_id, NEW.parent_group_id;
    END IF;

    RETURN NEW; -- Allow the INSERT/UPDATE to proceed
END;
$$ LANGUAGE plpgsql;

-- 2. Create the trigger (remains the same)
CREATE TRIGGER check_group_hierarchy_cycle
BEFORE INSERT OR UPDATE ON public.group_hierarchies
FOR EACH ROW
EXECUTE FUNCTION prevent_group_hierarchy_cycles();

-- Trigger fuction to enforce root cannot be a child
CREATE OR REPLACE FUNCTION prevent_root_as_child()
RETURNS TRIGGER AS $$
DECLARE
    child_type group_type_enum;
    root_count INTEGER;
BEGIN
    -- Check if the new child group is the root group
    SELECT type INTO child_type
    FROM public.groups
    WHERE id = NEW.child_group_id;

    -- If the child group is of type 'root', raise an exception
    IF child_type = 'root' THEN
        RAISE EXCEPTION 'Cannot add a root group as a child group.';
    END IF;

    RETURN NEW; -- Allow the insert/update to proceed
END;
$$ LANGUAGE plpgsql;

-- Trigger to attach the function to group_hierarchies table
CREATE OR REPLACE TRIGGER enforce_root_behavior
BEFORE INSERT OR UPDATE ON public.group_hierarchies
FOR EACH ROW
EXECUTE FUNCTION prevent_root_as_child();

-- Trigger function to enforce single root type in the groups table
CREATE OR REPLACE FUNCTION prevent_multiple_roots()
RETURNS TRIGGER AS $$
DECLARE
    root_count INTEGER;
BEGIN
    -- if there already exists a root, we cannot add another root 
    IF NEW.type IS DISTINCT FROM 'root' THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)
    INTO root_count
    FROM public.groups
    WHERE type = 'root'
        AND (TG_OP = 'INSERT' OR id != NEW.id);

    -- If the child group is of type 'root' and there is already a root group, raise an exception
    IF root_count > 0 THEN
        RAISE EXCEPTION 'Cannot add a root group when one already exists.';
    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

-- Trigger to attach the fuction to groups table
CREATE OR REPLACE TRIGGER enforce_single_root
BEFORE INSERT OR UPDATE ON public.groups
FOR each ROW
EXECUTE FUNCTION prevent_multiple_roots();

COMMIT;