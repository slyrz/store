PREFIX?=/usr
OCAMLC?=ocamlc
OCAMLMKLIB?=ocamlmklib

BINDCC=`pkg-config --cflags freetype2 libavformat libavutil | sed "s/\-I/\-I /g"`
BINDLD=`pkg-config --libs freetype2 libavformat libavutil`

all: store

store: meta.cmo main.cmo meta.so
	$(OCAMLC) -o $@ unix.cma str.cma meta.cmo main.cmo -dllib ./meta.so

%.cmo: %.ml
	$(OCAMLC) -c unix.cma str.cma $<

%.o: %.c
	$(OCAMLC) $(BINDCC) -c $<

%.so: %.o
	$(OCAMLMKLIB) $(BINDLD) -o $(<:.o=) $<; mv dll$@ $@

install: store
	install -d "${DESTDIR}${PREFIX}/bin"
	install -t "${DESTDIR}${PREFIX}/bin" $<

clean:
	rm -rf *.so *.o *.a *.cmo *.cmi *.cma
	rm -rf store
