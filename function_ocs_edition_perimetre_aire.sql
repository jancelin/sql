CREATE OR REPLACE VIEW public.ocs_edit_view AS
SELECT 
row_number() over() as unique_id,
  parcelle.par_id, 
  parcelle.par_annee, 
  parcelle.par_ocs, 
  code_culture.ocs_libelle, 
  classe_culture.nom_classe, 
  parcelle.geom, 
  parcelle.par_secteur, 
  parcelle.par_perimetre, 
  parcelle.par_aire, 
  parcelle.par_num_inra, 
  parcelle.par_age, 
  parcelle.par_exploitant,
  emprise.emp_id,
  emprise.emp_nom
FROM 
  public.parcelle left join code_culture on parcelle.par_ocs = code_culture.ocs_id
  left join classe_culture on code_culture.ocs_id_classe = classe_culture.id_classe,
  public.emprise
WHERE 
  emprise.emp_id=parcelle.emp_id;

CREATE OR REPLACE FUNCTION ocs_maj() RETURNS TRIGGER AS $$
	BEGIN

	IF (TG_OP = 'INSERT') then
	INSERT INTO parcelle VALUES(
	nextval('parcelle_chize_par_id_seq'::regclass),
	NEW.par_secteur,
	NEW.par_annee,
	NEW.par_exploitant,
	NEW.par_ocs,
	NEW.geom,
	NEW.par_age,
	NULL,
	NULL,
	NEW.par_num_inra,
    NULL);
	RETURN NEW;
  	 
 	ELSIF (TG_OP = 'UPDATE') THEN
       UPDATE parcelle SET 
	par_id=NEW.par_id, 
	par_secteur=NEW.par_secteur,
	par_annee=NEW.par_annee,
	par_exploitant=NEW.par_exploitant,
	par_ocs=NEW.par_ocs,
	geom=NEW.geom,
	par_age=NEW.par_age,
	par_perimetre=NULL,
	par_aire=NULL,
	par_num_inra=NEW.par_num_inra,
    emp_id=NULL
	where par_id=OLD.par_id;
	RETURN NEW;

	ELSIF (TG_OP = 'DELETE') THEN
	DELETE FROM parcelle where par_id=OLD.par_id;
	RETURN NULL;

	END IF;
	RETURN NEW;
	
	END;
	$$ LANGUAGE plpgsql;


CREATE TRIGGER ocs_edit_trig
INSTEAD OF INSERT OR UPDATE OR DELETE ON ocs_edit_view
    FOR EACH ROW EXECUTE PROCEDURE ocs_maj();


CREATE OR REPLACE FUNCTION surf_parcelle() RETURNS "trigger" AS $$

	BEGIN
  
	NEW.par_aire= st_area(NEW.geom);
	RETURN NEW;

	END;
	$$LANGUAGE 'plpgsql' IMMUTABLE;

ALTER FUNCTION surf_parcelle() OWNER TO postgres;

CREATE TRIGGER surf_parcelle_trig
BEFORE INSERT OR UPDATE ON public.parcelle FOR EACH ROW
   EXECUTE PROCEDURE public.surf_parcelle();


CREATE OR REPLACE FUNCTION perim_parcelle() RETURNS "trigger" AS $$

	BEGIN
  
	NEW.par_perimetre= st_perimeter(NEW.geom);
	RETURN NEW;

	END;
	$$LANGUAGE 'plpgsql' IMMUTABLE;

ALTER FUNCTION perim_parcelle() OWNER TO postgres;

CREATE TRIGGER perim_parcelle_trig
BEFORE INSERT OR UPDATE ON public.parcelle FOR EACH ROW
   EXECUTE PROCEDURE public.perim_parcelle();
   
  CREATE OR REPLACE FUNCTION empr_parcelle() RETURNS "trigger" AS $$

	BEGIN
  
	NEW.emp_id= distinct emprise.emp_id from emprise,parcelle where st_intersects(NEW.geom,emprise.geom);
	RETURN NEW;

	END;
	$$LANGUAGE 'plpgsql' IMMUTABLE;

ALTER FUNCTION empr_parcelle() OWNER TO postgres;

CREATE TRIGGER empr_parcelle_trig
BEFORE INSERT OR UPDATE ON public.parcelle FOR EACH ROW
   EXECUTE PROCEDURE public.empr_parcelle();
