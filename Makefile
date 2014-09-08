PREFIX?=/usr
OCAMLC?=ocamlopt
OCAMLMKLIB?=ocamlmklib

VERBOSE=-verbose

SOURCES=meta.ml main.ml
MODULES=unix.cmxa str.cmxa
PACKAGES=freetype2 libavformat libavutil

CFLAGS=`pkg-config --cflags ${PACKAGES}`
LDFLAGS=`pkg-config --libs ${PACKAGES}`

all: store

store: libmeta.a
	$(OCAMLC) $(VERBOSE) -o $@ $(MODULES) $(SOURCES) -ccopt "-L." -cclib "$(LDFLAGS) -lmeta"

%.o: %.c
	$(OCAMLC) $(VERBOSE) -ccopt "$(CFLAGS) -fPIC" -c $<

lib%.a: %.o
	$(OCAMLMKLIB) $(VERBOSE) -o $(<:.o=) $<

install: store
	install -d "${DESTDIR}${PREFIX}/bin"
	install -t "${DESTDIR}${PREFIX}/bin" $<

clean:
	rm -rf *.so *.o *.a *.cmi *.cmx
	rm -rf store
