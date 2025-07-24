import uuid
import pytest
import psycopg
import os
from dotenv import load_dotenv

load_dotenv()


## ----DB connection fixture----
@pytest.fixture(scope='module')
def conn():
    """Fixture to create a database connection for tests."""
    db_host = os.getenv("DB_HOST")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_user")
    db_password = os.getenv("DB_PASSWORD")
    db_port = os.getenv("DB_port")

    conn = psycopg.connect(
        host=db_host,
        dbname=db_name,
        user=db_user,
        password=db_password,
        port=db_port
    )
    
    yield conn
    conn.close()

## ----Helper functions for tests----
def create_group(conn, name, gtype = 'organizational_unit'):
    with conn.cursor() as cur:
        cur.execute("""
        INSERT INTO public.groups (id, name, type)
                VALUES (%s, %s, %s)
                RETURNING id;
        """, (str(uuid.uuid4()), name, gtype))
        return cur.fetchone()[0]
    
def create_group_hierarchy(conn, child_id, parent_id, child_name):
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO public.group_hierarchies (child_group_id, parent_group_id, child_name)
            VALUES (%s, %s, %s);
        """, (child_id, parent_id, child_name))

# ----Rollbsck after each test----
@pytest.fixture(autouse=True)
def rollback_after_test(conn):
    with conn.cursor() as cur:
        cur.execute("BEGIN;")
        yield
        cur.execute("ROLLBACK;")

# ----test cases----

def test_create_group(conn):
    group_name = "TEST_GROUP"
    group_id = create_group(conn, group_name)
    assert group_id is not None, "Group ID should not be none"
    with conn.cursor() as cur:
        cur.execute("SELECT name FROM public.groups WHERE id = %s;", (group_id,))
        result = cur.fetchone()[0]
        assert result is not None, "Group should exist in the database"
        assert result == group_name, "Group name should match the created name"
        # test passed
        print(f"Group '{group_name}' created successfully with ID: {group_id}")

def test_create_group_hirarchy(conn):
    parent_name = "A"
    child_name = "B"
    parent_id = create_group(conn, parent_name)
    child_id = create_group(conn, child_name)
    
    create_group_hierarchy(conn, child_id, parent_id, child_name)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT child_group_id, parent_group_id, child_name
            FROM public.group_hierarchies
            WHERE child_group_id = %s AND parent_group_id = %s;
            """, (child_id, parent_id))
        result = cur.fetchone()
        assert result is not None, "Group hierarchy should exist in the database"
        assert result[0] == child_id, "Child group ID should match"
        assert result[1] == parent_id, "Parent group ID should match"
        assert result[2] == child_name, "Child name should match"

def test_make_root_type_group_child(conn):
    root_group_name_1 = "root1"
    group_name = "A"

    root_id_1 = create_group(conn, root_group_name_1, 'root')

    group_id = create_group(conn, group_name)

    with pytest.raises(psycopg.Error) as excinfo:
        create_group_hierarchy(conn, root_id_1, group_id, root_group_name_1)
    
    assert "Cannot add a root group as a child group." in str(excinfo.value)

def test_add_multiple_roots(conn):
    root_group_name_1 = "root1"
    root_group_name_2 = "root2"

    root_id_1 = create_group(conn, root_group_name_1, 'root')

    with pytest.raises(psycopg.Error) as excinfo:
        root_id_2 = create_group(conn, root_group_name_2, 'root')

    assert "Cannot add a root group when one already exists." in str(excinfo.value)






    