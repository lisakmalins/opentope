# Opentope: An open-source pipeline to discover universal epitopes for vaccines.
# Developed during the CEND Covid-19 Hackathon, 25-26 March 2020.
import glob

configfile: "config.yaml"

rule all:
    input:
        "data/alignments/coronaviruses.aln"

# Read accession from config
def get_accession(wildcards):
    try:
        for item in config["genomes"].values():
            if item["filename"].split(".f", 1)[0] == wildcards.ref:
                return item["refseq-accession"]
        raise KeyError

    except KeyError:
        # Return if file exists
        if glob.glob("data/genomes/" + wildcards.ref + "*"):
            return
        else:
            raise Exception("No accession in config found for {}".format(wildcards.ref + ".fna"))

# If genome is not present,
# 1) read accession from config
# 2) get FTP link via Entrez Direct
# 3) download via wget
# 4) save to data/genomes/ under user's desired filename
rule download_genome:
    output:
        "data/genomes/{ref}.fna.gz"
    params:
        acc=get_accession
    shell: """
        wget `esearch -db assembly -query "{params.acc} [ASAC]" | \
        efetch -format docsum | \
        xtract -pattern DocumentSummary -element FtpPath_RefSeq | \
        awk -F"/" '{{print $0"/"$NF"_genomic.fna.gz"}}'` \
        -O {output}
        """

# Unzip with pigz
rule unzip_genome:
    input:
        "data/genomes/{ref}.fna.gz"
    output:
        "data/genomes/{ref}.fna"
    shell:
        "unpigz {input}"

# Return genome base names
def get_genomes():
    l = []
    for item in config["genomes"].values():
        # Get base filename, strip file extensions (.fa, .fna, .fasta, all supported)
        l.append(item["filename"].split(".f", 1)[0])
    return l

# Align all genomes with Clustal Omega (concatenate to standard in)
rule clustal:
    input:
        expand("data/genomes/{ref}.fna", ref=get_genomes())
    output:
        alignment="data/alignments/coronaviruses.aln"
    params:
        options=config["clustal"]["options"],
        guidetree="data/alignments/coronaviruses.dnd" # Kludge to not crash snakemake if guide tree not written
    shell: """
    cat {input} | \
    clustalo --seqtype=DNA --force {params.options} \
    --in=- --guidetree-out={params.guidetree} --out={output.alignment}
    """
