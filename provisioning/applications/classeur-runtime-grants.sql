-- Apply manually as postgres after backup and compatible app/preflight rollout.
-- Never run automatically when NixOS or Git branches change.
\set ON_ERROR_STOP on
BEGIN;
DO $$
BEGIN
  IF current_database() <> 'le_classeur_beta' THEN
    RAISE EXCEPTION 'Unexpected database';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='le_classeur_app'
      AND (rolsuper OR rolcreaterole OR rolcreatedb OR rolbypassrls)) THEN
    RAISE EXCEPTION 'Unsafe runtime role attributes';
  END IF;
END $$;
REVOKE UPDATE, DELETE ON TABLE
  events, settings_revisions, card_edit_history, beta_access_events,
  collection_events, collection_transfers FROM le_classeur_app;
GRANT SELECT, INSERT ON TABLE
  events, settings_revisions, card_edit_history, beta_access_events,
  collection_events, collection_transfers TO le_classeur_app;
DO $$
DECLARE relation text;
BEGIN
  FOREACH relation IN ARRAY ARRAY['events','settings_revisions','card_edit_history','beta_access_events','collection_events','collection_transfers'] LOOP
    IF has_table_privilege('le_classeur_app',relation,'UPDATE')
      OR has_table_privilege('le_classeur_app',relation,'DELETE')
      OR has_table_privilege('le_classeur_app',relation,'TRUNCATE')
      OR has_table_privilege('le_classeur_app',relation,'TRIGGER')
      OR has_table_privilege('le_classeur_app',relation,'REFERENCES') THEN
      RAISE EXCEPTION 'Excess effective journal privileges: %', relation;
    END IF;
    IF NOT has_table_privilege('le_classeur_app',relation,'SELECT')
      OR NOT has_table_privilege('le_classeur_app',relation,'INSERT') THEN
      RAISE EXCEPTION 'Missing effective journal privileges: %', relation;
    END IF;
  END LOOP;
END $$;
COMMIT;
