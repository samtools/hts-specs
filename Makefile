all: pdf

PDFS =	BCFv1_qref.pdf \
	BCFv2_qref.pdf \
	CRAMv2.1.pdf \
	CSIv1.pdf \
	SAMv1.pdf \
	tabix.pdf \
	VCFv4.1.pdf \
	VCFv4.2.pdf

pdf: $(PDFS)

CRAMv2.1.pdf: CRAMv2.1.tex CRAMv2.1.ver
SAMv1.pdf: SAMv1.tex SAMv1.ver
VCFv4.1.pdf: VCFv4.1.tex VCFv4.1.ver
VCFv4.2.pdf: VCFv4.2.tex VCFv4.2.ver


.SUFFIXES: .tex .pdf .ver
.tex.pdf:
	pdflatex $<
	while grep -q 'Rerun to get [a-z-]* right' $*.log; do pdflatex $< || exit; done

.tex.ver:
	echo "@newcommand*@commitdesc{`git describe --always --dirty`}@newcommand*@headdate{`git rev-list -n1 --format=%aD HEAD $< | sed '1d;s/.*, *//;s/ *[0-9]*:.*//'`}" | tr @ \\ > $@


mostlyclean:
	-rm -f *.aux *.idx *.log *.out *.toc *.ver

clean: mostlyclean
	-rm -f $(PDFS)


.PHONY: all pdf mostlyclean clean
