# VCF examples

This page describes some example VCF files as quick introduction to the format.

## [simple.vcf](simple.vcf)


This example shows (in order): a good simple SNP, a possible SNP that has been
filtered out because its quality is below 10, a site at which two alternate
alleles are called, with one of them (T) being ancestral (possibly a reference
sequencing error), a site that is called monomorphic reference (i.e. with no
alternate alleles), and a microsatellite with two alternative alleles, one a
deletion of 2 bases (TC), and the other an insertion of one base (T). Genotype
data are given for three samples, two of which are phased and the third
unphased, with per sample genotype quality, depth and haplotype qualities (the
latter only for the phased samples) given as well as the genotypes. The
microsatellite calls are unphased.

