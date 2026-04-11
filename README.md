# VAVIA *early dev-WIP*
## **V**iral **A**ntigen and **V**ariant calling **I**nformation **A**ggregator

A nextflow based workflow combining a number of tools run from paired-end sequencing reads all the
way to Haplotypes, Variant calls and Antigen prediction.

Standard configuration options (WIP)
-denovo (no reference guiding, uses raw reads and as such does not perform typical variant calling. Instead, uses de-novo MEGAHIT and de-novo SAVAGE alignment to attempt antigen prediction and haplotype reconstruction).
-ref (reference guided includes normal variant calling producer and attempts to generate viral haplotypes and antigen sequences)

Currently being developed on the basis of HPV analysis in Norwegian cervical cancer sequences --- to expand to hopefully include other viruses. 

Current input:
Some form of sample_id metadata in the reads:
reads = (a file following the pattern: {SAMPLEID}_{1/2}.fastq
RunConfig.yaml (exact name) can be made manually or taken from github repo and modified. MUST CONTAIN THE REQUIRED INPUTS
