SAM/BAM and related file format specifications
==============================================

Alignment data files
--------------------

**SAMv1.tex** is the canonical specification for the SAM (Sequence Alignment/Map) format, BAM (its binary equivalent), and the BAI format for indexing BAM files.

The CRAM format is described at [ENA's CRAM toolkit page][ena-cram].

The **tabix.tex** and **CSIv1.tex** quick references summarize more recent index formats: the [tabix] tool indexes generic textual genome position-sorted files, while CSI is [htslib]'s successor to the BAI index format.

Variant calling data files
--------------------------

The Variant Call Format and its textual and binary encodings are described on the [1000 Genomes wiki][g1k-vcf].

**BCFv1_qref.tex** summarizes the obsolete BCF1 format historically produced by [samtools].  This format is no longer recommended for use, as it has been superseded by the more widely-implemented BCF2.

**BCFv2.tex** is an in-progress non-canonical incomplete TeX conversion of the official [BCF2 specification][g1k-bcf2].  **BCFv2_qref.tex** is a quick reference describing just the layout of data within BCF2 files.

[ena-cram]:	http://www.ebi.ac.uk/ena/about/cram_toolkit
[g1k-bcf2]:	http://www.1000genomes.org/wiki/analysis/variant-call-format/bcf-binary-vcf-version-2
[g1k-vcf]:	http://www.1000genomes.org/wiki/Analysis/variant-call-format
[htslib]:	/samtools/htslib/
[samtools]:	/samtools/samtools/
[tabix]:	/samtools/tabix/

<!-- vim:set linebreak: -->
