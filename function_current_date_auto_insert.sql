--auto insert current date 
--Maintainer: Julien Ancelin
-------------------------------------------------------
CREATE OR REPLACE FUNCTION date_hh()
  RETURNS trigger AS
$BODY$
BEGIN
  new.hh_date = current_date;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION date_limi()
  OWNER TO postgres;

CREATE TRIGGER trig_date_hh
  BEFORE INSERT
  ON hauteur_herbe
  FOR EACH ROW
  EXECUTE PROCEDURE date_hh();
