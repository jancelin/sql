

CREATE OR REPLACE VIEW public.limi_view AS 

-- selectionne les champs à afficher
SELECT 
  limi_shp.limi_id as id, --id serial
  limi_shp.geom, -- geometrie
  limicole.limi_id, --id de l'observation
  --limicole.limi_date, --date de collecte de donnée
  limi_oiseau.id_oiseau,
  limi_oiseau.type_oiso, -- limicole ou non limicole
  limi_categorie.id_cat_lim,
  limi_categorie.categorie, -- individu, couple,...
  limicole.limi_qte, -- quantité d'individu
  limi_genre.id_gen_lim,
  limi_genre.genre, -- genre
  limi_espece.id_esp_lim,
  limi_espece.espece, -- espèce
  limi_sexe.id_sex_lim,
  limi_sexe.sexe, -- sexe
  limi_comportement.id_com_lim,
  limi_comportement.comportement, -- comportement pendant l'observation
  limicole.limi_nid, -- présence ou non d'un nid
  limicole.limi_jeun, -- nombre de jeune
  limicole.limi_anx, -- nombre d'animaux pour les parcelles hors domaine
  limicole.limi_com, -- commentaire
  limicole.limi_parc, -- code parcelle 
  limicole.limi_agent -- relevé par un autre agent
  
-- jointure externe gauche sur toutes les tables pour récupérer les champs vides
FROM 
    public.limi_shp
  
LEFT OUTER JOIN limicole ON (limicole.limi_id = limi_shp.limi_id )
lEFT OUTER JOIN limi_oiseau ON (limi_oiseau.id_oiseau = limicole.id_oiseau )
lEFT OUTER JOIN limi_categorie ON (limi_categorie.id_cat_lim = limicole.id_cat_lim )
lEFT OUTER JOIN limi_genre ON (limi_genre.id_gen_lim = limicole.id_gen_lim )
lEFT OUTER JOIN limi_espece ON (limi_espece.id_esp_lim = limicole.id_esp_lim )
lEFT OUTER JOIN limi_sexe ON (limi_sexe.id_sex_lim = limicole.id_sex_lim )
lEFT OUTER JOIN limi_comportement ON (limi_comportement.id_com_lim = limicole.id_com_lim)

-- condition, filtre
  
-- where limicole.limi_date between '\"01-01-2014\"' and '\"31-12-2014\"'


-- triage

order by   limicole.limi_date asc;
--droit
ALTER TABLE public.limi_view
  OWNER TO postgres;
GRANT ALL ON TABLE public.limi_view TO postgres;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.limi_view TO lizmap;

--trigger 
CREATE OR REPLACE FUNCTION limi_maj() RETURNS TRIGGER AS $$
	BEGIN

	IF (TG_OP = 'INSERT') then
	INSERT INTO limi_shp VALUES(nextval('limi_shp_limi_id_seq'::regclass),NEW.geom);
	INSERT INTO limicole VALUES (nextval('limicole_limi_id_seq'::regclass),
	NULL,
	new.id_oiseau,
	new.id_cat_lim,
	new.limi_qte, 
	new.id_gen_lim, 
	new.id_esp_lim,
	new.id_sex_lim,
	new.id_com_lim,
	new.limi_nid,
	new.limi_jeun,
	new.limi_anx,
	new.limi_com,
	NULL,
	NULL,
	new.limi_agent);
	RETURN NEW;
	

	ELSIF (TG_OP = 'UPDATE') THEN
       UPDATE limi_shp SET limi_id=NEW.limi_id, geom=NEW.geom WHERE limi_id=OLD.limi_id;
       UPDATE limicole SET limi_id=NEW.limi_id,
        limi_date=new.limi_date,
	id_oiseau=new.id_oiseau,
	id_cat_lim=new.id_cat_lim,
	limi_qte=new.limi_qte, 
	id_gen_lim=new.id_gen_lim, 
	id_esp_lim=new.id_esp_lim,
	id_sex_lim=new.id_sex_lim,
	id_com_lim=new.id_com_lim,
	limi_nid=new.limi_nid,
	limi_jeun=new.limi_jeun,
	limi_anx=new.limi_anx,
	limi_com=new.limi_com,
	limi_parc= NULL,
	limi_an= NULL,
	limi_agent=new.limi_agent
	
	WHERE limi_id=OLD.limi_id;
       RETURN NEW;

       ELSIF (TG_OP = 'DELETE') THEN -- pensez à inverser l'ordre des delete pour que ça marche
       DELETE FROM limicole WHERE limi_id=OLD.limi_id;
       DELETE FROM limi_shp WHERE limi_id=OLD.limi_id;
       RETURN NULL;
       
       END IF;
       RETURN NEW;
	
	END;
	$$ LANGUAGE plpgsql;
	
	CREATE TRIGGER test_limi_trigger
INSTEAD OF INSERT OR UPDATE OR DELETE ON limi_view
    FOR EACH ROW EXECUTE PROCEDURE limi_maj();

CREATE OR REPLACE FUNCTION date_limi()
  RETURNS "trigger" AS
$BODY$
BEGIN
  
  new.limi_date = current_date;
  RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE;
ALTER FUNCTION date_limi() OWNER TO postgres;


CREATE TRIGGER trig_date_limi BEFORE INSERT 
   ON public.limicole FOR EACH ROW
   EXECUTE PROCEDURE public.date_limi();
