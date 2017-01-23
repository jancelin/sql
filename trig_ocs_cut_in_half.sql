--CUT A POLYGON IN HALF WITH A LINE
--Maintainer: Julien Ancelin
-----------------------------------------------------
-- La fonction ST_cut_in_half permet de couper un multipolygone, dans une couche, par une ligne et sans sélection.
-- La fonction renvoi les deux nouveaux polygones ainsi que l'id du polygone d'origine.

--but:		Simplifier la saisie terrain pour l'occupation du sol via un webmapping.

--entrée: 	* une couche postgis multipolygone : brouillon_poly 
--		* une colonne géometry polygones: geom
--		* un identifiant des polygones: id
--		* une couche postgis ligne (une seule entité est permise) pour le découpage : brouillon_ligne
--		* une une colonne géometry ligne: geom
--			
--utilisation: 	SELECT * from ST_cut_in_half('brouillon_poly','geom,'id','brouillon_ligne','geom')
--
--pricipe: 	Maintenant dès qu'une nouvelle ligne est construite la fonction st_cut_in_half
-- 		l'intersects avec les polygones, coupe la ligne au dimension du polygone et découpe ce dernier.

--résultat: la fonction revoie un tableau avec id_old (id du polygone d'origine) et new_geom (les nouvelles géométries)

CREATE OR REPLACE FUNCTION st_cut_in_half(tbl_p text, geom_p text, id_p text, tbl_l text, geom_l text) 
RETURNS TABLE(old_id int, new_geom geometry)
AS 
$$
DECLARE
carver text :=''; 
BEGIN	
carver := 'SELECT
	  '|| tbl_p ||'.'|| id_p ||' as old_id,
	  geom(ST_Dump(ST_Split('|| tbl_p ||'.'|| geom_p ||','|| tbl_l ||'.'|| geom_l ||'))) as new_geom 
	  FROM
	  '|| tbl_p ||',
	  '|| tbl_l ||',
	  (SELECT do_carver.geom
	    FROM (	
			SELECT geom(st_dump(ST_Intersection( '|| tbl_l ||'.'|| geom_l ||','|| tbl_p ||'.'|| geom_p ||') ) ) 
		 	FROM 	'|| tbl_l ||','|| tbl_p ||') as do_carver,
		 '|| tbl_l ||'
	    WHERE   ST_intersects(do_carver.geom,ST_StartPoint('|| tbl_l ||'.'|| geom_l ||'))=false and
		    ST_intersects(do_carver.geom,ST_EndPoint('|| tbl_l ||'.'|| geom_l ||'))=false) as carver_ready

	  WHERE ST_intersects('|| tbl_p ||'.'|| geom_p ||',ST_PointOnSurface(carver_ready.geom)) and
	  (SELECT count('|| tbl_p ||'.'|| id_p ||')  
		 FROM '|| tbl_p ||','|| tbl_l ||',
		  (SELECT do_carver.geom
		    FROM ( SELECT geom(st_dump(ST_Intersection( '|| tbl_l ||'.'|| geom_l ||','|| tbl_p ||'.'|| geom_p ||') ) ) 
			 	FROM 	'|| tbl_l ||','|| tbl_p ||') as do_carver,
			 '|| tbl_l ||'
		    WHERE   ST_intersects(do_carver.geom,ST_StartPoint('|| tbl_l ||'.'|| geom_l ||'))=false and
			    ST_intersects(do_carver.geom,ST_EndPoint('|| tbl_l ||'.'|| geom_l ||'))=false) as carver_ready
		  WHERE ST_intersects('|| tbl_p ||'.'|| geom_p ||',ST_PointOnSurface(carver_ready.geom))) = 1';	

FOR old_id, new_geom IN EXECUTE (carver)
	LOOP
	 RETURN NEXT;
	END LOOP;
END;
$$
LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION st_edit_cut_in_half(tbl_p text, geom_p text, id_p text, tbl_l text, geom_l text) 
RETURNS BOOLEAN
AS $$
DECLARE
carver text :='';
old_id_s int;
	BEGIN
carver := 'SELECT * FROM st_cut_in_half('''|| tbl_p ||''','''|| geom_p ||''','''|| id_p ||''','''|| tbl_l ||''','''|| geom_l ||''')';

 IF (select distinct old_id from  (SELECT * FROM st_cut_in_half($1,$2,$3,$4,$5)) as carvering) is not null THEN
select distinct old_id INTO old_id_s from  (SELECT * FROM st_cut_in_half($1,$2,$3,$4,$5)) as carvering;
EXECUTE 'INSERT INTO '|| tbl_p ||' ('|| geom_p ||') select st_multi(new_geom)  from ('|| carver ||') as carver';
EXECUTE 'DELETE FROM '|| tbl_p ||' WHERE '|| id_p ||'= '||old_id_s||'';
EXECUTE 'DELETE  FROM '|| tbl_l ||'';
RETURN TRUE;
ELSE 
EXECUTE 'DELETE  FROM '|| tbl_l ||'';
RETURN FALSE;
END IF;
	END;
$$
LANGUAGE plpgsql;

----------------------------------------------------------------
CREATE OR REPLACE FUNCTION ocs_cut_in_alf() RETURNs trigger AS $$
    BEGIN
EXECUTE 'select st_edit_cut_in_half(''poly_test'',''geom'',''id'',''line_cut'',''geom'')';
RETURN NEW;
    END;
$$
LANGUAGE plpgsql;



CREATE  TRIGGER ocs_cut_in_half
AFTER INSERT ON line_cut 
FOR EACH ROW
   EXECUTE PROCEDURE ocs_cut_in_alf();
