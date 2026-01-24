# Examples (Compose Stack Changes)

## Example 1: Port change (low risk)
- Change only published port mapping for a UI service.
- Keep container ports and service names unchanged.
- Verify with:
  - `docker compose -f infra/compose/<file>.yml config`
  - `docker compose -f infra/compose/<file>.yml up -d --build`
  - `curl -I http://localhost:<new-port>/health`

## Example 2: Optional helper service (medium risk)
- Add a new helper service in an override file.
- Do not modify base stack files.
- Verify with:
  - `docker compose -f infra/compose/<base>.yml -f infra/compose/<override>.yml config`
  - `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'`
  - A simple smoke check for the helper endpoint
