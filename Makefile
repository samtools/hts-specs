all: pdf

PDFS =	BCFv1_qref.pdf \
	BCFv2.pdf BCFv2_qref.pdf \
	CSIv1.pdf \
	SAMv1.pdf \
	tabix.pdf

pdf: $(PDFS)

.SUFFIXES: .tex .pdf
.tex.pdf:
	pdflatex $<


mostlyclean:
	-rm -f *.aux *.idx *.log

clean: mostlyclean
	-rm -f $(PDFS)


.PHONY: all pdf mostlyclean clean
