LSLINT?=`pwd`/lslint/lslint -b `pwd`/lslint/builtins.txt 

SRC=$(wildcard src/*)
LIB=$(wildcard lib/*)
DBG=$(subst .lsl,.j,$(subst src,dbg,$(SRC))) $(subst .lsl,.i,$(subst src,dbg,$(SRC)))
OBJ=$(subst .lsl,.o,$(subst src,bin,$(SRC)))
HTML=$(subst .txt,.html,$(wildcard doc/*.txt))

FLAGS= -DDEBUG
#FLAGS=

all: prereqs $(DBG) $(OBJ) $(HTML) fini

fini:
	@echo ===
	@echo === compiled files are in bin
	@echo ===

txt2html:
	@if which txt2html; then echo txt2html found, good; else echo txt2html not found, please \'sudo apt-get install txt2html\'; exit -1; fi

lslint:
	@if [ ! -d lslint ]; then \
		echo ===; \
		echo === LSLINT NOT FOUND, attempting to fetch and build it; \
		echo ===; \
		git clone https://github.com/pclewis/lslint.git; \
		( cd lslint ; make ); \
		echo; \
		echo; \
	fi

prereqs: txt2html lslint

docs: $(HTML)
	cp doc/*.html ~/public_html

distro: clean
	rm -rf open9
	mkdir open9
	mkdir open9/dbg
	mkdir open9/bin
	mkdir open9/web
	mkdir open9/web/birth
	mkdir open9/web/gates
	mkdir open9/web/grave
	cp -a Makefile open9
	cp -a src open9
	cp -a lib open9
	cp -a doc open9
	cp -a tools open9
	cp web/*.pl web/*.cgi web/*.sh web/Makefile open9/web
	tar -czvf open9.tar.gz open9
	rm -rf open9
	cp open9.tar.gz ~/public_html
	cp open9.tar.gz ~/public_html/open9.`date +"%Y.%m.%d.%H.%M.%S"`.tar.gz

seeds:
	wget -O - "http://ma8p.com/~opengate/xml.cgi?sort=BORN" | \
	grep OBJECT_KEY | \
	sed "s/[^-a-f0-9]//g" | \
	head -150 > seeds

deps: $(SRC) $(LIB)
	@rm -f deps
	@touch deps
	@makedepend -fdeps -Ilib src/*
	@cat deps | sed "s/^src/bin/g" > deps2
	@cat deps | sed "s/^src/dbg/g" | sed "s/\.o/.i/g" >> deps2
	@mv deps2 deps
	@rm deps.bak

importer: all
	@rm -rf import
	@mkdir import
	@mkdir import/import_assets
	@tools/import.pl > import/import.xml
	@rm -rf /tmp/importer
	@cp -a import /tmp/importer

debug: $(DBG)

graph:
	(cd web; ./reap.pl; make)

clean:
	rm -f seeds dbg/* bin/* deps deps.bak doc/*.html

dbg/%.i: src/%.lsl
	@echo
	@echo "COMPILING $<"
	@echo -n "//" > $@
	@/lib/cpp -Ilib -P $(FLAGS) $< | md5sum >> $@
	@/lib/cpp -Ilib -P $(FLAGS) -DTIME=`date +0x%H%M%S` -DDATE=`date +0x%Y%m%d` $< >> $@

dbg/%.j: dbg/%.i
	@/lib/cpp -Ilib -P $(FLAGS) -Dvoid= $< > $@
	@-$(LSLINT) $@ |& egrep -v "Unused event parameter .unused"

bin/%.o: dbg/%.i
	@cat $< | tools/i2o.pl `basename $<` > $@

%.html: %.txt
	@echo PROCESSING $<
	@echo "<html>" > $@
	@echo "<body text=white bgcolor=black link=cyan vlink=magenta alink=red>" >> $@
	@echo "<font face=\"sans-serif\">" >> $@
	@txt2html \
		-pm \
		--tables \
		< $< | sed "s/[(]R[)]/\&#174;/g" | sed "s/[(]TM[)]/\&trade;/g" >> $@
	@echo "</font></body></html>" >> $@ 
	@chmod ugo+rx $@

dbg/phys_anglia-ui.i: lib/phys-ui.lsl
dbg/phys_destiny-ui.i: lib/phys-ui.lsl
dbg/phys_eleven-ui.i: lib/phys-ui.lsl
dbg/phys_generic-ui.i: lib/phys-ui.lsl
dbg/phys_oneprim-ui.i: lib/phys-ui.lsl
dbg/phys_simple-ui.i: lib/phys-ui.lsl
dbg/phys_super-ui.i: lib/phys-ui.lsl
dbg/phys_warp-ui.i: lib/phys-ui.lsl

-include deps
