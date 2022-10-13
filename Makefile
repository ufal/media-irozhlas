DATA := $(shell sh -c 'test `hostname` = "parczech" && echo -n "/opt/irozhlas/data/"')
IN := ${DATA}data-in
OUT := ${DATA}data-out
TEI := ${OUT}/tei
TEIANA := ${OUT}/tei-ana
BRAT := ${OUT}/brat
TEIANABRAT := ${OUT}/tei-ana-brat
UDPIPE := ${OUT}/udpipe
NAMETAG := ${OUT}/nametag
TEITOK := ${OUT}/teitok
TEITOKBRAT := ${OUT}/teitok-brat
TEITOKANNOTATIONS := ${OUT}/teitok-annotations

CONLLU := ${OUT}/conllu
TXTMETA := ${OUT}/txt-meta
FL := ${OUT}/tei.fl
SAXON := $(shell sh -c 'test `hostname` = "parczech" && echo -n "java -cp /opt/tools/shared/saxon/saxon-he-10.1.jar" || echo -n "java -cp /opt/saxon/SaxonHE10-1J/saxon-he-10.1.jar"')

SUBCORPUS =


all: convert2tei create_corpus_splitted udpipe nametag split_corpus convert2teitok


convert2tei: clean
	mkdir -p $(TEI)
	perl convert/iRozhlas2tei.pl --out-dir "$(TEI)" --debug $(IN)/all-*.json
	#find "$(TEI)" -type f -name "doc*.xml" -printf '%P\n' > $(FL)

convert2tei_sample: clean
	mkdir -p $(TEI)
	perl convert/iRozhlas2tei.pl --out-dir "$(TEI)" --debug $(IN)/all-76.json

create_corpus:
	echo '<?xml version="1.0" encoding="utf-8"?>' > $(TEI)/corpus.xml
	echo '<teiCorpus>' >> $(TEI)/corpus.xml
	cat $(FL) | sed 's@^@cat $(TEI)/@;s@$$@|sed "/^<\?xml /d"@' | sh >> $(TEI)/corpus.xml
	echo '</teiCorpus>' >> $(TEI)/corpus.xml
	echo 'corpus.xml' > $(FL)


create_corpus_splitted:
	rm -f $(FL)
	c=0 ; \
	i=0 ;	\
	for file in `find ${TEI} -name "doc-*"` ; \
	do \
	  test $$i -eq 0 &&  echo -n "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<teiCorpus>\n" > $(TEI)/corpus-$$c.xml && echo corpus-$$c.xml >> $(FL) ; \
	  sed '1d' $${file} >> $(TEI)/corpus-$$c.xml ; \
	  : $$((i=i+1)) ; \
	  test $$i -ge 50 && echo '</teiCorpus>' >> "$(TEI)/corpus-$$c.xml" && : $$((c=c+1)) && : $$((i=0)) ; \
	done ; \
	test $$i -gt 0 && echo '</teiCorpus>' >> $(TEI)/corpus-$$c.xml || echo

udpipe: lib udpipe2
	mkdir -p $(UDPIPE)
	perl -I lib udpipe2/udpipe2.pl --colon2underscore \
	                             --model=czech-pdt-ud-2.6-200830 \
	                             --elements "head,p,cell,li" \
	                             --debug \
	                             --use-xpos \
	                             --try2continue-on-error \
	                             --sub-elements "ref,hi" \
	                             --filelist $(FL) \
	                             --input-dir $(TEI) \
	                             --output-dir $(UDPIPE)

nametag: lib nametag2
	mkdir -p $(NAMETAG)
	perl -I lib nametag2/nametag2.pl --conll2003 \
                                 --varied-tei-elements \
                                 --model=czech-cnec2.0-200831 \
                                 --filelist $(FL) \
                                 --input-dir $(UDPIPE) \
                                 --output-dir $(NAMETAG)

split_corpus:
	mkdir -p $(TEIANA)
	for FILE in $(shell cat $(FL) ) ; do echo "splitting: $${FILE}" ; perl convert/splitCorpus.pl --in "$(NAMETAG)/$${FILE}" --out "$(TEIANA)"; done

convert2teitok:
	mkdir -p $(TEITOK)
	for FILE in $(shell cat $(FL) ) ; do echo "converting: $${FILE}" ; perl convert/tei2teitok.pl --split-corpus --in "$(NAMETAG)/$${FILE}" --out "$(TEITOK)"; done

convert2conllu:
	mkdir -p $(CONLLU)
	for FILE in $(shell ls $(TEIANA) ) ; \
	  do \
	    $(SAXON) net.sf.saxon.Transform -t -s:"$(TEIANA)/$${FILE}" -xsl:"convert/tei2conllu.xsl" -o:"$(CONLLU)/$${FILE}.conllu"; \
	  done

convert2txt-meta:
	echo "TODO: test output !!!"
	mkdir -p $(TXTMETA)
	for FILE in $(shell ls $(TEIANA) ) ; \
	  do \
	    $(SAXON) net.sf.saxon.Transform -t -s:"$(TEIANA)/$${FILE}" -xsl:"convert/tei2txt.xsl" -o:"$(TXTMETA)/$${FILE}.txt"; \
	  done


