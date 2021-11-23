DATA := $(shell sh -c 'test `hostname` = "parczech" && echo -n "/opt/irozhlas/data/"')
IN := ${DATA}data-in
OUT := ${DATA}data-out
TEI := ${OUT}/tei
TEIANA := ${OUT}/tei-ana
UDPIPE := ${OUT}/udpipe
NAMETAG := ${OUT}/nametag
TEITOK := ${OUT}/teitok
FL := ${OUT}/tei.fl

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




#################
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

TODO-prepare:
	perl convert/iRozhlas2tei.pl --out-dir "$(TEI)" --debug $(IN)/all-15.json
TODO:
	echo 'doc-8285292.xml' > $(FL)
	make udpipe

prereq: udpipe2 nametag2 lib

udpipe2:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/udpipe2
nametag2:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/nametag2
lib:
	svn checkout https://github.com/ufal/ParCzech/trunk/src/lib


clean:
	rm -rf $(OUT)