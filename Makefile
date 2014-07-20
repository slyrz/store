PREFIX?=/usr
OCAMLC?=ocamlc
OCAMLMKLIB?=ocamlmklib

PACKAGES=freetype2 libavformat libavutil

CFLAGS=`pkg-config --cflags ${PACKAGES} | sed "s/\-I/\-I /g"`
LDFLAGS=`pkg-config --libs ${PACKAGES}`

all: store

store: meta.cmo main.cmo meta.so
	$(OCAMLC) -o $@ unix.cma str.cma meta.cmo main.cmo -dllib ./meta.so

%.cmo: %.ml
	$(OCAMLC) -c unix.cma str.cma $<

%.o: %.c
	$(OCAMLC) $(CFLAGS) -c $<

%.so: %.o
	$(OCAMLMKLIB) $(LDFLAGS) -o $(<:.o=) $<; mv dll$@ $@

install: store
	install -d "${DESTDIR}${PREFIX}/bin"
	install -t "${DESTDIR}${PREFIX}/bin" $<

clean:
	rm -rf *.so *.o *.a *.cmo *.cmi *.cma
	rm -rf store
