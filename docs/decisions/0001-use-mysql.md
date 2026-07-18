# ADR 0001: Use MySQL for CineConnect

- Status: accepted
- Date: 2026-07-17
- Decision owner: user

## Context

The master backend report proposes PostgreSQL, including PostgreSQL-specific
types, extensions, and indexing. The user explicitly corrected the production
database engine to SQL/MySQL. The supplied database credentials authenticate
successfully against Percona Server for MySQL 8.4.7 on the production server.

## Decision

Use SQLAlchemy 2 and Alembic with MySQL 8.4-compatible SQL. Production connects
to the existing MySQL service over loopback. Local and CI environments use the
same major MySQL behavior rather than SQLite.

## Required adaptations

- Store UUID primary keys with SQLAlchemy's portable UUID type using
  `native_uuid=False`; keep unique human-readable public IDs.
- Replace `citext` with a normalized email column using a Unicode
  case-insensitive collation plus application-level normalization.
- Replace PostgreSQL `inet` with bounded canonical string storage.
- Replace `JSONB` with MySQL `JSON`.
- Replace PostgreSQL trigram/GIN indexes with MySQL full-text indexes or
  dedicated normalized search columns.
- Replace exclusion constraints with transaction-safe overlap checks and
  locking.
- Use checked strings instead of database enums where values can evolve.
- Retain all engine-neutral requirements: UTC timestamps, integer minor-unit
  money, foreign-key indexes, idempotency, audit events, and migrations.

## Consequences

PostgreSQL-specific examples in the master report are non-binding where they
conflict with this decision. The logical tables, state machines, security
rules, API contracts, and acceptance criteria remain binding.