annotate-brat:
	mkdir -p $(TEIANABRAT)
	for FILE in $(shell cat $(FL)$(SUBCORPUS) ) ; do \
	  echo "converting: $${FILE}" ; \
	  perl convert/annotate-brat.pl --in "$(TEIANA)/$${FILE}" \
	                                --ana "$(BRAT)/$${FILE}.ann" \
	                                --txt "$(BRAT)/$${FILE}.txt" \
	                                --out "$(TEIANABRAT)/$${FILE}" \
	                                --subcorpus "$(SUBCORPUS)"; \
	done

convert2teitok-brat:
	mkdir -p $(TEITOKBRAT)
	echo "==================== TODO: implement brat annotation in teitok conversion"
	for FILE in $(shell cat $(FL)* ) ; \
	  do echo "converting: $${FILE}" ; \
	  perl convert/tei2teitok.pl --in "$(TEIANABRAT)/$${FILE}" \
	                             --out "$(TEITOKBRAT)/$${FILE}" \
	                             --ana-to-attribute-value "#single=aquality=x #double_unified=aquality=xx #triple_unified_curated=aquality=xxx" \
	                             --stand-off-type "ATTRIBUTION" \
	                             --stand-off-val-patch '^(.*(?:official|anonymous).*)$$/SOURCE:$$1' \
	                             --stand-off-remove '^.*\d+$$' \
	                             --stand-off-pref "attrib"; \
	  done


################# DEVEL:


DEV-sync-sir-with-teitok:
	rm -f $(TEITOKANNOTATIONS)/*
	mkdir -p $(TEITOKANNOTATIONS)
	ls $(TEITOKBRAT) | xargs -I {} ln -s ../xmlfiles/{} $(TEITOKANNOTATIONS)/attrib_{}
	rsync -avz --recursive $(TEITOKANNOTATIONS)/* parczech@parczech:/var/www/html/teitok/sir/Annotations/
	rsync -avz  teitok-project/Annotations/attrib_def.xml parczech@parczech:/var/www/html/teitok/sir/Annotations/attrib_def.xml
	rsync -avz --recursive $(TEITOKBRAT)/* parczech@parczech:/var/www/html/teitok/sir/xmlfiles/
	rsync -avz --recursive teitok-project/Sources parczech@parczech:/var/www/html/teitok/sir/
	rsync -avz --recursive teitok-project/Scripts parczech@parczech:/var/www/html/teitok/sir/


DEV-brat-prepare: clean
	mkdir -p $(BRAT) $(TEIANA)
	rsync -av signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/manual/triple_unified_curated/ $(BRAT)
	rsync -av signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/double_unified/ $(BRAT)
	rsync -av signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/single/ $(BRAT)
	echo "adding single file !!!"
	ls signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/manual/triple_unified_curated/|sed 's/\.[a-z]*$$//'|sort|uniq > "$(FL)triple_unified_curated"
	ls signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/double_unified/|sed 's/\.[a-z]*$$//'|sort|uniq > "$(FL)double_unified"
	ls signal_a_sum/data/iRozhlas_and_Verifee/2022_07_data_final/single/|sed 's/\.[a-z]*$$//'|sort|uniq > "$(FL)single"
	rsync -av data-out-annotated-sample-20220611/data-out/tei-ana/ $(TEIANA)
	find $(OUT)

DEV-annotate-brat:
	make annotate-brat SUBCORPUS=triple_unified_curated
	make annotate-brat SUBCORPUS=double_unified
	make annotate-brat SUBCORPUS=single


convert2tei-sample: clean
	mkdir -p $(TEI)
	perl convert/iRozhlas2tei.pl --out-dir "$(TEI)" --debug small-sample.json

create_corpus_udpipe_test:  # all-0.json issue https://github.com/ufal/ParCzech/issues/151
	echo '<?xml version="1.0" encoding="utf-8"?>' > $(TEI)/corpus.xml
	echo '<teiCorpus>' >> $(TEI)/corpus.xml
	cat $(TEI)/doc-7408091.xml |sed '/^<?xml version/d'  >> $(TEI)/corpus.xml
	echo '</teiCorpus>' >> $(TEI)/corpus.xml
	echo 'corpus.xml' > $(FL)


issue-13-patch:
	sed -i 's/&#13;/ /g;s/ +/ /g' $(TEI)/corpus-1010.xml

issue-13: clean
	mkdir -p $(TEI)
	cp -r test-data/issue-13/tei "$(OUT)"
	#make issue-13-patch
	ls  "$(TEI)" > $(FL)
	#echo  "corpus-1010.xml" > $(FL)
	#echo  "doc-5995242.xml" > $(FL)
	cat $(FL)
	make udpipe
	#xmllint --noout $(UDPIPE)/corpus-*.xml

issue-20:
	rm -rf data-out-test
	mkdir -p data-out-test
	perl convert/iRozhlas2tei.pl --out-dir "data-out-test" --debug data-in-test/issue20.json
	cat data-out-test/doc-6675116.xml|grep -v '<' || :
	cat data-out-test/doc-6675116.xml|grep 'pic.twitter.' || :


TODO-prepare:
	perl convert/iRozhlas2tei.pl --out-dir "$(TEI)" --debug $(IN)/all-15.json
TODO:
	echo 'doc-8285292.xml' > $(FL)
	make udpipe



##################
prereq: udpipe2 nametag2 lib

udpipe2:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/udpipe2
nametag2:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/nametag2
lib:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/lib


clean:
	rm -rf $(OUT)