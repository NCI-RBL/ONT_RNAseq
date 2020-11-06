# Oxford Nanopore Technologies (ONT) based RNA sequencing

## Background

### ONT Basics

* Measures current not light
* Can distinguish modified bases
* mostly no PCR required
* no GC or low complexity based biases
* 50x fewer reads and 7x fewer bases need to be sequenced than Illumina short reads in order to get the same amount of information

|                             ONT                              |                           Illumina                           |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| Uniform coverage, <br />fuzzy exome boundaries (can be fixed with parallel Illumina transcriptome data), <br />accurate known/novel isoform quantification | GC and PCR biases make it harder for accurate isoform quantification |

* Different instruments from ONT

| Instrument | Throughput |
| :--------: | :--------: |
|  Flongle   |   1.8Gb    |
|   MinION   |    30Gb    |
|  GridION   |   150Gb    |
| PromethION |   8.6Tb    |

* Each flowcell has 512 wells
* Reads are saved as FAST5 files

#### FAST5

The fast5 format contains the raw electrical signal levels measured by the nanopores, from which various information can be extracted. It is essentially similar to HDF5 file and tools like `h5ls` and `h5dump` can be used directly to export FAST5 files. These FAST5 files have 3 main branches of data stored in the fast5, `Analysis`, `Raw`, and `UniqueGlobalKey`. `Raw` stores the raw signal levels, `Analysis` stores analysis results such as base-calls, signal correction and segmentation information. Some basecallers can have input and output in FAST5 format, i.e., append bases to the same HDF5 hierarchy. 

Thousands of FAST5 files can be batched up together into a single *multifast5* file. This format contains the same information but uses less disk space, and is expected to be compatible with future nanopore tools.

Both, *fast5* and *multifast5*, can be validated using `ont_h5_validator` found [here](https://github.com/nanoporetech/ont_h5_validator)

More information about FAST5 files can be found [here](https://medium.com/@shiansu/a-look-at-the-nanopore-fast5-format-f711999e2ff6)

#### Basecalling

ONT provides two main basecallers. There are other ONT and third-party basecallers, but as a general rule of thumb (and as per SF recommendation), guppy is preferred due to its reliable accuracy. Basecallers for ONT raw data mostly use neural networks and can give different results as the algorithms improve/change. This is another reason, why many ONT pipelines start with FAST5 files and not FASTQs.

More details on ONT basecalling [here](https://doi.org/10.1186/s13059-019-1727-y)

##### Albacore

CPU based general-purpose ONT basecaller.

##### Guppy

GPU based basecaller with improved basecalling speed. CPU version of Guppy also exists. GPU version of Guppy (guppy/4.2.2) runs on the **p100, v100** and **v100x** GPU nodes on Biowulf. We have also created a [docker image](https://hub.docker.com/r/nciccbr/ccbr_guppy_cpu_v4.2.2) of Guppy's CPU version.

| GPU/CPU | nGPUs/nCPUs | QueueTime | RunTime |
| :-----: | :---------: | :-------: | :-----: |
|  p100   |    1/14     |   8:40    | 5:50:06 |
|  p100   |    2/14     |   5:01    | 5:38:54 |
|  v100x  |    1/14     |   23:20   | 1:33:19 |
|  v100x  |    2/14     |   7:39    | 1:49:10 |

For the same data, the singularity based CPU Guppy run:

| nCPUs | --num_callers | --cpu_threads_per_caller | QueueTime | RunTime  |
| :---: | :-----------: | :----------------------: | :-------: | :------: |
|  56   |       7       |            8             |   6:10    | 18:41:40 |
|  56   |      14       |            4             |   6:00    | 19:15:52 |
|  56   |      28       |            2             |   5:47    | 20:58:13 |
|  14   |  1(default)   |        4(default)        |   5:01    |   \>24   |
|  28   |  1(default)   |        4(default)        |   4:12    |   \>24   |

In general, I found that the CPU version was only ~3-12 slower than the GPU version.

### RNAseq on ONT

* ONT has 3 types of RNA sequencing:
	+ **Direct RNA** sequencing: no amplification, can capture base-modification
	+ **Direct cDNA** sequencing: no amplification, more reliable as cDNA is more stable than direct RNA (This pipeline is mostly going to be focused on this)
	+ **PCR cDNA** sequencing (similar to Illumina)
* very little starting material is required ... comparable to low-input RNAseq from Illumina

#### Analysis pipelines

1. <u>[Pipeline-transcriptome-de](https://github.com/nanoporetech/pipeline-transcriptome-de)</u>
	* for DGE and DTU
	* reads are mapped to transcriptome
2. [Pipeline-pinfish-analysis](https://github.com/nanoporetech/pipeline-pinfish-analysis)
	* generates GFF2 file from ONT reads + reference fasta
	* uses **minimap2** for alignment and **pinfish** for transcriptome data analysis 
3. [Pychopper](https://github.com/nanoporetech/pychopper)
	*  for cDNA only
	*  run before running pinfish pipeline
4. Other pipelines:
	*  [Nanoseq](https://github.com/nf-core/nanoseq) from nf-core 
	*  