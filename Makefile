all: pdf

PDFS =	BCFv1_qref.pdf \
	BCFv2_qref.pdf \
	$(if $(CIRCLECI),,BEDv1.pdf) \
	CRAMv2.1.pdf \
	CRAMv3.pdf \
	crypt4gh.pdf \
	CRAMcodecs.pdf \
	CSIv1.pdf \
	SAMv1.pdf \
	SAMtags.pdf \
	tabix.pdf \
	VCFv4.1.pdf \
	VCFv4.2.pdf \
	VCFv4.3.pdf \
	VCFv4.4.pdf \
	VCFv4.5.pdf

pdf: $(PDFS:%=new/%)

%.pdf: new/%.pdf
	cp $^ $@

new/BEDv1.pdf       diff/BEDv1.pdf:       BEDv1.tex       new/BEDv1.ver
new/CRAMv2.1.pdf    diff/CRAMv2.1.pdf:    CRAMv2.1.tex    new/CRAMv2.1.ver
new/CRAMv3.pdf      diff/CRAMv3.pdf:      CRAMv3.tex      new/CRAMv3.ver
new/crypt4gh.pdf   diff/crypt4gh.pdf:   crypt4gh.tex   new/crypt4gh.ver
new/SAMv1.pdf      diff/SAMv1.pdf:      SAMv1.tex      new/SAMv1.ver
new/SAMtags.pdf    diff/SAMtags.pdf:    SAMtags.tex    new/SAMtags.ver
new/VCFv4.1.pdf    diff/VCFv4.1.pdf:    VCFv4.1.tex    new/VCFv4.1.ver
new/VCFv4.2.pdf    diff/VCFv4.2.pdf:    VCFv4.2.tex    new/VCFv4.2.ver
new/VCFv4.3.pdf    diff/VCFv4.3.pdf:    VCFv4.3.tex    new/VCFv4.3.ver
new/VCFv4.4.pdf    diff/VCFv4.4.pdf:    VCFv4.4.tex    new/VCFv4.4.ver
new/VCFv4.5.pdf    diff/VCFv4.5.pdf:    VCFv4.5.tex    new/VCFv4.5.ver
new/CRAMcodecs.pdf diff/CRAMcodecs.pdf: CRAMcodecs.tex new/CRAMcodecs.ver

# Set LATEXMK to "scripts/rerun.sh new/$* $(PDFLATEX)" to use the previous
# controller script, e.g., if your installation does not have latexmk.
PDFLATEX = pdflatex
LATEXMK  = latexmk $(LATEXMK_ENGINE) $(LATEXMK_FLAGS)
LATEXMK_ENGINE = --pdf --pdflatex='$(PDFLATEX)'
LATEXMK_FLAGS  =

LATEXDIFF_ENGINE = --config LATEX=pdflatex

new/%.pdf: %.tex | new
	$(LATEXMK) --output-directory=new $<

new/BEDv1.pdf: LATEXMK_ENGINE = --lualatex

new/CRAMv2.1.ver new/CRAMv3.ver: img/CRAMFileFormat2-1-fig001.png img/CRAMFileFormat2-1-fig002.png img/CRAMFileFormat2-1-fig003.png img/CRAMFileFormat2-1-fig004.png img/CRAMFileFormat2-1-fig005.png img/CRAMFileFormat2-1-fig006.png img/CRAMFileFormat2-1-fig007.png

new/VCFv4.1.ver new/VCFv4.2.ver new/VCFv4.3.ver new/VCFv4.4.ver: img/all_orientations-400x296.png img/derivation-400x267.png img/erosion-400x211.png img/inserted_contig-400x247.png img/inserted_sequence-400x189.png img/inversion-400x95.png img/microhomology-400x248.png img/multiple_mates-400x280.png img/phasing-400x259.png img/reciprocal_rearrangement-400x192.png img/telomere-400x251.png
new/CRAMcodecs.ver: img/range_code.png

new/%.ver: %.tex | new
	scripts/genversion.sh $^ > $@

new:
	mkdir new


diff diffs: $(PDFS:%=diff/%)

OLD = HEAD
NEW =

diff/%.pdf: %.tex
	BIBINPUTS=:.. TEXINPUTS=:..:../new latexdiff-vc $(LATEXDIFF_ENGINE) --pdf --dir diff --force --git --only-changes --graphics-markup=none --ignore-warnings --revision $(OLD) $(if $(NEW),--revision $(NEW)) $<

diff/BEDv1.pdf: LATEXDIFF_ENGINE = --config LATEX=lualatex


show-styles:
	@sed -n '/\\usepackage/s/.*{\(.*\)}$$/\1/p' *.tex | sort | uniq -c


mostlyclean:
	-rm -f new/*.aux new/*.bbl new/*.blg new/*.fdb_latexmk new/*.fls new/*.log new/*.out new/*.toc new/*.ver
	-rm -f diff/**.aux diff/*.blg diff/*.idx diff/*.log diff/*.out diff/*.tex diff/*.toc

clean: mostlyclean
	-rm -f $(PDFS:%=new/%)$(if $(wildcard new),; rmdir new)
	-rm -f $(PDFS:%=diff/%)$(if $(wildcard diff),; rmdir diff)
	-rm -rf .jekyll-cache .jekyll-metadata _site


# Checking of MM tag perl script
check test:
	cd test/SAMtags; \
	for i in `echo *.sam | sed 's/\.sam//g'`; \
	do \
	    ./parse_mm.pl $$i.sam > _; \
	    cmp _ $$i.txt; \
	done; \
	rm _

.PHONY: all pdf diff diffs show-styles mostlyclean clean
