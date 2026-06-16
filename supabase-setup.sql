CREATE TABLE IF NOT EXISTS panneau_data (
  id INTEGER PRIMARY KEY DEFAULT 1,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT DEFAULT 'admin'
);

INSERT INTO panneau_data (id, data) VALUES (1, '{}') ON CONFLICT DO NOTHING;

ALTER TABLE panneau_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_read" ON panneau_data FOR SELECT TO anon USING (true);
CREATE POLICY "auth_all" ON panneau_data FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER panneau_data_updated_at
  BEFORE UPDATE ON panneau_data
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
