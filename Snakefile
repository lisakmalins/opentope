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


# Optional feature: write sed script to alter genome fasta headers on the fly.
# Makes Clustal output more human-readable by appending nicknames to nucleotide accessions.
rule sed_expressions:
    input:
        expand("data/genomes/{ref}.fna", ref=get_genomes())
    output:
        "data/genomes/sedscript.txt"
    run:
        substitutions = {}

        try:
            for item in config["genomes"].values():
                with open("data/genomes/" + item["filename"], 'r') as f:
                    # Read header from genome fasta
                    header = f.readline()
                    id = header.split(" ", 1)[0]
                    # Read nickname from config
                    nickname = item["nickname"]
                    newid = id + "__" + nickname
                    # Save id and annotated id in dictionary
                    substitutions[id] = newid

            # Write all substitutions as sed script
            with open(output[0], 'w') as sedscript:
                for id, newid in substitutions.items():
                    sedscript.write("s/{}/{}/\n".format(id, newid))

        # If anything goes wrong, write empty file.
        # Headers will not be edited & snakemake will not crash.
        except:
            with open(output[0], 'w') as sedscript:
                sedscript.write("# This comment indicates that a sed script could not be written. Fasta headers will not be edited.\n")

# Align all genomes with Clustal Omega (concatenate to standard in)
rule clustal:
    input:
        genomes=expand("data/genomes/{ref}.fna", ref=get_genomes()),
        sedscript="data/genomes/sedscript.txt"
    output:
        alignment="data/alignments/coronaviruses.aln"
    params:
        options=config["clustal"]["options"],
        guidetree="data/alignments/coronaviruses.dnd" # Kludge to not crash snakemake if guide tree not written
    shell: """
    cat {input.genomes} | \
    sed -f {input.sedscript} | \
    clustalo --seqtype=DNA --force {params.options} \
    --in=- --guidetree-out={params.guidetree} --out={output.alignment}
    """
