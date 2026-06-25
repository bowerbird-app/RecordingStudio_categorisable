# Dummy App

This Rails app exists to validate `recording_studio_categorisable` inside a host-style application.

## What it covers

- Devise authentication with a seeded admin user
- `Current.actor` and `Current.impersonator` wiring for Recording Studio events
- workspace root recording setup
- mounted category management UI
- a page edit flow with one single-select and one multi-select category field
- FlatPack layout integration and Tailwind source scanning

## Quick start

```bash
bundle install
bin/rails db:setup
bin/dev
```

Then sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful routes

- `/`
- `/recording_studio`
- `/recording_studio_categorisable`
- `/pages`
- `/users/sign_in`
- `/up`
