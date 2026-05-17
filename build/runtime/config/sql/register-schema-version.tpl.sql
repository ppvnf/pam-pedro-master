CREATE TABLE IF NOT EXISTS guacamole_version (id INT PRIMARY KEY, version_num VARCHAR(20));
INSERT INTO guacamole_version (id, version_num)
    VALUES (1, '$GUAC_VER')
ON CONFLICT (id)
    DO UPDATE SET version_num = EXCLUDED.version_num;