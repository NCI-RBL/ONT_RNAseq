rule guppy:
    input:
        fast5path=samplesdf['path_to_fast5_parent_folder'][{sample}]
    output:
        outfastq=join(workdir,fastqs,"{sample}.fastq.gz")
	params:
		flowcell = config['flowcell'],
		kit = config['kit'],
		sample = {sample}
    envmodules: tools['guppy']['version']
	shell:"""
guppy_basecaller \
	--input_path {input.fast5path} \
    --recursive \
    --flowcell {params.flowcell} \
	--kit {params.kit} \
    -x cuda:all \
	--records_per_fastq 0 \
	--save_path /lscratch/$SLURM_JOBID/{params.sample}
find /lscratch/$SLURM_JOBID/{params.sample} -name "*.fastq" -exec cat {} \; \
	| gzip -n - > {output.outfastq}
"""