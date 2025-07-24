

### Groups 
This table represents the structure a group node will have.

The types mentioned in the group tables are of the group_type_enum.

| Column      | Type                     | Description                                                     | Primary? | not NULL? | Default               |
| ----------- | ------------------------ | --------------------------------------------------------------- | -------- | --------- | --------------------- |
| id          | UUID                     | Unique identifier for the group                                 | yes      | yes       | gen_random_uuid()     |
| name        | VARCHAR(255)             | The name of the group                                           | no       | yes       | NA                    |
| description | TEXT                     | Provides with a descriptive test about what the group is doing. | no       | no        | NA                    |
| type        | group_type_enum          | This specifies the type of the group                            | no       | yes       | 'organizational_unit' |
| created_at  | TIMESTAMP WITH TIME ZONE | creation timestamp                                              | no       | yes       | CURRENT_TIMESTAMP     |
| updated_at  | TIMESTAMP WITH TIME ZONE | updation timestamp                                              | no       | yes       | CURRENT_TIMESTAMP     |



### Group_Hierarchies 
This table defines the relations between the groups to form a hard tree structure with the help of some triggers and constraints.

Conditions-
1. A child can only have one parent, but a single parent can have multiple child.
2. Siblings under the same parent group cannot have same name
3. Prevent cyclic being possible (eg.  A->B->C->A)
4. To enforce that root is not children of any node and the lists are only children of the other nodes

Solutions-
1. The child_group_id is made the primary key of the table.
2. The child Name and the parent_id are made into a unique contraint this forcing different names for same parent
3. cycles are prevented using the no_cycle triggers and is run on the query before the insertion/updation
4. this is enforced using triggers to check the group type and enforce the conditions before the insertion/updation

| Column          | Type                     | Description                                     | Primary? | not NULL? | Default           |
| --------------- | ------------------------ | ----------------------------------------------- | -------- | --------- | ----------------- |
| child_group_id  | UUID                     | This references the id from the groups table    | yes      | yes       | NA                |
| parent_group_id | UUID                     | This references the id from the groups table    | no       | yes       | NA                |
| child_name      | VARCHAR(255)             | This references the name from the groups table. | no       | yes       | NA                |
| created_at      | TIMESTAMP WITH TIME ZONE | creation timestamp                              | no       | yes       | CURRENT_TIMESTAMP |
| updated_at      | TIMESTAMP WITH TIME ZONE | updation timestamp                              | no       | yes       | CURRENT_TIMESTAMP |





