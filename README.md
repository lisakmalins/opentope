# opentope

An open-source pipeline to discover universal epitopes for vaccines.

Developed during the [CEND](http://cend.globalhealth.berkeley.edu/) [Covid-19 Hackathon](https://www.cendcoronavirushackathon.com/), 25-26 March 2020.

## Usage

### STEP 1: Install miniconda and git
If you are using a work or lab server, ask your sysadmin if git and conda are installed already. If so, skip to STEP 2.

If you are running this repository locally, you may prefer to install [git](https://git-scm.com/downloads) and [miniconda](https://conda.io/en/latest/miniconda.html) from their websites. Then continue to STEP 2.

To __install miniconda__ from the command line:
```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

The installer will ask you some questions to complete installation. Review and accept the license, accept or change home location, and answer yes to placing it in your path.

To finish configuring miniconda:
```bash
source $HOME/.bashrc
```

To __install git__:
```bash
conda install git
```

### STEP 2: Clone the repository

In the terminal, navigate to your preferred location and __clone this repository__.

```bash
git clone https://github.com/lisakmalins/opentope.git
cd opentope
```

### STEP 3: Build and activate the conda environment
When you __build the conda environment__, Conda obtains all the software listed in `environment.yaml`.
```bash
# Recommended: prevent conda from crashing if home folder is not writable
conda config --add envs_dirs ./.conda/envs
conda config --add pkgs_dirs ./.conda/pkgs

# Build opentope conda environment
conda env create -f environment.yaml
```

Finally, you will need to __activate the environment__.
```bash
conda activate opentope
```

You only need to build the environment once. However, you'll need to activate the environment each time you log in. To deactivate the environment, use the command `conda deactivate`.

### STEP 4: Run test case
This repository includes an example config file for comparing coronavirus genomes.

To run the included test case:
```bash
snakemake
```

## Running with your own datasets
You may also alter the config file to run with other viral genomes.

Please place your reference genome assemblies in the `data/genome/` directory, then enter the info for each organism into `config.yaml`. (FTP links are not necessary if you already downloaded the genomes.)

Each organism must have an entry in the following format:
```yaml
genomes:
  organism1: # You can put whatever nickname you want here
    filename: "..." # Enter the name of the genome assembly file
  organism2:
    filename: "..."
  # And so on...
```
