# traccar-cleanup

Stop your [Traccar](https://www.traccar.org/) database growing forever.

A small bash script that deletes old GPS positions and events from a Traccar MySQL database **in small batches**, so the server keeps running normally while it works. Run it every night with cron and the database stays roughly the same size.

📖 **Full guide:** [Stop your Traccar database growing forever — automated cleanup with bash and cron](https://gennissi.com/blog/traccar-database-cleanup)

## Features

- Deletes `tc_positions` and `tc_events` older than N days (default 90)
- Batches of 10,000 rows with a short pause, so there are no long locks or huge transactions
- **Never deletes a device's latest position** (`tc_devices.positionid`), so offline devices keep their last location on the map
- Dry-run mode that only counts rows
- Reads credentials from a MySQL options file, so no password appears in the script or in `ps`

## Quick start

```bash
# 1. Install the script
sudo cp traccar-cleanup.sh /usr/local/bin/
sudo chmod 750 /usr/local/bin/traccar-cleanup.sh

# 2. Create a MySQL user that can only clean up (edit the password first)
mysql -u root -p < grants.sql

# 3. Add the credentials file (edit the password first)
sudo cp traccar-cleanup.cnf.example /etc/traccar-cleanup.cnf
sudo chmod 600 /etc/traccar-cleanup.cnf

# 4. Back up, then do a dry run
mysqldump --single-transaction traccar | gzip > traccar-$(date +%F).sql.gz
sudo DRY_RUN=1 /usr/local/bin/traccar-cleanup.sh

# 5. Run it for real, then schedule it (see cron.example)
sudo /usr/local/bin/traccar-cleanup.sh
```

## Configuration

Set these as environment variables, or in the cron line:

| Variable | Default | Meaning |
|---|---|---|
| `DAYS` | `90` | Days of history to keep |
| `BATCH` | `10000` | Rows deleted per transaction |
| `DB` | `traccar` | Database name |
| `DRY_RUN` | `0` | `1` = only count rows, delete nothing |

Example: keep 180 days with `DAYS=180 /usr/local/bin/traccar-cleanup.sh`.

## Getting disk space back

InnoDB reuses the freed space for new rows, so the table stops growing. To shrink the file on disk, run `OPTIMIZE TABLE tc_positions;` once after the first big cleanup, in a quiet period and after a backup. It needs free disk space about the size of the remaining table data.

## Requirements

- Traccar with a MySQL or MariaDB database
- `bash` and the `mysql` client on the server
- Written for the Traccar 5.x database schema. Recent Traccar versions also have a built-in `database.historyDays` setting; see the guide for when this script is still useful.

## Need help?

Need help with your Traccar server? I offer Traccar setup and maintenance, GPS tracking apps and Flutter development — [contact me](https://gennissi.com/contact).

## License

MIT — see [LICENSE](LICENSE).
