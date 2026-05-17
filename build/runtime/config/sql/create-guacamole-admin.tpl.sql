-- Create default user "$GUACAMOLE_ADMIN_USER"
INSERT INTO guacamole_entity (name, type) VALUES ('$GUACAMOLE_ADMIN_USER', 'USER');
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
SELECT
    entity_id,
    decode('$HASH', 'hex'),
    decode('$SALT', 'hex'),
    CURRENT_TIMESTAMP
FROM guacamole_entity WHERE name = '$GUACAMOLE_ADMIN_USER' AND guacamole_entity.type = 'USER';

-- Grant this user all system permissions
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission::guacamole_system_permission_type
FROM (
    VALUES
        ('$GUACAMOLE_ADMIN_USER', 'CREATE_CONNECTION'),
        ('$GUACAMOLE_ADMIN_USER', 'CREATE_CONNECTION_GROUP'),
        ('$GUACAMOLE_ADMIN_USER', 'CREATE_SHARING_PROFILE'),
        ('$GUACAMOLE_ADMIN_USER', 'CREATE_USER'),
        ('$GUACAMOLE_ADMIN_USER', 'CREATE_USER_GROUP'),
        ('$GUACAMOLE_ADMIN_USER', 'ADMINISTER')
) permissions (username, permission)
JOIN guacamole_entity ON permissions.username = guacamole_entity.name AND guacamole_entity.type = 'USER';

-- Grant admin permission to read/update/administer self
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT guacamole_entity.entity_id, guacamole_user.user_id, permission::guacamole_object_permission_type
FROM (
    VALUES
        ('$GUACAMOLE_ADMIN_USER', '$GUACAMOLE_ADMIN_USER', 'READ'),
        ('$GUACAMOLE_ADMIN_USER', '$GUACAMOLE_ADMIN_USER', 'UPDATE'),
        ('$GUACAMOLE_ADMIN_USER', '$GUACAMOLE_ADMIN_USER', 'ADMINISTER')
) permissions (username, affected_username, permission)
JOIN guacamole_entity          ON permissions.username = guacamole_entity.name AND guacamole_entity.type = 'USER'
JOIN guacamole_entity affected ON permissions.affected_username = affected.name AND guacamole_entity.type = 'USER'
JOIN guacamole_user            ON guacamole_user.entity_id = affected.entity_id;