--calcul la pression de pâturage d'un cheptel de bovin sur une exploitation.
--Maintainer: Julien Ancelin
-------------------------------------------------------

SELECT ROW_NUMBER() OVER () as unique_id,
G.parcelle,
G.geom,
G.surface,
sum(G.ugbha_pond)as ugbha_moy_pond,
sum (ugbjha_pond) as ugbjha_moy_pond, 
sum (ugbha1) as ugb_ha
FROM (SELECT F.pat,
	  F.nbr_j_patur,
	  zzz.sum,
	  (F.nbr_j_patur/zzz.sum)as pourc_patur,
	  sum(F."ugb/j") as ugbha1,
	  sum(F."ugb/j/ha") as ugbha,
	  cast(((F.nbr_j_patur/zzz.sum)*sum(F."ugb/j/ha"))as numeric (5,2)) as ugbha_pond,
	  sum(F."ugb.j/ha")as ugbjha,
	  cast(((F.nbr_j_patur/zzz.sum)*sum(F."ugb.j/ha"))as numeric (5,2)) as ugbjha_pond,
	  zz.parcelle, zz.surface,zzz.geom
	  FROM (SELECT E.num,
			E.pat,
			E.surface,
			cast(E.nbr_j_patur as numeric),
			(E.sig1+E.sig2+E.sig3+E.sig4) as somsig,
			cast((E.sig1+E.sig2+E.sig3+E.sig4)/E.nbr_j_patur as numeric(4,2)) as "ugb/j",
			cast(((E.sig1+E.sig2+E.sig3+E.sig4)/E.nbr_j_patur)/E.surface as numeric(4,2)) as "ugb/j/ha",
			cast((((E.sig1+E.sig2+E.sig3+E.sig4)/E.nbr_j_patur)/E.surface)*E.nbr_j_patur as numeric(6,2)) as "ugb.j/ha" 
			FROM (SELECT D.num,
				  D.pat,
				  D.surface,
				  D.nbr_j_patur,
				  case when (D.om1-D.om5)*1 >=0 then (D.om1-D.om5)*1 else 0 end as sig1,
				  case when (D.om2-D.om1-D.om6)*0.8 >=0 then (D.om2-D.om1-D.om6)*0.8 else 0 end as sig2,
				  case when (D.om3-D.om2-D.om7)*0.6 >=0 then (D.om3-D.om2-D.om7)*0.6 else 0 end as sig3,
				  case when (D.om4-D.om3-D.om8)*0 >=0 then (D.om4-D.om3-D.om8)*0 else 0 end as sig4 
				  FROM (SELECT A.num,
						C.even1,
						C.even08,
						C.even06,
						C.even0,
						A.pat,
						B.surface,
						B.delta1,
						B.delta2,
						B.nbr_j_patur,
						case when (B.delta2-C.even1)>=0 then (B.delta2-C.even1) else 0 end as om1,
						case when (B.delta2-C.even08)>=0 then (B.delta2-C.even08) else 0 end as om2,
						case when (B.delta2-C.even06)>=0 then (B.delta2-C.even06) else 0 end as om3,
						case when (B.delta2-C.even0)>=0 then (B.delta2-C.even0) else 0 end as om4,
						case when (B.delta1-C.even1)>=0 then (B.delta1-C.even1) else 0 end as om5,
						case when (B.delta1-C.even08)>=0 then (B.delta1-C.even08) else 0 end as om6,
						case when (B.delta1-C.even06)>=0 then (B.delta1-C.even06) else 0 end as om7,
						case when (B.delta1-C.even0)>=0 then (B.delta1-C.even0) else 0 end as om8 
						FROM (SELECT distinct animaux.id_num_w as num,
							  paturage.id_patur as pat 
							  FROM public.animaux,
							  public.lolo_anx,
							  public.lot_anx,
							  public.paturage 
							  WHERE lolo_anx.id_num_w = animaux.id_num_w AND
							  lot_anx.id_lot_anx = lolo_anx.id_lot_anx AND
							  lot_anx.id_lot_anx = paturage.id_lot_anx 
							  ORDER by animaux.id_num_w) as A,
						
						(select distinct paturage.id_patur as pat ,
						 sum(parcelles_culturales.superficie)/10000 as surface ,
						 paturage.date_ent as delta1 ,
						 paturage.date_sort as delta2 ,
						 (paturage.date_sort - paturage.date_ent) as nbr_j_patur 
						 FROM public.paturage,
						 public.patur_parc,
						 public.parcelles_culturales 
						 WHERE paturage.id_patur = patur_parc.id_patur and
						 patur_parc.id_par_cul=parcelles_culturales.id_parcel and
						 paturage.date_ent between '2015-01-01' and '2015-12-31' 
						 GROUP by paturage.id_patur order by paturage.id_patur) as B,
						
						(SELECT distinct anx.id_num_w as num,
						 w.even1,
						 x.even08,
						 y.even06,
						 z.even0 
						 FROM public.animaux as anx,
						 (SELECT distinct animaux.id_num_w as num ,
						  CASE WHEN (ugb.ugb_valeur = 1) THEN evenement.even_date END AS even1 
						  FROM public.animaux join public.lolo_anx ON lolo_anx.id_num_w = animaux.id_num_w 
						  join public.lot_anx ON lot_anx.id_lot_anx = lolo_anx.id_lot_anx 
						  join public.catlo_an ON lot_anx.id_lot_anx = catlo_an.id_lot_anx 
						  join public.evenement ON catlo_an.id_even = evenement.id_even 
						  join public.even_ugb ON evenement.id_even = even_ugb.id_even 
						  join public.ugb ON even_ugb.id_ugb = ugb.id_ugb 
						  where CASE WHEN (ugb.ugb_valeur = 1) THEN evenement.even_date END is not null 
						  order by animaux.id_num_w) as w,
						 
						 (SELECT distinct animaux.id_num_w as num ,
						  CASE WHEN (ugb.ugb_valeur = 0.8) THEN evenement.even_date END AS even08
						  FROM public.animaux join public.lolo_anx ON lolo_anx.id_num_w = animaux.id_num_w 
						  join public.lot_anx ON lot_anx.id_lot_anx = lolo_anx.id_lot_anx 
						  join public.catlo_an ON lot_anx.id_lot_anx = catlo_an.id_lot_anx 
						  join public.evenement ON catlo_an.id_even = evenement.id_even 
						  join public.even_ugb ON evenement.id_even = even_ugb.id_even 
						  join public.ugb ON even_ugb.id_ugb = ugb.id_ugb 
						  where CASE WHEN (ugb.ugb_valeur = 0.8) THEN evenement.even_date END is not null 
						  order by animaux.id_num_w) as x,
						 
						 (SELECT distinct animaux.id_num_w as num , CASE WHEN (ugb.ugb_valeur = 0.6) THEN evenement.even_date END AS even06 
						  FROM public.animaux join public.lolo_anx ON lolo_anx.id_num_w = animaux.id_num_w 
						  join public.lot_anx ON lot_anx.id_lot_anx = lolo_anx.id_lot_anx 
						  join public.catlo_an ON lot_anx.id_lot_anx = catlo_an.id_lot_anx 
						  join public.evenement ON catlo_an.id_even = evenement.id_even 
						  join public.even_ugb ON evenement.id_even = even_ugb.id_even 
						  join public.ugb ON even_ugb.id_ugb = ugb.id_ugb 
						  where CASE WHEN (ugb.ugb_valeur = 0.6) THEN evenement.even_date END is not null 
						  order by animaux.id_num_w) as y,
						 
						 (SELECT distinct animaux.id_num_w as num , CASE WHEN (ugb.ugb_valeur = 0) THEN evenement.even_date END AS even0 
						  FROM public.animaux join public.lolo_anx ON lolo_anx.id_num_w = animaux.id_num_w 
						  join public.lot_anx ON lot_anx.id_lot_anx = lolo_anx.id_lot_anx 
						  join public.catlo_an ON lot_anx.id_lot_anx = catlo_an.id_lot_anx 
						  join public.evenement ON catlo_an.id_even = evenement.id_even 
						  join public.even_ugb ON evenement.id_even = even_ugb.id_even 
						  join public.ugb ON even_ugb.id_ugb = ugb.id_ugb 
						  where CASE WHEN (ugb.ugb_valeur = 0) THEN evenement.even_date END is not null 
						  order by animaux.id_num_w) as z 
						 
						 where anx.id_num_w=w.num and
						 anx.id_num_w=x.num and
						 anx.id_num_w=y.num and
						 anx.id_num_w=z.num 
						 ORDER BY anx.id_num_w) as C 
						WHERE A.num=C.num AND A.pat=B.pat)
				  as D)
			as E)
	  F,
	  ( select paturage.id_patur as pat ,
	   parcelles_culturales.nom as parcelle,
	   (parcelles_culturales.superficie)/10000 as surface 
	   FROM public.paturage, public.patur_parc,
	   public.parcelles_culturales 
	   WHERE paturage.id_patur = patur_parc.id_patur and
	   patur_parc.id_par_cul=parcelles_culturales.id_parcel 
	   GROUP by paturage.id_patur,
	   parcelles_culturales.nom,
	   parcelles_culturales.superficie 
	   order by paturage.id_patur)as zz,
	  
	  (select parcelles_culturales.nom as parcelle,
	   sum(paturage.date_sort - paturage.date_ent),
	   parcelle_culturales_shp.geom 
	   FROM public.paturage,
	   public.patur_parc,
	   public.parcelles_culturales,
	   public.parcelle_culturales_shp 
	   WHERE paturage.id_patur = patur_parc.id_patur and
	   patur_parc.id_par_cul=parcelles_culturales.id_parcel and
	   parcelles_culturales.id_geom=parcelle_culturales_shp.id_geom 
	   GROUP by parcelles_culturales.nom,parcelle_culturales_shp.geom 
	   order by parcelles_culturales.nom)as zzz 
	  
	  WHERE zz.pat =F.pat and
	  zzz.parcelle= zz.parcelle 
	  group by F.pat,F.nbr_j_patur,
	  zz.parcelle, zz.surface,
	  zzz.sum,zzz.geom 
	  order by zz.parcelle) as G 
	group by G.parcelle, 
	G.surface,
	G.geom 
	  
	  
