CREATE OR REPLACE FUNCTION parcelle_hh()
  RETURNS trigger AS
$BODY$
BEGIN
  new.hh_par_co = distinct assol.nom from assol_view as assol,hauteur_herbe as hh where camp_an = '2015-2016' and st_intersects(assol.geom,NEW.geom);
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION parcelle_hh()
  OWNER TO postgres;

CREATE TRIGGER trig_parcelle_hh
  BEFORE INSERT OR UPDATE
  ON hauteur_herbe
  FOR EACH ROW
  EXECUTE PROCEDURE parcelle_hh();
