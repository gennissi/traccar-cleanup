-- A MySQL user that can only read and delete the Traccar history tables.
-- Change CHANGE_ME to a strong password (and use the same one in /etc/traccar-cleanup.cnf).
CREATE USER 'traccar_cleanup'@'127.0.0.1' IDENTIFIED BY 'CHANGE_ME';
GRANT SELECT, DELETE ON traccar.tc_positions TO 'traccar_cleanup'@'127.0.0.1';
GRANT SELECT, DELETE ON traccar.tc_events    TO 'traccar_cleanup'@'127.0.0.1';
GRANT SELECT         ON traccar.tc_devices   TO 'traccar_cleanup'@'127.0.0.1';
