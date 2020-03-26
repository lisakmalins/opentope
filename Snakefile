# Opentope: An open-source pipeline to discover universal epitopes for vaccines.
# Developed during the CEND Covid-19 Hackathon, 25-26 March 2020.

configfile: "config.yaml"

rule all:
    input:
        "coronaviruses_alignment.aln"

# Read ftp links from config
def get_ftp(wildcards):
    for item in config["genomes"].values():
        if item["filename"].split(".f", 1)[0] == wildcards.ref:
            return item["ftp"]
    raise Exception("No ftp link in config found for {}".format(gzipped_filename))

rule download_genome:
    output:
        "{ref}.fna.gz"
    params:
        ftp=get_ftp
    shell:
        "wget {params.ftp}"

rule unzip_genome:
    input:
        "{ref}.fna.gz"
    output:
        "{ref}.fna"
    shell:
        "unpigz {input}"

# Return list of genome files
# Strip .gz if present so we don't care whether user typed .gz or not
def get_genomes(wildcards):
    l = []
    for item in config["genomes"].values():
        # print("heres an item")
        # print(item)
        l.append(item["filename"].split(".gz", 1)[0])
    return l

# Align all genomes with Clustal Omega (concatenate to standard in)
rule clustal:
    input:
        get_genomes
    output:
        alignment="coronaviruses_alignment.aln"
    params:
        options=config["clustal"]["options"],
        guidetree="coronaviruses.dnd" # Kludge to not crash snakemake if guide tree not written
    shell: """
    cat {input} | \
    clustalo --seqtype=DNA --force {params.options} \
    --in=- --guidetree-out={params.guidetree} --out={output.alignment}
    """
