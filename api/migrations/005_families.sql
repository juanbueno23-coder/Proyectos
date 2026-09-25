CREATE TABLE families (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO families(code)
SELECT DISTINCT trim(family_code) FROM members
WHERE family_code IS NOT NULL AND trim(family_code) <> '';
UPDATE members SET family_code=NULL WHERE family_code IS NOT NULL AND trim(family_code)='';
CREATE SEQUENCE family_code_seq;
SELECT setval('family_code_seq', GREATEST(1, COALESCE((SELECT max(substring(code from '^F-([0-9]+)$')::bigint) FROM families WHERE code ~ '^F-[0-9]+$'), 0)+1), false);
ALTER TABLE members ADD CONSTRAINT members_family_code_fk FOREIGN KEY (family_code) REFERENCES families(code);
