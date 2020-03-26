# Opentope: An open-source pipeline to discover universal epitopes for vaccines.
# Developed during the CEND Covid-19 Hackathon, 25-26 March 2020.

configfile: "config.yaml"

rule all:
    input:
        "data/alignments/coronaviruses.aln"

# Read RefSeq ftp links from config
def get_ftp(wildcards):
    for item in config["genomes"].values():
        if item["filename"].split(".f", 1)[0] == wildcards.ref:
            return item["ftp"]
    raise Exception("No ftp link in config found for {}".format(gzipped_filename))

# If genome is not present, download with wget and redirect to data/genomes/
rule download_genome:
    output:
        "data/genomes/{ref}.fna.gz"
    params:
        ftp=get_ftp
    shell:
        "wget {params.ftp} -O {output}"

# Unzip with pigz
rule unzip_genome:
    input:
        "data/genomes/{ref}.fna.gz"
    output:
        "data/genomes/{ref}.fna"
    shell:
        "unpigz {input}"

# Return list of unzipped genome files
def get_genomes(wildcards):
    l = []
    for item in config["genomes"].values():
        # Get base filename, prepend "data/genomes"
        # Strip .gz if present so we don't care whether user typed .gz or not
        l.append("data/genomes/" + item["filename"].split(".gz", 1)[0])
    return l

# Align all genomes with Clustal Omega (concatenate to standard in)
rule clustal:
    input:
        get_genomes
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
